import gleam/bytes_tree
import gleam/http/response.{type Response}
import gleam/io
import gleam/list
import gleam/string
import mist.{type ResponseData, Bytes}

/// Meeting type representing a calendar meeting
pub type Meeting {
  Meeting(
    id: String,
    title: String,
    description: String,
    date: String,
    start_time: String,
    duration_minutes: Int,
    attendees: List(String),
    timezone: String,
    location_type: String,
    location: String,
  )
}

/// Email notification type
pub type EmailNotification {
  EmailNotification(to: String, subject: String, body: String, from: String)
}

/// Handle a meeting scheduling request
/// In a real implementation this would:
/// 1. Parse the JSON data
/// 2. Extract meeting details
/// 3. Send emails to attendees
/// 4. Store the meeting in a database
/// For now we just log information and return a success response
pub fn handle_meeting_request(body: String) -> Response(ResponseData) {
  // Log the meeting data we received
  io.println("Meeting scheduling request received")
  io.println("Meeting data: " <> body)

  // Simulate sending emails
  io.println("Would send emails to attendees with meeting details")
  io.println("Using sender email: instance.select@gmail.com")

  // Return a success response
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(
    Bytes(bytes_tree.from_string(
      "{\"status\":\"success\",\"message\":\"Meeting scheduled and emails sent\"}",
    )),
  )
}

/// Create an error response
pub fn create_error_response(
  status: Int,
  message: String,
) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(
    Bytes(bytes_tree.from_string("{\"error\":\"" <> message <> "\"}")),
  )
}
