import argv
import gleam/dynamic
import gleam/erlang/os
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage, Text, websocket,
}
import simplifile

// Meeting types
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
  )
}

pub type CartState {
  CartState(items: String)
}

pub type CartActor {
  CartActor(state: CartState, connections: List(String))
}

// Mock data for meetings
pub fn get_mock_meetings() -> List(Meeting) {
  [
    Meeting(
      id: "1",
      title: "Team Standup",
      description: "Daily team sync meeting",
      date: "2023-04-25",
      start_time: "10:00",
      duration_minutes: 30,
      attendees: ["user1", "user2", "user3"],
      timezone: "UTC",
    ),
    Meeting(
      id: "2",
      title: "Project Review",
      description: "Quarterly project review",
      date: "2023-04-28",
      start_time: "14:00",
      duration_minutes: 60,
      attendees: ["user1", "user4"],
      timezone: "UTC",
    ),
  ]
}

// Server setup
pub fn main() {
  let port = case argv.load().get(1) {
    Ok(port_str) -> {
      case int.parse(port_str) {
        Ok(port) -> port
        Error(_) -> 3000
      }
    }
    Error(_) -> 3000
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

fn handle_request(req: Request(ResponseData)) -> Response(ResponseData) {
  case req.method, req.path_segments() {
    Get, ["meetings", id] -> {
      // Find meeting in mock data
      let meetings = get_mock_meetings()
      let meeting = list.find(meetings, fn(m) { m.id == id })

      case meeting {
        Ok(found) -> {
          response.new(200)
          |> response.set_header("content-type", "application/json")
          |> response.set_body(json.to_string(meeting_to_json(found)))
        }
        Error(_) -> {
          response.new(404)
          |> response.set_header("content-type", "application/json")
          |> response.set_body(
            json.to_string(error_to_json("Meeting not found")),
          )
        }
      }
    }

    Post, ["meetings"] -> {
      // In a real app, we would parse the request body and save to db
      let mock_meeting =
        Meeting(
          id: "3",
          title: "New Meeting",
          description: "Created from request",
          date: "2023-05-01",
          start_time: "15:00",
          duration_minutes: 45,
          attendees: ["user1"],
          timezone: "UTC",
        )

      response.new(201)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(json.to_string(meeting_to_json(mock_meeting)))
    }

    _, _ -> response.new(404)
  }
}

fn meeting_to_json(meeting: Meeting) -> json.Json {
  json.object([
    #("id", json.string(meeting.id)),
    #("title", json.string(meeting.title)),
    #("description", json.string(meeting.description)),
    #("date", json.string(meeting.date)),
    #("start_time", json.string(meeting.start_time)),
    #("duration_minutes", json.int(meeting.duration_minutes)),
    #("timezone", json.string(meeting.timezone)),
    #("attendees", json.array(list.map(meeting.attendees, json.string))),
  ])
}

fn error_to_json(error: String) -> json.Json {
  json.object([#("error", json.string(error))])
}

fn handle_message(msg: WebsocketMessage(String), state: CartActor) -> CartActor {
  case msg {
    Text(data) -> {
      CartActor(..state, connections: [data, ..state.connections])
    }
    _ -> state
  }
}
