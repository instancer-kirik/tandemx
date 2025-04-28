import gleam/io
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// Define the message types our app can handle
pub type Msg {
  NoOp
  Navigate(String)
}

// Define our app's state model
pub type Model {
  Model(page: String, title: String)
}

// Initialize the app with default state
pub fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(page: "home", title: "instance.select"), effect.none())
}

// Handle messages and update the model accordingly
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
    Navigate(path) -> {
      let new_model = Model(..model, page: path)
      #(new_model, effect.none())
    }
  }
}

// Render the app UI
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app-container")], [
    view_header(model),
    view_main_content(model),
  ])
}

// Helper function to render the header
fn view_header(model: Model) -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text(model.title)]),
    html.nav([attribute.class("main-nav")], [
      html.a([attribute.href("/"), event.on_click(Navigate("home"))], [
        html.text("Home"),
      ]),
      html.a([attribute.href("/tools"), event.on_click(Navigate("tools"))], [
        html.text("Tools"),
      ]),
      html.a([attribute.href("/about"), event.on_click(Navigate("about"))], [
        html.text("About"),
      ]),
    ]),
  ])
}

// Helper function to render the main content
fn view_main_content(model: Model) -> Element(Msg) {
  case model.page {
    "home" -> view_home_page()
    "tools" -> view_tools_page()
    "about" -> view_about_page()
    _ -> view_home_page()
  }
}

// Home page content
fn view_home_page() -> Element(Msg) {
  html.div([attribute.class("page home-page")], [
    html.h2([], [html.text("Welcome to instance.select")]),
    html.p([], [
      html.text(
        "A collection of specialized development and creative tools organized by language and purpose.",
      ),
    ]),
  ])
}

// Tools page content
fn view_tools_page() -> Element(Msg) {
  html.div([attribute.class("page tools-page")], [
    html.h2([], [html.text("Developer Tools")]),
    html.p([], [html.text("Browse our collection of development tools.")]),
  ])
}

// About page content
fn view_about_page() -> Element(Msg) {
  html.div([attribute.class("page about-page")], [
    html.h2([], [html.text("About instance.select")]),
    html.p([], [
      html.text(
        "instance.select provides specialized tools for developers and creative professionals.",
      ),
    ]),
  ])
}
