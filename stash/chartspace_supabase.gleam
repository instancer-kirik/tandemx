import chartspace_types.{
  type ChartspaceNode, type ChartspaceNodeConnection, type ChartspaceState,
  type ConnectionType, type NodeStatus, type NodeType, type Position, Blocked,
  ChartspaceNode, ChartspaceNodeConnection, ChartspaceState, Completed,
  Dependency, Flow, Goal, InProgress, Milestone, NotStarted, Outcome, Position,
  Reference, Resource, Task,
}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import supabase.{
  type Client, type QueryBuilder, create, delete, eq, execute, from, insert,
  maybe_single, update,
}

// --- Types ---

pub type ChartspaceError {
  DecodeError(String)
  DatabaseError(String)
  ValidationError(String)
  NotFound
}

// --- Client Creation ---

pub fn create_client(url: String, key: String) -> Client {
  create(url, key)
}

// --- Node Operations ---

pub fn save_node(
  client: Client,
  node: ChartspaceNode,
) -> Result(Nil, ChartspaceError) {
  case node_to_json(node) {
    Ok(json) -> {
      let query = from(client, "chartspace_nodes")
      case execute(insert(query, json)) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(DatabaseError(string.inspect(e)))
      }
    }
    Error(e) -> Error(DecodeError(e))
  }
}

pub fn get_node(
  client: Client,
  id: String,
) -> Result(ChartspaceNode, ChartspaceError) {
  let query = from(client, "chartspace_nodes")
  case execute(maybe_single(eq(query, "id", id))) {
    Ok(dynamic) -> decode_node(dynamic)
    Error(_) -> Error(NotFound)
  }
}

pub fn update_node(
  client: Client,
  node: ChartspaceNode,
) -> Result(Nil, ChartspaceError) {
  case node_to_json(node) {
    Ok(json) -> {
      let query = from(client, "chartspace_nodes")
      case execute(update(eq(query, "id", node.id), json)) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(DatabaseError(string.inspect(e)))
      }
    }
    Error(e) -> Error(DecodeError(e))
  }
}

pub fn delete_node(client: Client, id: String) -> Result(Nil, ChartspaceError) {
  let query = from(client, "chartspace_nodes")
  case execute(delete(eq(query, "id", id))) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(string.inspect(e)))
  }
}

// --- Connection Operations ---

pub fn save_connection(
  client: Client,
  connection: ChartspaceNodeConnection,
) -> Result(Nil, ChartspaceError) {
  case connection_to_json(connection) {
    Ok(json) -> {
      let query = from(client, "chartspace_connections")
      case execute(insert(query, json)) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(DatabaseError(string.inspect(e)))
      }
    }
    Error(e) -> Error(DecodeError(e))
  }
}

pub fn get_connection(
  client: Client,
  id: String,
) -> Result(ChartspaceNodeConnection, ChartspaceError) {
  let query = from(client, "chartspace_connections")
  case execute(maybe_single(eq(query, "id", id))) {
    Ok(dynamic) -> decode_connection(dynamic)
    Error(_) -> Error(NotFound)
  }
}

pub fn delete_connection(
  client: Client,
  id: String,
) -> Result(Nil, ChartspaceError) {
  let query = from(client, "chartspace_connections")
  case execute(delete(eq(query, "id", id))) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(string.inspect(e)))
  }
}

// --- State Operations ---

pub fn get_full_state(
  client: Client,
) -> Result(ChartspaceState, ChartspaceError) {
  let nodes_query = from(client, "chartspace_nodes")
  let connections_query = from(client, "chartspace_connections")

  let nodes_result = execute(nodes_query)
  let connections_result = execute(connections_query)

  case nodes_result, connections_result {
    Ok(nodes), Ok(connections) -> {
      case decode_nodes(nodes), decode_connections(connections) {
        Ok(nodes), Ok(connections) ->
          Ok(
            ChartspaceState(
              nodes: nodes,
              connections: connections,
              collaborators: [],
            ),
          )
        Error(e), _ -> Error(e)
        _, Error(e) -> Error(e)
      }
    }
    Error(e), _ -> Error(DatabaseError(string.inspect(e)))
    _, Error(e) -> Error(DatabaseError(string.inspect(e)))
  }
}

// --- JSON Conversion ---

fn node_to_json(node: ChartspaceNode) -> Result(json.Json, String) {
  let position_json =
    json.object([
      #("x", json.float(node.position.x)),
      #("y", json.float(node.position.y)),
    ])

  let deadline_json = case node.deadline {
    Some(d) -> json.string(d)
    None -> json.null()
  }

  let completion_percentage_json = case node.completion_percentage {
    Some(p) -> json.float(int.to_float(p))
    None -> json.null()
  }

  let assignees_json =
    json.array(list.map(node.assignees, json.string), fn(j) { j })

  Ok(
    json.object([
      #("id", json.string(node.id)),
      #("position", position_json),
      #("label", json.string(node.label)),
      #("node_type", json.string(node_type_to_string(node.node_type))),
      #("status", json.string(node_status_to_string(node.status))),
      #("description", json.string(node.description)),
      #("deadline", deadline_json),
      #("assignees", assignees_json),
      #("completion_percentage", completion_percentage_json),
    ]),
  )
}

