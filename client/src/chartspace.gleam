import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute.{class, style}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

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

pub type Node {
  Node(
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

pub type NodeConnection {
  NodeConnection(
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

pub type WebSocketMsg {
  UserJoined(User)
  UserLeft(String)
  CursorMoved(String, Position)
  NodeSelected(String, Option(String))
  ChangeApplied(Change)
  SyncRequest
  SyncResponse(List(Node), List(NodeConnection))
}

pub type Model {
  Model(
    nodes: List(Node),
    connections: List(NodeConnection),
    scale: Float,
    selected: Option(Node),
    connecting: Option(String),
    dragging: Option(String),
    collaborators: List(Collaborator),
    local_user: User,
    ws: Option(WebSocket),
    subscriptions: List(Subscription),
  )
}

pub type User {
  User(id: String, name: String, color: String)
}

pub type Collaborator {
  Collaborator(
    user: User,
    cursor_position: Option(Position),
    selected_node: Option(String),
    last_active: String,
  )
}

pub type Change {
  NodeAdded(Node)
  NodeUpdated(Node)
  NodeDeleted(String)
  ConnectionAdded(NodeConnection)
  ConnectionDeleted(String)
  NodeMoved(String, Position)
}

pub type Msg {
  AddNode(NodeType)
  SelectNodeMsg(Node)
  DeselectNode
  UpdateScale(Float)
  ResetView
  StartDragging(String)
  StopDragging
  UpdatePosition(String, Position)
  StartConnecting(String)
  CompleteConnection(String)
  CancelConnection
  UpdateNodeStatus(String, NodeStatus)
  UpdateNodeLabel(String, String)
  UpdateNodeDescription(String, String)
  UpdateNodeDeadline(String, String)
  AddAssignee(String, String)
  RemoveAssignee(String, String)
  WebSocketConnected(WebSocket)
  WebSocketMessage(WebSocketMsg)
  WebSocketError(String)
  NodesChanged(List(Node))
  ConnectionsChanged(List(NodeConnection))
  CollaboratorJoined(User)
  CollaboratorLeft(String)
  UpdateCursor(Position)
  SelectNode(Option(Node))
}

pub type WebSocket {
  WebSocket(id: String)
}

pub type Subscription {
  Subscription(id: String)
}

pub fn init() -> Model {
  let local_user =
    User(
      id: generate_uuid(),
      name: "Anonymous User",
      color: generate_random_color(),
    )

  Model(
    nodes: [],
    connections: [],
    scale: 1.0,
    selected: None,
    connecting: None,
    dragging: None,
    collaborators: [],
    local_user: local_user,
    ws: None,
    subscriptions: [],
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AddNode(node_type) -> {
      let id = "node-" <> int.to_string(list.length(model.nodes) + 1)
      let new_node =
        Node(
          id: id,
          position: Position(x: 100.0, y: 100.0),
          label: case node_type {
            Goal -> "New Goal"
            Task -> "New Task"
            Resource -> "New Resource"
            Outcome -> "New Outcome"
            Milestone -> "New Milestone"
          },
          node_type: node_type,
          status: NotStarted,
          description: "",
          deadline: None,
          assignees: [],
          completion_percentage: None,
        )

      let new_model = Model(..model, nodes: [new_node, ..model.nodes])
      broadcast_change(new_model, NodeAdded(new_node))
      #(new_model, effect.none())
    }

    SelectNodeMsg(node) -> #(
      Model(..model, selected: Some(node)),
      effect.none(),
    )

    DeselectNode -> #(Model(..model, selected: None), effect.none())

    UpdateScale(new_scale) -> #(
      Model(..model, scale: float.clamp(new_scale, 0.1, 3.0)),
      effect.none(),
    )

    ResetView -> #(Model(..model, scale: 1.0), effect.none())

    StartDragging(node_id) -> #(
      Model(..model, dragging: Some(node_id)),
      effect.none(),
    )

    StopDragging -> #(Model(..model, dragging: None), effect.none())

    UpdatePosition(node_id, position) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, position: position)
            False -> n
          }
        })
      let new_model = Model(..model, nodes: updated_nodes)
      broadcast_change(new_model, NodeMoved(node_id, position))
      #(new_model, effect.none())
    }

    StartConnecting(node_id) -> #(
      Model(..model, connecting: Some(node_id)),
      effect.none(),
    )

    CompleteConnection(to_node_id) -> {
      case model.connecting {
        Some(from_node_id) -> {
          let new_connection =
            NodeConnection(
              id: generate_uuid(),
              from: from_node_id,
              to: to_node_id,
              connection_type: Dependency,
            )
          let new_model =
            Model(..model, connecting: None, connections: [
              new_connection,
              ..model.connections
            ])
          broadcast_change(new_model, ConnectionAdded(new_connection))
          #(new_model, effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    CancelConnection -> #(Model(..model, connecting: None), effect.none())

    UpdateNodeStatus(node_id, status) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, status: status)
            False -> n
          }
        })
      case list.find(updated_nodes, fn(n) { n.id == node_id }) {
        Ok(updated_node) -> {
          let new_model = Model(..model, nodes: updated_nodes)
          broadcast_change(new_model, NodeUpdated(updated_node))
          #(new_model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }

    UpdateNodeLabel(node_id, label) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, label: label)
            False -> n
          }
        })
      case list.find(updated_nodes, fn(n) { n.id == node_id }) {
        Ok(updated_node) -> {
          let new_model = Model(..model, nodes: updated_nodes)
          broadcast_change(new_model, NodeUpdated(updated_node))
          #(new_model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }

    UpdateNodeDescription(node_id, description) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, description: description)
            False -> n
          }
        })
      case list.find(updated_nodes, fn(n) { n.id == node_id }) {
        Ok(updated_node) -> {
          let new_model = Model(..model, nodes: updated_nodes)
          broadcast_change(new_model, NodeUpdated(updated_node))
          #(new_model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }

    UpdateNodeDeadline(node_id, deadline) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, deadline: Some(deadline))
            False -> n
          }
        })
      case list.find(updated_nodes, fn(n) { n.id == node_id }) {
        Ok(updated_node) -> {
          let new_model = Model(..model, nodes: updated_nodes)
          broadcast_change(new_model, NodeUpdated(updated_node))
          #(new_model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }

    AddAssignee(node_id, assignee) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, assignees: [assignee, ..n.assignees])
            False -> n
          }
        })
      case list.find(updated_nodes, fn(n) { n.id == node_id }) {
        Ok(updated_node) -> {
          let new_model = Model(..model, nodes: updated_nodes)
          broadcast_change(new_model, NodeUpdated(updated_node))
          #(new_model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }

    RemoveAssignee(node_id, assignee) -> {
      let updated_nodes =
        list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True ->
              Node(
                ..n,
                assignees: list.filter(n.assignees, fn(a) { a != assignee }),
              )
            False -> n
          }
        })
      case list.find(updated_nodes, fn(n) { n.id == node_id }) {
        Ok(updated_node) -> {
          let new_model = Model(..model, nodes: updated_nodes)
          broadcast_change(new_model, NodeUpdated(updated_node))
          #(new_model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }

    NodesChanged(nodes) -> #(Model(..model, nodes: nodes), effect.none())

    ConnectionsChanged(connections) -> #(
      Model(..model, connections: connections),
      effect.none(),
    )

    CollaboratorJoined(user) -> {
      let new_collaborator =
        Collaborator(
          user: user,
          cursor_position: None,
          selected_node: None,
          last_active: get_current_time(),
        )
      #(
        Model(..model, collaborators: [new_collaborator, ..model.collaborators]),
        effect.none(),
      )
    }

    CollaboratorLeft(user_id) -> {
      let updated_collaborators =
        list.filter(model.collaborators, fn(c) { c.user.id != user_id })
      #(Model(..model, collaborators: updated_collaborators), effect.none())
    }

    UpdateCursor(position) -> {
      broadcast_change(model, NodeMoved(model.local_user.id, position))
      #(model, effect.none())
    }

    SelectNode(node) -> #(Model(..model, selected: node), effect.none())

    WebSocketConnected(ws) -> #(Model(..model, ws: Some(ws)), effect.none())
    WebSocketMessage(msg) -> #(
      handle_websocket_message(model, msg),
      effect.none(),
    )
    WebSocketError(_) -> #(model, effect.none())

    _ -> #(model, effect.none())
  }
}

