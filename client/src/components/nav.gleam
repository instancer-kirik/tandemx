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
        // Task Management
        html.a([attribute.href("/todos")], [
          html.text("Tasks"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/todos")], [html.text("Todo List")]),
            html.a([attribute.href("/partner-progress")], [
              html.text("Partner Progress"),
            ]),
          ]),
        ]),
        // Financial Management
        html.a([attribute.href("/finance")], [
          html.text("Finance"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/banking")], [html.text("Banking")]),
            html.a([attribute.href("/cards")], [html.text("Cards")]),
            html.a([attribute.href("/currency")], [html.text("Currency")]),
            html.a([attribute.href("/bills")], [html.text("Bills")]),
            html.a([attribute.href("/payroll")], [html.text("Payroll")]),
            html.a([attribute.href("/tax")], [html.text("Tax")]),
            html.a([attribute.href("/ads")], [html.text("Ad Accounts")]),
          ]),
        ]),
        // Contract Management
        html.a([attribute.href("/divvyqueue")], [
          html.text("Contracts"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/divvyqueue")], [html.text("Queue")]),
            html.a([attribute.href("/divvyqueue/contracts")], [
              html.text("Agreements"),
            ]),
          ]),
        ]),
        // Events Management
        html.a([attribute.href("/events")], [
          html.text("Events"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/events")], [html.text("Discover")]),
            html.a([attribute.href("/events/share")], [
              html.text("Share Schedule"),
            ]),
            html.a([attribute.href("/events/calendar")], [html.text("Calendar")]),
          ]),
        ]),
        // Constructs System
        html.a([attribute.href("/constructs")], [
          html.text("Constructs"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/constructs/works")], [html.text("Works")]),
            html.a([attribute.href("/constructs/personas")], [
              html.text("Personas"),
            ]),
            html.a([attribute.href("/constructs/social")], [html.text("Social")]),
            html.a([attribute.href("/constructs/metrics")], [
              html.text("Metrics"),
            ]),
          ]),
        ]),
        // Analytics
        html.a([attribute.href("/chartspace")], [
          html.text("Analytics"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/chartspace/editor")], [html.text("Editor")]),
            html.a([attribute.href("/chartspace/viewer")], [html.text("Viewer")]),
          ]),
        ]),
        // Compliance
        html.a([attribute.href("/compliance")], [
          html.text("Compliance"),
          html.div([attribute.class("nav-sub-links")], [
            html.a([attribute.href("/compliance/audit")], [
              html.text("Audit Trail"),
            ]),
            html.a([attribute.href("/compliance/reports")], [
              html.text("Reports"),
            ]),
            html.a([attribute.href("/compliance/alerts")], [
              html.text("Regulatory Alerts"),
            ]),
            html.a([attribute.href("/compliance/tax")], [
              html.text("Tax Filings"),
            ]),
            html.a([attribute.href("/compliance/settings")], [
              html.text("Settings"),
            ]),
          ]),
        ]),
        // Settings
        html.a([attribute.href("/settings")], [html.text("Settings")]),
      ]),
    ]),
  ])
}
