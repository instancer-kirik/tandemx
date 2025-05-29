import email_service.{type EmailNotification}
import gleam/bytes_tree
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

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
    location_type: Option(MeetingLocationType),
    virtual_meeting_link: Option(String),
  )
}

/// Type for meeting location: Physical or Virtual
pub type MeetingLocationType {
  Physical
  Virtual
}

/// Handle a meeting scheduling request
/// This function:
/// 1. Parses the JSON data
/// 2. Extracts meeting details
/// 3. Sends emails to attendees
/// 4. Returns a response to the client
pub fn handle_meeting_request(
  json_body: dynamic.Dynamic,
) -> Response(ResponseData) {
  case decode_meeting(json_body) {
    Ok(meeting) -> {
      let notifications =
        list.map(meeting.attendees, fn(attendee) {
          email_service.EmailNotification(
            to: attendee,
            from: "instance.select@example.com",
            subject: "New Meeting: " <> meeting.title,
            body: string.concat([
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
              int.to_string(meeting.duration_minutes),
              " minutes\n",
              case meeting.location_type {
                Some(Virtual) ->
                  "Location: Virtual Meeting\nLink: "
                  <> option.unwrap(
                    meeting.virtual_meeting_link,
                    "No link provided",
                  )
                  <> "\n"
                Some(Physical) ->
                  "Location: Physical Meeting (Details to be confirmed)\n"
                None -> "Location: To be determined\n"
              },
            ]),
          )
        })

      list.each(notifications, fn(n: EmailNotification) {
        send_email_ffi_placeholder(n.to, n.subject, n.body)
      })

      response.new(200)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(Bytes(
        json.object([#("status", json.string("success"))])
        |> json.to_string
        |> bytes_tree.from_string,
      ))
    }
    Error(errors) -> {
      let error_string = format_decode_errors(errors)
      response.new(400)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(Bytes(
        json.object([
          #("error", json.string("Invalid request data: " <> error_string)),
        ])
        |> json.to_string
        |> bytes_tree.from_string,
      ))
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

// Helper function to format decode errors
fn format_decode_errors(errors: List(decode.DecodeError)) -> String {
  errors
  |> list.map(fn(error) {
    let path = string.join(error.path, ".")
    // Accessing DecodeError fields directly
    "Path: '"
    <> path
    <> "', Expected: '"
    <> error.expected
    <> "', Found: '"
    <> error.found
    <> "'"
  })
  |> string.join("; ")
}

// Decoder for MeetingLocationType enum
fn meeting_location_type_decoder() -> decode.Decoder(MeetingLocationType) {
  decode.string
  |> decode.then(fn(s) {
    case string.lowercase(s) {
      "physical" -> decode.success(Physical)
      "virtual" -> decode.success(Virtual)
      _ -> decode.failure(Physical, "Invalid MeetingLocationType string: " <> s)
    }
  })
}

// Decoder for the Meeting struct
fn meeting_field_decoder() -> decode.Decoder(Meeting) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.string)
    use date <- decode.field("date", decode.string)
    use start_time <- decode.field("start_time", decode.string)
    use duration_minutes <- decode.field("duration_minutes", decode.int)
    use attendees <- decode.field("attendees", decode.list(decode.string))
    use timezone <- decode.field("timezone", decode.string)
    use location_type <- decode.field(
      "location_type",
      decode.optional(meeting_location_type_decoder()),
    )
    use virtual_meeting_link <- decode.field(
      "virtual_meeting_link",
      decode.optional(decode.string),
    )
    decode.success(Meeting(
      id,
      title,
      description,
      date,
      start_time,
      duration_minutes,
      attendees,
      timezone,
      location_type,
      virtual_meeting_link,
    ))
  }
}

// Public function to decode a Meeting from dynamic data
pub fn decode_meeting(
  data: dynamic.Dynamic,
) -> Result(Meeting, List(decode.DecodeError)) {
  decode.run(data, meeting_field_decoder())
}

// Placeholder function for sending an email
fn send_email_ffi_placeholder(
  _to: String,
  _subject: String,
  _body: String,
) -> Nil {
  Nil
}
