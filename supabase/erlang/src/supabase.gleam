// tandemx/priv/static/supabase/supabase.gleam

// This is a conceptual skeleton for a Gleam Supabase client.
// You will need to implement the actual HTTP requests to the Supabase PostgREST API.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

// You'''ll need an HTTP client. gleam/httpc is a common choice.

// --- Types ---

pub type Client {
  Client(host: String, key: String)
}

// A QueryBuilder to construct queries step-by-step
// This is a simplified example. A real one would be more complex.
pub type QueryBuilder {
  QueryBuilder(
    client: Client,
    table: String,
    method: String,
    // "GET", "POST", "DELETE", "PATCH"
    select_columns: Option(String),
    // e.g., "*", "id,name"
    filters: List(#(String, String, String)),
    // e.g., [#(op, column, value)]
    body: Option(json.Json),
    // For INSERT, UPDATE
    expect_single: Bool,
    // prefer_return: Option(String), // e.g. Some("representation") for insert/update
  )
}

// Custom error type for Supabase operations
pub type SupabaseError {
  HttpRequestError(String)
  ApiError(status_code: Int, response_body: String)
  DecodeError(json.DecodeError)
  UnsupportedOperation(String)
  InvalidUrl(String)
  // Add other error types as needed
}

// --- Client Creation ---

pub fn create(host: String, key: String) -> Client {
  Client(host, key)
}

// --- Query Building ---

pub fn from(client: Client, table_name: String) -> QueryBuilder {
  QueryBuilder(
    client: client,
    table: table_name,
    method: "GET",
    // Default to GET
    select_columns: Some("*"),
    // Default to selecting all columns
    filters: [],
    body: None,
    expect_single: False,
    // prefer_return: None,
  )
}

pub fn select(builder: QueryBuilder, columns: String) -> QueryBuilder {
  QueryBuilder(..builder, select_columns: Some(columns), method: "GET")
}

pub fn insert(builder: QueryBuilder, data: json.Json) -> QueryBuilder {
  QueryBuilder(
    ..builder,
    body: Some(data),
    method: "POST",
    // prefer_return: Some("representation"), // Typically you want the inserted data back
  )
}

pub fn delete(builder: QueryBuilder) -> QueryBuilder {
  QueryBuilder(..builder, method: "DELETE")
}

// Example filter. A real client would have more (gt, lt, like, etc.)
// And handle value types more robustly.
pub fn eq(
  builder: QueryBuilder,
  column: String,
  value: String,
  // Value should be URL encoded if it contains special chars
) -> QueryBuilder {
  // Supabase filter format: column=eq.value
  let new_filters = list.append(builder.filters, [#("eq", column, value)])
  QueryBuilder(..builder, filters: new_filters)
}

pub fn gt(builder: QueryBuilder, column: String, value: String) -> QueryBuilder {
  let new_filters = list.append(builder.filters, [#("gt", column, value)])
  QueryBuilder(..builder, filters: new_filters)
}

pub fn lt(builder: QueryBuilder, column: String, value: String) -> QueryBuilder {
  let new_filters = list.append(builder.filters, [#("lt", column, value)])
  QueryBuilder(..builder, filters: new_filters)
}

pub fn like(
  builder: QueryBuilder,
  column: String,
  value: String,
) -> QueryBuilder {
  let new_filters = list.append(builder.filters, [#("like", column, value)])
  QueryBuilder(..builder, filters: new_filters)
}

pub fn order(
  builder: QueryBuilder,
  column: String,
  ascending: Bool,
) -> QueryBuilder {
  let direction = case ascending {
    True -> "asc"
    False -> "desc"
  }
  let new_filters =
    list.append(builder.filters, [#("order", column, direction)])
  QueryBuilder(..builder, filters: new_filters)
}

pub fn maybe_single(builder: QueryBuilder) -> QueryBuilder {
  QueryBuilder(..builder, expect_single: True)
}

pub fn update(builder: QueryBuilder, data: json.Json) -> QueryBuilder {
  QueryBuilder(..builder, body: Some(data), method: "PATCH")
}

// --- Execution ---

fn build_url(
  client: Client,
  builder: QueryBuilder,
) -> Result(String, SupabaseError) {
  let base_url = string.concat([client.host, "/rest/v1/", builder.table])

  // Add select columns
  let url_with_select = case builder.select_columns {
    Some(columns) -> string.concat([base_url, "?select=", columns])
    None -> base_url
  }

  // Add filters
  let url_with_filters =
    list.fold(builder.filters, url_with_select, fn(url, filter) {
      let #(op, column, value) = filter
      let separator = case string.contains(url, "?") {
        True -> "&"
        False -> "?"
      }
      string.concat([url, separator, column, "=", op, ".", value])
    })

  Ok(url_with_filters)
}

fn build_headers(client: Client) -> List(#(String, String)) {
  [
    #("apikey", client.key),
    #("Authorization", string.concat(["Bearer ", client.key])),
    #("Content-Type", "application/json"),
    #("Prefer", "return=representation"),
  ]
}

fn handle_response_body(body: String) -> Result(dynamic.Dynamic, SupabaseError) {
  case body {
    "" -> {
      // Create a dynamic value representing null
      let empty_json = json.null()
      case json.parse(from: json.to_string(empty_json), using: decode.dynamic) {
        Ok(null_val) -> Ok(null_val)
        Error(e) -> Error(DecodeError(e))
      }
    }
    body_string ->
      case json.parse(from: body_string, using: decode.dynamic) {
        Ok(json_val) -> Ok(json_val)
        Error(err) -> Error(DecodeError(err))
      }
  }
}

fn handle_response(
  response: Response(String),
) -> Result(decode.Dynamic, SupabaseError) {
  case response.status {
    200 | 201 | 204 -> handle_response_body(response.body)
    _ -> Error(ApiError(response.status, response.body))
  }
}

fn prepare_request_body(builder: QueryBuilder) -> String {
  case builder.body {
    Some(body) -> json.to_string(body)
    None -> ""
  }
}

fn build_request(
  url: String,
  method: http.Method,
  headers: List(#(String, String)),
  body: String,
) -> request.Request(String) {
  let req = request.new()
  let req = request.set_method(req, method)
  let req = request.set_host(req, url)
  let req = request.set_path(req, "/")
  let req =
    list.fold(headers, req, fn(req, header) {
      let #(key, value) = header
      request.set_header(req, key, value)
    })
  request.set_body(req, body)
}

fn send_request(
  req: request.Request(String),
) -> Result(Response(String), SupabaseError) {
  case httpc.send(req) {
    Ok(response) -> Ok(response)
    Error(e) -> Error(HttpRequestError(string.inspect(e)))
  }
}

pub fn execute(builder: QueryBuilder) -> Result(decode.Dynamic, SupabaseError) {
  case build_url(builder.client, builder) {
    Ok(url) -> {
      let headers = build_headers(builder.client)
      let method = string_to_http_method(builder.method)
      let body = prepare_request_body(builder)
      let req = build_request(url, method, headers, body)

      case send_request(req) {
        Ok(response) -> handle_response(response)
        Error(e) -> Error(e)
      }
    }
    Error(e) -> Error(e)
  }
}

// --- Helper functions ---

fn string_to_http_method(method_string: String) -> http.Method {
  case method_string {
    "GET" -> http.Get
    "POST" -> http.Post
    "DELETE" -> http.Delete
    "PATCH" -> http.Patch
    _ -> http.Get
  }
}

pub fn rpc(
  _function_name: String,
  _params: dynamic.Dynamic,
  client: Client,
) -> Result(dynamic.Dynamic, SupabaseError) {
  let _header = [#("apikey", client.key)]
  let _request_body_string = "{}"  // Default empty object
  
  // The actual HTTP call would go here using header and request_body_string
  // For now, let's assume a placeholder response body for parsing logic demo
  // In a real scenario, you'd get this from the HTTP response
  let mock_response_body = "{\"data\": \"rpc_result\"}"
  // Parsing logic for the response (same as handle_response_body)
  case mock_response_body {
    "" -> {
      // Create a dynamic value representing null
      let empty_json = json.null()
      case json.parse(from: json.to_string(empty_json), using: decode.dynamic) {
        Ok(null_val) -> Ok(null_val)
        Error(e) -> Error(DecodeError(e))
      }
    }
    body_string ->
      case json.parse(from: body_string, using: decode.dynamic) {
        Ok(json_val) -> Ok(json_val)
        Error(err) -> Error(DecodeError(err))
      }
  }
}
