import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute.{class, content, selected, value}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    user_id: String,
    year: Int,
    month: Int,
    calendar_system: CalendarSystem,
    calendar_data: CalendarData,
    meetings: List(Meeting),
    schedule_state: ScheduleState,
  )
}

pub type CalendarSystem {
  CalendarSystem(
    id: String,
    name: String,
    description: String,
    timezone: String,
    first_day_of_week: Int,
    working_days: List(Int),
    working_hours: #(Int, Int),
  )
}

pub type CalendarData {
  CalendarData(
    calendar_system: CalendarSystem,
    day_data: List(DayData),
    events: List(Event),
    daily_reminders: List(DailyReminder),
  )
}

pub type DayData {
  DayData(
    date: String,
    is_today: Bool,
    is_current_month: Bool,
    is_working_day: Bool,
    events: List(String),
    reminders: List(String),
  )
}

pub type Event {
  Event(
    id: String,
    title: String,
    description: String,
    start_time: String,
    end_time: String,
    category: String,
    color: String,
  )
}

pub type DailyReminder {
  DailyReminder(id: String, title: String, time: String, days: List(Int))
}

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

pub type ScheduleState {
  NotScheduling
  SchedulingStep1(date: String)
  SchedulingStep2(date: String, start_time: String)
}

pub type Msg {
  ChangeMonth(Int, Int)
  PrevMonth
  NextMonth
  SelectDate(String)
  AddEvent(Event)
  AddReminder(DailyReminder)
  StartScheduling(String)
  SelectTime(String)
  SetMeetingDetails(String, String, List(String))
  CancelScheduling
}

pub type FormData {
  FormData(title: String, description: String, attendees: String)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_: Nil) -> #(Model, Effect(Msg)) {
  let default_system =
    CalendarSystem(
      id: "default",
      name: "Default Calendar",
      description: "Standard calendar system",
      timezone: "UTC",
      first_day_of_week: 1,
      // Monday
      working_days: [1, 2, 3, 4, 5],
      // Mon-Fri
      working_hours: #(9, 17),
      // 9 AM to 5 PM
    )

  let today = get_today()
  let calendar_data = get_month_data("user1", today.0, today.1, default_system)

  #(
    Model(
      user_id: "user1",
      year: today.0,
      month: today.1,
      calendar_system: default_system,
      calendar_data: calendar_data,
      meetings: [],
      schedule_state: NotScheduling,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ChangeMonth(year, month) -> {
      let calendar_data =
        get_month_data(model.user_id, year, month, model.calendar_system)
      #(
        Model(..model, year: year, month: month, calendar_data: calendar_data),
        effect.none(),
      )
    }

    PrevMonth -> {
      let #(year, month) = case model.month - 1 {
        0 -> #(model.year - 1, 12)
        month -> #(model.year, month)
      }
      let calendar_data =
        get_month_data(model.user_id, year, month, model.calendar_system)
      #(
        Model(..model, year: year, month: month, calendar_data: calendar_data),
        effect.none(),
      )
    }

    NextMonth -> {
      let #(year, month) = case model.month + 1 {
        13 -> #(model.year + 1, 1)
        month -> #(model.year, month)
      }
      let calendar_data =
        get_month_data(model.user_id, year, month, model.calendar_system)
      #(
        Model(..model, year: year, month: month, calendar_data: calendar_data),
        effect.none(),
      )
    }

    SelectDate(date) -> {
      // TODO: Implement date selection
      #(model, effect.none())
    }

    AddEvent(event) -> {
      // TODO: Implement event addition
      #(model, effect.none())
    }

    AddReminder(reminder) -> {
      // TODO: Implement reminder addition
      #(model, effect.none())
    }

    StartScheduling(date) -> {
      #(Model(..model, schedule_state: SchedulingStep1(date)), effect.none())
    }

    SelectTime(time) -> {
      case model.schedule_state {
        SchedulingStep1(date) -> #(
          Model(..model, schedule_state: SchedulingStep2(date, time)),
          effect.none(),
        )
        _ -> #(model, effect.none())
      }
    }

    SetMeetingDetails(title, description, attendees) -> {
      case model.schedule_state {
        SchedulingStep2(date, time) -> {
          let meeting =
            Meeting(
              id: generate_id(),
              title: title,
              description: description,
              date: date,
              start_time: time,
              duration_minutes: 30,
              // Default duration
              attendees: attendees,
              timezone: get_timezone(),
            )
          let meetings = [meeting, ..model.meetings]
          // Schedule meeting and send emails
          #(
            Model(..model, meetings: meetings, schedule_state: NotScheduling),
            schedule_meeting(meeting),
          )
        }
        _ -> #(model, effect.none())
      }
    }

    CancelScheduling -> #(
      Model(..model, schedule_state: NotScheduling),
      effect.none(),
    )

    _ -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("calendar-container")], [
    view_header(model),
    view_scheduling_modal(model),
    view_calendar(model),
  ])
}

