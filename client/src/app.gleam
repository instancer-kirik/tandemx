import calendar
import components/nav
import events/events
import findry

import gleam/dynamic.{type Dynamic}

import gleam/int

import gleam/io

import gleam/option.{type Option, None, Some}

import gleam/result

import gleam/string

import landing

import lustre
import lustre/attribute.{class, id}
import lustre/effect
import lustre/element.{type Element}

import lustre/element/html.{div}

import lustre/event

import vendure_store

pub type Route {
  Home
  Events
  EventDetails(String)
  EventsShare
  NotFound
  Findry
  DivvyQueue
  DivvyQueue2
  Projects
  About
  Calendar
  Login
  Signup
  VendureStore
}

pub type Msg {
  ToggleNav
  UpdateRoute(Route)
  EventsMsg(events.Msg)
  FindryMsg(findry.Msg)
  LandingMsg(landing.Msg)
  VendureStoreMsg(vendure_store.Msg)
  CalendarMsg(calendar.Msg)
  NoOp
}

pub type Model {
  Model(
    nav_open: Bool,
    route: Route,
    events_model: events.Model,
    findry_model: findry.Model,
    landing_model: landing.Model,
    vendure_store_model: vendure_store.Model,
    calendar_model: calendar.Model,
  )
}

fn parse_route(path: String) -> Route {
  io.debug("Parsing route: " <> path)
  let route = case path {
    "/about" -> About
    "/" -> Home
    "/events" -> Events
    "/events/share" -> EventsShare
    "/findry" -> Findry
    "/divvyqueue" -> DivvyQueue
    "/divvyqueue2" -> DivvyQueue2
    "/projects" -> Projects
    "/calendar" -> Calendar
    "/login" -> Login
    "/signup" -> Signup
    "/store" -> VendureStore
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

@external(javascript, "./calendar_ffi.js", "changeMonth")
fn do_change_month_ffi(year: Int, month: Int) -> Dynamic

pub fn init(_: Nil) -> #(Model, effect.Effect(Msg)) {
  let #(events_model, events_effect) = events.init(Nil)
  let #(findry_model, findry_effect) = findry.init()
  let #(landing_model, landing_effect) = landing.init(Nil)
  let #(vendure_store_model, vendure_store_effect) = vendure_store.init(Nil)
  let #(calendar_model, calendar_effect) = calendar.init(Nil)

  #(
    Model(
      nav_open: False,
      route: parse_route("/"),
      events_model: events_model,
      findry_model: findry_model,
      landing_model: landing_model,
      vendure_store_model: vendure_store_model,
      calendar_model: calendar_model,
    ),
    effect.batch([
      effect.map(events_effect, EventsMsg),
      effect.map(findry_effect, FindryMsg),
      effect.map(landing_effect, LandingMsg),
      effect.map(vendure_store_effect, VendureStoreMsg),
      effect.map(calendar_effect, CalendarMsg),
    ]),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    ToggleNav -> #(
      Model(..model, nav_open: model.nav_open == False),
      effect.none(),
    )
    UpdateRoute(route) -> {
      case route {
        Calendar -> #(Model(..model, route: route), effect.none())
        _ -> #(Model(..model, route: route), effect.none())
      }
    }
    EventsMsg(events_msg) -> {
      let #(events_model, events_effect) =
        events.update(model.events_model, events_msg)
      #(
        Model(..model, events_model: events_model),
        effect.map(events_effect, EventsMsg),
      )
    }
    FindryMsg(findry_msg) -> {
      let #(findry_model, findry_effect) =
        findry.update(model.findry_model, findry_msg)
      #(
        Model(..model, findry_model: findry_model),
        effect.map(findry_effect, FindryMsg),
      )
    }
    LandingMsg(landing_msg) -> {
      let #(landing_model, landing_effect) =
        landing.update(model.landing_model, landing_msg)
      #(
        Model(..model, landing_model: landing_model),
        effect.map(landing_effect, LandingMsg),
      )
    }
    VendureStoreMsg(vendure_store_msg) -> {
      let #(vendure_store_model, vendure_store_effect) =
        vendure_store.update(model.vendure_store_model, vendure_store_msg)
      #(
        Model(..model, vendure_store_model: vendure_store_model),
        effect.map(vendure_store_effect, VendureStoreMsg),
      )
    }
    CalendarMsg(calendar_msg) -> {
      let #(calendar_model, calendar_effect) =
        calendar.update(model.calendar_model, calendar_msg)
      #(
        Model(..model, calendar_model: calendar_model),
        effect.map(calendar_effect, CalendarMsg),
      )
    }
    NoOp -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  let container_class = case model.nav_open {
    True -> "nav-open"
    False -> ""
  }
  let main_content = case model.route {
    About -> view_about()
    Home -> {
      io.debug("Rendering Home view")
      element.map(landing.view_without_nav(model.landing_model), LandingMsg)
    }
    Events -> {
      io.debug("Rendering Events view")
      element.map(events.view(model.events_model), EventsMsg)
    }
    EventsShare -> {
      io.debug("Rendering Events Share view")
      element.map(events.view(model.events_model), EventsMsg)
    }
    EventDetails(event_id) -> {
      io.debug("Rendering Event Details view for event: " <> event_id)
      element.map(events.view(model.events_model), EventsMsg)
    }
    Findry -> {
      io.debug("Rendering Findry view")
      element.map(findry.view(model.findry_model), FindryMsg)
    }
    Calendar -> {
      io.debug("Rendering Calendar view")
      div([id("calendar-container"), class("calendar-container")], [
        element.map(calendar.view(model.calendar_model), CalendarMsg),
      ])
    }
    VendureStore -> {
      io.debug("Rendering Vendure Store view")
      element.map(
        vendure_store.view(model.vendure_store_model),
        VendureStoreMsg,
      )
    }
    DivvyQueue -> {
      io.debug("Rendering DivvyQueue view")
      view_placeholder("DivvyQueue")
    }
    DivvyQueue2 -> {
      io.debug("Rendering DivvyQueue2 view")
      view_placeholder("DivvyQueue2")
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
  }

  html.div([attribute.class(container_class)], [
    nav.view()
      |> element.map(fn(msg) {
        case msg {
          nav.ToggleNav -> ToggleNav
        }
      }),
    html.main([attribute.class("main-content")], [main_content]),
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

fn view_about() -> Element(Msg) {
  html.div([attribute.class("about-page")], [
    html.h1([], [html.text("About Us")]),
    html.p([], [html.text("This is the about page content.")]),
    html.a([attribute.href("/")], [html.text("Return to Home")]),
  ])
}

fn map_nav_msg(msg: nav.Msg) -> Msg {
  case msg {
    nav.ToggleNav -> ToggleNav
  }
}

pub fn main() {
  // Create the Lustre application
  let app = lustre.application(init, update, view)

  // Start the application
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
