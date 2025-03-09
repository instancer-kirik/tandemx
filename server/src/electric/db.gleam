import electric/types.{
  type ConnectionType, type Node, type NodeConnection, type NodeStatus,
  type NodeType, Node, NodeConnection,
}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Delete, Get, Patch, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub type Database {
  Database(base_url: String)
}

pub type DbError {
  ConnectionError(String)
  QueryError(String)
  ValidationError(String)
  SubscriptionError(String)
  ParseError(String)
  NetworkError(String)
}

pub type Subscription {
  Subscription(id: String)
}

pub type ShapeResponse {
  ShapeResponse(nodes: List(Node), connections: List(NodeConnection))
}

fn encode_json(data: Dynamic) -> String {
  let json_value = case dynamic.classify(data) {
    "List" -> {
      let assert Ok(list) = dynamic.list(dynamic.dynamic)(data)
      json.array(list, fn(x) {
        case dynamic.classify(x) {
          "String" -> {
            let assert Ok(s) = dynamic.string(x)
            json.string(s)
          }
          "Int" -> {
            let assert Ok(i) = dynamic.int(x)
            json.int(i)
          }
          "Float" -> {
            let assert Ok(f) = dynamic.float(x)
            json.float(f)
          }
          _ -> json.null()
        }
      })
    }
    "String" -> {
      let assert Ok(s) = dynamic.string(data)
      json.string(s)
    }
    "Int" -> {
      let assert Ok(i) = dynamic.int(data)
      json.int(i)
    }
    "Float" -> {
      let assert Ok(f) = dynamic.float(data)
      json.float(f)
    }
    _ -> json.null()
  }
  json.to_string(json_value)
}

fn decode_json(data: String) -> Dynamic {
  json.decode(data, dynamic.dynamic)
  |> result.unwrap(dynamic.from(Nil))
}

pub fn connect(url: String) -> Result(Database, DbError) {
  Ok(Database(url))
}

pub fn insert_node(db: Database, x: Float, y: Float) -> Result(Node, DbError) {
  let body = json.object([#("x", json.float(x)), #("y", json.float(y))])
  let req =
    request.new()
    |> request.set_method(Post)
    |> request.set_host(db.base_url)
    |> request.set_path("/nodes")
    |> request.set_body(json.to_string(body))

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          let data = decode_json(resp.body)
          case parse_node(data) {
            Ok(node) -> Ok(node)
            Error(_) -> Error(ParseError("Failed to parse node"))
          }
        }
        _ -> Error(NetworkError("Failed to insert node"))
      }
    }
    Error(_) -> Error(NetworkError("Failed to send request"))
  }
}

pub fn update_node_position(
  db: Database,
  node_id: String,
  x: Float,
  y: Float,
) -> Result(Node, DbError) {
  let data = dynamic.from([#("x", dynamic.from(x)), #("y", dynamic.from(y))])

  let json = encode_json(data)
  let req =
    request.new()
    |> request.set_method(Patch)
    |> request.set_host(db.base_url)
    |> request.set_path("/nodes/" <> node_id)
    |> request.set_body(json)

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          Ok(Node(
            node_id,
            x,
            y,
            "",
            "",
            types.Task,
            types.NotStarted,
            None,
            None,
            Some(0),
          ))
        }
        _ -> Error(ConnectionError("Failed to update node position"))
      }
    }
    Error(_) -> Error(ConnectionError("Failed to send request"))
  }
}

pub fn update_node_status(
  db: Database,
  node_id: String,
  status: NodeStatus,
) -> Result(Node, DbError) {
  let data = dynamic.from([#("status", dynamic.from(status))])

  let json = encode_json(data)
  let req =
    request.new()
    |> request.set_method(Patch)
    |> request.set_host(db.base_url)
    |> request.set_path("/nodes/" <> node_id)
    |> request.set_body(json)

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          Ok(Node(
            node_id,
            0.0,
            0.0,
            "",
            "",
            types.Task,
            status,
            None,
            None,
            Some(0),
          ))
        }
        _ -> Error(ConnectionError("Failed to update node status"))
      }
    }
    Error(_) -> Error(ConnectionError("Failed to send request"))
  }
}

pub fn delete_node(db: Database, node_id: String) -> Result(Nil, DbError) {
  let req =
    request.new()
    |> request.set_method(Delete)
    |> request.set_host(db.base_url)
    |> request.set_path("/nodes/" <> node_id)

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> Ok(Nil)
        _ -> Error(ConnectionError("Failed to delete node"))
      }
    }
    Error(_) -> Error(ConnectionError("Failed to send request"))
  }
}

