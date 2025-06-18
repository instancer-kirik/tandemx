import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/list
import gleam/string
import gleam/int
import gleam/io
import glenvy/env
import glenvy/dotenv
import glibsql

pub type DbPool =
  glibsql.Connection

pub type DbError {
  ConnectionError(String)
  QueryError(String)
  TransactionError(String)
  NoResultError
  ParseError(String)
}

// Get a connection to the Turso database
pub fn get_connection() -> Result(DbPool, DbError) {
  // Load environment variables
  let _ = dotenv.load()
  
  // Get database URL from environment variables
  let db_url = case env.string("TURSO_DATABASE_URL") {
    Ok(url) -> url
    Error(_) -> {
      // Try to get auth token if URL is missing
      let auth_token = case env.string("TURSO_AUTH_TOKEN") {
        Ok(token) -> token
        Error(_) -> {
          io.println("TURSO_DATABASE_URL and TURSO_AUTH_TOKEN not found. Using local development database.")
          // Default to a local SQLite database for development
          ""  // Empty token for local database
        }
      }
      
      // Try to get database name if URL is missing
      let db_name = case env.string("TURSO_DB_NAME") {
        Ok(name) -> name
        Error(_) -> "tandemx.db"  // Default local database name
      }
      
      // If we have an auth token, use a remote database with authentication
      case auth_token {
        "" -> "file:" <> db_name  // Local SQLite database
        token -> {
          // For remote Turso database with authentication
          // https://docs.turso.tech/libsql/client-access/http-api
          "https://" <> db_name <> ".turso.io?authToken=" <> token
        }
      }
    }
  }

  // Connect to the database
  let config = glibsql.Config(url: db_url)
  glibsql.connect(config)
  |> result.map_error(fn(err) { ConnectionError(string.inspect(err)) })
}

pub fn close_connection(conn: DbPool) -> Result(Nil, DbError) {
  glibsql.close(conn)
  |> result.map_error(fn(err) { ConnectionError(string.inspect(err)) })
}

// Execute a SQL query with parameters
pub fn execute(
  conn: DbPool,
  query: String,
  params: List(dynamic.Dynamic),
) -> Result(glibsql.Result, DbError) {
  glibsql.query(conn, query, params)
  |> result.map_error(fn(err) { QueryError(string.inspect(err)) })
}

// Query a single row
pub fn query_one(
  conn: DbPool,
  query: String,
  params: List(dynamic.Dynamic),
) -> Result(glibsql.Row, DbError) {
  use result <- result.try(glibsql.query(conn, query, params)
    |> result.map_error(fn(err) { QueryError(string.inspect(err)) }))
  
  case result.rows {
    [row] -> Ok(row)
    [] -> Error(NoResultError)
    _ -> Error(QueryError("Expected exactly one row, but got multiple"))
  }
}

// Query multiple rows
pub fn query_all(
  conn: DbPool,
  query: String,
  params: List(dynamic.Dynamic),
) -> Result(List(glibsql.Row), DbError) {
  use result <- result.try(glibsql.query(conn, query, params)
    |> result.map_error(fn(err) { QueryError(string.inspect(err)) }))
  
  Ok(result.rows)
}

// Set up the database schema
pub fn setup_database() -> Result(Nil, DbError) {
  io.println("Setting up Turso database...")

  use conn <- result.try(get_connection())

  // Create tables if they don't exist
  let create_users_table = "
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  "

  let create_products_table = "
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      sku TEXT UNIQUE,
      stock_quantity INTEGER DEFAULT 0,
      status TEXT DEFAULT 'active',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  "

  let create_categories_table = "
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      parent_id INTEGER,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
    );
  "

  let create_product_categories_table = "
    CREATE TABLE IF NOT EXISTS product_categories (
      product_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      PRIMARY KEY (product_id, category_id),
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
      FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
    );
  "

  let create_orders_table = "
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY,
      user_id INTEGER,
      status TEXT NOT NULL DEFAULT 'pending',
      total_amount REAL NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    );
  "

  let create_order_items_table = "
    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY,
      order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
    );
  "

  // Execute the create table statements
  use _ <- result.try(execute(conn, create_users_table, []))
  io.println("Users table created or already exists")
  
  use _ <- result.try(execute(conn, create_products_table, []))
  io.println("Products table created or already exists")
  
  use _ <- result.try(execute(conn, create_categories_table, []))
  io.println("Categories table created or already exists")
  
  use _ <- result.try(execute(conn, create_product_categories_table, []))
  io.println("Product_Categories table created or already exists")
  
  use _ <- result.try(execute(conn, create_orders_table, []))
  io.println("Orders table created or already exists")
  
  use _ <- result.try(execute(conn, create_order_items_table, []))
  io.println("Order_Items table created or already exists")

  io.println("Turso database setup complete!")
  let _ = close_connection(conn)
  Ok(Nil)
}

