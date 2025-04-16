import app
import gleam/io
import lustre

pub fn main() {
  io.println("Starting TandemX application...")

  // Create the Lustre application
  let app = lustre.application(app.init, app.update, app.view)

  // Start the application and mount it to the document
  case lustre.start(app, "#app", Nil) {
    Ok(_) -> io.println("App started successfully")
    Error(_) -> io.println("Failed to start app")
  }
}
