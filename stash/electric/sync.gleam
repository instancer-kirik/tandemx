import chartspace_server.{type Position}
import gleam/result
import gleam/string

// Add import for Position

// Assuming Position type is defined elsewhere or imported
// import chartspace_server.{type Position} // Example import if needed

pub type SyncClient

pub type Subscription {
  Subscription(id: String)
}

pub fn connect(_url: String) -> Result(SyncClient, String) {
  // TODO: Implement Electric SQL sync client connection
  Error("Not implemented")
}

pub fn update_cursor(
  _client: SyncClient,
  _user_id: String,
  _position: Position,
  // Assuming Position is in scope from elsewhere
) -> Nil {
  // TODO: Implement cursor position update
  Nil
}

pub fn on_cursor_update(
  _client: SyncClient,
  _callback: fn(String, Position) -> a,
  // Assuming Position is in scope
) -> Nil {
  // TODO: Implement callback registration for cursor updates
  Nil
}

pub fn on_presence_update(
  _client: SyncClient,
  _callback: fn(String, Bool) -> a,
) -> Nil {
  // TODO: Implement callback registration for presence updates
  Nil
}

pub fn subscribe_cursor_positions(
  _client: SyncClient,
  _callback: fn(String, Position) -> a,
) -> Subscription {
  // TODO: Implement cursor position subscription
  Subscription(id: "cursor-positions-subscription")
}

pub fn subscribe_presence(
  _client: SyncClient,
  _callback: fn(String, Bool) -> a,
) -> Subscription {
  // TODO: Implement presence subscription
  Subscription(id: "presence-subscription")
}
