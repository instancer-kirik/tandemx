import argv
import chartspace_server
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage, Bytes, Text, websocket,
}
import simplifile

pub type CartState {
  CartState(items: String)
}

pub type CartActor {
  CartActor(state: CartState, connections: List(Connection))
}

fn try_serve_static_file(path: String) -> Result(Response(ResponseData), Nil) {
  let paths = [
    string.concat(["../client/", path]),
    string.concat(["../client/src/", path]),
    string.concat(["../client/build/", path]),
    string.concat(["../client/build/dev/", path]),
    string.concat(["../client/build/dev/javascript/", path]),
    string.concat(["../client/build/dev/javascript/tandemx_client/", path]),
    string.concat(["../client/build/dev/javascript/gleam_stdlib/gleam/", path]),
    string.concat(["../client/build/dev/javascript/lustre/", path]),
    string.concat(["../client/build/dev/javascript/lustre/lustre/", path]),
  ]

  io.println("\nTrying to serve: " <> path)
  io.println("Checking paths:")
  list.each(paths, fn(p) { io.println("  - " <> p) })

  case
    list.find(paths, fn(p) {
      simplifile.verify_is_file(p) |> result.unwrap(False)
    })
  {
    Ok(file_path) -> {
      io.println("  Found at: " <> file_path)
      let assert Ok(content) = simplifile.read(file_path)
      let content_type = case string.split(path, ".") |> list.last {
        Ok("js") | Ok("mjs") -> "text/javascript"
        Ok("css") -> "text/css"
        Ok("html") -> "text/html"
        Ok("ico") -> "image/x-icon"
        Ok("jpg") | Ok("jpeg") -> "image/jpeg"
        Ok("png") -> "image/png"
        Ok("svg") -> "image/svg+xml"
        Ok("woff") | Ok("woff2") -> "font/woff2"
        Ok("ttf") -> "font/ttf"
        _ -> "application/octet-stream"
      }
      Ok(
        response.new(200)
        |> response.set_header("content-type", content_type)
        |> response.set_body(Bytes(bytes_tree.from_string(content))),
      )
    }
    Error(_) -> {
      io.println("  Not found in any location!")
      Error(Nil)
    }
  }
}

pub fn main() {
  // Get port from arguments, default to 8000
  io.println("\nArguments: " <> string.join(argv.load().arguments, ", "))
  let port = case argv.load().arguments {
    ["--port", port_str, ..] -> {
      io.println("Found port argument: " <> port_str)
      case int.parse(port_str) {
        Ok(port) -> {
          io.println("Using port: " <> int.to_string(port))
          port
        }
        Error(_) -> {
          io.println("Invalid port, using default: 8000")
          8000
        }
      }
    }
    _ -> {
      io.println("No port argument, using default: 8000")
      8000
    }
  }

  let cart_state = CartState(items: "[]")
  let _cart_actor = CartActor(state: cart_state, connections: [])

  // Initialize chartspace
  let chartspace_state = chartspace_server.init()
  let assert Ok(chartspace_actor) = chartspace_server.start()

  let handler = fn(req: Request(Connection)) {
    case request.path_segments(req) {
      ["ws", "cart"] -> {
        let selector = process.new_selector()
        websocket(
          request: req,
          on_init: fn(_conn) { #(cart_state, Some(selector)) },
          on_close: fn(_state) { io.println("Cart WebSocket closed") },
          handler: fn(state, conn, msg) {
            case msg {
              Text(text) -> {
                let assert Ok(_) = mist.send_text_frame(conn, text)
                actor.continue(state)
              }
              _ -> actor.continue(state)
            }
          },
        )
      }

      ["ws", "chartspace"] -> {
        let selector = process.new_selector()
        websocket(
          request: req,
          on_init: fn(conn) { #(chartspace_state, Some(selector)) },
          on_close: fn(_state) { io.println("Chartspace WebSocket closed") },
          handler: fn(state, conn, msg) {
            let #(new_state, _) =
              chartspace_server.handle_message(state, conn, msg, [])
            actor.continue(new_state)
          },
        )
      }

      segments -> {
        case segments {
          [] -> serve_html("divvyqueue.html")
          ["divvyqueue"] -> serve_html("divvyqueue.html")
          ["todos"] -> serve_html("todos.html")
          ["banking"] -> serve_html("banking.html")
          ["cards"] -> serve_html("cards.html")
          ["currency"] -> serve_html("currency.html")
          ["bills"] -> serve_html("bills.html")
          ["payroll"] -> serve_html("payroll.html")
          ["tax"] -> serve_html("tax.html")
          ["ads"] -> serve_html("ads.html")
          ["partner-progress"] -> serve_html("partner_progress.html")
          ["divvyqueue", "contracts"] -> serve_html("contracts.html")
          ["form-analyzer"] -> serve_html("form_analyzer.html")
          ["constructs"] -> serve_html("constructs.html")
          ["constructs", "works"] -> serve_html("constructs.html")
          ["constructs", "personas"] -> serve_html("constructs.html")
          ["constructs", "social"] -> serve_html("constructs.html")
          ["constructs", "metrics"] -> serve_html("constructs.html")
          ["chartspace"] -> serve_html("chartspace.html")
          ["chartspace", "editor"] -> serve_html("chartspace.html")
          ["chartspace", "viewer"] -> serve_html("chartspace.html")
          ["settings"] -> serve_html("settings.html")
          ["compliance"] -> serve_html("compliance.html")
          ["compliance", "audit"] -> serve_html("compliance.html")
          ["compliance", "reports"] -> serve_html("compliance.html")
          ["compliance", "tax"] -> serve_html("compliance.html")
          ["debug", "files"] -> {
            let assert Ok(files) = simplifile.read_directory("../client/build")
            let content = string.join(files, "\n")
            serve_content(content, "text/plain")
          }
          ["assets", ..rest] -> {
            let file_path = string.join(rest, "/")
            case try_serve_static_file("assets/" <> file_path) {
              Ok(response) -> response
              Error(_) -> serve_404()
            }
          }
          path -> {
            let file_path = string.join(path, "/")
            case try_serve_static_file(file_path) {
              Ok(response) -> response
              Error(_) -> serve_404()
            }
          }
        }
      }
    }
  }

  // Start server
  let assert Ok(_) =
    handler
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}

fn serve_404() -> Response(ResponseData) {
  response.new(404)
  |> response.set_body(Bytes(bytes_tree.from_string("Not found")))
}

fn serve_html(filename: String) -> Response(ResponseData) {
  case try_serve_static_file(filename) {
    Ok(response) -> response
    Error(_) -> serve_404()
  }
}

fn serve_css(filename: String) -> Response(ResponseData) {
  case try_serve_static_file(filename) {
    Ok(response) -> response
    Error(_) -> serve_404()
  }
}

fn serve_content(
  content: String,
  content_type: String,
) -> Response(ResponseData) {
  response.new(200)
  |> response.set_header("content-type", content_type)
  |> response.set_body(Bytes(bytes_tree.from_string(content)))
}
