import chartspace_supabase.{
  type ChartspaceError, create_client, delete_connection, delete_node,
  get_full_state, save_connection, save_node, update_node,
}
import chartspace_types.{
  type ChartspaceCollaborator, type ChartspaceNode,
  type ChartspaceNodeConnection, type ChartspaceState, type ConnectionType,
  type NodeStatus, type NodeType, type Position, type User, Blocked,
  ChartspaceNode, ChartspaceNodeConnection, ChartspaceState, Completed,
  Dependency, Flow, Goal, InProgress, Milestone, NotStarted, Outcome, Position,
  Reference, Resource, Task,
}
import gleam/bool
import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/string
import mist.{type WebsocketConnection, type WebsocketMessage, Text}
import supabase.{type Client}

pub type ChartspaceActor {
  ChartspaceActor(
    state: ChartspaceState,
    connections: List(WebsocketConnection),
    supabase_client: supabase.Client,
  )
}

pub type Change {
  NodeAdded(ChartspaceNode)
  NodeUpdated(ChartspaceNode)
  NodeDeleted(String)
  ConnectionAdded(ChartspaceNodeConnection)
  ConnectionDeleted(String)
  NodeMoved(String, Position)
}

pub type ClientMessage {
  UserJoined(User)
  UserLeft(String)
  CursorMoved(String, Position)
  NodeSelected(String, Option(String))
  ChangeApplied(Change)
  SyncRequest
  SyncResponse(List(ChartspaceNode), List(ChartspaceNodeConnection))
}

pub fn handle_message(
  state: ChartspaceState,
  conn: WebsocketConnection,
  msg: WebsocketMessage(String),
  connections: List(WebsocketConnection),
  supabase_client: supabase.Client,
) -> #(ChartspaceState, List(WebsocketConnection)) {
  case msg {
    Text(text) -> {
      let message = parse_electric_message(text)
      case message {
        UserJoined(user) -> {
          let new_state =
            ChartspaceState(..state, collaborators: [
              ChartspaceCollaborator(
                user: user,
                cursor_position: None,
                selected_node: None,
                last_active: get_current_time(),
              ),
              ..state.collaborators
            ])
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }
        UserLeft(user_id) -> {
          let new_state =
            ChartspaceState(
              ..state,
              collaborators: list.filter(state.collaborators, fn(c) {
                c.user.id != user_id
              }),
            )
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }
        CursorMoved(_, _) | NodeSelected(_, _) -> {
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(state, connections)
        }
        ChangeApplied(change) -> {
          case apply_change_with_supabase(state, change, supabase_client) {
            Ok(new_state) -> {
              broadcast_to_others(
                conn,
                serialize_electric_message(message),
                connections,
              )
              #(new_state, connections)
            }
            Error(e) -> {
              // Log error and keep old state
              io.println("Failed to apply change: " <> string.inspect(e))
              #(state, connections)
            }
          }
        }
        SyncRequest -> {
          case get_full_state(supabase_client) {
            Ok(supabase_state) -> {
              let sync_msg =
                SyncResponse(supabase_state.nodes, supabase_state.connections)
              let assert Ok(_) =
                mist.send_text_frame(conn, serialize_electric_message(sync_msg))
              #(supabase_state, connections)
            }
            Error(e) -> {
              io.println(
                "Failed to get state from Supabase: " <> string.inspect(e),
              )
              #(state, connections)
            }
          }
        }
        SyncResponse(nodes, node_connections) -> {
          #(
            ChartspaceState(
              ..state,
              nodes: nodes,
              connections: node_connections,
            ),
            connections,
          )
        }
      }
    }
    _ -> #(state, connections)
  }
}

fn broadcast_to_others(
  sender: WebsocketConnection,
  msg: String,
  connections: List(WebsocketConnection),
) {
  list.filter(connections, fn(conn) { conn != sender })
  |> list.each(fn(conn) {
    let assert Ok(_) = mist.send_text_frame(conn, msg)
  })
}

