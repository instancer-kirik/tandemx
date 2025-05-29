import gleam/option.{type Option}

// Shared types for chartspace modules

pub type Position {
  Position(x: Float, y: Float)
}

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

pub type ChartspaceNode {
  ChartspaceNode(
    id: String,
    position: Position,
    label: String,
    node_type: NodeType,
    status: NodeStatus,
    description: String,
    deadline: Option(String),
    assignees: List(String),
    completion_percentage: Option(Int),
  )
}

pub type ChartspaceNodeConnection {
  ChartspaceNodeConnection(
    id: String,
    from: String,
    to: String,
    connection_type: ConnectionType,
  )
}

pub type ConnectionType {
  Dependency
  Reference
  Flow
}

pub type User {
  User(id: String, name: String, color: String)
}

pub type ChartspaceCollaborator {
  ChartspaceCollaborator(
    user: User,
    cursor_position: Option(Position),
    selected_node: Option(String),
    last_active: String,
  )
}

pub type ChartspaceState {
  ChartspaceState(
    nodes: List(ChartspaceNode),
    connections: List(ChartspaceNodeConnection),
    collaborators: List(ChartspaceCollaborator),
  )
}
