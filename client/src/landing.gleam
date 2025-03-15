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
      let _ = navigate(path)
      #(model, effect.none())
    }
  }
}

@external(javascript, "./app_ffi.js", "navigate")
fn navigate(path: String) -> Nil

fn view_payment_section() -> Element(Msg) {
  html.div([class("payment-section")], [
    html.div([class("payment-content")], [
      html.h2([class("payment-title")], [html.text("Support/Sponsor")]),
      html.p([class("payment-subtitle")], [
        html.text(
          "Also I am taking the hunter exam on March 29th, and still have software and gadgets to prepare. ",
        ),
        html.a([attribute.href("https://thehuntersassociation.com")], [
          html.text("https://thehuntersassociation.com"),
        ]),
      ]),
      html.div([class("payment-options")], [
        html.div([class("payment-option cashapp")], [
          html.h3([], [html.text("Quick Support via Cash App")]),
          html.a(
            [
              class("cashapp-button"),
              attribute.href("https://cash.app/$Instancer"),
              attribute.target("_blank"),
            ],
            [
              html.span([class("cashapp-icon")], [html.text("")]),
              html.text("Support via $Instancer"),
            ],
          ),
        ]),
        html.div([class("payment-option contact")], [
          html.h3([], [html.text("Get in Touch")]),
          html.p([], [
            html.text("For business inquiries: "),
            html.a(
              [
                class("email-link"),
                attribute.href("mailto:kirik@instance.select"),
              ],
              [html.text("kirik@instance.select")],
            ),
            html.text(" or "),
            html.a(
              [
                attribute.href(
                  "https://bsky.app/profile/instancer-kirik.bsky.social",
                ),
              ],
              [html.text("instancer-kirik.bsky.social")],
            ),
            html.text(" or "),
            html.a([attribute.href("https://x.com/instance_select")], [
              html.text("https://x.com/instance_select"),
            ]),
            html.text(" or "),
            html.a(
              [attribute.href("https://www.tiktok.com/@ultimate.starter.kit")],
              [html.text("https://www.tiktok.com/@ultimate.starter.kit")],
            ),
          ]),
        ]),
      ]),
    ]),
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("landing-page")], [
    view_nav(),
    view_hero(),
    view_products(),
    view_features(),
    view_payment_section(),
    view_footer(),
  ])
}

fn view_nav() -> Element(Msg) {
  html.nav([class("main-nav")], [
    html.div([class("nav-content")], [
      html.a([class("logo"), attribute.href("/")], [html.text("TandemX")]),
      html.div([class("nav-links")], [
        html.a([class("nav-link"), attribute.href("/findry")], [
          html.text("Findry"),
        ]),
        html.a([class("nav-link"), attribute.href("/divvyqueue")], [
          html.text("DivvyQueue"),
        ]),
        html.a([class("nav-link"), attribute.href("/bizpay")], [
          html.text("BizPay"),
        ]),
        html.a([class("nav-link"), attribute.href("/projects")], [
          html.text("Projects"),
        ]),
      ]),
      html.div([class("nav-actions")], [
        html.a([class("nav-btn login"), attribute.href("/login")], [
          html.text("Log In(NOT IMPLEMENTED YET)"),
        ]),
        html.a([class("nav-btn signup"), attribute.href("/signup")], [
          html.text("Sign Up(NOT IMPLEMENTED YET)"),
        ]),
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
          "From development tools to creative spaces, instance.select's tandemx provides a comprehensive suite of solutions. Connect, collaborate, and grow with our integrated platform ecosystem.",
        ),
      ]),
      html.div([class("hero-cta")], [
        html.a([class("cta-btn primary"), attribute.href("/signup")], [
          html.text("Get Started"),
        ]),
        html.a([class("cta-btn secondary"), attribute.href("/projects")], [
          html.text("Explore Projects"),
        ]),
      ]),
    ]),
  ])
}

fn view_products() -> Element(Msg) {
  html.div([class("products-section")], [
    html.div([class("section-header")], [
      html.h2([class("section-title")], [html.text("Featured Projects")]),
      html.a([class("view-all-btn"), attribute.href("/projects")], [
        html.text(
          "View All Projects →(also I don't think the express interest buttons work yet - no db)",
        ),
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
      html.a([class("product-link"), attribute.href(path)], [
        html.text("Learn More"),
      ]),
      html.a([class("interest-btn"), attribute.href(path <> "/interest")], [
        html.text("Express Interest"),
      ]),
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
          #("Calendar", "/calendar"),
          #("Projects", "/projects"),
          #("About", "/about"),
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
          html.a([class("footer-link"), attribute.href(path)], [html.text(text)]),
        ])
      }),
    ),
  ])
}
