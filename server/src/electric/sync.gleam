import chartspace_server.{type Position}

pub type SyncClient

pub type Subscription {
  Subscription(id: String)
}

pub fn connect(url: String) -> Result(SyncClient, String) {
  // TODO: Implement Electric SQL sync client connection
  panic as "Not implemented"
}

pub fn broadcast_cursor_position(
  client: SyncClient,
  user_id: String,
  position: Position,
) -> Result(Nil, String) {
  // TODO: Implement cursor position broadcast
  panic as "Not implemented"
}

pub fn subscribe_cursor_positions(
  client: SyncClient,
  callback: fn(String, Position) -> a,
) -> Subscription {
  // TODO: Implement cursor position subscription
  Subscription(id: "cursor-positions-subscription")
}

pub fn subscribe_presence(
  client: SyncClient,
  callback: fn(String, Bool) -> a,
) -> Subscription {
  // TODO: Implement presence subscription
  Subscription(id: "presence-subscription")
}
