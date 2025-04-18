import gleam/dynamic
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute.{class, style}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Event {
  Event(
    id: String,
    title: String,
    description: String,
    start_date: String,
    end_date: String,
    location: String,
    venue: String,
    city: String,
    state: String,
    country: String,
    artist_count: Int,
    attendee_count: Int,
    image_url: String,
    ticket_prices: List(TicketPrice),
    featured_artists: List(String),
    schedule: List(TimeSlot),
  )
}

pub type TicketPrice {
  TicketPrice(name: String, price: Float, description: Option(String))
}

pub type TimeSlot {
  TimeSlot(
    date: String,
    start_time: String,
    end_time: String,
    description: Option(String),
  )
}

pub type SharedSchedule {
  SharedSchedule(
    id: String,
    owner_id: String,
    owner_name: String,
    start_date: String,
    end_date: String,
    events: List(Event),
    message: Option(String),
    visibility: ScheduleVisibility,
  )
}

pub type ScheduleVisibility {
  ShowDetails
  ShowBusyFree
  ShowTitlesOnly
}

pub type Msg {
  NoOp
  Navigate(String)
  EventsUpdated(List(Event))
  EventSelected(String)
  ShareEvent(String)
  ShareSchedule(SharedSchedule)
  ScheduleShared(String)
  FilterChanged(EventFilter)
  MapViewToggled
}

pub type Model {
  Model(
    route: String,
    events: List(Event),
    selected_event: Option(Event),
    shared_schedules: List(SharedSchedule),
    ui_state: EventUiState,
  )
}