fn apply_change_with_supabase(
  state: ChartspaceState,
  change: Change,
  supabase_client: supabase.Client,
) -> Result(ChartspaceState, String) {
  case change {
    NodeAdded(node) -> {
      case save_node(supabase_client, node) {
        Ok(_) -> {
          Ok(ChartspaceState(..state, nodes: list.append([node], state.nodes)))
        }
        Error(e) -> Error("Failed to save node: " <> string.inspect(e))
      }
    }
    NodeUpdated(updated_node) -> {
      case update_node(supabase_client, updated_node) {
        Ok(_) -> {
          Ok(
            ChartspaceState(
              ..state,
              nodes: list.map(state.nodes, fn(n) {
                case n.id == updated_node.id {
                  True -> updated_node
                  False -> n
                }
              }),
            ),
          )
        }
        Error(e) -> Error("Failed to update node: " <> string.inspect(e))
      }
    }
    NodeDeleted(node_id) -> {
      case delete_node(supabase_client, node_id) {
        Ok(_) -> {
          Ok(
            ChartspaceState(
              ..state,
              nodes: list.filter(state.nodes, fn(n) { n.id != node_id }),
            ),
          )
        }
        Error(e) -> Error("Failed to delete node: " <> string.inspect(e))
      }
    }
    ConnectionAdded(conn) -> {
      case save_connection(supabase_client, conn) {
        Ok(_) -> {
          Ok(
            ChartspaceState(
              ..state,
              connections: list.append([conn], state.connections),
            ),
          )
        }
        Error(e) -> Error("Failed to save connection: " <> string.inspect(e))
      }
    }
    ConnectionDeleted(conn_id) -> {
      case delete_connection(supabase_client, conn_id) {
        Ok(_) -> {
          Ok(
            ChartspaceState(
              ..state,
              connections: list.filter(state.connections, fn(c) {
                c.id != conn_id
              }),
            ),
          )
        }
        Error(e) -> Error("Failed to delete connection: " <> string.inspect(e))
      }
    }
    NodeMoved(node_id, position) -> {
      case list.find(state.nodes, fn(n) { n.id == node_id }) {
        Ok(node) -> {
          let updated_node = ChartspaceNode(..node, position: position)
          case update_node(supabase_client, updated_node) {
            Ok(_) -> {
              Ok(
                ChartspaceState(
                  ..state,
                  nodes: list.map(state.nodes, fn(n) {
                    case n.id == node_id {
                      True -> updated_node
                      False -> n
                    }
                  }),
                ),
              )
            }
            Error(e) ->
              Error("Failed to update node position: " <> string.inspect(e))
          }
        }
        Error(_) -> Error("Node not found: " <> node_id)
      }
    }
  }
}

fn parse_electric_message(text: String) -> ClientMessage {
  io.println(
    "Received raw message (parse_electric_message placeholder): " <> text,
  )
  case json.parse(from: text, using: client_message_decoder_placeholder()) {
    Error(_) -> {
      io.println("Failed to parse JSON text in parse_electric_message.")
      UserJoined(User(
        id: "json_error_user",
        name: "JSON Error",
        color: "#FF0000",
      ))
    }
    Ok(msg) -> {
      msg
    }
  }
}

fn client_message_decoder_placeholder() -> decode.Decoder(ClientMessage) {
  {
    use type_str <- decode.field("type", decode.string)
    case type_str {
      "USER_JOINED" -> {
        use payload <- decode.field("payload", user_decoder_placeholder())
        decode.success(UserJoined(payload))
      }
      "USER_LEFT" -> {
        use user_id <- decode.field("payload", decode.string)
        decode.success(UserLeft(user_id))
      }
      "CURSOR_MOVED" -> {
        use payload <- decode.field("payload", decode.dynamic)
        case dynamic.field(payload, "userId", dynamic.string) {
          Ok(user_id) -> {
            case
              dynamic.field(payload, "position", position_decoder_placeholder())
            {
              Ok(position) -> decode.success(CursorMoved(user_id, position))
              Error(errors) -> decode.failure(string.inspect(errors))
            }
          }
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      "NODE_SELECTED" -> {
        use payload <- decode.field("payload", decode.dynamic)
        case dynamic.field(payload, "userId", dynamic.string) {
          Ok(user_id) -> {
            case
              dynamic.field(payload, "nodeId", dynamic.optional(dynamic.string))
            {
              Ok(node_id) -> decode.success(NodeSelected(user_id, node_id))
              Error(errors) -> decode.failure(string.inspect(errors))
            }
          }
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      "CHANGE_APPLIED" -> {
        use payload <- decode.field("payload", decode.dynamic)
        case decode.run(payload, change_decoder_placeholder()) {
          Ok(change) -> decode.success(ChangeApplied(change))
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      "SYNC_REQUEST" -> decode.success(SyncRequest)
      "SYNC_RESPONSE" -> {
        use payload <- decode.field("payload", decode.dynamic)
        let node_decoder = node_decoder_placeholder()
        let connection_decoder = connection_decoder_placeholder()
        case dynamic.field(payload, "nodes", dynamic.list(node_decoder)) {
          Ok(nodes) -> {
            case
              dynamic.field(
                payload,
                "connections",
                dynamic.list(connection_decoder),
              )
            {
              Ok(connections) ->
                decode.success(SyncResponse(nodes, connections))
              Error(errors) -> decode.failure(string.inspect(errors))
            }
          }
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      _ -> decode.failure("Unknown client message type: " <> type_str)
    }
  }
}

fn user_decoder_placeholder() -> decode.Decoder(User) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use color <- decode.field("color", decode.string)
    decode.success(User(id, name, color))
  }
}

fn position_decoder_placeholder() -> decode.Decoder(Position) {
  {
    use x <- decode.field("x", decode.float)
    use y <- decode.field("y", decode.float)
    decode.success(Position(x, y))
  }
}

fn node_decoder_placeholder() -> decode.Decoder(ChartspaceNode) {
  {
    use id <- decode.field("id", decode.string)
    use position <- decode.field("position", position_decoder_placeholder())
    use label <- decode.field("label", decode.string)
    use node_type <- decode.field("node_type", node_type_decoder_placeholder())
    use status <- decode.field("status", node_status_decoder_placeholder())
    use description <- decode.field("description", decode.string)
    use deadline <- decode.field("deadline", decode.optional(decode.string))
    use assignees <- decode.field("assignees", decode.list(decode.string))
    use completion_percentage <- decode.field(
      "completion_percentage",
      decode.optional(decode.int),
    )
    decode.success(ChartspaceNode(
      id,
      position,
      label,
      node_type,
      status,
      description,
      deadline,
      assignees,
      completion_percentage,
    ))
  }
}

fn node_type_decoder_placeholder() -> decode.Decoder(NodeType) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "goal" -> decode.success(Goal)
      "task" -> decode.success(Task)
      "resource" -> decode.success(Resource)
      "outcome" -> decode.success(Outcome)
      "milestone" -> decode.success(Milestone)
      _ -> decode.failure("Unknown node type: " <> s)
    }
  })
}

fn node_status_decoder_placeholder() -> decode.Decoder(NodeStatus) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "notstarted" -> decode.success(NotStarted)
      "inprogress" -> decode.success(InProgress)
      "completed" -> decode.success(Completed)
      "blocked" -> decode.success(Blocked)
      _ -> decode.failure("Unknown node status: " <> s)
    }
  })
}

