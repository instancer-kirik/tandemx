pub type Node {
  Node(id: String, x: Float, y: Float, label: String)
}

pub type Connection {
  Connection(id: String, from: String, to: String)
}

pub type ChartspaceState {
  ChartspaceState(nodes: List(Node), connections: List(Connection))
}

pub type ChartspaceMessage {
  AddNode(String, Float, Float, String)
  AddConnection(String, String)
  MoveNode(String, Float, Float)
  RemoveNode(String)
  RemoveConnection(String)
}

pub fn start() -> Result(Nil, Nil) {
  Ok(Nil)
}