pub type EventUiState {
  EventUiState(
    current_filter: EventFilter,
    show_map_view: Bool,
    selected_date_range: Option(#(String, String)),
    sharing_schedule: Bool,
  )
}

pub type EventFilter {
  EventFilter(
    date_range: Option(#(String, String)),
    location: Option(String),
    price_range: Option(#(Float, Float)),
    artist_count: Option(#(Int, Int)),
    attendee_count: Option(#(Int, Int)),
  )
}

pub fn init(_: Nil) -> #(Model, effect.Effect(Msg)) {
  let model =
    Model(
      route: "/events",
      events: [],
      selected_event: None,
      shared_schedules: [],
      ui_state: EventUiState(
        current_filter: EventFilter(
          date_range: None,
          location: None,
          price_range: None,
          artist_count: None,
          attendee_count: None,
        ),
        show_map_view: False,
        selected_date_range: None,
        sharing_schedule: False,
      ),
    )

  #(model, effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())

    Navigate(route) -> #(Model(..model, route: route), effect.none())

    EventsUpdated(events) -> #(Model(..model, events: events), effect.none())

    EventSelected(event_id) -> {
      let selected_event =
        list.find(model.events, fn(event) { event.id == event_id })
        |> option.from_result
      #(Model(..model, selected_event: selected_event), effect.none())
    }

    ShareEvent(event_id) -> {
      // TODO: Implement event sharing logic
      #(model, effect.none())
    }

    ShareSchedule(schedule) -> {
      let new_schedules = [schedule, ..model.shared_schedules]
      #(Model(..model, shared_schedules: new_schedules), effect.none())
    }

    ScheduleShared(schedule_id) -> {
      // TODO: Implement schedule sharing confirmation
      #(model, effect.none())
    }

    FilterChanged(filter) -> {
      let new_ui_state = EventUiState(..model.ui_state, current_filter: filter)
      #(Model(..model, ui_state: new_ui_state), effect.none())
    }

    MapViewToggled -> {
      let new_ui_state =
        EventUiState(
          ..model.ui_state,
          show_map_view: model.ui_state.show_map_view == False,
        )
      #(Model(..model, ui_state: new_ui_state), effect.none())
    }
  }
}

fn view_event_card(event: Event) -> Element(Msg) {
  html.div([class("event-card")], [
    html.img([
      attribute.src(event.image_url),
      attribute.alt(event.title),
      class("event-image"),
    ]),
    html.div([class("event-info")], [
      html.h3([], [html.text(event.title)]),
      html.p([], [
        html.text(
          event.start_date
          <> " - "
          <> event.end_date
          <> " · "
          <> event.venue
          <> ", "
          <> event.city
          <> ", "
          <> event.state,
        ),
      ]),
      html.p([], [
        html.text(
          int.to_string(event.artist_count)
          <> " artists · "
          <> int.to_string(event.attendee_count)
          <> "+ attendees",
        ),
      ]),
      html.div([class("event-actions")], [
        html.button(
          [
            class("view-details"),
            event.on("click", fn(_) { Ok(EventSelected(event.id)) }),
          ],
          [html.text("View Details")],
        ),
        html.button(
          [
            class("share-event"),
            event.on("click", fn(_) { Ok(ShareEvent(event.id)) }),
          ],
          [html.text("Share")],
        ),
      ]),
    ]),
  ])
}

fn view_event_details(event: Event) -> Element(Msg) {
  html.div([class("event-details")], [
    html.div([class("event-header")], [
      html.img([
        attribute.src(event.image_url),
        attribute.alt(event.title),
        class("event-image"),
      ]),
      html.div([class("event-title")], [
        html.h1([], [html.text(event.title)]),
        html.p([], [
          html.text(
            event.start_date
            <> " - "
            <> event.end_date
            <> " · "
            <> event.venue
            <> ", "
            <> event.city
            <> ", "
            <> event.state,
          ),
        ]),
      ]),
    ]),
    html.div([class("event-content")], [
      html.section([class("description")], [
        html.h2([], [html.text("Description")]),
        html.p([], [html.text(event.description)]),
      ]),
      html.section([class("schedule")], [
        html.h2([], [html.text("Schedule")]),
        html.ul(
          [],
          list.map(event.schedule, fn(slot) {
            html.li([], [
              html.text(
                slot.date <> ": " <> slot.start_time <> " - " <> slot.end_time,
              ),
            ])
          }),
        ),
      ]),
      html.section([class("tickets")], [
        html.h2([], [html.text("Tickets")]),
        html.ul(
          [],
          list.map(event.ticket_prices, fn(price) {
            html.li([], [
              html.text(price.name <> ": $" <> float.to_string(price.price)),
            ])
          }),
        ),
      ]),
      html.section([class("artists")], [
        html.h2([], [html.text("Featured Artists")]),
        html.ul(
          [],
          list.map(event.featured_artists, fn(artist) {
            html.li([], [html.text(artist)])
          }),
        ),
      ]),
      html.div([class("event-actions")], [
        html.button([class("buy-tickets")], [html.text("Buy Tickets")]),
        html.button(
          [
            class("share-event"),
            event.on("click", fn(_) { Ok(ShareEvent(event.id)) }),
          ],
          [html.text("Share Event")],
        ),
      ]),
    ]),
  ])
}

fn view_schedule_sharing(model: Model) -> Element(Msg) {
  html.div([class("schedule-sharing")], [
    html.h2([], [html.text("Share Schedule")]),
    html.div([class("date-range")], [
      html.label([], [html.text("Select Date Range:")]),
      html.input([
        attribute.type_("date"),
        attribute.name("start_date"),
        event.on("change", fn(_) { Ok(NoOp) }),
      ]),
      html.input([
        attribute.type_("date"),
        attribute.name("end_date"),
        event.on("change", fn(_) { Ok(NoOp) }),
      ]),
    ]),
    html.div([class("events-selection")], [
      html.h3([], [html.text("Select Events to Share")]),
      html.div(
        [class("events-list")],
        list.map(model.events, fn(event) {
          html.div([class("event-checkbox")], [
            html.input([
              attribute.type_("checkbox"),
              attribute.id(event.id),
              event.on("change", fn(_) { Ok(NoOp) }),
            ]),
            html.label([attribute.for(event.id)], [
              html.text(
                event.title
                <> " - "
                <> event.start_date
                <> " to "
                <> event.end_date,
              ),
            ]),
          ])
        }),
      ),
    ]),
    html.div([class("visibility-options")], [
      html.h3([], [html.text("Visibility Options")]),
      html.div([class("radio-group")], [
        html.div([class("radio")], [
          html.input([
            attribute.type_("radio"),
            attribute.name("visibility"),
            attribute.value("details"),
            attribute.checked(True),
            event.on("change", fn(_) { Ok(NoOp) }),
          ]),
          html.label([], [html.text("Show event details")]),
        ]),
        html.div([class("radio")], [
          html.input([
            attribute.type_("radio"),
            attribute.name("visibility"),
            attribute.value("busy"),
            event.on("change", fn(_) { Ok(NoOp) }),
          ]),
          html.label([], [html.text("Show busy/free status only")]),
        ]),
        html.div([class("radio")], [
          html.input([
            attribute.type_("radio"),
            attribute.name("visibility"),
            attribute.value("titles"),
            event.on("change", fn(_) { Ok(NoOp) }),
          ]),
          html.label([], [html.text("Show event titles only")]),
        ]),
      ]),
    ]),
    html.div([class("message")], [
      html.label([], [html.text("Add Message:")]),
      html.textarea([event.on("input", fn(_) { Ok(NoOp) })], ""),
    ]),
    html.div([class("actions")], [
      html.button(
        [class("cancel"), event.on("click", fn(_) { Ok(Navigate("/events")) })],
        [html.text("Cancel")],
      ),
      html.button([class("share"), event.on("click", fn(_) { Ok(NoOp) })], [
        html.text("Share Schedule"),
      ]),
    ]),
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  case model.route {
    "/events" -> {
      html.div([class("events-page")], [
        html.div([class("events-header")], [
          html.h1([], [html.text("Events Near You")]),
          html.div([class("view-controls")], [
            html.button(
              [class("filter-button"), event.on("click", fn(_) { Ok(NoOp) })],
              [html.text("Filter")],
            ),
            html.button(
              [
                class("map-toggle"),
                event.on("click", fn(_) { Ok(MapViewToggled) }),
              ],
              [html.text("Map View")],
            ),
          ]),
        ]),
        html.div(
          [class("events-grid")],
          list.map(model.events, view_event_card),
        ),
      ])
    }
    "/events/" <> event_id -> {
      case model.selected_event {
        Some(event) -> view_event_details(event)
        None -> html.div([], [html.text("Event not found")])
      }
    }
    "/events/share" -> view_schedule_sharing(model)
    _ -> html.div([], [html.text("Page not found")])
  }
}

pub fn main() {
  // Create the Lustre application
  let app = lustre.application(init, update, view)

  // Start the application
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