fn view_header(model: Model) -> Element(Msg) {
  html.div([class("calendar-header")], [
    html.h1([class("calendar-title")], [html.text("Calendar")]),
    html.div([class("calendar-controls")], [
      html.button([class("control-btn"), event.on_click(PrevMonth)], [
        html.text("←"),
      ]),
      html.div([class("current-month")], [
        html.text(
          get_month_name(model.month) <> " " <> int.to_string(model.year),
        ),
      ]),
      html.button([class("control-btn"), event.on_click(NextMonth)], [
        html.text("→"),
      ]),
    ]),
  ])
}

fn get_month_name(month: Int) -> String {
  case month {
    1 -> "January"
    2 -> "February"
    3 -> "March"
    4 -> "April"
    5 -> "May"
    6 -> "June"
    7 -> "July"
    8 -> "August"
    9 -> "September"
    10 -> "October"
    11 -> "November"
    12 -> "December"
    _ -> "Unknown"
  }
}

@external(javascript, "./calendar_ffi.js", "getFormData")
fn get_form_data(form: Element(Msg)) -> Dict(String, String)

fn handle_submit(form: FormData) -> Msg {
  SetMeetingDetails(
    form.title,
    form.description,
    string.split(form.attendees, ","),
  )
}

fn view_scheduling_modal(model: Model) -> Element(Msg) {
  case model.schedule_state {
    NotScheduling -> element.none()

    SchedulingStep1(date) ->
      html.div([class("scheduling-modal")], [
        html.h2([], [html.text("Select Meeting Time")]),
        html.div([class("time-slots")], [
          view_time_slots(date, model.calendar_system.working_hours),
        ]),
        html.button([class("cancel-btn"), event.on_click(CancelScheduling)], [
          html.text("Cancel"),
        ]),
      ])

    SchedulingStep2(date, time) ->
      html.div([class("scheduling-modal")], [
        html.h2([], [html.text("Meeting Details")]),
        html.div([class("meeting-form")], [
          html.div([class("form-group")], [
            html.label([attribute.for("title")], [html.text("Title")]),
            html.input([
              attribute.type_("text"),
              attribute.name("title"),
              attribute.required(True),
            ]),
          ]),
          html.div([class("form-group")], [
            html.label([attribute.for("description")], [
              html.text("Description"),
            ]),
            html.textarea([attribute.name("description")], ""),
          ]),
          html.div([class("form-group")], [
            html.label([attribute.for("attendees")], [
              html.text("Attendees (comma-separated emails)"),
            ]),
            html.input([
              attribute.type_("text"),
              attribute.name("attendees"),
              attribute.required(True),
            ]),
          ]),
          html.div([class("time-info")], [
            html.p([], [
              html.text(
                "Meeting on "
                <> format_date(date)
                <> " at "
                <> format_time(time),
              ),
            ]),
            html.p([], [
              html.text(
                "EST: " <> convert_to_est(date, time) <> " | Local: " <> time,
              ),
            ]),
          ]),
          html.div([class("form-actions")], [
            html.button(
              [class("cancel-btn"), event.on_click(CancelScheduling)],
              [html.text("Cancel")],
            ),
            html.button(
              [
                class("submit-btn"),
                event.on_click(SetMeetingDetails(
                  "New Meeting",
                  "Meeting description",
                  string.split("user@example.com", ","),
                )),
              ],
              [html.text("Schedule Meeting")],
            ),
          ]),
        ]),
      ])
  }
}

fn view_calendar(model: Model) -> Element(Msg) {
  html.div([class("calendar-grid")], [
    view_weekdays(model.calendar_system),
    view_days(
      model.calendar_data.day_data,
      model.calendar_system,
      model.meetings,
    ),
    view_scheduling_modal(model),
  ])
}

fn view_weekdays(system: CalendarSystem) -> Element(Msg) {
  let weekdays = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
  ]

  // Rotate weekdays based on first_day_of_week
  let rotated_weekdays = case system.first_day_of_week {
    1 -> weekdays
    n -> {
      let index = n - 1
      list.append(list.drop(weekdays, index), list.take(weekdays, index))
    }
  }

  html.div(
    [class("weekdays")],
    list.map(rotated_weekdays, fn(name) {
      html.div([class("weekday")], [html.text(name)])
    }),
  )
}

