import components/background
import gleam/list
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(selected_feature: Option(String))
}

pub type Msg {
  SelectFeature(String)
  NavigateTo(String)
  ExpressInterest
}

pub type Option(a) {
  Some(a)
  None
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_: Nil) -> #(Model, Effect(Msg)) {
  #(Model(selected_feature: None), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SelectFeature(feature) -> #(
      Model(selected_feature: Some(feature)),
      effect.none(),
    )
    NavigateTo(path) -> {
      let _ = set_window_location(path)
      #(model, effect.none())
    }
    ExpressInterest -> {
      let _ = set_window_location("/bizpay/interest")
      #(model, effect.none())
    }
  }
}

@external(javascript, "./bizpay_ffi.js", "setWindowLocation")
fn set_window_location(path: String) -> Nil

fn view(model: Model) -> Element(Msg) {
  html.div([class("bizpay-landing")], [
    background.view(),
    view_header(),
    view_hero(),
    view_features(model.selected_feature),
    view_pricing(),
    view_testimonials(),
    view_cta(),
  ])
}

fn view_header() -> Element(Msg) {
  html.header([class("main-header")], [
    html.div([class("header-content")], [
      html.a([class("logo"), event.on_click(NavigateTo("/"))], [
        html.text("BizPay"),
      ]),
      html.nav([class("main-nav")], [
        html.a(
          [class("nav-link"), event.on_click(NavigateTo("/bizpay/features"))],
          [html.text("Features")],
        ),
        html.a(
          [class("nav-link"), event.on_click(NavigateTo("/bizpay/pricing"))],
          [html.text("Pricing")],
        ),
        html.a([class("nav-link"), event.on_click(NavigateTo("/bizpay/docs"))], [
          html.text("Documentation"),
        ]),
        html.button([class("cta-button"), event.on_click(ExpressInterest)], [
          html.text("Get Started"),
        ]),
      ]),
    ]),
  ])
}

fn view_hero() -> Element(Msg) {
  html.section([class("hero-section")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [
        html.text("Building the Future of Business Payments Together 🚀"),
      ]),
      html.p([class("hero-subtitle")], [
        html.text(
          "We're crafting a payment platform that works the way you do. Join us early and help shape the future of business payments. Share your needs, suggest features, and get early access benefits.",
        ),
      ]),
      html.div([class("hero-badges")], [
        html.span([class("badge early-access")], [html.text("Early Access")]),
        html.span([class("badge feedback-welcome")], [
          html.text("Seeking Feedback"),
        ]),
      ]),
      html.div([class("hero-cta")], [
        html.button([class("primary-button"), event.on_click(ExpressInterest)], [
          html.text("Join Early Access"),
        ]),
        html.button(
          [
            class("secondary-button"),
            event.on_click(NavigateTo("/bizpay/features")),
          ],
          [html.text("Share Feature Ideas 💡")],
        ),
      ]),
    ]),
  ])
}