fn handle_node_click(
  node: Node,
) -> fn(dynamic.Dynamic) -> Result(Msg, List(dynamic.DecodeError)) {
  fn(_) { Ok(SelectNodeMsg(node)) }
}

fn handle_button_click(
  msg: Msg,
) -> fn(dynamic.Dynamic) -> Result(Msg, List(dynamic.DecodeError)) {
  fn(_) { Ok(msg) }
}

fn render_node(
  node: Node,
  selected: Bool,
  connecting: Option(String),
) -> Element(Msg) {
  let pos_style = [
    #(
      "transform",
      "translate("
        <> float.to_string(node.position.x)
        <> "px, "
        <> float.to_string(node.position.y)
        <> "px)",
    ),
  ]

  let node_classes = [
    "node",
    case selected {
      True -> "selected"
      False -> ""
    },
    case node.node_type {
      Goal -> "node-goal"
      Task -> "node-task"
      Resource -> "node-resource"
      Outcome -> "node-outcome"
      Milestone -> "node-milestone"
    },
    case node.status {
      NotStarted -> "status-not-started"
      InProgress -> "status-in-progress"
      Completed -> "status-completed"
      Blocked -> "status-blocked"
    },
  ]

  html.div(
    [
      class(string.join(node_classes, " ")),
      style("left", float.to_string(node.position.x) <> "px"),
      style("top", float.to_string(node.position.y) <> "px"),
      event.on_click(SelectNodeMsg(node)),
      event.on_mouse_down(StartDragging(node.id)),
      event.on_mouse_up({
        case connecting {
          Some(_) -> CompleteConnection(node.id)
          None -> StopDragging
        }
      }),
    ],
    [
      html.div([class("node-header")], [
        html.span([class("node-type")], [
          html.text(case node.node_type {
            Goal -> "Goal"
            Task -> "Task"
            Resource -> "Resource"
            Outcome -> "Outcome"
            Milestone -> "Milestone"
          }),
        ]),
        html.span([class("node-status")], [
          html.text(case node.status {
            NotStarted -> "Not Started"
            InProgress -> "In Progress"
            Completed -> "Completed"
            Blocked -> "Blocked"
          }),
        ]),
      ]),
      html.div([class("node-content")], [
        html.h3([class("node-label")], [html.text(node.label)]),
        case node.description {
          "" -> html.text("")
          desc -> html.p([class("node-description")], [html.text(desc)])
        },
      ]),
      case node.deadline {
        Some(date) ->
          html.div([class("node-deadline")], [html.text("Due: " <> date)])
        None -> html.text("")
      },
      case node.assignees {
        [] -> html.text("")
        assignees ->
          html.div([class("node-assignees")], [
            html.text("Assigned: " <> string.join(assignees, ", ")),
          ])
      },
    ],
  )
}

