import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute.{class, href, id, rel, type_}
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html.{
  a, button, div, form, h1, h2, input, label, li, nav, p, span, text, ul,
}
import lustre/event

pub type Model {
  Model(
    year: Int,
    month: Int,
    user_id: String,
    calendar_system: CalendarSystem,
    calendar_data: CalendarData,
    meetings: List(Meeting),
    schedule_state: ScheduleState,
    selected_date: Option(String),
    loading: Bool,
    system_type: CalendarSystemType,
  )
}

pub type CalendarSystem {
  CalendarSystem(
    events: List(Event),
    daily_reminders: List(DailyReminder),
    year: Int,
    month: Int,
    selected_date: Option(String),
    new_meeting: Option(Meeting),
    system_type: CalendarSystemType,
  )
}

pub type Meeting {
  Meeting(
    id: Option(String),
    title: String,
    description: String,
    date: String,
    start_time: String,
    duration_minutes: Int,
    attendees: String,
    location_type: LocationType,
    location: String,
  )
}

pub type LocationType {
  Physical
  Virtual
}

pub type CalendarData {
  MonthData(
    days: List(DayData),
    weeks: List(List(DayData)),
    month_name: String,
    prev_month: String,
    next_month: String,
  )
}

pub type DayData {
  DayData(
    date: String,
    day: Int,
    day_of_week: Int,
    is_current_month: Bool,
    events: List(Event),
    reminders: List(DailyReminder),
  )
}

pub type Event {
  Event(
    id: String,
    title: String,
    description: String,
    start_time: String,
    end_time: String,
    date: String,
  )
}

pub type DailyReminder {
  DailyReminder(id: String, text: String, time: String)
}

pub type ScheduleState {
  NotScheduling
  SchedulingStep1(date: String)
  SchedulingStep2(date: String, time: String)
}

pub type FormData {
  FormData(title: String, description: String, attendees: String)
}

pub type Msg {
  ChangeMonth(String)
  PrevMonth
  NextMonth
  SelectDate(date: String)
  AddEvent(event: Event)
  AddReminder(reminder: DailyReminder)
  StartScheduling(date: String)
  SelectTime(time: String)
  SetMeetingDetails(Meeting)
  CancelScheduling
  SetWeekLength(length: Int)
  SetWeekOffset(offset: Int)
  OpenDayView(date: String)
  CloseDayView
  Initialized
  SetupComplete
  MeetingsLoaded(List(Meeting))
  OpenScheduler(String)
  MeetingScheduled(Meeting)
  ChangeCalendarSystem(CalendarSystemType)
}

pub type CalendarSystemType {
  Gregorian
  Mayan
  Julian
  Hebrew
  Islamic
  Persian
}