fn view_days(
  days: List(DayData),
  system: CalendarSystem,
  meetings: List(Meeting),
) -> Element(Msg) {
  html.div(
    [class("days")],
    list.map(days, fn(day) {
      let is_working_day =
        list.contains(system.working_days, get_weekday(day.date))
      html.div(
        [
          class(
            "day"
            <> case day.is_current_month {
              True -> " current-month"
              False -> " other-month"
            }
            <> case day.is_today {
              True -> " today"
              False -> ""
            }
            <> case is_working_day {
              True -> " working-day"
              False -> " non-working-day"
            },
          ),
          event.on_click(StartScheduling(day.date)),
        ],
        [
          html.div([class("day-number")], [html.text(get_day_number(day.date))]),
          view_day_events(day.events),
          view_day_reminders(day.reminders),
          view_day_meetings(day.date, meetings),
        ],
      )
    }),
  )
}

fn view_day_events(events: List(String)) -> Element(Msg) {
  html.div(
    [class("day-events")],
    list.map(events, fn(event) {
      html.div([class("event")], [html.text(event)])
    }),
  )
}

fn view_day_reminders(reminders: List(String)) -> Element(Msg) {
  html.div(
    [class("day-reminders")],
    list.map(reminders, fn(reminder) {
      html.div([class("reminder")], [html.text(reminder)])
    }),
  )
}

fn view_day_meetings(date: String, meetings: List(Meeting)) -> Element(Msg) {
  let day_meetings = list.filter(meetings, fn(meeting) { meeting.date == date })

  html.div(
    [class("day-meetings")],
    list.map(day_meetings, fn(meeting) {
      html.div([class("meeting")], [
        html.text(meeting.title <> " (" <> meeting.start_time <> ")"),
      ])
    }),
  )
}

fn view_time_slots(date: String, working_hours: #(Int, Int)) -> Element(Msg) {
  let #(start_hour, end_hour) = working_hours
  let hours = list.range(start_hour, end_hour)

  html.div(
    [class("time-slots-grid")],
    list.flat_map(hours, fn(hour) {
      [view_time_slot(date, hour, 0), view_time_slot(date, hour, 30)]
    }),
  )
}

fn view_time_slot(date: String, hour: Int, minute: Int) -> Element(Msg) {
  let time = format_time_from_parts(hour, minute)
  html.button([class("time-slot"), event.on_click(SelectTime(time))], [
    html.text(time),
  ])
}

// Helper function to get weekday (1-7, Monday-Sunday)
fn get_weekday(date: String) -> Int {
  get_weekday_ffi(date)
}

// TODO: Implement these functions
fn get_today() -> #(Int, Int) {
  get_current_date()
}

fn get_month_data(
  user_id: String,
  year: Int,
  month: Int,
  system: CalendarSystem,
) -> CalendarData {
  let days = get_month_data_ffi(year, month)

  CalendarData(
    calendar_system: system,
    day_data: days,
    events: [],
    // TODO: Load events from backend
    daily_reminders: [],
    // TODO: Load reminders from backend
  )
}

fn get_day_number(date: String) -> String {
  get_day_number_ffi(date) |> int.to_string
}

@external(javascript, "./calendar_ffi.js", "getCurrentDate")
fn get_current_date() -> #(Int, Int)

@external(javascript, "./calendar_ffi.js", "getDayNumber")
fn get_day_number_ffi(date: String) -> Int

@external(javascript, "./calendar_ffi.js", "getWeekday")
fn get_weekday_ffi(date: String) -> Int

@external(javascript, "./calendar_ffi.js", "getMonthData")
fn get_month_data_ffi(year: Int, month: Int) -> List(DayData)

@external(javascript, "./calendar_ffi.js", "generateId")
fn generate_id() -> String

@external(javascript, "./calendar_ffi.js", "getTimezone")
fn get_timezone() -> String

@external(javascript, "./calendar_ffi.js", "formatDate")
fn format_date(date: String) -> String

@external(javascript, "./calendar_ffi.js", "formatTime")
fn format_time(time: String) -> String

@external(javascript, "./calendar_ffi.js", "formatTimeFromParts")
fn format_time_from_parts(hour: Int, minute: Int) -> String

@external(javascript, "./calendar_ffi.js", "convertToEst")
fn convert_to_est(date: String, time: String) -> String

@external(javascript, "./calendar_ffi.js", "scheduleMeeting")
fn schedule_meeting(meeting: Meeting) -> Effect(Msg)
