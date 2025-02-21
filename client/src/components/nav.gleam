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
        html.a([attribute.href("/todos")], [html.text("Todos")]),
        html.a([attribute.href("/divvyqueue")], [
          html.text("DivvyQueue"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/divvyqueue/contracts")], [
              html.text("Contracts"),
            ]),
          ]),
        ]),
        html.a([attribute.href("/cards")], [html.text("Payment Cards")]),
      ]),
    ]),
  ])
}