// Initialize user interface with today's date
pub fn init(_: Nil) -> #(Model, effect.Effect(Msg)) {
  let today_date = get_today_date()
  let today = string.split(today_date, "-")
  let year = case list.first(today) {
    Ok(y) -> int.parse(y) |> result.unwrap(2023)
    Error(_) -> 2023
  }

  // Get month (second element) by dropping the first element and taking the first of what remains
  let month = case list.drop(today, 1) |> list.first {
    Ok(m) -> int.parse(m) |> result.unwrap(1)
    Error(_) -> 1
  }

  let days = generate_month_days(year, month, today_date)

  let default_system =
    CalendarSystem(
      events: [],
      daily_reminders: [],
      year: year,
      month: month,
      selected_date: Some(today_date),
      new_meeting: None,
      system_type: Mayan,
    )

  let default_data =
    MonthData(
      days: days,
      weeks: create_weeks(days),
      month_name: month_name(month),
      prev_month: month_name(case month - 1 {
        0 -> 12
        m -> m
      }),
      next_month: month_name(case month + 1 {
        13 -> 1
        m -> m
      }),
    )

  #(
    Model(
      year: year,
      month: month,
      user_id: "user123",
      calendar_system: default_system,
      calendar_data: default_data,
      meetings: [],
      schedule_state: NotScheduling,
      selected_date: Some(today_date),
      loading: True,
      system_type: Mayan,
    ),
    effect.batch([
      effect.from(fn(dispatch) { dispatch(Initialized) }),
      load_meetings_ffi("user123"),
    ]),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Initialized -> {
      io.println("Calendar initialized")
      #(Model(..model, loading: False), effect.none())
    }

    SetupComplete -> {
      io.println("Calendar setup complete")
      #(Model(..model, loading: False), effect.none())
    }

    MeetingsLoaded(meetings) -> {
      io.println(
        "Loaded " <> int.to_string(list.length(meetings)) <> " meetings",
      )

      // Add meetings to the calendar data
      let updated_days =
        add_meetings_to_days(model.calendar_data.days, meetings)
      let updated_data =
        MonthData(
          ..model.calendar_data,
          days: updated_days,
          weeks: create_weeks(updated_days),
        )

      #(
        Model(
          ..model,
          meetings: meetings,
          calendar_data: updated_data,
          loading: False,
        ),
        effect.none(),
      )
    }

    ChangeMonth(direction) -> {
      let #(new_year, new_month) = case direction {
        "next" -> {
          case model.month == 12 {
            True -> #(model.year + 1, 1)
            False -> #(model.year, model.month + 1)
          }
        }
        "prev" -> {
          case model.month == 1 {
            True -> #(model.year - 1, 12)
            False -> #(model.year, model.month - 1)
          }
        }
        _ -> #(model.year, model.month)
      }

      let today_date = model.selected_date |> option.unwrap(get_today_date())
      let days = generate_month_days(new_year, new_month, today_date)
      let updated_days = add_meetings_to_days(days, model.meetings)

      let new_data =
        MonthData(
          days: updated_days,
          weeks: create_weeks(updated_days),
          month_name: month_name(new_month),
          prev_month: month_name(case new_month - 1 {
            0 -> 12
            m -> m
          }),
          next_month: month_name(case new_month + 1 {
            13 -> 1
            m -> m
          }),
        )

      let new_system =
        CalendarSystem(
          ..model.calendar_system,
          year: new_year,
          month: new_month,
        )

      #(
        Model(
          ..model,
          year: new_year,
          month: new_month,
          calendar_system: new_system,
          calendar_data: new_data,
        ),
        effect.none(),
      )
    }

    SelectDate(date) -> {
      io.println("Selected date: " <> date)
      #(
        Model(
          ..model,
          selected_date: Some(date),
          calendar_system: CalendarSystem(
            ..model.calendar_system,
            selected_date: Some(date),
          ),
        ),
        effect.none(),
      )
    }

    OpenScheduler(date) -> {
      let new_meeting =
        Meeting(
          id: None,
          title: "",
          description: "",
          date: date,
          start_time: "09:00",
          duration_minutes: 30,
          attendees: "",
          location_type: Virtual,
          location: "",
        )

      #(
        Model(
          ..model,
          schedule_state: SchedulingStep1(date),
          calendar_system: CalendarSystem(
            ..model.calendar_system,
            new_meeting: Some(new_meeting),
          ),
        ),
        open_scheduler_ffi(date),
      )
    }

    SetMeetingDetails(meeting) -> {
      io.println("Setting meeting details: " <> meeting.title)
      #(model, schedule_meeting_ffi(meeting))
    }

    MeetingScheduled(meeting) -> {
      io.println("Meeting scheduled: " <> meeting.title)

      let updated_meetings = [meeting, ..model.meetings]

      // Add the new meeting to calendar days
      let updated_days =
        add_meetings_to_days(model.calendar_data.days, updated_meetings)
      let updated_data =
        MonthData(
          ..model.calendar_data,
          days: updated_days,
          weeks: create_weeks(updated_days),
        )

      #(
        Model(
          ..model,
          meetings: updated_meetings,
          calendar_data: updated_data,
          schedule_state: NotScheduling,
          calendar_system: CalendarSystem(
            ..model.calendar_system,
            new_meeting: None,
          ),
        ),
        effect.none(),
      )
    }

    CancelScheduling -> #(
      Model(..model, schedule_state: NotScheduling),
      effect.none(),
    )

    ChangeCalendarSystem(system_type) -> {
      io.println("Changing calendar system to: " <> string.inspect(system_type))

      #(
        Model(
          ..model,
          system_type: system_type,
          calendar_system: CalendarSystem(
            ..model.calendar_system,
            system_type: system_type,
          ),
        ),
        change_calendar_system_ffi(system_type),
      )
    }

    _ -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  case model.loading {
    True ->
      div([id("calendar-root"), class("calendar-container")], [
        div([id("calendar-header"), class("calendar-header")], [
          h1([class("calendar-title")], [text("Calendar")]),
          p([], [text("View and schedule your meetings")]),
        ]),
        div([class("loading")], [text("Loading calendar...")]),
      ])

    False ->
      div([id("calendar-root"), class("calendar-container")], [
        div([id("calendar-header"), class("calendar-header")], [
          h1([class("calendar-title")], [text("Calendar")]),
          div([class("calendar-controls")], [
            div([class("month-selector")], [
              button(
                [
                  class("control-btn prev-month"),
                  event.on("click", fn(_) { Ok(ChangeMonth("prev")) }),
                ],
                [text("Previous")],
              ),
              h2([class("current-month")], [
                text(
                  month_name(model.month) <> " " <> int.to_string(model.year),
                ),
              ]),
              button(
                [
                  class("control-btn next-month"),
                  event.on("click", fn(_) { Ok(ChangeMonth("next")) }),
                ],
                [text("Next")],
              ),
            ]),
          ]),
        ]),
        div([id("calendar-view"), class("calendar-view")], [
          // Calendar grid
          div([id("calendar-grid"), class("calendar-grid")], [
            // Weekdays header
            div(
              [
                class("weekdays"),
                attribute.style([#("grid-template-columns", "repeat(7, 1fr)")]),
              ],
              render_weekdays(),
            ),
            // Days grid
            div(
              [
                class("days"),
                attribute.style([#("grid-template-columns", "repeat(7, 1fr)")]),
              ],
              render_days(model),
            ),
          ]),
        ]),
      ])
  }
}

fn render_weekdays() -> List(Element(Msg)) {
  let weekday_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  list.map(weekday_names, fn(day) {
    div([class("weekday")], [span([class("weekday-letter")], [text(day)])])
  })
}

fn render_days(model: Model) -> List(Element(Msg)) {
  // Flatten all days into a single list for the grid
  list.flat_map(model.calendar_data.weeks, fn(week) {
    list.map(week, fn(day) {
      let is_selected = case model.selected_date {
        Some(selected) -> selected == day.date
        None -> False
      }

      let is_today = day.date == get_today_date()

      let day_classes =
        string.join(
          list.filter(
            [
              "day",
              case day.is_current_month {
                True -> ""
                False -> "other-month"
              },
              case is_selected {
                True -> "selected"
                False -> ""
              },
              case is_today {
                True -> "today"
                False -> ""
              },
            ],
            fn(c) { c != "" },
          ),
          " ",
        )

      div(
        [
          class(day_classes),
          event.on("click", fn(_) { Ok(SelectDate(day.date)) }),
        ],
        [
          div([class("day-header")], [
            span([class("day-number")], [text(int.to_string(day.day))]),
            div([class("day-labels")], [
              span([class("weekday-name")], [
                text(get_short_day_name(day.day_of_week)),
              ]),
            ]),
          ]),
          // Events for this day
          render_day_events(day),
          // Button to add event if this is the current month
          case day.is_current_month {
            True ->
              div([class("day-actions")], [
                button(
                  [
                    class("schedule-btn"),
                    event.on("click", fn(_) { Ok(OpenScheduler(day.date)) }),
                  ],
                  [text("+")],
                ),
              ])
            False -> div([], [])
          },
        ],
      )
    })
  })
}

fn render_day_events(day: DayData) -> Element(Msg) {
  div(
    [class("day-events")],
    list.map(day.events, fn(event) {
      div([class("event")], [
        text(event.title <> " (" <> event.start_time <> ")"),
      ])
    }),
  )
}

// Helper to get short day name from day of week
fn get_short_day_name(day: Int) -> String {
  case day {
    1 -> "Mon"
    2 -> "Tue"
    3 -> "Wed"
    4 -> "Thu"
    5 -> "Fri"
    6 -> "Sat"
    7 -> "Sun"
    _ -> ""
  }
}

// Generate the days for a month
fn generate_month_days(year: Int, month: Int, today: String) -> List(DayData) {
  // Get the first day of the month
  let first_day = get_first_day_of_month(year, month)
  // Get the number of days in the month
  let days_in_month = get_days_in_month(year, month)
  // Get the day of the week of the first day (1-7, Monday-Sunday)
  let first_day_of_week = get_day_of_week(first_day)

  // Calculate previous month details
  let #(prev_year, prev_month) = case month {
    1 -> #(year - 1, 12)
    _ -> #(year, month - 1)
  }
  let prev_month_days = get_days_in_month(prev_year, prev_month)

  // Calculate next month details
  let #(next_year, next_month) = case month {
    12 -> #(year + 1, 1)
    _ -> #(year, month + 1)
  }

  // Create days from previous month to fill first week
  let prev_month_filler =
    list.range(prev_month_days - first_day_of_week + 2, prev_month_days + 1)
    |> list.map(fn(day) {
      let date = format_date(prev_year, prev_month, day)
      DayData(
        date: date,
        day: day,
        day_of_week: get_day_of_week(date),
        is_current_month: False,
        events: [],
        reminders: [],
      )
    })

  // Create days for current month
  let current_month_days =
    list.range(1, days_in_month)
    |> list.map(fn(day) {
      let date = format_date(year, month, day)
      DayData(
        date: date,
        day: day,
        day_of_week: get_day_of_week(date),
        is_current_month: True,
        events: [],
        reminders: [],
      )
    })

  // Calculate how many days we need from next month
  let total_days_so_far =
    list.length(prev_month_filler) + list.length(current_month_days)
  let next_month_days_needed = 42 - total_days_so_far
  // 6 weeks grid

  // Create days from next month
  let next_month_filler =
    list.range(1, next_month_days_needed)
    |> list.map(fn(day) {
      let date = format_date(next_year, next_month, day)
      DayData(
        date: date,
        day: day,
        day_of_week: get_day_of_week(date),
        is_current_month: False,
        events: [],
        reminders: [],
      )
    })

  // Combine all days
  list.append(
    prev_month_filler,
    list.append(current_month_days, next_month_filler),
  )
}

// Format a date as YYYY-MM-DD
fn format_date(year: Int, month: Int, day: Int) -> String {
  let month_str = int.to_string(month)
  let month_padded = case string.length(month_str) {
    1 -> "0" <> month_str
    _ -> month_str
  }

  let day_str = int.to_string(day)
  let day_padded = case string.length(day_str) {
    1 -> "0" <> day_str
    _ -> day_str
  }

  int.to_string(year) <> "-" <> month_padded <> "-" <> day_padded
}

// Group days into weeks
fn create_weeks(days: List(DayData)) -> List(List(DayData)) {
  case days {
    [] -> []
    _ -> {
      // Create 7-day chunks for weeks
      let first_week = list.take(days, 7)
      let remaining = list.drop(days, 7)
      [first_week, ..create_weeks(remaining)]
    }
  }
}

// Add meetings to the appropriate days
fn add_meetings_to_days(
  days: List(DayData),
  meetings: List(Meeting),
) -> List(DayData) {
  list.map(days, fn(day) {
    let day_meetings =
      list.filter(meetings, fn(meeting) { meeting.date == day.date })

    // Convert meetings to events
    let events =
      list.map(day_meetings, fn(meeting) {
        Event(
          id: option.unwrap(meeting.id, generate_id()),
          title: meeting.title,
          description: meeting.description,
          start_time: meeting.start_time,
          end_time: calculate_end_time(
            meeting.start_time,
            meeting.duration_minutes,
          ),
          date: meeting.date,
        )
      })

    DayData(..day, events: events)
  })
}

// Calculate end time based on start time and duration
fn calculate_end_time(start_time: String, duration_minutes: Int) -> String {
  // Simple placeholder - in a real app would use date arithmetic
  start_time
}

// Helper to get the first day of a month as YYYY-MM-DD
fn get_first_day_of_month(year: Int, month: Int) -> String {
  format_date(year, month, 1)
}

// Helper to get days in month
fn get_days_in_month(year: Int, month: Int) -> Int {
  case month {
    2 -> {
      // Check for leap year
      case is_leap_year(year) {
        True -> 29
        False -> 28
      }
    }
    4 | 6 | 9 | 11 -> 30
    _ -> 31
  }
}

// Check if a year is a leap year
fn is_leap_year(year: Int) -> Bool {
  case int.remainder(year, 400) {
    Ok(0) -> True
    _ ->
      case int.remainder(year, 100) {
        Ok(0) -> False
        _ ->
          case int.remainder(year, 4) {
            Ok(0) -> True
            _ -> False
          }
      }
  }
}

// Get day of week (1-7, Monday-Sunday) from a date string
fn get_day_of_week(date: String) -> Int {
  let js_day = get_weekday(date)

  // Convert JS day (0=Sunday) to our format (1=Monday, 7=Sunday)
  case js_day {
    0 -> 7
    // Sunday
    _ -> js_day
  }
}

// Helper function to handle form submission
fn handle_submit(form: FormData) -> Msg {
  SetMeetingDetails(Meeting(
    id: None,
    title: form.title,
    description: form.description,
    date: "",
    start_time: "",
    duration_minutes: 30,
    attendees: form.attendees,
    location_type: Virtual,
    location: "",
  ))
}

// Helper to convert month number to name
fn month_name(month: Int) -> String {
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

// External function imports
@external(javascript, "./calendar_ffi.js", "scheduleMeeting")
fn schedule_meeting_ffi(meeting: Meeting) -> effect.Effect(Msg)

@external(javascript, "./calendar_ffi.js", "getTodayDate")
fn get_today_date() -> String

@external(javascript, "./calendar_ffi.js", "getTimezone")
fn get_timezone() -> String

@external(javascript, "./calendar_ffi.js", "generateId")
fn generate_id() -> String

@external(javascript, "./calendar_ffi.js", "generateMeetingLink")
fn auto_generate_meeting_link() -> String

@external(javascript, "./calendar_ffi.js", "getWeekday")
fn get_weekday(date: String) -> Int

/// Call the calendar FFI to setup the UI
fn call_calendar_ffi(model: Model) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_setup_calendar_ffi()
    dispatch(SetupComplete)
  })
}