fn connection_decoder_placeholder() -> decode.Decoder(ChartspaceNodeConnection) {
  {
    use id <- decode.field("id", decode.string)
    use from <- decode.field("from", decode.string)
    use to <- decode.field("to", decode.string)
    use connection_type <- decode.field(
      "connection_type",
      connection_type_decoder_placeholder(),
    )
    decode.success(ChartspaceNodeConnection(id, from, to, connection_type))
  }
}

fn connection_type_decoder_placeholder() -> decode.Decoder(ConnectionType) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "dependency" -> decode.success(Dependency)
      "reference" -> decode.success(Reference)
      "flow" -> decode.success(Flow)
      _ -> decode.failure("Unknown connection type: " <> s)
    }
  })
}

fn change_decoder_placeholder() -> decode.Decoder(Change) {
  {
    use type_str <- decode.field("type", decode.string)
    case type_str {
      "NODE_ADDED" -> {
        use payload <- decode.field("node", decode.dynamic)
        case decode.run(payload, node_decoder_placeholder()) {
          Ok(node) -> decode.success(NodeAdded(node))
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      "NODE_UPDATED" -> {
        use payload <- decode.field("node", decode.dynamic)
        case decode.run(payload, node_decoder_placeholder()) {
          Ok(node) -> decode.success(NodeUpdated(node))
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      "NODE_DELETED" -> {
        use node_id <- decode.field("nodeId", decode.string)
        decode.success(NodeDeleted(node_id))
      }
      "CONNECTION_ADDED" -> {
        use payload <- decode.field("connection", decode.dynamic)
        case decode.run(payload, connection_decoder_placeholder()) {
          Ok(conn) -> decode.success(ConnectionAdded(conn))
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      "CONNECTION_DELETED" -> {
        use conn_id <- decode.field("connectionId", decode.string)
        decode.success(ConnectionDeleted(conn_id))
      }
      "NODE_MOVED" -> {
        use node_id <- decode.field("nodeId", decode.string)
        use payload <- decode.field("position", decode.dynamic)
        case decode.run(payload, position_decoder_placeholder()) {
          Ok(position) -> decode.success(NodeMoved(node_id, position))
          Error(errors) -> decode.failure(string.inspect(errors))
        }
      }
      _ -> decode.failure("Unknown change type: " <> type_str)
    }
  }
}

fn serialize_electric_message(msg: ClientMessage) -> String {
  let content = case msg {
    UserJoined(user) ->
      json.object([
        #("type", json.string("USER_JOINED")),
        #("payload", user_to_json_placeholder(user)),
      ])
    UserLeft(user_id) ->
      json.object([
        #("type", json.string("USER_LEFT")),
        #("payload", json.string(user_id)),
      ])
    CursorMoved(user_id, pos) ->
      json.object([
        #("type", json.string("CURSOR_MOVED")),
        #(
          "payload",
          json.object([
            #("userId", json.string(user_id)),
            #("position", position_to_json_placeholder(pos)),
          ]),
        ),
      ])
    NodeSelected(user_id, node_id_opt) ->
      json.object([
        #("type", json.string("NODE_SELECTED")),
        #(
          "payload",
          json.object([
            #("userId", json.string(user_id)),
            #(
              "nodeId",
              option.map(node_id_opt, json.string) |> option.unwrap(json.null()),
            ),
          ]),
        ),
      ])
    ChangeApplied(change) ->
      json.object([
        #("type", json.string("CHANGE_APPLIED")),
        #("payload", change_to_json_placeholder(change)),
      ])
    SyncRequest -> json.object([#("type", json.string("SYNC_REQUEST"))])
    SyncResponse(nodes, conns) ->
      json.object([
        #("type", json.string("SYNC_RESPONSE")),
        #(
          "payload",
          json.object([
            #(
              "nodes",
              json.array(list.map(nodes, node_to_json_placeholder), fn(j) { j }),
            ),
            #(
              "connections",
              json.array(list.map(conns, connection_to_json_placeholder), fn(j) {
                j
              }),
            ),
          ]),
        ),
      ])
  }
  json.to_string(content)
}

fn user_to_json_placeholder(user: User) -> json.Json {
  json.object([
    #("id", json.string(user.id)),
    #("name", json.string(user.name)),
    #("color", json.string(user.color)),
  ])
}

fn position_to_json_placeholder(pos: Position) -> json.Json {
  json.object([#("x", json.float(pos.x)), #("y", json.float(pos.y))])
}

fn node_to_json_placeholder(node: ChartspaceNode) -> json.Json {
  json.object([
    #("id", json.string(node.id)),
    #("label", json.string(node.label)),
    #("description", json.string(node.description)),
    #("position", position_to_json_placeholder(node.position)),
  ])
}

fn connection_to_json_placeholder(conn: ChartspaceNodeConnection) -> json.Json {
  json.object([
    #("id", json.string(conn.id)),
    #("from", json.string(conn.from)),
    #("to", json.string(conn.to)),
  ])
}

fn change_to_json_placeholder(change: Change) -> json.Json {
  case change {
    NodeAdded(n) ->
      json.object([
        #("type", json.string("NODE_ADDED")),
        #("node", node_to_json_placeholder(n)),
      ])
    NodeUpdated(n) ->
      json.object([
        #("type", json.string("NODE_UPDATED")),
        #("node", node_to_json_placeholder(n)),
      ])
    NodeDeleted(id) ->
      json.object([
        #("type", json.string("NODE_DELETED")),
        #("nodeId", json.string(id)),
      ])
    ConnectionAdded(c) ->
      json.object([
        #("type", json.string("CONNECTION_ADDED")),
        #("connection", connection_to_json_placeholder(c)),
      ])
    ConnectionDeleted(id) ->
      json.object([
        #("type", json.string("CONNECTION_DELETED")),
        #("connectionId", json.string(id)),
      ])
    NodeMoved(id, pos) ->
      json.object([
        #("type", json.string("NODE_MOVED")),
        #("nodeId", json.string(id)),
        #("position", position_to_json_placeholder(pos)),
      ])
  }
}

fn get_current_time() -> String {
  "2024-07-22T12:00:00Z"
}

pub fn init(
  supabase_url: String,
  supabase_key: String,
) -> Result(ChartspaceState, String) {
  let supabase_client = create_client(supabase_url, supabase_key)
  case get_full_state(supabase_client) {
    Ok(state) -> Ok(state)
    Error(e) ->
      Error("Failed to initialize state from Supabase: " <> string.inspect(e))
  }
}

pub fn start(
  supabase_url: String,
  supabase_key: String,
) -> Result(process.Subject(ChartspaceActor), actor.StartError) {
  case init(supabase_url, supabase_key) {
    Ok(state) -> {
      let supabase_client = create_client(supabase_url, supabase_key)
      actor.start_spec(
        actor.Spec(
          init: fn() {
            actor.Ready(
              state: ChartspaceActor(
                state: state,
                connections: [],
                supabase_client: supabase_client,
              ),
              selector: process.new_selector(),
            )
          },
          init_timeout: 1000,
          loop: fn(message_from_parent_or_self, actor_state) {
            echo {
              "ChartspaceActor main loop received (or ignored) message_from_parent_or_self"
            }
            echo { message_from_parent_or_self }
            actor.continue(actor_state)
          },
        ),
      )
    }
    Error(e) -> Error(actor.StartError(e))
  }
}
