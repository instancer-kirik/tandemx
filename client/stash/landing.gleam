import gleam/dynamic
import gleam/float
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
  AddToCart(String)
  NavigateToVendure(String)
}

pub type Model {
  Model
}

pub fn init(_) -> #(Model, Effect(Msg)) {
  #(Model, effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(path) -> {
      let _ = navigate(path)
      #(model, effect.none())
    }
    AddToCart(product_id) -> {
      let _ = add_to_cart(product_id)
      #(model, effect.none())
    }
    NavigateToVendure(path) -> {
      let _ = navigate_to_vendure(path)
      #(model, effect.none())
    }
  }
}

@external(javascript, "./app_ffi.js", "navigate")
fn navigate(path: String) -> Nil

@external(javascript, "./app_ffi.js", "addToCart")
fn add_to_cart(product_id: String) -> Nil

@external(javascript, "./app_ffi.js", "navigateToVendure")
fn navigate_to_vendure(path: String) -> Nil

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
  html.div([class("landing-page dashboard-layout")], [
    view_nav(),
    html.div([class("dashboard-container")], [
      view_hero(),
      view_dashboard_modules(),
    ]),
    view_payment_section(),
    view_footer(),
  ])
}

// New function that renders the landing page without its own navigation
pub fn view_without_nav(model: Model) -> Element(Msg) {
  html.div([class("landing-page dashboard-layout")], [
    html.div([class("dashboard-container")], [
      view_hero(),
      view_dashboard_modules(),
    ]),
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
        html.a([class("nav-link"), attribute.href("/divvyqueue2")], [
          html.text("DivvyQueue2"),
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
  html.div([class("hero-section dashboard-hero")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [html.text("TandemX Dashboard")]),
      html.p([class("hero-subtitle")], [
        html.text(
          "Your command center for creative collaboration and business operations. Access all your tools from one central hub.",
        ),
      ]),
    ]),
  ])
}

fn view_dashboard_modules() -> Element(Msg) {
  html.div([class("dashboard-grid")], [
    // Row 1: Main modules
    html.div([class("dashboard-row")], [
      // Creative tools
      view_dashboard_card(
        "Creative Tools",
        [
          #("Findry", "/findry", "Artist and space discovery platform"),
          #("Events", "/events", "Event discovery and scheduling"),
          #("ChartSpace", "/chartspace", "Visual data analytics"),
          #("Digital Boards", "/digital-boards", "Visual organization tools"),
        ],
        "creative",
      ),
      // Business tools
      view_dashboard_card(
        "Business Tools",
        [
          #("DivvyQueue", "/divvyqueue", "Agreement management"),
          #("DivvyQueue2", "/divvyqueue2", "Financial management"),
          #("Compliance", "/compliance", "Regulatory compliance tools"),
          #("Banking", "/banking", "Financial operations"),
        ],
        "business",
      ),
    ]),
    // Row 2: Additional tools and quick stats
    html.div([class("dashboard-row")], [
      // Tasks and Calendar
      view_dashboard_card(
        "Organization",
        [
          #("Tasks", "/todos", "Task management system"),
          #("Calendar", "/calendar", "Schedule and event management"),
          #("Projects", "/projects", "Project management hub"),
          #("Cards", "/cards", "Card-based management"),
        ],
        "organization",
      ),
      // Quick stats
      view_stats_card(),
    ]),
    // Row 3: Products and marketplace
    html.div([class("dashboard-row")], [
      // Products showcase
      view_dashboard_card(
        "Products",
        [
          #(
            "MT Clipboards",
            "/mt-clipboards",
            "Professional clipboard solutions",
          ),
          #("Sledge", "/sledge", "Developer browser"),
          #("Hunter Exam Prep", "/hunter", "Training for the Hunter Exam"),
          #("Digital Tools", "/tools", "Digital productivity tools"),
        ],
        "products",
      ),
      // Activity feed
      view_activity_feed(),
    ]),
  ])
}

fn view_dashboard_card(
  title: String,
  links: List(#(String, String, String)),
  card_type: String,
) -> Element(Msg) {
  html.div([class("dashboard-card " <> card_type)], [
    html.h3([class("card-title")], [html.text(title)]),
    html.div(
      [class("card-links")],
      list.map(links, fn(link_data) {
        let #(name, link, description) = link_data
        html.a(
          [
            class("dashboard-link"),
            attribute.href(link),
            attribute.title(description),
          ],
          [
            html.div([class("link-content")], [
              html.span([class("link-name")], [html.text(name)]),
              html.span([class("link-description")], [html.text(description)]),
            ]),
          ],
        )
      }),
    ),
  ])
}

fn view_stats_card() -> Element(Msg) {
  html.div([class("dashboard-card stats")], [
    html.h3([class("card-title")], [html.text("Quick Stats")]),
    html.div([class("stats-container")], [
      html.div([class("stat-item")], [
        html.span([class("stat-value")], [html.text("12")]),
        html.span([class("stat-label")], [html.text("Active Projects")]),
      ]),
      html.div([class("stat-item")], [
        html.span([class("stat-value")], [html.text("4")]),
        html.span([class("stat-label")], [html.text("Pending Agreements")]),
      ]),
      html.div([class("stat-item")], [
        html.span([class("stat-value")], [html.text("8")]),
        html.span([class("stat-label")], [html.text("Upcoming Events")]),
      ]),
      html.div([class("stat-item")], [
        html.span([class("stat-value")], [html.text("3")]),
        html.span([class("stat-label")], [html.text("New Messages")]),
      ]),
    ]),
  ])
}

fn view_activity_feed() -> Element(Msg) {
  html.div([class("dashboard-card activity")], [
    html.h3([class("card-title")], [html.text("Recent Activity")]),
    html.ul([class("activity-feed")], [
      html.li([class("activity-item")], [
        html.span([class("activity-time")], [html.text("Today 10:45 AM")]),
        html.span([class("activity-text")], [
          html.text("New agreement proposal from Studio 721"),
        ]),
      ]),
      html.li([class("activity-item")], [
        html.span([class("activity-time")], [html.text("Yesterday 3:20 PM")]),
        html.span([class("activity-text")], [
          html.text("Task completed: Update project timeline"),
        ]),
      ]),
      html.li([class("activity-item")], [
        html.span([class("activity-time")], [html.text("March 12, 2:15 PM")]),
        html.span([class("activity-text")], [
          html.text("Event scheduled: Team planning session"),
        ]),
      ]),
      html.li([class("activity-item")], [
        html.span([class("activity-time")], [html.text("March 10, 11:30 AM")]),
        html.span([class("activity-text")], [
          html.text("New artist space match found in Brooklyn"),
        ]),
      ]),
    ]),
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
        view_footer_column("Products", [
          #("MT Clipboards", "/mt-clipboards"),
          #("Sledge", "/sledge"),
          #("D.d", "/ddew"),
          #("Shiny", "/shiny"),
        ]),
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
          #("DivvyQueue2", "/divvyqueue2"),
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

pub fn main() {
  let app = lustre.application(init, update, view)

  // Start the application and mount it to the document
  case lustre.start(app, "#app", Nil) {
    Ok(_) -> Nil
    Error(_) -> Nil
  }
}
