import argv
import db_init
import dot_env
import findry_server
import gleam/bytes_tree
import gleam/dynamic
import gleam/erlang/process
import gleam/float
import gleam/http.{Delete, Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/http/service
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist

import chartspace_server
import meeting_server
import simplifile
import wishlist_api.{get_mock_products, get_mock_specs}

// Temporarily commented out due to module issues
// import tandemx_server/cart
// import tandemx_server/cart_actor
// import tandemx_server/chartspace
// import tandemx_server/findry
// import tandemx_server/wishlist_api

//add gravatar (glevatar)for easy multiprofiles with links and payment opts
pub type CartMessage {
  AddItem(Int, String, Float)
  RemoveItem(Int)
  UpdateQuantity(Int, Int)
  SyncState(String)
}

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
    location_type: String,
    location: String,
  )
}

pub type EmailNotification {
  EmailNotification(to: String, subject: String, body: String, from: String)
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

// Define missing types
pub type ResponseData {
  Bytes(bytes_tree.BytesTree)
  String(String)
}

pub type WebsocketConnection {
  WebsocketConnection
}

pub type WebsocketMessage(a) {
  Text(a)
  Binary(String)
}

fn try_serve_static_file(path: String) -> Result(Response(ResponseData), Nil) {
  let paths = [
    // Client source files - try these first for faster development
    string.concat(["../client/src/", path]),
    string.concat(["../client/", path]),
    // Module-specific paths
    string.concat(["../client/src/events/", path]),
    string.concat(["../client/src/findry/", path]),
    string.concat(["../client/src/divvyqueue/", path]),
    string.concat(["../client/src/divvyqueue2/", path]),
    string.concat(["../client/src/projects/", path]),
    string.concat(["../client/src/components/", path]),
    string.concat(["../client/src/assets/", path]),
    string.concat(["../client/src/styles/", path]),
    // Build artifacts
    string.concat(["../client/build/dev/javascript/tandemx_client/", path]),
    string.concat(["../client/build/dev/javascript/", path]),
    // FFI files
    string.concat(["../client/src/findry/findry_ffi.js"]),
    string.concat(["../client/src/events/events_ffi.js"]),
    string.concat(["../client/src/calendar_ffi.js"]),
    // Dependencies
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
        Ok("js") | Ok("mjs") | Ok("jsx") -> "application/javascript"
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
  let assert Ok(_) = dot_env.load()

  // Commented out due to missing modules
  // let assert Ok(port) = env.get("PORT")
  // let assert Ok(port) = string.to_int(port)
  let port = 8000
  // Default port

  // Commented out due to missing modules
  // let assert Ok(_) = cart_actor.start()
  // let assert Ok(_) = chartspace.start()
  // let assert Ok(_) = findry.start()

  // let handler = wisp_mist.handler(fn(req) { handle_request(req) })
  let handler = fn(req) { handle_request(req) }

  let assert Ok(_) = mist.new()
  let assert Ok(_) = mist.start(handler, port)

  io.println("Server started on port " <> string.from_int(port))
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

// Meeting handling functionality moved to the meeting_server module

@external(erlang, "io", "format")
fn io_format(format: String, args: List(String)) -> Nil

fn send_email(notification: EmailNotification) -> Result(Nil, String) {
  io_format("Sending email:\nFrom: ~s\nTo: ~s\nSubject: ~s\nBody: ~s\n---\n", [
    notification.from,
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

fn serve_projects_partial(project_filter: String) -> Response(ResponseData) {
  // Simple implementation for now - just return placeholder HTML
  let html =
    "<div class=\"project-list\"><h3>Projects filtered by: "
    <> project_filter
    <> "</h3><p>This is a placeholder for filtered project listing.</p></div>"

  response.new(200)
  |> response.set_header("content-type", "text/html")
  |> response.set_body(Bytes(bytes_tree.from_string(html)))
}

fn serve_checkout_success() -> Response(ResponseData) {
  // Just show a simple success page for now
  response.new(200)
  |> response.set_header("content-type", "text/html")
  |> response.set_body(
    Bytes(bytes_tree.from_string(
      "<!DOCTYPE html><html><head><title>Checkout Success</title></head><body><h1>Checkout Success!</h1><p>Your order has been processed successfully.</p><p><a href=\"/\">Return to homepage</a></p></body></html>",
    )),
  )
}

// Helper to get current date formatted as "Month Day, Year"
fn get_current_date() -> String {
  // Just return hardcoded date for the example
  "March 12, 2024"
}

// Serve the cart page
fn serve_cart_page() -> Response(ResponseData) {
  serve_html("cart.html")
}

fn handle_get_request(req: Request(String)) -> Response(ResponseData) {
  case serve_static(req) {
    Ok(resp) -> resp
    Error(_) ->
      case handle_html_routes(req) {
        Ok(resp) -> resp
        Error(_) ->
          case handle_api_request(req) {
            Ok(resp) -> resp
            Error(_) -> not_found_response()
          }
      }
  }
}

fn handle_other_request(req: Request(String)) -> Response(ResponseData) {
  case handle_api_request(req) {
    Ok(resp) -> resp
    Error(_) -> not_found_response()
  }
}

fn not_found_response() -> Response(ResponseData) {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.from_string("Not Found")))
}

// Temporarily commented out
// fn handle_cart_message(
//   msg: CartMessage,
//   state: CartState,
// ) -> actor.Next(CartMessage, CartState) {
//   case msg {
//     AddItem(id, title, price) -> {
//       let new_state = CartState(items: state.items)
//       actor.continue(new_state)
//     }
//     RemoveItem(id) -> {
//       let new_state = CartState(items: state.items)
//       actor.continue(new_state)
//     }
//     UpdateQuantity(id, qty) -> {
//       let new_state = CartState(items: state.items)
//       actor.continue(new_state)
//     }
//     SyncState(items) -> {
//       let new_state = CartState(items: items)
//       actor.continue(new_state)
//     }
//   }
// }

fn handle_request(req: Request(String)) -> Response(ResponseData) {
  case req.path {
    "/ws/cart" -> {
      // Websocket handling temporarily disabled
      not_found_response()
      // Original code:
      // let assert Ok(actor) = cart_actor.start()
      // let ws_handler = fn(conn: WebsocketConnection) -> #(
      //   CartState,
      //   Option(process.Subject(CartMessage)),
      // ) {
      //   let state = CartState(items: "[]")
      //   #(state, Some(actor))
      // }
      // 
      // let msg_handler = fn(
      //   state: CartState,
      //   conn: WebsocketConnection,
      //   msg: WebsocketMessage(String),
      // ) -> actor.Next(String, CartState) {
      //   case msg {
      //     Text(text) -> {
      //       case string.split(text, ":") {
      //         ["add", id_str, title, price_str] -> {
      //           case int.parse(id_str), float.parse(price_str) {
      //             Ok(id), Ok(price) -> {
      //               actor.send(actor, AddItem(id, title, price))
      //               actor.continue(state)
      //             }
      //             _, _ -> actor.continue(state)
      //           }
      //         }
      //         ["remove", id_str] -> {
      //           case int.parse(id_str) {
      //             Ok(id) -> {
      //               actor.send(actor, RemoveItem(id))
      //               actor.continue(state)
      //             }
      //             Error(_) -> actor.continue(state)
      //           }
      //         }
      //         ["update", id_str, qty_str] -> {
      //           case int.parse(id_str), int.parse(qty_str) {
      //             Ok(id), Ok(qty) -> {
      //               actor.send(actor, UpdateQuantity(id, qty))
      //               actor.continue(state)
      //             }
      //             _, _ -> actor.continue(state)
      //           }
      //         }
      //         ["sync"] -> {
      //           let state = CartState(items: state.items)
      //           let msg = string.concat(["state|", state.items])
      //           websocket.send_text(conn, msg)
      //           actor.continue(state)
      //         }
      //         _ -> actor.continue(state)
      //       }
      //     }
      //     _ -> actor.continue(state)
      //   }
      // }
      // 
      // let close_handler = fn(_state: CartState) -> Nil { Nil }
      // 
      // websocket.upgrade(req, ws_handler, msg_handler, close_handler)
    }
    _ -> {
      case serve_static(req) {
        Ok(resp) -> resp
        Error(_) ->
          case handle_html_routes(req) {
            Ok(resp) -> resp
            Error(_) ->
              case handle_api_request(req) {
                Ok(resp) -> resp
                Error(_) -> not_found_response()
              }
          }
      }
    }
  }
}

fn serve_static(req: Request(String)) -> Result(Response(ResponseData), Nil) {
  // Remove leading slash and serve static file
  let path = req.path
  let path = case string.starts_with(path, "/") {
    True -> string.slice(path, 1, string.length(path))
    False -> path
  }

  case try_serve_static_file(path) {
    Ok(response) -> Ok(response)
    Error(_) -> Error(Nil)
  }
}

fn handle_html_routes(
  req: Request(String),
) -> Result(Response(ResponseData), Nil) {
  // Check if this is a known static page
  case req.path {
    "/" -> Ok(serve_html("index.html"))
    "/findry" -> Ok(serve_html("index.html"))
    "/events" -> Ok(serve_html("index.html"))
    "/divvyqueue" -> Ok(serve_html("index.html"))
    "/divvyqueue2" -> Ok(serve_html("index.html"))
    "/projects" -> Ok(serve_html("projects_page.html"))
    "/about" -> Ok(serve_html("index.html"))
    "/calendar" -> Ok(serve_html("calendar_page.html"))
    "/login" -> Ok(serve_html("index.html"))
    "/signup" -> Ok(serve_html("index.html"))
    "/store" -> Ok(serve_html("index.html"))
    "/mt-clipboards" -> Ok(serve_html("mt_clipboards.html"))
    "/cart" -> Ok(serve_cart_page())
    "/wishlist" -> Ok(serve_html("wishlist.html"))
    "/account" -> Ok(serve_html("account.html"))
    "/checkout" -> Ok(serve_html("checkout.html"))
    "/checkout/success" -> Ok(serve_checkout_success())
    _ -> {
      // Try to serve as a static file
      let path = req.path
      let path = case string.starts_with(path, "/") {
        True -> string.slice(path, 1, string.length(path))
        False -> path
      }

      case try_serve_static_file(path) {
        Ok(response) -> Ok(response)
        Error(_) -> Error(Nil)
      }
    }
  }
}

fn method_not_allowed() -> Response(ResponseData) {
  let error_json = json.object([#("error", json.string("Method not allowed"))])
  let body = json.to_string(error_json)
  response.new(405)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(Bytes(bytes_tree.from_string(body)))
}

// Function to route wishlist API requests
fn route_wishlist_request(req: Request(String)) -> Response(ResponseData) {
  // Extract necessary information and construct a similar response
  let path_segments = request.path_segments(req)

  // Handle different wishlist API routes
  case list.drop(path_segments, 2), req.method {
    // GET /api/wishlist/products - List all products
    ["products"], Get -> handle_wishlist_products()

    // GET /api/wishlist/products/:id - Get product by ID
    ["products", product_id], Get -> handle_wishlist_product(product_id)

    // Other routes can be added as needed
    _, _ -> method_not_allowed()
  }
}

// Restore these functions for handling wishlist products
fn handle_wishlist_products() -> Response(ResponseData) {
  // Get all products endpoint
  let products = get_mock_products()

  let products_json =
    list.map(products, fn(product) {
      json.object([
        #("id", json.string(product.id)),
        #("name", json.string(product.name)),
        #("description", json.string(product.description)),
        #("category", json.string(product.category)),
        #("price", json.float(product.price)),
        #("salePrice", case product.sale_price {
          Some(price) -> json.float(price)
          None -> json.null()
        }),
        #("image", json.string(product.image_url)),
        #("badge", case product.badge {
          Some(badge) -> json.string(badge)
          None -> json.null()
        }),
        #("specs", json.object(get_mock_specs(product.id))),
      ])
    })

  let body = json.to_string(json.array(products_json, fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(Bytes(bytes_tree.from_string(body)))
}

fn handle_wishlist_product(product_id: String) -> Response(ResponseData) {
  let products = get_mock_products()
  let product = list.find(products, fn(p) { p.id == product_id })

  case product {
    Ok(product) -> {
      let product_json =
        json.object([
          #("id", json.string(product.id)),
          #("name", json.string(product.name)),
          #("description", json.string(product.description)),
          #("category", json.string(product.category)),
          #("price", json.float(product.price)),
          #("salePrice", case product.sale_price {
            Some(price) -> json.float(price)
            None -> json.null()
          }),
          #("image", json.string(product.image_url)),
          #("badge", case product.badge {
            Some(badge) -> json.string(badge)
            None -> json.null()
          }),
          #("specs", json.object(get_mock_specs(product.id))),
        ])
      let body = json.to_string(product_json)
      response.new(200)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(Bytes(bytes_tree.from_string(body)))
    }
    Error(_) -> {
      let error_json =
        json.object([#("error", json.string("Product not found"))])
      let body = json.to_string(error_json)
      response.new(404)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(Bytes(bytes_tree.from_string(body)))
    }
  }
}

fn handle_api_request(
  _req: Request(String),
) -> Result(Response(ResponseData), Nil) {
  // Default response for unmatched API endpoints
  Ok(
    response.new(404)
    |> response.set_header("content-type", "application/json")
    |> response.set_body(
      Bytes(bytes_tree.from_string("{\"error\": \"API endpoint not found\"}")),
    ),
  )
}
