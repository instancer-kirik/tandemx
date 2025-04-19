import argv
import chartspace_server
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
    list.find(paths, fn(p) { simplifile.is_file(p) |> result.unwrap(False) })
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

// Check if a file exists in the server directory
fn check_file_exists(filename: String) -> Bool {
  simplifile.is_file(filename)
  |> result.unwrap(False)
}

// Check if we should ignore database errors
fn should_ignore_db_errors(args: List(String)) -> Bool {
  // Check for the flag file first (simple approach)
  check_file_exists(".disable_db")
}

pub fn main() {
  // Get all arguments
  let args = argv.load().arguments
  io.println("\nArguments: " <> string.join(args, ", "))

  // Check if we should ignore DB errors
  let ignore_db_errors = should_ignore_db_errors(args)

  // Print the status of database error handling
  case ignore_db_errors {
    True ->
      io.println("Database errors will be ignored (running in standalone mode)")
    False -> io.println("Database features are enabled")
  }

  // Get port from arguments, default to 8000
  let port = case args {
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

  // Initialize chartspace (with DB errors flag)
  let chartspace_state = chartspace_server.init()
  let chartspace_actor = case chartspace_server.start() {
    Ok(actor) -> actor
    Error(error) -> {
      // Only abort if we're not ignoring DB errors
      case ignore_db_errors {
        True -> {
          io.println(
            "WARNING: Chartspace actor failed to start, but continuing anyway",
          )
          io.println("Error was: " <> string.inspect(error))
          // Create an empty subject with the correct type
          process.new_subject()
        }
        False -> {
          io.println(
            "ERROR: Chartspace actor failed to start: " <> string.inspect(error),
          )
          // Still need to return a subject even if we'll exit shortly
          let subject = process.new_subject()
          process.sleep(100)
          // Give logger time to print
          panic as "Server cannot start without chartspace actor"
        }
      }
    }
  }

  let handler = fn(req: Request(Connection)) {
    case request.path_segments(req) {
      [] -> serve_html("landing.html")
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
          ["landing"] -> serve_html("landing.html")

          ["pricing"] -> serve_html("pricing.html")
          ["terms-and-conditions"] -> serve_html("terms-and-conditions.html")
          ["poemsmith"] -> serve_html("landing.html")
          // Temporary redirect until PoemSmith is ready
          ["bizpay", "api", "submit-interest"] -> {
            case req.method {
              http.Post -> {
                case mist.read_body(req, 1024 * 1024) {
                  Ok(req) -> {
                    let json = dynamic.from(req.body)
                    case decode_interest_submission(json) {
                      Ok(submission) -> {
                        // TODO: Store in database
                        // For now, just log it
                        io.println(
                          string.concat([
                            "\nNew interest submission:\n",
                            "Project: ",
                            submission.project,
                            "\nName: ",
                            submission.name,
                            "\nEmail: ",
                            submission.email,
                            "\nCompany: ",
                            submission.company,
                            "\nMessage: ",
                            submission.message,
                          ]),
                        )

                        response.new(200)
                        |> response.set_header(
                          "content-type",
                          "application/json",
                        )
                        |> response.set_body(
                          Bytes(bytes_tree.from_string(
                            "{\"status\":\"success\",\"message\":\"Thank you for your interest! We'll be in touch soon.\"}",
                          )),
                        )
                      }
                      Error(_) ->
                        response.new(400)
                        |> response.set_header(
                          "content-type",
                          "application/json",
                        )
                        |> response.set_body(
                          Bytes(bytes_tree.from_string(
                            "{\"error\":\"Invalid submission data\"}",
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
                  Bytes(bytes_tree.from_string(
                    "{\"error\":\"Method not allowed\"}",
                  )),
                )
            }
          }
          ["bizpay.css"] -> serve_css("bizpay.css")
          [project_name, "interest"] -> handle_interest_form(project_name)
          ["projects"] -> serve_html("projects.html")
          ["sledge"] -> serve_html("sledge.html")
          ["dd"] -> serve_html("dd.html")
          ["shiny"] -> serve_html("shiny.html")
          ["space-captains"] -> serve_html("space-captains.html")
          ["hunter"] -> serve_html("hunter.html")
          ["chartspace"] -> serve_html("chartspace.html")
          ["compliance"] -> serve_html("compliance.html")
          ["buzzpay"] -> serve_html("buzzpay.html")
          ["styles.css"] -> serve_css("styles.css")
          ["landing.css"] -> serve_css("landing.css")
          ["chartspace.css"] -> serve_css("chartspace.css")
          ["campaign-form.css"] -> serve_css("campaign-form.css")
          ["projects.css"] -> serve_css("projects.css")
          ["todos"] -> serve_html("todos.html")
          ["banking"] -> serve_html("banking.html")
          ["cards"] -> serve_html("cards.html")
          ["currency"] -> serve_html("currency.html")
          ["bills"] -> serve_html("bills.html")
          ["payroll"] -> serve_html("payroll.html")
          ["tax"] -> serve_html("tax.html")
          ["ads"] -> serve_html("ads.html")
          ["styles.css"] -> serve_css("styles.css")
          ["chartspace"] -> serve_html("chartspace.html")
          ["chartspace", "editor"] -> serve_html("chartspace.html")
          ["chartspace", "viewer"] -> serve_html("chartspace.html")
          ["settings"] -> serve_html("settings.html")
          ["calendar"] -> serve_html("calendar.html")
          ["calendar.css"] -> serve_css("calendar.css")
          ["calendar.mjs"] -> serve_file("calendar.mjs", "text/javascript")
          ["calendar_ffi.js"] ->
            serve_file("calendar_ffi.js", "text/javascript")
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
  // Return a JSON response
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
