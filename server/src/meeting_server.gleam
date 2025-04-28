import email_service.{type EmailNotification}
import gleam/bytes_tree
import gleam/dynamic
import gleam/http/response.{type Response}
import gleam/io
import gleam/list
import gleam/result
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
    location_type: LocationType,
    location: String,
  )
}

/// Location type for meetings
pub type LocationType {
  Virtual
  Physical
}

/// Handle a meeting scheduling request
/// This function:
/// 1. Parses the JSON data
/// 2. Extracts meeting details
/// 3. Sends emails to attendees
/// 4. Returns a response to the client
pub fn handle_meeting_request(body: String) -> Response(ResponseData) {
  // Parse the meeting JSON
  let json = dynamic.from(body)

  // Extract basic meeting fields first
  let basic_result = decode_basic_meeting(json)

  case basic_result {
    Ok(basic_meeting) -> {
      // Determine location type (default to Virtual)
      let location_type = case get_location_type(json) {
        Ok(location_type) -> location_type
        Error(_) -> Virtual
      }

      // Get location
      let location = case dynamic.field("location", dynamic.string)(json) {
        Ok(loc) -> loc
        Error(_) -> ""
      }

      // Create full meeting
      let meeting =
        Meeting(
          ..basic_meeting,
          location_type: location_type,
          location: location,
        )

      // Log the meeting data we received
      io.println("\nMeeting scheduling request received")
      io.println("Meeting title: " <> meeting.title)
      io.println(
        "Meeting date: " <> meeting.date <> " at " <> meeting.start_time,
      )
      io.println(
        "Duration: " <> string.inspect(meeting.duration_minutes) <> " minutes",
      )
      io.println("Attendees: " <> string.join(meeting.attendees, ", "))

      // Generate meeting link if it's virtual and no link was provided
      let final_location = case meeting.location_type, meeting.location {
        Virtual, "" -> generate_meeting_link("google")
        _, loc -> loc
      }

      // Create a meeting with the possibly updated location
      let final_meeting = Meeting(..meeting, location: final_location)

      // Send emails to all attendees
      let notifications =
        list.map(meeting.attendees, fn(attendee) {
          create_meeting_notification(final_meeting, attendee)
        })

      // Send the emails using our new email service
      list.each(notifications, email_service.send_meeting_invitation)

      // Return a success response
      response.new(200)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(
        Bytes(bytes_tree.from_string(
          "{\"status\":\"success\",\"message\":\"Meeting scheduled and emails sent\",\"meeting_link\":\""
          <> final_location
          <> "\"}",
        )),
      )
    }
    Error(errors) -> {
      // Log the error
      io.println("\nError decoding meeting data: " <> string.inspect(errors))
      io.println("Raw body: " <> body)

      // Return an error response
      create_error_response(400, "Invalid meeting data format")
    }
  }
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

/// Create an email notification for a meeting
fn create_meeting_notification(
  meeting: Meeting,
  recipient: String,
) -> EmailNotification {
  // Create meeting details text
  let location_info = case meeting.location_type {
    Virtual -> "Virtual meeting link: " <> meeting.location
    Physical -> "Location: " <> meeting.location
  }

  // Format the email body
  let body =
    string.concat([
      "You have been invited to a meeting:\n\n",
      "Title: ",
      meeting.title,
      "\n",
      "Description: ",
      meeting.description,
      "\n",
      "Date: ",
      meeting.date,
      "\n",
      "Time: ",
      meeting.start_time,
      " (",
      meeting.timezone,
      ")\n",
      "Duration: ",
      string.inspect(meeting.duration_minutes),
      " minutes\n\n",
      location_info,
      "\n\n",
      "This meeting was scheduled using TandemX Calendar.",
    ])

  // Create the notification object using the imported constructor
  email_service.EmailNotification(
    to: recipient,
    subject: "Meeting Invitation: " <> meeting.title,
    body: body,
    from: "instance.select@gmail.com",
    // As requested, use this as sender
  )
}

/// Send an email notification
fn send_email(notification: EmailNotification) -> Nil {
  // In a real implementation, this would connect to an email service
  // For now, we just log the email details
  io.println("\nSending email notification:")
  io.println("From: " <> notification.from)
  io.println("To: " <> notification.to)
  io.println("Subject: " <> notification.subject)
  io.println("Body:\n" <> notification.body)
  io.println("---")
}

/// Generate a Google Meet link
fn generate_meeting_link(service: String) -> String {
  case service {
    "google" -> {
      // In a real implementation, this would use the Google Calendar API
      // For now, we generate a mock link
      let random_suffix = generate_random_string(10)
      "https://meet.google.com/" <> random_suffix
    }
    _ -> "https://meet.google.com/" <> generate_random_string(10)
  }
}

/// Generate a random string for meeting IDs
fn generate_random_string(length: Int) -> String {
  // Simple implementation for demo purposes
  // In a real application, use a proper random generator
  "abc" <> string.inspect(length) <> "xyz123"
}

// Create a partial meeting record without location information
fn decode_basic_meeting(
  json: dynamic.Dynamic,
) -> Result(Meeting, List(dynamic.DecodeError)) {
  dynamic.decode8(
    fn(id, title, description, date, start_time, duration, attendees, timezone) {
      Meeting(
        id: id,
        title: title,
        description: description,
        date: date,
        start_time: start_time,
        duration_minutes: duration,
        attendees: attendees,
        timezone: timezone,
        location_type: Virtual,
        // Default
        location: "",
        // Default
      )
    },
    dynamic.field("id", dynamic.string),
    dynamic.field("title", dynamic.string),
    dynamic.field("description", dynamic.string),
    dynamic.field("date", dynamic.string),
    dynamic.field("start_time", dynamic.string),
    dynamic.field("duration_minutes", dynamic.int),
    dynamic.field("attendees", dynamic.list(dynamic.string)),
    dynamic.field("timezone", dynamic.string),
  )(json)
}

// Extract the location type from the JSON data
fn get_location_type(
  json: dynamic.Dynamic,
) -> Result(LocationType, List(dynamic.DecodeError)) {
  dynamic.field("location_type", dynamic.string)(json)
  |> result.map(fn(location_type) {
    case location_type {
      "virtual" | "Virtual" -> Virtual
      "physical" | "Physical" -> Physical
      _ -> Virtual
    }
  })
}
