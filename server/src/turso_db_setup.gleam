import turso_db
import gleam/io
import gleam/result
import glenvy/dotenv

pub fn main() {
  // Load environment variables
  let _ = dotenv.load()
  
  io.println("Starting Turso database setup...")
  
  // Initialize database tables
  case turso_db.setup_database() {
    Ok(_) -> {
      io.println("Turso database setup completed successfully!")
    }
    Error(error) -> {
      io.println("Failed to set up Turso database: " <> inspect_error(error))
      // Don't panic, just return Ok so the server can continue
      // This makes the startup process more resilient
      Ok(Nil)
    }
  }
}

fn inspect_error(error: turso_db.DbError) -> String {
  case error {
    turso_db.ConnectionError(message) -> "Connection error: " <> message
    turso_db.QueryError(message) -> "Query error: " <> message
    turso_db.TransactionError(message) -> "Transaction error: " <> message
    turso_db.NoResultError -> "No result error"
    turso_db.ParseError(message) -> "Parse error: " <> message
  }
}

// Note: Pog module is disabled as it's not compatible with Turso
// import pog