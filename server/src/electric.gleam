pub type Client

pub type Subscription

pub fn connect(url: String) -> Result(Client, String) {
  // TODO: Implement Electric SQL client connection
  panic as "Not implemented"
}

pub fn subscribe(client: Client, topic: String) -> Subscription {
  // TODO: Implement Electric SQL subscription
  panic as "Not implemented"
}

pub fn unsubscribe(subscription: Subscription) -> Nil {
  // TODO: Implement Electric SQL unsubscribe
  panic as "Not implemented"
}

pub fn broadcast(
  client: Client,
  topic: String,
  message: String,
) -> Result(Nil, String) {
  // TODO: Implement Electric SQL broadcast
  panic as "Not implemented"
}