/// Load meetings for the calendar
fn load_meetings_ffi(user_id: String) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let meetings = do_load_meetings_ffi(user_id)
    dispatch(MeetingsLoaded(meetings))
  })
}

/// Change the month in the calendar
fn change_month_ffi(year: Int, month: Int) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_change_month_ffi(year, month)
    dispatch(Initialized)
  })
}

/// Select a date in the calendar
fn select_date_ffi(date: String) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_select_date_ffi(date)
    dispatch(Initialized)
  })
}

/// Open the scheduler for a date
fn open_scheduler_ffi(date: String) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_open_scheduler_ffi(date)
    dispatch(Initialized)
  })
}

/// Close the scheduler
fn close_scheduler_ffi() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_close_scheduler_ffi()
    dispatch(Initialized)
  })
}

/// Load the calendar FFI setup
fn load_calendar_ffi() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let _ = do_load_calendar_ffi()
    dispatch(Initialized)
  })
}

// External FFI functions
@external(javascript, "./calendar_ffi.js", "setupCalendar")
fn do_setup_calendar_ffi() -> Dynamic

@external(javascript, "./calendar_ffi.js", "loadMeetings")
fn do_load_meetings_ffi(user_id: String) -> List(Meeting)

@external(javascript, "./calendar_ffi.js", "changeMonth")
fn do_change_month_ffi(year: Int, month: Int) -> Dynamic

