import components/nav
import events/events
import gleam/dynamic
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import landing
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Route {
  Home
  Events
  EventDetails(String)
  EventsShare
  NotFound
  Findry
  DivvyQueue
  BizPay
  Projects
  Login
  Signup
}

pub type Msg {
  NavMsg(nav.Msg)
  EventsMsg(events.Msg)
  LandingMsg(landing.Msg)
  Navigate(String)
}

pub type Model {
  Model(route: Route, nav_open: Bool, events_model: events.Model)
}

fn parse_route(path: String) -> Route {
  io.debug("Parsing route: " <> path)
  let route = case path {
    "/" -> Home
    "/events" -> Events
    "/events/share" -> EventsShare
    "/findry" -> Findry
    "/divvyqueue" -> DivvyQueue
    "/bizpay" -> BizPay
    "/projects" -> Projects
    "/login" -> Login
    "/signup" -> Signup
    _ -> {
      case string.starts_with(path, "/events/") {
        True -> {
          let event_id = string.slice(path, 8, string.length(path))
          EventDetails(event_id)
        }
        False -> NotFound
      }
    }
  }
  io.debug("Route parsed as: " <> string.inspect(route))
  route
}

@external(javascript, "./app_ffi.js", "init")
fn ffi_init() -> Bool

@external(javascript, "./app_ffi.js", "getWindowLocation")
fn get_window_location() -> String

@external(javascript, "./app_ffi.js", "setupNavigationListener")
fn setup_navigation_listener(callback: fn(String) -> Bool) -> Bool

@external(javascript, "./app_ffi.js", "setupCustomEventListener")
fn setup_custom_event_listener(callback: fn(String) -> Bool) -> Bool

@external(javascript, "./app_ffi.js", "navigate")
fn ffi_navigate(path: String) -> Nil

pub fn init(_: Nil) -> #(Model, effect.Effect(Msg)) {
  let #(events_model, events_effect) = events.init(Nil)

  // Get the current path from the window location
  let current_path = get_window_location()
  io.debug("Initial path: " <> current_path)
  let initial_route = parse_route(current_path)

  let model =
    Model(route: initial_route, nav_open: False, events_model: events_model)

  let mapped_effect = effect.map(events_effect, EventsMsg)

  // Initialize FFI
  let _ = ffi_init()

  // Create a navigation callback function
  let navigation_callback = fn(path) {
    // This will be called when a navigation event occurs
    io.debug("Navigation event received for path: " <> path)
    // We need to dispatch a message to the Lustre runtime
    let _ = lustre.dispatch(Navigate(path))
    io.debug("Dispatched Navigate message for path: " <> path)
    True
  }

  // Set up a listener for navigation events
  let _ = setup_navigation_listener(navigation_callback)

  // Also set up the fallback custom event listener
  let _ = setup_custom_event_listener(navigation_callback)

  #(model, mapped_effect)
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> #(
          Model(..model, nav_open: !model.nav_open),
          effect.none(),
        )
      }
    }

    LandingMsg(landing_msg) -> {
      case landing_msg {
        landing.NavigateTo(path) -> {
          io.debug("LandingMsg NavigateTo: " <> path)
          // Use the FFI navigate function to ensure proper navigation
          let _ = ffi_navigate(path)
          let new_route = parse_route(path)
          io.debug(
            "LandingMsg: Updating model with new route: "
            <> string.inspect(new_route),
          )
          #(Model(..model, route: new_route), effect.none())
        }
      }
    }

    EventsMsg(events_msg) -> {
      let #(new_events_model, events_effect) =
        events.update(model.events_model, events_msg)
      let mapped_effect = effect.map(events_effect, EventsMsg)

      case events_msg {
        events.Navigate(path) -> {
          io.debug("EventsMsg Navigate: " <> path)
          // Use the FFI navigate function to ensure proper navigation
          let _ = ffi_navigate(path)
          let new_route = parse_route(path)
          io.debug(
            "EventsMsg: Updating model with new route: "
            <> string.inspect(new_route),
          )
          #(
            Model(..model, route: new_route, events_model: new_events_model),
            mapped_effect,
          )
        }
        _ -> #(Model(..model, events_model: new_events_model), mapped_effect)
      }
    }

    Navigate(path) -> {
      io.debug("Navigate message received: " <> path)
      let new_route = parse_route(path)
      io.debug("Updating model with new route: " <> string.inspect(new_route))

      // Force a re-render by creating a new model
      let updated_model =
        Model(
          route: new_route,
          nav_open: model.nav_open,
          events_model: model.events_model,
        )
      io.debug(
        "Created new model with route: " <> string.inspect(updated_model.route),
      )

      #(updated_model, effect.none())
    }
  }
}

pub fn view(model: Model) -> Element(Msg) {
  io.debug("Rendering view for route: " <> string.inspect(model.route))
  html.div([attribute.class("app-container")], [
    element.map(nav.view(), NavMsg),
    html.main([attribute.class("main-content")], [
      case model.route {
        Home -> {
          io.debug("Rendering Home view")
          element.map(landing.view(landing.Model), LandingMsg)
        }
        Events -> {
          io.debug("Rendering Events view")
          element.map(events.view(model.events_model), EventsMsg)
        }
        EventDetails(event_id) -> {
          io.debug("Rendering EventDetails view for: " <> event_id)
          element.map(events.view(model.events_model), EventsMsg)
        }
        EventsShare -> {
          io.debug("Rendering EventsShare view")
          element.map(events.view(model.events_model), EventsMsg)
        }
        Findry -> {
          io.debug("Rendering Findry view")
          view_placeholder("Findry")
        }
        DivvyQueue -> {
          io.debug("Rendering DivvyQueue view")
          view_placeholder("DivvyQueue")
        }
        BizPay -> {
          io.debug("Rendering BizPay view")
          view_placeholder("BizPay")
        }
        Projects -> {
          io.debug("Rendering Projects view")
          view_placeholder("Projects")
        }
        Login -> {
          io.debug("Rendering Login view")
          view_placeholder("Login")
        }
        Signup -> {
          io.debug("Rendering Signup view")
          view_placeholder("Signup")
        }
        NotFound -> {
          io.debug("Rendering NotFound view")
          view_not_found()
        }
      },
    ]),
  ])
}

fn view_placeholder(name: String) -> Element(Msg) {
  html.div([attribute.class("placeholder-page")], [
    html.h1([], [html.text(name)]),
    html.p([], [html.text("This page is under construction.")]),
    html.a([attribute.href("/")], [html.text("Return to Home")]),
  ])
}

fn view_not_found() -> Element(Msg) {
  html.div([attribute.class("not-found")], [
    html.h1([], [html.text("404 - Page Not Found")]),
    html.p([], [html.text("The page you are looking for does not exist.")]),
    html.a([attribute.href("/")], [html.text("Return to Home")]),
  ])
}

pub fn main() {
  // Create the Lustre application
  let app = lustre.application(init, update, view)

  // Start the application
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
