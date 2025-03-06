import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub opaque type WebSocket {
  WebSocket(
    internal_ws: Dynamic,
    on_message: fn(Json) -> Nil,
    on_close: fn() -> Nil,
  )
}

pub fn connect(
  url: String,
  on_message: fn(Json) -> Nil,
  on_close: fn() -> Nil,
) -> WebSocket {
  let ws = create_websocket(url)
  set_message_handler(ws, on_message)
  set_close_handler(ws, on_close)
  WebSocket(internal_ws: ws, on_message: on_message, on_close: on_close)
}

pub fn send(ws: WebSocket, msg: Json) -> Nil {
  send_message(ws.internal_ws, json.to_string(msg))
}

@external(javascript, "./websocket_ffi.js", "createWebSocket")
fn create_websocket(url: String) -> Dynamic

@external(javascript, "./websocket_ffi.js", "setMessageHandler")
fn set_message_handler(ws: Dynamic, handler: fn(Json) -> Nil) -> Nil

@external(javascript, "./websocket_ffi.js", "setCloseHandler")
fn set_close_handler(ws: Dynamic, handler: fn() -> Nil) -> Nil

@external(javascript, "./websocket_ffi.js", "sendMessage")
fn send_message(ws: Dynamic, msg: String) -> Nil
