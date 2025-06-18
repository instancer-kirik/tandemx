import database
import gleam/io
import gleam/result
import glenvy/dotenv

pub fn main() {
  // Load environment variables
  let _ = dotenv.load()
  
  io.println("Starting database setup...")
  
  // Initialize database tables
  case database.setup_database() {
    Ok(_) -> {
      io.println("Database setup completed successfully!")
    }
    Error(error) -> {
      io.println("Failed to set up database: " <> inspect_error(error))
      // Exit with error status
      // Note: In a real application, you might want to handle this more gracefully
      // or implement retries before failing
      panic("Database setup failed")
    }
  }
}

fn inspect_error(error: database.DbError) -> String {
  case error {
    database.ConnectionError(message) -> "Connection error: " <> message
    database.QueryError(message) -> "Query error: " <> message
    database.TransactionError(message) -> "Transaction error: " <> message
    database.NoResultError -> "No result error"
    database.ParseError(message) -> "Parse error: " <> message
  }
}