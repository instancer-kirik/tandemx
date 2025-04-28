import argv
import gleam/int
import gleam/io

// Server setup
pub fn main() {
  let port = case argv.load().arguments {
    [_, port_str, ..] -> {
      case int.parse(port_str) {
        Ok(port) -> port
        Error(_) -> 3000
      }
    }
    _ -> 3000
  }

  io.println("This is a placeholder server!")
  io.println("Server would start on port " <> int.to_string(port))
  io.println("")
  io.println("The real server implementation needs:")
  io.println("- gleam_bit_string package")
  io.println("- gleam_postgres package")
  io.println("")
  io.println("For now, use the client-side database implementation we created.")
}