fn view_features(selected: Option(String)) -> Element(Msg) {
  html.section([class("features-section")], [
    html.h2([class("section-title")], [
      html.text("Complete Business Operations Platform 🏗️"),
    ]),
    html.p([class("features-subtitle")], [
      html.text(
        "A comprehensive suite of tools designed for modern business operations, from payments to inventory management.",
      ),
    ]),
    html.div([class("features-grid")], [
      // Core Payment Features
      view_feature_group("Payments & Processing", [
        view_feature(
          "payments",
          "Smart Payment Processing 💳",
          "Multi-currency support, fraud protection, and intelligent routing for both traditional and alternative payment methods.",
          selected == Some("payments"),
        ),
        view_feature(
          "instant",
          "Instant Settlements ⚡",
          "Get paid faster with instant settlement options and flexible payout schedules.",
          selected == Some("instant"),
        ),
        view_feature(
          "crypto",
          "Crypto & Alternative 🌐",
          "Support for cryptocurrencies and alternative payment methods with automatic conversion.",
          selected == Some("crypto"),
        ),
      ]),
      // Catalog & POS Operations
      view_feature_group("Catalog & POS", [
        view_feature(
          "catalog",
          "Smart Catalog Management 📚",
          "Multi-channel product management, dynamic pricing, and automated inventory sync across all sales channels.",
          selected == Some("catalog"),
        ),
        view_feature(
          "pos",
          "Modern POS Solutions 🏪",
          "Cloud-based POS with offline support, custom workflows, and real-time analytics.",
          selected == Some("pos"),
        ),
        view_feature(
          "inventory",
          "Inventory Intelligence 📦",
          "Smart stock management, predictive ordering, and multi-location support.",
          selected == Some("inventory"),
        ),
      ]),
      // Business Operations
      view_feature_group("Business Suite", [
        view_feature(
          "operations",
          "Operations Hub 🏢",
          "Centralized dashboard for bills, subscriptions, and vendor management.",
          selected == Some("operations"),
        ),
        view_feature(
          "quotes",
          "Quick Quote Engine 📝",
          "Generate and manage custom quotes with dynamic pricing and approval workflows.",
          selected == Some("quotes"),
        ),
        view_feature(
          "automation",
          "Smart Automation 🤖",
          "Automate routine tasks, payments, and business processes with custom workflows.",
          selected == Some("automation"),
        ),
      ]),
      // Financial Tools
      view_feature_group("Financial Tools", [
        view_feature(
          "credit",
          "Credit Systems 🌱",
          "Innovative financing with Labor Credits and early-stage investment benefits.",
          selected == Some("credit"),
        ),
        view_feature(
          "cards",
          "Virtual Cards 💳",
          "Issue and manage virtual cards with granular spending controls.",
          selected == Some("cards"),
        ),
        view_feature(
          "analytics",
          "Business Intelligence 📊",
          "Real-time analytics, custom reports, and predictive insights.",
          selected == Some("analytics"),
        ),
      ]),
      // Team & Compliance
      view_feature_group("Team & Compliance", [
        view_feature(
          "team",
          "Team Management 👥",
          "Employee management, payroll, and team budgeting in one place.",
          selected == Some("team"),
        ),
        view_feature(
          "compliance",
          "Compliance Suite 🛡️",
          "Automated tax calculations, regulatory tracking, and reporting.",
          selected == Some("compliance"),
        ),
        view_feature(
          "security",
          "Enterprise Security 🔒",
          "Advanced fraud protection, role-based access, and audit trails.",
          selected == Some("security"),
        ),
      ]),
    ]),
    html.div([class("feature-categories")], [
      html.h3([class("categories-title")], [html.text("Ecosystem Integration")]),
      html.p([class("categories-description")], [
        html.text(
          "BizPay is part of a larger ecosystem of business tools. Seamlessly integrate with:",
        ),
      ]),
      html.div([class("categories-grid")], [
        view_category(
          "DivvyQueue",
          "Multi-party contract and agreement management",
          "/divvyqueue",
        ),
        view_category(
          "Findry",
          "Creative space and resource marketplace",
          "/findry",
        ),
        view_category(
          "ChartSpace",
          "Visual collaboration and planning",
          "/chartspace",
        ),
      ]),
    ]),
    html.div([class("feature-request")], [
      html.h3([class("request-title")], [html.text("Help Shape Our Roadmap")]),
      html.p([class("request-text")], [
        html.text(
          "We're actively developing new features and integrations. Share your needs and ideas - your input directly influences our development priorities.",
        ),
      ]),
      html.div([class("request-actions")], [
        html.button(
          [class("request-button primary"), event.on_click(ExpressInterest)],
          [html.text("Join Early Access")],
        ),
        html.button(
          [
            class("request-button secondary"),
            event.on_click(NavigateTo("/bizpay/roadmap")),
          ],
          [html.text("View Public Roadmap")],
        ),
      ]),
    ]),
  ])
}

fn view_feature_group(
  title: String,
  features: List(Element(Msg)),
) -> Element(Msg) {
  html.div([class("feature-group")], [
    html.h3([class("group-title")], [html.text(title)]),
    html.div([class("group-features")], features),
  ])
}

fn view_feature(
  id: String,
  title: String,
  description: String,
  is_selected: Bool,
) -> Element(Msg) {
  html.div(
    [
      class(
        "feature-card "
        <> case is_selected {
          True -> "selected"
          False -> ""
        },
      ),
      event.on_click(SelectFeature(id)),
    ],
    [
      html.h3([class("feature-title")], [html.text(title)]),
      html.p([class("feature-description")], [html.text(description)]),
    ],
  )
}

fn view_category(
  name: String,
  description: String,
  path: String,
) -> Element(Msg) {
  html.div([class("category-card")], [
    html.h4([class("category-name")], [html.text(name)]),
    html.p([class("category-description")], [html.text(description)]),
    html.a([class("category-link"), event.on_click(NavigateTo(path))], [
      html.text("Learn More →"),
    ]),
  ])
}