fn render_connection(conn: NodeConnection, scale: Float) -> Element(Msg) {
  // Simple line for now
  html.div([], [])
}

pub fn render(model: Model) -> Element(Msg) {
  let canvas =
    html.div(
      [
        class("canvas"),
        style("transform", "scale(" <> float.to_string(model.scale) <> ")"),
        event.on(
          "mousemove",
          decode.success(UpdateCursor(Position(x: 100.0, y: 100.0))),
        ),
      ],
      list.append(
        list.map(model.connections, fn(conn) {
          render_connection(conn, model.scale)
        }),
        list.map(model.nodes, fn(node) {
          render_node(
            node,
            case model.selected {
              Some(selected) -> selected.id == node.id
              None -> False
            },
            model.connecting,
          )
        }),
      ),
    )

  html.div([class("chartspace-container")], [canvas])
}

fn render_palette_item(
  type_: String,
  label: String,
  model: Model,
) -> Element(Msg) {
  html.div(
    [
      class("palette-item palette-" <> type_),
      event.on_click(
        AddNode(case type_ {
          "goal" -> Goal
          "task" -> Task
          "resource" -> Resource
          "outcome" -> Outcome
          "milestone" -> Milestone
          _ -> Task
        }),
      ),
    ],
    [
      html.div([class("palette-item-icon")], []),
      html.div([class("palette-item-label")], [html.text(label)]),
    ],
  )
}

fn render_node_details(node: Node) -> Element(Msg) {
  let status_options = [
    #("not-started", "Not Started"),
    #("in-progress", "In Progress"),
    #("completed", "Completed"),
    #("blocked", "Blocked"),
  ]

  html.div([class("node-details")], [
    html.h2([], [html.text("Node Details")]),
    html.div([class("details-form")], [
      html.div([class("form-group")], [
        html.label([], [html.text("Label")]),
        html.input([
          attribute.type_("text"),
          attribute.value(node.label),
          event.on_input(fn(value) { UpdateNodeLabel(node.id, value) }),
        ]),
      ]),
      html.div([class("form-group")], [
        html.label([], [html.text("Description")]),
        html.input([
          attribute.type_("text"),
          attribute.value(node.description),
          event.on_input(fn(value) { UpdateNodeDescription(node.id, value) }),
        ]),
      ]),
      html.div([class("form-group")], [
        html.label([], [html.text("Status")]),
        html.div(
          [],
          list.map(status_options, fn(opt) {
            let #(value, label) = opt
            html.div([], [
              html.input([
                attribute.type_("radio"),
                attribute.name("status"),
                attribute.value(value),
                attribute.checked(case node.status {
                  NotStarted if value == "not-started" -> True
                  InProgress if value == "in-progress" -> True
                  Completed if value == "completed" -> True
                  Blocked if value == "blocked" -> True
                  _ -> False
                }),
                event.on_change(fn(_) {
                  UpdateNodeStatus(node.id, case value {
                    "not-started" -> NotStarted
                    "in-progress" -> InProgress
                    "completed" -> Completed
                    "blocked" -> Blocked
                    _ -> NotStarted
                  })
                }),
              ]),
              html.label([], [html.text(label)]),
            ])
          }),
        ),
      ]),
      html.div([class("form-group")], [
        html.label([], [html.text("Deadline")]),
        html.input([
          attribute.type_("date"),
          case node.deadline {
            Some(date) -> attribute.value(date)
            None -> attribute.value("")
          },
          event.on_input(fn(value) { UpdateNodeDeadline(node.id, value) }),
        ]),
      ]),
    ]),
  ])
}

