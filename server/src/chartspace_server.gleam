import electric/db.{type Database, type DbError, type Subscription}
import electric/types.{type Collaborator, type Node, type NodeConnection, Node}
import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage, Text, websocket,
}

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
    db: Option(Database),
    subscriptions: List(Subscription),
  )
}

pub type ChartspaceActor {
  ChartspaceActor(
    state: ChartspaceState,
    connections: List(WebsocketConnection),
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
) -> #(ChartspaceState, List(WebsocketConnection)) {
  case msg {
    Text(text) -> {
      // Parse the message using Electric SQL's protocol
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

          // Broadcast to all connections
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
          // Just broadcast to others
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(state, connections)
        }

        ChangeApplied(change) -> {
          let new_state = apply_change(state, change)
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        SyncRequest -> {
          // Send current state to requesting client
          let sync_msg = SyncResponse(state.nodes, state.connections)
          let assert Ok(_) =
            mist.send_text_frame(conn, serialize_electric_message(sync_msg))
          #(state, connections)
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

fn apply_change(state: ChartspaceState, change: Change) -> ChartspaceState {
  case change {
    NodeAdded(node) -> ChartspaceState(..state, nodes: [node, ..state.nodes])

    NodeUpdated(updated_node) -> {
      ChartspaceState(
        ..state,
        nodes: list.map(state.nodes, fn(n) {
          case n.id == updated_node.id {
            True -> updated_node
            False -> n
          }
        }),
      )
    }

    NodeDeleted(node_id) -> {
      ChartspaceState(
        ..state,
        nodes: list.filter(state.nodes, fn(n) { n.id != node_id }),
      )
    }

    ConnectionAdded(conn) -> {
      ChartspaceState(..state, connections: [conn, ..state.connections])
    }

    ConnectionDeleted(conn_id) -> {
      ChartspaceState(
        ..state,
        connections: list.filter(state.connections, fn(c) { c.id != conn_id }),
      )
    }

    NodeMoved(node_id, position) -> {
      ChartspaceState(
        ..state,
        nodes: list.map(state.nodes, fn(n) {
          case n.id == node_id {
            True -> ChartspaceNode(..n, position: position)
            False -> n
          }
        }),
      )
    }
  }
}

// Electric SQL integration
fn parse_electric_message(_text: String) -> ClientMessage {
  // TODO: Implement Electric SQL message parsing
  // This will use Electric's protocol for serialization/deserialization
  panic as "Not implemented"
}

fn serialize_electric_message(_msg: ClientMessage) -> String {
  // TODO: Implement Electric SQL message serialization
  // This will use Electric's protocol for serialization/deserialization
  panic as "Not implemented"
}

fn get_current_time() -> String {
  // TODO: Implement using Erlang's :os.system_time
  "2024-03-20T12:00:00Z"
}

pub fn init() -> ChartspaceState {
  ChartspaceState(
    nodes: [],
    connections: [],
    collaborators: [],
    db: None,
    subscriptions: [],
  )
}

fn handle_db_error(error: DbError) {
  case error {
    db.ConnectionError(msg) -> io.println("DB Connection Error: " <> msg)
    db.QueryError(msg) -> io.println("DB Query Error: " <> msg)
    db.ValidationError(msg) -> io.println("DB Validation Error: " <> msg)
    db.SubscriptionError(msg) -> io.println("DB Subscription Error: " <> msg)
    db.ParseError(msg) -> io.println("DB Parse Error: " <> msg)
    db.NetworkError(msg) -> io.println("DB Network Error: " <> msg)
  }
}

fn setup_subscriptions(
  state: ChartspaceState,
  database: Database,
) -> ChartspaceState {
  case
    db.subscribe_nodes(database, fn(nodes) {
      // Handle node updates
      Ok(Nil)
    })
  {
    Ok(nodes_sub) -> {
      case
        db.subscribe_connections(database, fn(connections) {
          // Handle connection updates
          Ok(Nil)
        })
      {
        Ok(conns_sub) ->
          ChartspaceState(..state, db: Some(database), subscriptions: [
            nodes_sub,
            conns_sub,
          ])
        Error(error) -> {
          handle_db_error(error)
          state
        }
      }
    }
    Error(error) -> {
      handle_db_error(error)
      state
    }
  }
}

pub fn start() -> Result(process.Subject(ChartspaceActor), actor.StartError) {
  let state = init()

  // Try to connect to the database
  let state = case db.connect("electric://localhost:5133") {
    Ok(database) -> setup_subscriptions(state, database)
    Error(error) -> {
      handle_db_error(error)
      state
    }
  }

  actor.start_spec(
    actor.Spec(
      init: fn() {
        actor.Ready(
          state: ChartspaceActor(state: state, connections: []),
          selector: process.new_selector(),
        )
      },
      init_timeout: 1000,
      loop: fn(_msg, state) { actor.continue(state) },
    ),
  )
}

fn handle_node_subscriptions(database: Database, conn: Connection) {
  let selector = process.new_selector()
  // Example of how you might fetch initial nodes, adjust as per your actual logic
  // actor.call(database_actor_pid, fn(req) { GetNodes(req) }, 0)
  // case process.select(selector, 0) {
  //   process.Received(nodes_result) -> {
  //     // Handle nodes_result
  //     io.debug(nodes_result) // Placeholder
  //   }
  //   process.Aborted | process.Timeout -> Nil
  // }

  // Subscribe to node updates
  let _node_subscription =
    db.subscribe_nodes(database, fn(_nodes) {
      // This callback will be invoked when nodes change
      // Send updated nodes to the client via conn - ensure `conn` is usable here or passed correctly
      // For now, returning Ok(Nil) to match expected Result type if db.subscribe_nodes expects it
      case conn {
        _ -> Ok(Nil)
        // Placeholder for actual send logic
      }
    })

  // Subscribe to connection updates
  let _connection_subscription =
    db.subscribe_connections(database, fn(_connections) {
      // This callback will be invoked when connections change
      // Send updated connections to the client via conn - ensure `conn` is usable here or passed correctly
      case conn {
        _ -> Ok(Nil)
        // Placeholder for actual send logic
      }
    })
  process.sleep_forever()
  // Keep actor alive if this is its main loop
}
