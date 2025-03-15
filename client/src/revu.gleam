import components/nav
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import revu/curl_tool

pub type Model {
  Model(nav_open: Bool, curl_tool: curl_tool.Model)
}

pub type Msg {
  NavMsg(nav.Msg)
  CurlToolMsg(curl_tool.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let #(curl_tool_model, curl_tool_effect) = curl_tool.init(Nil)
  #(
    Model(nav_open: False, curl_tool: curl_tool_model),
    effect.map(curl_tool_effect, CurlToolMsg),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> #(
          Model(..model, nav_open: !model.nav_open),
          effect.none(),
        )
      }
    }

    CurlToolMsg(curl_msg) -> {
      let #(curl_model, curl_effect) =
        curl_tool.update(model.curl_tool, curl_msg)
      #(
        Model(..model, curl_tool: curl_model),
        effect.map(curl_effect, CurlToolMsg),
      )
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [
      element.map(nav.view(), NavMsg),
      html.main([attribute.class("revu-app")], [
        html.header([attribute.class("app-header")], [
          html.h1([], [html.text("REVU API Testing")]),
          html.p([attribute.class("header-subtitle")], [
            html.text("Test and explore the REVU API endpoints"),
          ]),
        ]),
        element.map(curl_tool.view(model.curl_tool), CurlToolMsg),
      ]),
    ],
  )
}