fn connection_to_json(
  connection: ChartspaceNodeConnection,
) -> Result(json.Json, String) {
  Ok(
    json.object([
      #("id", json.string(connection.id)),
      #("from", json.string(connection.from)),
      #("to", json.string(connection.to)),
      #(
        "connection_type",
        json.string(connection_type_to_string(connection.connection_type)),
      ),
    ]),
  )
}

fn node_type_to_string(node_type: NodeType) -> String {
  case node_type {
    Goal -> "Goal"
    Task -> "Task"
    Resource -> "Resource"
    Outcome -> "Outcome"
    Milestone -> "Milestone"
  }
}

fn node_status_to_string(status: NodeStatus) -> String {
  case status {
    NotStarted -> "NotStarted"
    InProgress -> "InProgress"
    Completed -> "Completed"
    Blocked -> "Blocked"
  }
}

fn connection_type_to_string(connection_type: ConnectionType) -> String {
  case connection_type {
    Dependency -> "Dependency"
    Reference -> "Reference"
    Flow -> "Flow"
  }
}

// --- Decoding Functions ---

fn node_field_decoder() -> decode.Decoder(ChartspaceNode) {
  {
    use id <- decode.field("id", decode.string)
    use position <- decode.field("position", position_decoder())
    use label <- decode.field("label", decode.string)
    use node_type <- decode.field("node_type", node_type_decoder())
    use status <- decode.field("status", node_status_decoder())
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

fn position_decoder() -> decode.Decoder(Position) {
  {
    use x <- decode.field("x", decode.float)
    use y <- decode.field("y", decode.float)
    decode.success(Position(x, y))
  }
}

fn node_type_decoder() -> decode.Decoder(NodeType) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "goal" -> decode.success(Goal)
      "task" -> decode.success(Task)
      "resource" -> decode.success(Resource)
      "outcome" -> decode.success(Outcome)
      "milestone" -> decode.success(Milestone)
      _ -> decode.failure(Goal, "Invalid NodeType string: " <> s)
    }
  })
}

fn node_status_decoder() -> decode.Decoder(NodeStatus) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "notstarted" -> decode.success(NotStarted)
      "inprogress" -> decode.success(InProgress)
      "completed" -> decode.success(Completed)
      "blocked" -> decode.success(Blocked)
      _ -> decode.failure(NotStarted, "Invalid NodeStatus string: " <> s)
    }
  })
}

fn connection_type_decoder() -> decode.Decoder(ConnectionType) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "dependency" -> decode.success(Dependency)
      "reference" -> decode.success(Reference)
      "flow" -> decode.success(Flow)
      _ -> decode.failure(Dependency, "Invalid ConnectionType string: " <> s)
    }
  })
}

fn connection_field_decoder() -> decode.Decoder(ChartspaceNodeConnection) {
  {
    use id <- decode.field("id", decode.string)
    use from <- decode.field("from", decode.string)
    use to <- decode.field("to", decode.string)
    use connection_type <- decode.field(
      "connection_type",
      connection_type_decoder(),
    )
    decode.success(ChartspaceNodeConnection(id, from, to, connection_type))
  }
}

pub fn decode_node(
  data: dynamic.Dynamic,
) -> Result(ChartspaceNode, ChartspaceError) {
  case decode.run(data, node_field_decoder()) {
    Ok(node) -> Ok(node)
    Error(errors) -> Error(DecodeError(string.inspect(errors)))
  }
}

pub fn decode_connection(
  data: dynamic.Dynamic,
) -> Result(ChartspaceNodeConnection, ChartspaceError) {
  case decode.run(data, connection_field_decoder()) {
    Ok(connection) -> Ok(connection)
    Error(errors) -> Error(DecodeError(string.inspect(errors)))
  }
}

pub fn decode_nodes(
  data: dynamic.Dynamic,
) -> Result(List(ChartspaceNode), ChartspaceError) {
  case decode.run(data, decode.list(node_field_decoder())) {
    Ok(nodes) -> Ok(nodes)
    Error(errors) -> Error(DecodeError(string.inspect(errors)))
  }
}

pub fn decode_connections(
  data: dynamic.Dynamic,
) -> Result(List(ChartspaceNodeConnection), ChartspaceError) {
  case decode.run(data, decode.list(connection_field_decoder())) {
    Ok(connections) -> Ok(connections)
    Error(errors) -> Error(DecodeError(string.inspect(errors)))
  }
}
