import argv
import chartspace_server
import findry_server
import gleam/bytes_tree
import gleam/dynamic
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/json
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

//add gravatar (glevatar)for easy multiprofiles with links and payment opts
pub type CartState {
  CartState(items: String)
}

pub type CartActor {
  CartActor(state: CartState, connections: List(Connection))
}

pub type Meeting {
  Meeting(
    id: String,
    title: String,
    description: String,
    date: String,
    start_time: String,
    duration_minutes: Int,
    attendees: List(String),
    timezone: String,
  )
}

pub type EmailNotification {
  EmailNotification(to: String, subject: String, body: String)
}

pub type InterestSubmission {
  InterestSubmission(
    project: String,
    email: String,
    name: String,
    company: String,
    message: String,
  )
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
    string.concat(["../client/node_modules/", path]),
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
        Ok("js") | Ok("mjs") | Ok("jsx") -> "text/javascript"
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

  // Initialize findry
  let findry_state = findry_server.init()
  let assert Ok(findry_actor) = findry_server.start()

  let handler = fn(req: Request(Connection)) {
    case request.path_segments(req) {
      [] -> serve_html("app.html")
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

      ["ws", "findry"] -> {
        let selector = process.new_selector()
        websocket(
          request: req,
          on_init: fn(conn) { #(findry_state, Some(selector)) },
          on_close: fn(_state) { io.println("Findry WebSocket closed") },
          handler: fn(state, conn, msg) {
            let #(new_state, _) =
              findry_server.handle_message(state, conn, msg, [])
            actor.continue(new_state)
          },
        )
      }

      ["api", "schedule-meeting"] -> {
        case req.method {
          http.Post -> {
            case mist.read_body(req, 1024 * 1024) {
              Ok(req) -> {
                let json = dynamic.from(req.body)
                case decode_meeting(json) {
                  Ok(meeting) -> {
                    // Send email notifications to all attendees
                    let notifications =
                      list.map(meeting.attendees, fn(attendee) {
                        EmailNotification(
                          to: attendee,
                          subject: "New Meeting: " <> meeting.title,
                          body: string.concat([
                            "You have been invited to a meeting:\n\n",
                            "Title: ",
                            meeting.title,
                            "\n",
                            "Description: ",
                            meeting.description,
                            "\n",
                            "Date: ",
                            meeting.date,
                            "\n",
                            "Time: ",
                            meeting.start_time,
                            " (",
                            meeting.timezone,
                            ")\n",
                            "Duration: ",
                            int.to_string(meeting.duration_minutes),
                            " minutes\n",
                          ]),
                        )
                      })

                    // Send emails (this would connect to an email service in production)
                    let _ = list.map(notifications, send_email)

                    response.new(200)
                    |> response.set_header("content-type", "application/json")
                    |> response.set_body(
                      Bytes(bytes_tree.from_string("{\"status\":\"success\"}")),
                    )
                  }
                  Error(_) ->
                    response.new(400)
                    |> response.set_header("content-type", "application/json")
                    |> response.set_body(
                      Bytes(bytes_tree.from_string(
                        "{\"error\":\"Invalid request data\"}",
                      )),
                    )
                }
              }
              Error(_) ->
                response.new(400)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(
                  Bytes(bytes_tree.from_string(
                    "{\"error\":\"Invalid request body\"}",
                  )),
                )
            }
          }
          _ ->
            response.new(405)
            |> response.set_header("content-type", "application/json")
            |> response.set_body(
              Bytes(bytes_tree.from_string("{\"error\":\"Method not allowed\"}")),
            )
        }
      }

      segments -> {
        case segments {
          // Main app routes
          ["app.html"] -> serve_html("app.html")
          ["app.css"] -> serve_css("app.css")
          ["app.mjs"] -> serve_file("app.mjs", "text/javascript")
          ["app_ffi.js"] -> serve_file("app_ffi.js", "text/javascript")

          // Events module routes
          ["events"] -> serve_html("events/events.html")
          ["events", "share"] -> serve_html("events/events.html")
          ["events", "events.css"] -> serve_css("events/events.css")
          ["events", "events.html"] -> serve_html("events/events.html")
          ["events", "events.mjs"] ->
            serve_file("events/events.mjs", "text/javascript")
          ["events", "events_ffi.js"] ->
            serve_file("events/events_ffi.js", "text/javascript")
          ["events", event_id] -> serve_html("events/events.html")

          // Revert to serving individual HTML files for each route
          ["bizpay"] -> serve_html("bizpay.html")
          ["divvyqueue"] -> serve_html("divvyqueue.html")
          ["findry"] -> serve_html("findry.html")
          ["projects"] -> serve_html("projects.html")
          ["login"] -> serve_html("login.html")
          ["signup"] -> serve_html("signup.html")

          // Non-SPA routes
          ["landing"] -> serve_html("landing.html")
          ["revu"] -> serve_html("revu.html")
          ["revu", "curl_tool.css"] -> serve_css("revu/curl_tool.css")
          ["divvyqueue", "contracts"] -> serve_html("contracts.html")
          ["contracts"] -> serve_html("contracts.html")
          ["ambigunector", "ambigunector_ffi.js"] ->
            serve_file("ambigunector/ambigunector_ffi.js", "text/javascript")
          ["findry", "findry.css"] -> serve_css("findry/findry.css")
          ["findry", "findry.js"] ->
            serve_file("findry/findry.js", "text/javascript")
          ["findry", "spaces"] -> serve_html("findry.html")
          ["styles.css"] -> serve_css("styles.css")
          ["landing.css"] -> serve_css("landing.css")
          ["chartspace.css"] -> serve_css("chartspace.css")
          ["campaign-form.css"] -> serve_css("campaign-form.css")
          ["projects.css"] -> serve_css("projects.css")
          ["bizpay", "features"] -> serve_html("bizpay.html")
          ["bizpay", "pricing"] -> serve_html("bizpay.html")
          ["bizpay", "docs"] -> serve_html("bizpay.html")
          ["bizpay", "demo"] -> serve_html("bizpay.html")
          ["bizpay", "contact"] -> serve_html("bizpay.html")
          ["bizpay", "interest"] -> handle_interest_form("bizpay")
          ["bizpay.css"] -> serve_css("bizpay.css")
          [project_name, "interest"] -> handle_interest_form(project_name)
          ["sledge"] -> serve_html("sledge.html")
          ["dd"] -> serve_html("dd.html")
          ["shiny"] -> serve_html("shiny.html")
          ["space-captains"] -> serve_html("space-captains.html")
          ["hunter"] -> serve_html("hunter.html")
          ["chartspace"] -> serve_html("chartspace.html")
          ["compliance"] -> serve_html("compliance.html")
          ["buzzpay"] -> serve_html("buzzpay.html")
          ["todos"] -> serve_html("todos.html")
          ["banking"] -> serve_html("banking.html")
          ["cards"] -> serve_html("cards.html")
          ["currency"] -> serve_html("currency.html")
          ["bills"] -> serve_html("bills.html")
          ["payroll"] -> serve_html("payroll.html")
          ["tax"] -> serve_html("tax.html")
          ["ads"] -> serve_html("ads.html")
          ["settings"] -> serve_html("settings.html")
          ["calendar"] -> serve_html("calendar.html")
          ["calendar.css"] -> serve_css("calendar.css")
          ["calendar.mjs"] -> serve_file("calendar.mjs", "text/javascript")
          ["calendar_ffi.js"] ->
            serve_file("calendar_ffi.js", "text/javascript")
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
    |> mist.bind("0.0.0.0")
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

fn decode_meeting(
  json: dynamic.Dynamic,
) -> Result(Meeting, List(dynamic.DecodeError)) {
  dynamic.decode8(
    Meeting,
    dynamic.field("id", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("date", dynamic.string),
    dynamic.field("start_time", dynamic.string),
    dynamic.field("duration_minutes", dynamic.int),
    dynamic.field("attendees", dynamic.list(dynamic.string)),
    dynamic.field("timezone", dynamic.string),
  )(json)
}

@external(erlang, "io", "format")
fn io_format(format: String, args: List(String)) -> Nil

fn send_email(notification: EmailNotification) -> Result(Nil, String) {
  io_format("Sending email:\nTo: ~s\nSubject: ~s\nBody: ~s\n---\n", [
    notification.to,
    notification.subject,
    notification.body,
  ])
  Ok(Nil)
}

fn handle_interest_form(project_name: String) -> Response(ResponseData) {
  // TODO: In the future, this will store interest in a database
  // For now, we'll just return a JSON response
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(
    Bytes(bytes_tree.from_string(
      "{\"status\":\"success\",\"message\":\"Thank you for your interest in "
      <> project_name
      <> "\"}",
    )),
  )
}

fn decode_interest_submission(
  json: dynamic.Dynamic,
) -> Result(InterestSubmission, List(dynamic.DecodeError)) {
  dynamic.decode5(
    InterestSubmission,
    dynamic.field("project", dynamic.string),
    dynamic.field("email", dynamic.string),
    dynamic.field("name", dynamic.string),
    dynamic.field("company", dynamic.string),
    dynamic.field("message", dynamic.string),
  )(json)
}

fn serve_file(filename: String, content_type: String) -> Response(ResponseData) {
  case try_serve_static_file(filename) {
    Ok(response) -> response
    Error(_) -> serve_404()
  }
}