@external(javascript, "./calendar_ffi.js", "selectDate")
fn do_select_date_ffi(date: String) -> Dynamic

@external(javascript, "./calendar_ffi.js", "openScheduler")
fn do_open_scheduler_ffi(date: String) -> Dynamic

@external(javascript, "./calendar_ffi.js", "closeScheduler")
fn do_close_scheduler_ffi() -> Dynamic

@external(javascript, "./calendar_ffi.js", "loadCalendar")
fn do_load_calendar_ffi() -> Dynamic

// External function that clears any existing calendar elements and re-initializes calendar
@external(javascript, "./calendar_ffi.js", "initCalendarWithAppEntrypoint")
fn do_initialize_calendar_app() -> Dynamic

// Add a function to handle calendar system change
fn change_calendar_system_ffi(
  system_type: CalendarSystemType,
) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    let system_str = case system_type {
      Gregorian -> "gregorian"
      Mayan -> "mayan"
      Julian -> "julian"
      Hebrew -> "hebrew"
      Islamic -> "islamic"
      Persian -> "persian"
    }

    let _ = do_change_calendar_system_ffi(system_str)
    dispatch(Initialized)
  })
}

// Add the FFI function for calendar system change
@external(javascript, "./calendar_ffi.js", "setCalendarSystem")
fn do_change_calendar_system_ffi(system: String) -> Dynamic

// Main function to export
pub fn main() {
  io.println("Calendar module main function called")

  // Initialize the app
  let #(model, effect) = init(Nil)

  // Create the Lustre app
  let app = lustre.application(fn(_) { #(model, effect) }, update, view)

  // Start the app in the calendar-root element
  let _ = lustre.start(app, "#calendar-root", Nil)
  io.println("Calendar application started")
  Nil
}

// External function to check if direct calendar root element exists
@external(javascript, "./calendar_ffi.js", "getDirectCalendarRoot")
fn get_direct_calendar_root() -> Bool

// External function to check if DOM is ready and run initialization function
@external(javascript, "./calendar_ffi.js", "checkReady")
fn do_check_ready_ffi(callback: fn() -> Nil) -> Dynamic

// External function to check if calendar root element exists
@external(javascript, "./calendar_ffi.js", "getCalendarRoot")
fn do_get_calendar_root_ffi() -> Bool

// External function to create a calendar root element if needed
@external(javascript, "./calendar_ffi.js", "createCalendarRoot")
fn do_create_calendar_root_ffi() -> Dynamic

// Type definition for FFI interop
pub type Dynamic
