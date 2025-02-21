import argv
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http.{Delete, Get, Post, Put}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import mist.{type Connection, type ResponseData, Bytes}
import simplifile

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

  let handler = fn(req: Request(Connection)) -> Response(ResponseData) {
    // Print request path for debugging
    io.println("\n=== Request received ===")
    io.println("  Path: " <> req.path)
    io.println("  Method: " <> method_to_string(req.method))
    io.println(
      "  Headers: "
      <> string.join(
        list.map(req.headers, fn(h) { h.0 <> ": " <> h.1 }),
        "\n    ",
      ),
    )

    case req.path {
      "/" | "/divvyqueue" -> serve_html("divvyqueue.html")
      "/todos" -> serve_html("index.html")
      "/cards" -> serve_html("cards.html")
      "/divvyqueue/contracts" -> serve_html("contracts.html")
      "/styles.css" -> serve_css("styles.css")

      "/favicon.ico" -> {
        // Return empty 204 for favicon requests
        response.new(204)
        |> response.map(fn(_) { Bytes(bytes_tree.from_string("")) })
      }

      "/debug/files" -> {
        let assert Ok(files) = simplifile.read_directory("../client/build")
        let content = string.join(files, "\n")
        serve_content(content, "text/plain")
      }

      // Handle JavaScript files from build directory
      path -> {
        case string.starts_with(path, "/build/dev/javascript/") {
          True -> {
            let paths = [
              string.concat(["client", path]),
              string.concat(["../client", path]),
              "../client/build/dev/javascript/tandemx_client/cards.mjs",
              "../client/build/dev/javascript/tandemx_client/contracts.mjs",
              "../client/build/dev/javascript/tandemx_client/todomvc.mjs",
            ]

            io.println("\nServing JavaScript file:")
            io.println("  Path: " <> path)

            case try_paths(paths, path) {
              Ok(content) -> {
                response.new(200)
                |> response.set_header("content-type", "text/javascript")
                |> response.set_header("access-control-allow-origin", "*")
                |> response.set_body(content)
                |> response.map(fn(_) { Bytes(bytes_tree.from_string(content)) })
              }
              Error(_) -> serve_404()
            }
          }
          False -> serve_404()
        }
      }
    }
  }

  // Try to start server on specified port
  io.println("\n=== Starting server ===")
  io.println("Port: " <> int.to_string(port))
  io.println(
    "Current directory: "
    <> case simplifile.current_directory() {
      Ok(dir) -> dir
      Error(_) -> "unknown"
    },
  )

  case mist.new(handler) |> mist.port(port) |> mist.start_http() {
    Ok(_server) -> {
      io.println("\n✅ Server started successfully")
      io.println("URL: http://localhost:" <> int.to_string(port))
      process.sleep_forever()
      Ok(Nil)
    }
    Error(e) -> {
      io.println("\n❌ Failed to start server")
      io.println("Error: " <> string.inspect(e))
      Error(Nil)
    }
  }
}

fn method_to_string(method) {
  case method {
    Get -> "GET"
    Post -> "POST"
    Put -> "PUT"
    Delete -> "DELETE"
    _ -> "OTHER"
  }
}

fn try_paths(paths: List(String), _filename: String) -> Result(String, Nil) {
  list.fold_until(paths, Error(Nil), fn(acc, path) {
    case simplifile.read(path) {
      Ok(content) -> {
        io.println("  ✓ Found: " <> path)
        list.Stop(Ok(content))
      }
      Error(_) -> {
        io.println("  × Not found: " <> path)
        list.Continue(acc)
      }
    }
  })
}

fn serve_content(
  content: String,
  content_type: String,
) -> Response(ResponseData) {
  io.println("  Serving " <> content_type <> " content")
  response.new(200)
  |> response.set_header("content-type", content_type)
  |> response.set_body(content)
  |> response.map(fn(_) { Bytes(bytes_tree.from_string(content)) })
}

fn serve_404() -> Response(ResponseData) {
  io.println("  Returning 404 Not Found")
  response.new(404)
  |> response.set_body("Not found")
  |> response.map(fn(_) { Bytes(bytes_tree.from_string("Not found")) })
}

fn serve_html(filename: String) -> Response(ResponseData) {
  let paths = [
    string.concat(["client/", filename]),
    string.concat(["../client/", filename]),
  ]
  case try_paths(paths, filename) {
    Ok(content) -> {
      io.println("✅ Serving " <> filename)
      serve_content(content, "text/html")
    }
    Error(_) -> serve_404()
  }
}

fn serve_css(filename: String) -> Response(ResponseData) {
  case simplifile.read(string.concat(["../client/", filename])) {
    Ok(content) -> {
      response.new(200)
      |> response.set_header("content-type", "text/css")
      |> response.set_body(content)
      |> response.map(fn(_) { Bytes(bytes_tree.from_string(content)) })
    }
    Error(_) -> serve_404()
  }
}