// Extract values from database rows
pub fn extract_int(row: glibsql.Row, field: String) -> Result(Int, DbError) {
  glibsql.get_int(row, field)
  |> result.map_error(fn(_) { ParseError("Failed to extract int value for field: " <> field) })
}

pub fn extract_float(row: glibsql.Row, field: String) -> Result(Float, DbError) {
  glibsql.get_float(row, field)
  |> result.map_error(fn(_) { ParseError("Failed to extract float value for field: " <> field) })
}

pub fn extract_string(row: glibsql.Row, field: String) -> Result(String, DbError) {
  glibsql.get_string(row, field)
  |> result.map_error(fn(_) { ParseError("Failed to extract string value for field: " <> field) })
}

pub fn extract_optional_string(row: glibsql.Row, field: String) -> Result(Option(String), DbError) {
  case glibsql.get_string(row, field) {
    Ok(value) -> Ok(Some(value))
    Error(_) -> {
      // Check if it's null
      case glibsql.get_null(row, field) {
        Ok(_) -> Ok(None)
        Error(_) -> Error(ParseError("Field not found or not nullable: " <> field))
      }
    }
  }
}

// Shop specific operations

// Product operations
pub fn create_product(
  conn: DbPool,
  name: String,
  description: String,
  price: Float,
  sku: String,
  stock_quantity: Int,
) -> Result(glibsql.Row, DbError) {
  let query = "
    INSERT INTO products (name, description, price, sku, stock_quantity) 
    VALUES (?, ?, ?, ?, ?)
    RETURNING *
  "
  
  query_one(conn, query, [
    dynamic.from(name), 
    dynamic.from(description), 
    dynamic.from(price), 
    dynamic.from(sku),
    dynamic.from(stock_quantity)
  ])
}

pub fn get_product(
  conn: DbPool,
  id: Int,
) -> Result(Option(glibsql.Row), DbError) {
  let query = "SELECT * FROM products WHERE id = ?"
  
  let result = glibsql.query(conn, query, [dynamic.from(id)])
    |> result.map_error(fn(err) { QueryError(string.inspect(err)) })
  
  case result {
    Ok(result) -> case result.rows {
      [row] -> Ok(Some(row))
      _ -> Ok(None)
    }
    Error(err) -> Error(err)
  }
}

pub fn get_all_products(
  conn: DbPool,
  limit: Int,
  offset: Int,
) -> Result(List(glibsql.Row), DbError) {
  let query = "
    SELECT * FROM products 
    ORDER BY created_at DESC
    LIMIT ? OFFSET ?
  "
  
  query_all(conn, query, [dynamic.from(limit), dynamic.from(offset)])
}

// Order operations
pub fn create_order(
  conn: DbPool,
  user_id: Option(Int),
  total_amount: Float,
) -> Result(glibsql.Row, DbError) {
  let query = case user_id {
    Some(id) -> "
      INSERT INTO orders (user_id, total_amount) 
      VALUES (?, ?)
      RETURNING *
    "
    None -> "
      INSERT INTO orders (total_amount) 
      VALUES (?)
      RETURNING *
    "
  }
  
  let params = case user_id {
    Some(id) -> [dynamic.from(id), dynamic.from(total_amount)]
    None -> [dynamic.from(total_amount)]
  }
  
  query_one(conn, query, params)
}

pub fn add_order_item(
  conn: DbPool,
  order_id: Int,
  product_id: Int,
  quantity: Int,
  price: Float,
) -> Result(glibsql.Row, DbError) {
  let query = "
    INSERT INTO order_items (order_id, product_id, quantity, price)
    VALUES (?, ?, ?, ?)
    RETURNING *
  "
  
  query_one(conn, query, [
    dynamic.from(order_id),
    dynamic.from(product_id),
    dynamic.from(quantity),
    dynamic.from(price)
  ])
}

pub fn get_order_with_items(
  conn: DbPool,
  order_id: Int,
) -> Result(#(glibsql.Row, List(glibsql.Row)), DbError) {
  let order_query = "SELECT * FROM orders WHERE id = ?"
  let items_query = "
    SELECT oi.*, p.name as product_name, p.sku 
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    WHERE oi.order_id = ?
  "
  
  let order_result = query_one(conn, order_query, [dynamic.from(order_id)])
  case order_result {
    Error(err) -> Error(err)
    Ok(order) -> {
      let items_result = query_all(conn, items_query, [dynamic.from(order_id)])
      case items_result {
        Error(err) -> Error(err)
        Ok(items) -> Ok(#(order, items))
      }
    }
  }
}