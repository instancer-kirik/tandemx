import gleam/option.{type Option}

pub type NodeType {
  Goal
  Task
  Resource
  Outcome
  Milestone
}

pub type NodeStatus {
  NotStarted
  InProgress
  Completed
  Blocked
}

pub type ConnectionType {
  Dependency
  Reference
  Flow
}

pub type Node {
  Node(
    id: String,
    x: Float,
    y: Float,
    label: String,
    color: String,
    node_type: NodeType,
    status: NodeStatus,
    description: Option(String),
    deadline: Option(String),
    completion_percentage: Option(Int),
  )
}

pub type NodeConnection {
  NodeConnection(
    id: String,
    source_id: String,
    target_id: String,
    label: String,
    connection_type: ConnectionType,
  )
}

pub type Collaborator {
  Collaborator(
    id: String,
    name: String,
    color: String,
    cursor_position: Option(#(Float, Float)),
    selected_node: Option(String),
    last_active: String,
  )
}