pub fn update_node_label(
  db: Database,
  node_id: String,
  label: String,
) -> Result(Nil, DbError) {
  // TODO: Implement node label update
  panic as "Not implemented"
}

pub fn update_node_description(
  db: Database,
  node_id: String,
  description: String,
) -> Result(Nil, DbError) {
  // TODO: Implement node description update
  panic as "Not implemented"
}

pub fn update_node_deadline(
  db: Database,
  node_id: String,
  deadline: String,
) -> Result(Nil, DbError) {
  // TODO: Implement node deadline update
  panic as "Not implemented"
}

pub fn add_node_assignee(
  db: Database,
  node_id: String,
  assignee: String,
) -> Result(Nil, DbError) {
  // TODO: Implement node assignee addition
  panic as "Not implemented"
}

pub fn remove_node_assignee(
  db: Database,
  node_id: String,
  assignee: String,
) -> Result(Nil, DbError) {
  // TODO: Implement node assignee removal
  panic as "Not implemented"
}

pub fn insert_connection(
  db: Database,
  connection: NodeConnection,
) -> Result(NodeConnection, DbError) {
  let data =
    dynamic.from([
      #("source_id", dynamic.from(connection.source_id)),
      #("target_id", dynamic.from(connection.target_id)),
      #("connection_type", dynamic.from(connection.connection_type)),
    ])

  let json = encode_json(data)
  let req =
    request.new()
    |> request.set_method(Post)
    |> request.set_host(db.base_url)
    |> request.set_path("/connections")
    |> request.set_body(json)

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> Ok(connection)
        _ -> Error(ConnectionError("Failed to insert connection"))
      }
    }
    Error(_) -> Error(ConnectionError("Failed to send request"))
  }
}

pub fn delete_connection(
  db: Database,
  connection_id: String,
) -> Result(Nil, DbError) {
  let req =
    request.new()
    |> request.set_method(Delete)
    |> request.set_host(db.base_url)
    |> request.set_path("/connections/" <> connection_id)

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> Ok(Nil)
        _ -> Error(ConnectionError("Failed to delete connection"))
      }
    }
    Error(_) -> Error(ConnectionError("Failed to send request"))
  }
}

pub fn subscribe_nodes(
  db: Database,
  callback: fn(List(Node)) -> Result(Nil, DbError),
) -> Result(Subscription, DbError) {
  let subscription_id = "nodes_" <> string.concat(["", string.inspect(8)])

  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_host(db.base_url)
    |> request.set_path("/v1/shape?table=nodes&offset=-1")

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          let data = decode_json(resp.body)
          // TODO: Parse data into List(Node) and call callback
          Ok(Subscription(subscription_id))
        }
        _ -> Error(SubscriptionError("Failed to subscribe to nodes"))
      }
    }
    Error(_) -> Error(SubscriptionError("Failed to subscribe to nodes"))
  }
}

pub fn subscribe_connections(
  db: Database,
  callback: fn(List(NodeConnection)) -> Result(Nil, DbError),
) -> Result(Subscription, DbError) {
  let subscription_id = "connections_" <> string.concat(["", string.inspect(8)])

  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_host(db.base_url)
    |> request.set_path("/v1/shape?table=connections&offset=-1")

  case httpc.send(req) {
    Ok(resp) -> {
      case resp.status {
        200 -> {
          let data = decode_json(resp.body)
          // TODO: Parse data into List(NodeConnection) and call callback
          Ok(Subscription(subscription_id))
        }
        _ -> Error(SubscriptionError("Failed to subscribe to connections"))
      }
    }
    Error(_) -> Error(SubscriptionError("Failed to subscribe to connections"))
  }
}

pub fn unsubscribe(subscription: Subscription) -> Result(Nil, DbError) {
  // TODO: Implement WebSocket unsubscription
  Ok(Nil)
}

fn node_type_to_string(node_type: NodeType) -> String {
  case node_type {
    types.Goal -> "goal"
    types.Task -> "task"
    types.Resource -> "resource"
    types.Outcome -> "outcome"
    types.Milestone -> "milestone"
  }
}

fn node_status_to_string(status: NodeStatus) -> String {
  case status {
    types.NotStarted -> "not_started"
    types.InProgress -> "in_progress"
    types.Completed -> "completed"
    types.Blocked -> "blocked"
  }
}

fn connection_type_to_string(conn_type: ConnectionType) -> String {
  case conn_type {
    types.Dependency -> "dependency"
    types.Reference -> "reference"
    types.Flow -> "flow"
  }
}

