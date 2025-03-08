import gleam/dynamic
import gleam/list
import gleam/result
import lustre
import lustre/attribute.{type Attribute, class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Msg {
  NavigateTo(String)
}

pub type Model {
  Model
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model, effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(path) -> {
      let _ = set_window_location(path)
      #(model, effect.none())
    }
  }
}

@external(javascript, "./landing_ffi.js", "setWindowLocation")
fn set_window_location(path: String) -> Nil

fn view(_model: Model) -> Element(Msg) {
  html.div([class("landing-page")], [
    view_nav(),
    view_hero(),
    view_products(),
    view_features(),
    view_footer(),
  ])
}

fn view_nav() -> Element(Msg) {
  html.nav([class("main-nav")], [
    html.div([class("nav-content")], [
      html.a([class("logo")], [html.text("TandemX")]),
      html.div([class("nav-links")], [
        html.a([class("nav-link"), event.on_click(NavigateTo("/findry"))], [
          html.text("Findry"),
        ]),
        html.a([class("nav-link"), event.on_click(NavigateTo("/divvyqueue"))], [
          html.text("DivvyQueue"),
        ]),
        html.a([class("nav-link"), event.on_click(NavigateTo("/bizpay"))], [
          html.text("BizPay"),
        ]),
        html.a([class("nav-link"), event.on_click(NavigateTo("/projects"))], [
          html.text("Projects"),
        ]),
      ]),
      html.div([class("nav-actions")], [
        html.a([class("nav-btn login"), event.on_click(NavigateTo("/login"))], [
          html.text("Log In"),
        ]),
        html.a(
          [class("nav-btn signup"), event.on_click(NavigateTo("/signup"))],
          [html.text("Sign Up")],
        ),
      ]),
    ]),
  ])
}

fn view_hero() -> Element(Msg) {
  html.div([class("hero-section")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [
        html.text(
          "Empowered Multiparty Contact, Contract, Business Operations and Creative Collaborationator",
        ),
      ]),
      html.p([class("hero-subtitle")], [
        html.text(
          "From development tools to creative spaces, TandemX provides a comprehensive suite of solutions. Connect, collaborate, and grow with our integrated platform ecosystem.",
        ),
      ]),
      html.div([class("hero-cta")], [
        html.button(
          [class("cta-btn primary"), event.on_click(NavigateTo("/signup"))],
          [html.text("Get Started")],
        ),
        html.button(
          [class("cta-btn secondary"), event.on_click(NavigateTo("/projects"))],
          [html.text("Explore Projects")],
        ),
      ]),
    ]),
  ])
}

fn view_products() -> Element(Msg) {
  html.div([class("products-section")], [
    html.div([class("section-header")], [
      html.h2([class("section-title")], [html.text("Featured Projects")]),
      html.a([class("view-all-btn"), event.on_click(NavigateTo("/projects"))], [
        html.text("View All Projects →"),
      ]),
    ]),
    html.div([class("products-grid")], [
      view_product_card(
        "Sledge",
        "🌐",
        "A web browser made by developers, for developers, with advanced privacy features and developer tools",
        "/sledge",
        [
          "Privacy-focused architecture with sandboxing",
          "QWebEngine with Chromium support",
          "Group-based memory-state tab management",
          "Anti-flashbang and force dark mode",
          "V3 extensions and Manifest V2 support",
        ],
      ),
      view_product_card(
        "Findry",
        "🎨",
        "Art and resource discovery platform connecting creative spaces with artists",
        "/findry",
        [
          "Artist/Offerer Discovery", "Space/Equipment marketplace",
          "Interactive virtual space tours", "Event scheduling and organizing",
          "Brand-managed events",
        ],
      ),
      view_product_card(
        "DivvyQueue",
        "📊",
        "Corporeal-Incorporation agreement management platform",
        "/divvyqueue",
        [
          "Multiparty agreements with document support",
          "Timeline tracking and breach handling", "Smart contract integration",
          "Cross-discipline project tools", "Real-time collaboration",
        ],
      ),
    ]),
  ])
}