fn handle_websocket_message(model: Model, msg: WebSocketMsg) -> Model {
  case msg {
    UserJoined(user) -> {
      Model(..model, collaborators: [
        Collaborator(
          user: user,
          cursor_position: None,
          selected_node: None,
          last_active: get_current_time(),
        ),
        ..model.collaborators
      ])
    }

    UserLeft(user_id) -> {
      Model(
        ..model,
        collaborators: list.filter(model.collaborators, fn(c) {
          c.user.id != user_id
        }),
      )
    }

    CursorMoved(user_id, position) -> {
      Model(
        ..model,
        collaborators: list.map(model.collaborators, fn(c) {
          case c.user.id == user_id {
            True -> Collaborator(..c, cursor_position: Some(position))
            False -> c
          }
        }),
      )
    }

    NodeSelected(user_id, node_id) -> {
      Model(
        ..model,
        collaborators: list.map(model.collaborators, fn(c) {
          case c.user.id == user_id {
            True -> Collaborator(..c, selected_node: node_id)
            False -> c
          }
        }),
      )
    }

    ChangeApplied(change) -> apply_change(model, change)

    SyncRequest -> model

    SyncResponse(nodes, connections) -> {
      Model(..model, nodes: nodes, connections: connections)
    }
  }
}

fn apply_change(model: Model, change: Change) -> Model {
  case change {
    NodeAdded(node) -> Model(..model, nodes: [node, ..model.nodes])

    NodeUpdated(updated_node) -> {
      Model(
        ..model,
        nodes: list.map(model.nodes, fn(n) {
          case n.id == updated_node.id {
            True -> updated_node
            False -> n
          }
        }),
      )
    }

    NodeDeleted(node_id) -> {
      Model(..model, nodes: list.filter(model.nodes, fn(n) { n.id != node_id }))
    }

    ConnectionAdded(conn) -> {
      Model(..model, connections: [conn, ..model.connections])
    }

    ConnectionDeleted(conn_id) -> {
      Model(
        ..model,
        connections: list.filter(model.connections, fn(c) { c.id != conn_id }),
      )
    }

    NodeMoved(node_id, position) -> {
      Model(
        ..model,
        nodes: list.map(model.nodes, fn(n) {
          case n.id == node_id {
            True -> Node(..n, position: position)
            False -> n
          }
        }),
      )
    }
  }
}

fn broadcast_change(model: Model, change: Change) -> Nil {
  case model.ws {
    Some(ws) -> {
      let msg = ChangeApplied(change)
      send_ws_message(ws, msg)
    }
    None -> Nil
  }
}

fn send_ws_message(ws: WebSocket, msg: WebSocketMsg) -> Nil {
  // Implementation to serialize and send WebSocket message
  Nil
}

pub fn main() {
  let app =
    lustre.application(fn(_) { #(init(), effect.none()) }, update, render)

  // Connect to WebSocket
  let ws_url = "ws://" <> "localhost:8000" <> "/ws/chartspace"
  let assert Ok(_) = lustre.start(app, "#chartspace-container", Nil)
  Nil
}

// Helper functions
fn generate_uuid() -> String {
  // Simple implementation for now
  "id-" <> int.to_string(random_int(0, 99_999))
}

fn random_int(min: Int, max: Int) -> Int {
  // Simple implementation for now
  min
}

fn generate_random_color() -> String {
  let colors = [
    "#2563eb",
    // Blue
    "#059669",
    // Green
    "#7c3aed",
    // Purple
    "#dc2626",
    // Red
    "#ea580c",
    // Orange
    "#0891b2",
    // Cyan
    "#4f46e5",
    // Indigo
    "#be185d",
    // Pink
  ]
  case
    list.find_map(colors, fn(color) {
      case random_int(0, list.length(colors) - 1) {
        0 -> Ok(color)
        _ -> Error(Nil)
      }
    })
  {
    Ok(color) -> color
    Error(_) -> "#2563eb"
  }
}

fn get_current_time() -> String {
  // Implementation using Date.now() or similar
  "2024-03-20T12:00:00Z"
}
