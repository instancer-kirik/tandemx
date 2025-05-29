import gleam/dynamic
import gleam/json
import gleam/string
import supabase.{
  type Client, type QueryBuilder, create, delete, eq, execute, from, insert,
  select,
}

pub fn create_client(url: String, key: String) -> Client {
  create(url, key)
}

pub fn query_table(client: Client, table: String) -> QueryBuilder {
  from(client, table)
}

pub fn select_all(builder: QueryBuilder) -> QueryBuilder {
  select(builder, "*")
}

pub fn select_columns(builder: QueryBuilder, columns: String) -> QueryBuilder {
  select(builder, columns)
}

pub fn insert_row(builder: QueryBuilder, data: json.Json) -> QueryBuilder {
  insert(builder, data)
}

pub fn filter_eq(
  builder: QueryBuilder,
  column: String,
  value: String,
) -> QueryBuilder {
  eq(builder, column, value)
}

pub fn run_query(builder: QueryBuilder) -> Result(dynamic.Dynamic, String) {
  case execute(builder) {
    Ok(result) -> Ok(result)
    Error(e) -> Error(string.inspect(e))
  }
}