fn view_product_card(
  name: String,
  emoji: String,
  description: String,
  path: String,
  features: List(String),
) -> Element(Msg) {
  html.div([class("product-card")], [
    html.div([class("product-header")], [
      html.span([class("product-emoji")], [html.text(emoji)]),
      html.h3([class("product-name")], [html.text(name)]),
    ]),
    html.p([class("product-description")], [html.text(description)]),
    html.ul(
      [class("product-features")],
      list.map(features, fn(feature) {
        html.li([], [
          html.span([class("feature-check")], [html.text("✓")]),
          html.text(feature),
        ])
      }),
    ),
    html.div([class("product-actions")], [
      html.a([class("product-link"), event.on_click(NavigateTo(path))], [
        html.text("Learn More"),
      ]),
      html.button(
        [class("interest-btn"), event.on_click(NavigateTo(path <> "/interest"))],
        [html.text("Express Interest")],
      ),
    ]),
  ])
}

fn view_features() -> Element(Msg) {
  html.div([class("features-section")], [
    html.h2([class("section-title")], [html.text("Why Choose TandemX")]),
    html.div([class("features-grid")], [
      view_feature(
        "🛠️",
        "Developer-First",
        "Built by developers for developers, with powerful tools and environments",
      ),
      view_feature(
        "🎨",
        "Creative Spaces",
        "Connect with the perfect spaces and resources for your creative projects",
      ),
      view_feature(
        "🤝",
        "Smart Collaboration",
        "Advanced tools for multiparty agreements and project coordination",
      ),
      view_feature(
        "🚀",
        "Scalable Solutions",
        "From development tools to business operations, grow with our ecosystem",
      ),
    ]),
  ])
}

fn view_feature(
  emoji: String,
  title: String,
  description: String,
) -> Element(Msg) {
  html.div([class("feature-card")], [
    html.span([class("feature-emoji")], [html.text(emoji)]),
    html.h3([class("feature-title")], [html.text(title)]),
    html.p([class("feature-description")], [html.text(description)]),
  ])
}

fn view_footer() -> Element(Msg) {
  html.footer([class("main-footer")], [
    html.div([class("footer-content")], [
      html.div([class("footer-brand")], [
        html.h3([class("footer-logo")], [html.text("TandemX")]),
        html.p([class("footer-tagline")], [
          html.text("Building the future of creative collaboration"),
        ]),
      ]),
      html.div([class("footer-links")], [
        view_footer_column("Development", [
          #("Sledge", "/sledge"),
          #("D.d", "/ddew"),
          #("Shiny", "/shiny"),
        ]),
        view_footer_column("Creative", [
          #("Findry", "/findry"),
          #("DivvyQueue", "/divvyqueue"),
          #("ChartSpace", "/chartspace"),
        ]),
        view_footer_column("Business", [
          #("BizPay", "/bizpay"),
          #("CardCard", "/cards"),
          #("Cumpliers", "/compliance"),
        ]),
        view_footer_column("Resources", [
          #("Documentation", "/docs"),
          #("Support", "/support"),
          #("Status", "/status"),
        ]),
      ]),
    ]),
    html.div([class("footer-bottom")], [
      html.p([], [html.text("© 2024 TandemX. All rights reserved.")]),
    ]),
  ])
}

fn view_footer_column(
  title: String,
  links: List(#(String, String)),
) -> Element(Msg) {
  html.div([class("footer-column")], [
    html.h4([class("footer-column-title")], [html.text(title)]),
    html.ul(
      [class("footer-column-links")],
      list.map(links, fn(link) {
        let #(text, path) = link
        html.li([], [
          html.a([class("footer-link"), event.on_click(NavigateTo(path))], [
            html.text(text),
          ]),
        ])
      }),
    ),
  ])
}