fn parse_node_type(type_str: String) -> Result(NodeType, String) {
  case type_str {
    "goal" -> Ok(types.Goal)
    "task" -> Ok(types.Task)
    "resource" -> Ok(types.Resource)
    "outcome" -> Ok(types.Outcome)
    "milestone" -> Ok(types.Milestone)
    _ -> Error("Invalid node type: " <> type_str)
  }
}

fn parse_node_status(status_str: String) -> Result(NodeStatus, String) {
  case status_str {
    "not_started" -> Ok(types.NotStarted)
    "in_progress" -> Ok(types.InProgress)
    "completed" -> Ok(types.Completed)
    "blocked" -> Ok(types.Blocked)
    _ -> Error("Invalid node status: " <> status_str)
  }
}

fn parse_connection_type(type_str: String) -> Result(ConnectionType, String) {
  case type_str {
    "dependency" -> Ok(types.Dependency)
    "reference" -> Ok(types.Reference)
    "flow" -> Ok(types.Flow)
    _ -> Error("Invalid connection type: " <> type_str)
  }
}

pub fn parse_shape_response(
  json_data: Dynamic,
) -> Result(ShapeResponse, List(dynamic.DecodeError)) {
  let nodes_decoder = dynamic.field("nodes", dynamic.list(of: parse_node))
  let connections_decoder =
    dynamic.field("connections", dynamic.list(of: parse_connection))

  case nodes_decoder(json_data), connections_decoder(json_data) {
    Ok(nodes), Ok(connections) -> Ok(ShapeResponse(nodes, connections))
    Error(e), _ -> Error(e)
    _, Error(e) -> Error(e)
  }
}

fn parse_node(json_data: Dynamic) -> Result(Node, List(dynamic.DecodeError)) {
  let decoder =
    dynamic.decode7(
      fn(id, x, y, label, color, node_type, status) {
        Node(id, x, y, label, color, node_type, status, None, None, Some(0))
      },
      dynamic.field("id", dynamic.string),
      dynamic.field("x", dynamic.float),
      dynamic.field("y", dynamic.float),
      dynamic.field("label", dynamic.string),
      dynamic.field("color", dynamic.string),
      dynamic.field("node_type", parse_node_type_decoder),
      dynamic.field("status", parse_node_status_decoder),
    )
  decoder(json_data)
}

fn parse_connection(
  json_data: Dynamic,
) -> Result(NodeConnection, List(dynamic.DecodeError)) {
  let decoder =
    dynamic.decode5(
      fn(id, source_id, target_id, label, connection_type) {
        NodeConnection(id, source_id, target_id, label, connection_type)
      },
      dynamic.field("id", dynamic.string),
      dynamic.field("source_id", dynamic.string),
      dynamic.field("target_id", dynamic.string),
      dynamic.field("label", dynamic.string),
      dynamic.field("connection_type", parse_connection_type_decoder),
    )
  decoder(json_data)
}

fn parse_node_type_decoder(
  data: Dynamic,
) -> Result(NodeType, List(dynamic.DecodeError)) {
  case dynamic.string(data) {
    Ok("goal") -> Ok(types.Goal)
    Ok("task") -> Ok(types.Task)
    Ok("resource") -> Ok(types.Resource)
    Ok("outcome") -> Ok(types.Outcome)
    Ok("milestone") -> Ok(types.Milestone)
    Ok(other) ->
      Error([
        dynamic.DecodeError(expected: "valid node type", found: other, path: []),
      ])
    Error(e) -> Error(e)
  }
}

fn parse_node_status_decoder(
  data: Dynamic,
) -> Result(NodeStatus, List(dynamic.DecodeError)) {
  case dynamic.string(data) {
    Ok("not_started") -> Ok(types.NotStarted)
    Ok("in_progress") -> Ok(types.InProgress)
    Ok("completed") -> Ok(types.Completed)
    Ok("blocked") -> Ok(types.Blocked)
    Ok(other) ->
      Error([
        dynamic.DecodeError(
          expected: "valid node status",
          found: other,
          path: [],
        ),
      ])
    Error(e) -> Error(e)
  }
}

fn parse_connection_type_decoder(
  data: Dynamic,
) -> Result(ConnectionType, List(dynamic.DecodeError)) {
  case dynamic.string(data) {
    Ok("dependency") -> Ok(types.Dependency)
    Ok("reference") -> Ok(types.Reference)
    Ok("flow") -> Ok(types.Flow)
    Ok(other) ->
      Error([
        dynamic.DecodeError(
          expected: "valid connection type",
          found: other,
          path: [],
        ),
      ])
    Error(e) -> Error(e)
  }
}
