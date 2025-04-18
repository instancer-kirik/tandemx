import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Msg {
  ToggleNav
}

pub fn view() -> Element(Msg) {
  html.div([attribute.class("nav-container")], [
    html.button([attribute.class("nav-toggle"), event.on_click(ToggleNav)], [
      html.text("☰"),
    ]),
    html.nav([attribute.class("navbar")], [
      html.div([attribute.class("nav-brand")], [
        html.a([attribute.href("/")], [html.text("TandemX")]),
      ]),
      html.div([attribute.class("nav-links")], [
        // Core
        html.a([attribute.href("/")], [html.text("Home")]),
        // Programming & Tools
        html.a([attribute.href("/tools")], [
          html.text("Dev Tools"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/tools/sledge")], [html.text("Sledge")]),
            html.a([attribute.href("/tools/explorinator")], [
              html.text("Explorinator"),
            ]),
            html.a([attribute.href("/tools/clipdirstructor")], [
              html.text("Clipdirstructor"),
            ]),
            html.a([attribute.href("/tools/clipdirstructer")], [
              html.text("Clipdirstructer"),
            ]),
            html.a([attribute.href("/tools/varchiver")], [
              html.text("Varchiver"),
            ]),
          ]),
        ]),
        // Elixir Applications
        html.a([attribute.href("/elixir-apps")], [
          html.text("Elixir Apps"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/tools/deepscape")], [
              html.text("Deepscape"),
            ]),
            html.a([attribute.href("/tools/pause-effect")], [
              html.text("Pause || Effect"),
            ]),
            html.a([attribute.href("/tools/resolvinator")], [
              html.text("Resolvinator"),
            ]),
            html.a([attribute.href("/tools/fonce")], [html.text("Fonce")]),
            html.a([attribute.href("/tools/seek")], [html.text("Seek")]),
            html.a([attribute.href("/tools/veix")], [html.text("Veix")]),
          ]),
        ]),
        // Creative Tools
        html.a([attribute.href("/creative")], [
          html.text("Creative"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/tools/bonify")], [html.text("Bonify")]),
            html.a([attribute.href("/tools/mediata")], [html.text("Mediata")]),
            html.a([attribute.href("https://findry.lovable.app")], [
              html.text("Findry"),
            ]),
          ]),
        ]),
        // Other Tools
        html.a([attribute.href("/projects")], [
          html.text("Other Tools"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/tools/combocounter")], [
              html.text("Combocounter"),
            ]),
            html.a([attribute.href("/tools/cround")], [html.text("Cround")]),
            html.a([attribute.href("https://divvyqueue.lovable.app")], [
              html.text("DivvyQueue"),
            ]),
          ]),
        ]),
        // Calendar
        html.a([attribute.href("/calendar")], [html.text("Calendar")]),
        // Projects
        html.a([attribute.href("/projects")], [html.text("Projects")]),
        // Settings
        html.a([attribute.href("/settings")], [html.text("Settings")]),
        // About
        html.a([attribute.href("/about"), attribute.class("nav-link")], [
          html.text("About"),
        ]),
      ]),
    ]),
  ])
}
