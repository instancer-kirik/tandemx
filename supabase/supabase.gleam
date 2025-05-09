// tandemx/priv/static/supabase/supabase.gleam

// This is a conceptual skeleton for a Gleam Supabase client.
// You will need to implement the actual HTTP requests to the Supabase PostgREST API.

import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/result

// For handling JSON responses
import gleam/json

// For constructing JSON request bodies
import gleam/list
import gleam/string

// You'''ll need an HTTP client. gleam/httpc is a common choice.
import gleam/http
import gleam/httpc

// --- Types ---

pub type Client {
  Client(
    supabase_url: String,
    supabase_key: String,
    http_client: httpc.Client,
    // HTTP client instance
  )
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
  HttpRequestError(httpc.Error)
  ApiError(status_code: Int, response_body: String)
  DecodeError(json.DecodeError)
  UnsupportedOperation(String)
  InvalidUrl(String)
  // Add other error types as needed
}

// --- Client Creation ---

pub fn create(supabase_url: String, supabase_key: String) -> Client {
  let http_client = httpc.new()
  Client(
    supabase_url: supabase_url,
    supabase_key: supabase_key,
    http_client: http_client,
  )
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

pub fn maybe_single(builder: QueryBuilder) -> QueryBuilder {
  QueryBuilder(..builder, expect_single: True)
}

// --- Execution ---
pub fn execute(builder: QueryBuilder) -> Result(dynamic.Dynamic, SupabaseError) {
  let some_string = "http://example.com"
  use _url <- result.map_error(string.to_url(some_string), fn(_) {
    InvalidUrl(some_string)
  })
  // ... rest of the function, or just Ok(dynamic.from(Nil)) for now
  Ok(dynamic.from(Nil))
}

// --- Helper functions ---

fn string_to_http_method(method_string: String) -> http.Method {
  case method_string {
    "GET" -> http.Get
    "POST" -> http.Post
    "DELETE" -> http.Delete
    "PATCH" -> http.Patch
    _ -> {
      // Defaulting to GET, but ideally this should not happen with controlled QueryBuilder
      // Consider panicking or returning a Result if method_string is invalid.
      http.Get
    }
  }
}
