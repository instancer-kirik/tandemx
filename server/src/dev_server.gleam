import argv
import chartspace_server
import gleam/bytes_tree
import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import glenvy/dotenv
import glenvy/env
import mist.{type Connection, type ResponseData, Bytes, Text, websocket}
import simplifile
import token_upgrade_api

//add gravatar (glevatar)for easy multiprofiles with links and payment opts
pub type CartState {
  CartState(items: String)
}

pub type CartActor {
  CartActor(state: CartState, connections: List(String))
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
  // TEMPORARY DEBUG: Only check dist directory for JS files
  let paths = case string.ends_with(path, ".js") {
    True -> [string.concat(["../client/dist/", path])]
    False -> [
      // Keep original paths for non-JS files
      string.concat(["../client/dist/", path]),
      // Check dist first
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
  }

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
fn should_ignore_db_errors(_args: List(String)) -> Bool {
  // Check for the flag file first (simple approach)
  check_file_exists(".disable_db")
}

// Helper to get env var or use a default/error
fn get_env(variable_name: String, default: String) -> String {
  // Use glenvy/env.get_string which returns Result(String, env.VariableError)
  case env.get_string(variable_name) {
    Ok(value) -> value
    Error(_) -> {
      // Handle env.VariableError (NotPresent, InvalidUtf8)
      // Log a warning in a real app if a required env var is missing
      io.println(
        "Warning: Environment variable "
        <> variable_name
        <> " not set or invalid. Using default.",
      )
      default
    }
  }
}

pub fn main() {
  // Load environment variables from .env file using glenvy/dotenv
  let _ = dotenv.load()
  // Use glenvy's dotenv.load()

  // Read Supabase config from environment variables
  let supabase_url = get_env("SUPABASE_URL", "")
  // Provide empty default or placeholder
  let supabase_anon_key = get_env("SUPABASE_ANON_KEY", "")
  // Provide empty default

  // Warn if essential config is missing
  case supabase_url == "" {
    True -> io.println("Warning: SUPABASE_URL is not set!")
    False -> Nil
    // Do nothing if set
  }
  case supabase_anon_key == "" {
    True -> io.println("Warning: SUPABASE_ANON_KEY is not set!")
    False -> Nil
    // Do nothing if set
  }

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
  let _chartspace_actor = case chartspace_server.start() {
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
          let _subject = process.new_subject()
          process.sleep(100)
          // Give logger time to print
          panic as "Server cannot start without chartspace actor"
        }
      }
    }
  }

  let handler = fn(req: Request(Connection)) {
    case request.path_segments(req) {
      [] -> serve_html("index.html")

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
          on_init: fn(_conn) { #(chartspace_state, Some(selector)) },
          on_close: fn(_state) { io.println("Chartspace WebSocket closed") },
          handler: fn(state, conn, msg) {
            let #(new_state, _) =
              chartspace_server.handle_message(state, conn, msg, [])
            actor.continue(new_state)
          },
        )
      }

      // --- API Routes --- 
      ["api", "config"] -> {
        case req.method {
          Get -> {
            let config_json =
              json.object([
                #("supabaseUrl", json.string(supabase_url)),
                #("supabaseAnonKey", json.string(supabase_anon_key)),
              ])
            let body = json.to_string(config_json)
            response.new(200)
            |> response.set_header("content-type", "application/json")
            |> response.set_body(Bytes(bytes_tree.from_string(body)))
          }
          _ -> serve_404()
        }
      }
      ["api", "schedule-meeting"] -> {
        case req.method {
          Post -> {
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
          _ -> serve_404()
        }
      }
      ["api", "access-content", "create"] -> {
        case req.method {
          Post -> {
            case mist.read_body(req, 1024 * 1024) {
              Ok(req_with_body) -> {
                // Now use req_with_body.body
                io.println(
                  "\nInstance Access Content creation request received",
                )
                io.println(
                  "Request body: " <> string.inspect(req_with_body.body),
                )

                // Return success response
                response.new(200)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(
                  Bytes(bytes_tree.from_string(
                    "{\"status\":\"success\",\"message\":\"Content created successfully\"}",
                  )),
                )
              }
              Error(_) -> {
                bad_request(
                  "Invalid or missing request body for instance access content",
                )
              }
            }
          }
          _ -> {
            serve_404()
          }
        }
      }

      // Token/Upgrade API routes
      ["api", "tokens"] -> {
        case req.method {
          Get ->
            token_upgrade_api.handle_token_upgrade_request(
              ["tokens"],
              Get,
              None,
            )
          _ -> serve_404()
        }
      }
      ["api", "upgrades"] -> {
        case req.method {
          Get ->
            token_upgrade_api.handle_token_upgrade_request(
              ["upgrades"],
              Get,
              None,
            )
          _ -> serve_404()
        }
      }
      ["api", "payment-options"] -> {
        case req.method {
          Get ->
            token_upgrade_api.handle_token_upgrade_request(
              ["payment-options"],
              Get,
              None,
            )
          _ -> serve_404()
        }
      }
      ["api", "badges", user_id] -> {
        case req.method {
          Get ->
            token_upgrade_api.handle_token_upgrade_request(
              ["badges", user_id],
              Get,
              None,
            )
          _ -> serve_404()
        }
      }
      ["api", "purchase", "token", user_id, token_id] -> {
        case req.method {
          Post -> {
            case mist.read_body(req, 1024 * 1024) {
              Ok(req_with_body) -> {
                // Use dynamic.from
                let dynamic_body = dynamic.from(req_with_body.body)
                token_upgrade_api.handle_token_upgrade_request(
                  ["purchase", "token", user_id, token_id],
                  Post,
                  Some(dynamic_body),
                  // Pass dynamic body
                )
              }
              Error(_) -> bad_request("Invalid or missing request body")
            }
          }
          _ -> serve_404()
        }
      }
      ["api", "purchase", "upgrade", user_id, upgrade_id] -> {
        case req.method {
          Post -> {
            case mist.read_body(req, 1024 * 1024) {
              Ok(req_with_body) -> {
                // Use dynamic.from
                let dynamic_body = dynamic.from(req_with_body.body)
                token_upgrade_api.handle_token_upgrade_request(
                  ["purchase", "upgrade", user_id, upgrade_id],
                  Post,
                  Some(dynamic_body),
                  // Pass dynamic body
                )
              }
              Error(_) -> bad_request("Invalid or missing request body")
            }
          }
          _ -> serve_404()
        }
      }
      // --- Handle Specific Page/Asset Routes (Assume GET) --- 
      ["landing"] -> serve_html("index.html")
      ["pricing"] -> serve_html("pricing.html")
      ["terms-and-conditions"] -> serve_html("terms-and-conditions.html")
      ["poemsmith"] -> serve_html("landing.html")
      ["veix"] -> serve_html("veix_about.html")
      ["art-techniques"] -> serve_html("art_techniques.html")

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
      ["calendar"] -> serve_html("calendar.html")
      ["calendar.css"] -> serve_css("calendar.css")
      ["calendar.mjs"] -> serve_file("calendar.mjs", "text/javascript")
      ["calendar_ffi.js"] -> serve_file("calendar_ffi.js", "text/javascript")

      ["compliance", "audit"] -> serve_html("compliance.html")
      ["compliance", "reports"] -> serve_html("compliance.html")
      ["compliance", "tax"] -> serve_html("compliance.html")
      ["access-content"] -> serve_html("access_content.html")
      ["access-content", _post_slug] -> {
        // Handle individual content item view by slug
        // The actual logic is handled client-side, so just serve the main HTML
        serve_html("access_content.html")
        // Serve the container HTML
      }
      ["access-content", ..rest] -> {
        case rest {
          // Special asset routes
          ["markdown_parser.js"] ->
            serve_file("access_content/markdown_parser.js", "text/javascript")
          ["access_content_renderer.js"] ->
            serve_file(
              "access_content/access_content_renderer.js",
              "text/javascript",
            )
          ["index.json"] ->
            serve_file("access_content/index.json", "application/json")
          // Other asset fallbacks if necessary can go here
          _ -> serve_404()
          // Or serve the main html? Let's 404 for now.
        }
      }
      ["access_content.css"] -> serve_css("access_content.css")

      // Serve content images from assets directory
      ["assets", "blog-images", ..rest] -> {
        let file_path = string.join(rest, "/")
        case try_serve_static_file("assets/blog-images/" <> file_path) {
          Ok(response) -> response
          Error(_) -> serve_404()
        }
      }

      ["assets", ..rest] -> {
        let file_path = string.join(rest, "/")
        case try_serve_static_file("assets/" <> file_path) {
          Ok(response) -> response
          Error(_) -> serve_404()
        }
      }

      // --- Fallback for General File Serving (Assume GET) --- 
      segments -> {
        let file_path = string.join(segments, "/")
        case try_serve_static_file(file_path) {
          Ok(response) -> response
          Error(_) -> serve_404()
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

fn serve_file(filename: String, content_type: String) -> Response(ResponseData) {
  case try_serve_static_file(filename) {
    Ok(response) -> {
      // Apply the content type specified
      response
      |> response.set_header("content-type", content_type)
    }
    Error(_) -> serve_404()
  }
}

fn decode_meeting_decoder() -> decode.Decoder(Meeting) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.string)
    use date <- decode.field("date", decode.string)
    use start_time <- decode.field("start_time", decode.string)
    use duration_minutes <- decode.field("duration_minutes", decode.int)
    use attendees <- decode.field("attendees", decode.list(decode.string))
    use timezone <- decode.field("timezone", decode.string)
    decode.success(Meeting(
      id,
      title,
      description,
      date,
      start_time,
      duration_minutes,
      attendees,
      timezone,
    ))
  }
}

fn decode_meeting(
  data: dynamic.Dynamic,
) -> Result(Meeting, List(decode.DecodeError)) {
  decode.run(data, decode_meeting_decoder())
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

// Define the decoder logic for InterestSubmission
fn interest_submission_decoder() -> decode.Decoder(InterestSubmission) {
  {
    use project <- decode.field("project", decode.string)
    use email <- decode.field("email", decode.string)
    use name <- decode.field("name", decode.string)
    use company <- decode.field("company", decode.string)
    use message <- decode.field("message", decode.string)
    decode.success(InterestSubmission(project, email, name, company, message))
  }
}

fn decode_interest_submission(
  data: dynamic.Dynamic,
) -> Result(InterestSubmission, List(decode.DecodeError)) {
  decode.run(data, interest_submission_decoder())
}

fn bad_request(message: String) -> Response(ResponseData) {
  let error_json = json.object([#("error", json.string(message))])
  let body = json.to_string(error_json)
  response.new(400)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(Bytes(bytes_tree.from_string(body)))
}