fn view_pricing() -> Element(Msg) {
  html.section([class("pricing-section")], [
    html.h2([class("section-title")], [html.text("Early Adopter Pricing 🌟")]),
    html.p([class("pricing-subtitle")], [
      html.text(
        "Join us early and lock in special rates. We're growing with you.",
      ),
    ]),
    html.div([class("pricing-grid")], [
      view_pricing_tier(
        "Early Bird",
        "1.2% + $0.20",
        "Perfect for startups and small businesses",
        [
          "Early access to new features", "Priority feature requests",
          "Direct access to founding team", "Up to $50k monthly processing",
          "Next-day payouts", "Basic fraud protection",
          "Community Discord access",
        ],
      ),
      view_pricing_tier(
        "Growth Partner",
        "1.0% + $0.15",
        "For businesses ready to scale",
        [
          "All Early Bird features", "Up to $250k monthly processing",
          "Same-day payouts", "Advanced fraud detection", "Priority support",
          "Full API access", "Monthly feedback sessions",
          "Rate lock guarantee for 2 years",
        ],
      ),
      view_pricing_tier(
        "Launch Pad",
        "Let's Talk",
        "Custom solutions for unique needs",
        [
          "All Growth Partner features", "Custom processing limits",
          "Tailored pricing models", "Custom feature development",
          "Dedicated support team", "Strategic partnership options",
          "Investment opportunities",
        ],
      ),
    ]),
  ])
}

fn view_pricing_tier(
  name: String,
  price: String,
  description: String,
  features: List(String),
) -> Element(Msg) {
  html.div([class("pricing-tier")], [
    html.h3([class("tier-name")], [html.text(name)]),
    html.div([class("tier-price")], [html.text(price)]),
    html.p([class("tier-description")], [html.text(description)]),
    html.ul(
      [class("tier-features")],
      list.map(features, fn(feature) {
        html.li([class("feature-item")], [
          html.span([class("check-icon")], [html.text("✓")]),
          html.text(feature),
        ])
      }),
    ),
    html.button([class("tier-cta"), event.on_click(ExpressInterest)], [
      html.text("Get Started"),
    ]),
  ])
}

fn view_testimonials() -> Element(Msg) {
  html.section([class("testimonials-section")], [
    html.h2([class("section-title")], [html.text("Happy Money Movers 🌟")]),
    html.div([class("testimonials-grid")], [
      view_testimonial(
        "Sarah from PixelPerfect",
        "Digital Art Marketplace",
        "BizPay turned our payment chaos into a beautiful symphony. Our artists get paid faster than their art loads! 🎨",
      ),
      view_testimonial(
        "Mike's Global Goodies",
        "International Snack Shop",
        "Managing payments in 12 currencies used to give me headaches. Now it's easier than eating a cookie! 🍪",
      ),
      view_testimonial(
        "TechTribe Solutions",
        "Software Agency",
        "The API is so good, our developers actually smiled during integration. That's like seeing a unicorn! 🦄",
      ),
    ]),
  ])
}

fn view_testimonial(name: String, title: String, quote: String) -> Element(Msg) {
  html.div([class("testimonial-card")], [
    html.p([class("testimonial-quote")], [html.text(quote)]),
    html.div([class("testimonial-author")], [
      html.strong([class("author-name")], [html.text(name)]),
      html.span([class("author-title")], [html.text(title)]),
    ]),
  ])
}

fn view_cta() -> Element(Msg) {
  html.section([class("cta-section")], [
    html.div([class("cta-content")], [
      html.h2([class("cta-title")], [
        html.text("Let's Build Something Amazing Together 🌟"),
      ]),
      html.p([class("cta-description")], [
        html.text(
          "Join our early access program and help shape the future of business payments. Get special rates, priority support, and direct input into our roadmap.",
        ),
      ]),
      html.div([class("cta-options")], [
        html.div([class("cta-option")], [
          html.h3([class("option-title")], [html.text("Early Access")]),
          html.p([class("option-description")], [
            html.text(
              "Get started with special early adopter rates and benefits.",
            ),
          ]),
          html.button(
            [class("primary-button"), event.on_click(ExpressInterest)],
            [html.text("Join Now")],
          ),
        ]),
        html.div([class("cta-option")], [
          html.h3([class("option-title")], [html.text("Partnership")]),
          html.p([class("option-description")], [
            html.text(
              "Interested in strategic partnership or investment opportunities?",
            ),
          ]),
          html.button(
            [
              class("secondary-button"),
              event.on_click(NavigateTo("/bizpay/contact")),
            ],
            [html.text("Let's Talk")],
          ),
        ]),
      ]),
    ]),
  ])
}
