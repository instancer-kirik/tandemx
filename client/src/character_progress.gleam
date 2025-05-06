import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// Added for int/float conversion
import gleam/int

// Added for int conversion
import gleam/float

// Added for float conversion
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

// --- Types ---

pub type Badge {
  Badge(name: String, icon_url: String, description: String)
}

pub type Skill {
  Skill(name: String, level: Int, progress: Option(Float))
  // level 1-100, progress 0.0-100.0
}

pub type Quote {
  Quote(text: String, source: Option(String))
}

pub type Work {
  Work(
    title: String,
    description: String,
    image_url: Option(String),
    link: Option(String),
    date: String,
  )
}

pub type Model {
  Model(
    badges: List(Badge),
    skills: List(Skill),
    quotes: List(Quote),
    works: List(Work),
    loading: Bool,
  )
}

// No messages needed for now with static data
pub type Msg {
  NoOp
}

// --- Init ---

pub fn init() -> #(Model, Effect(Msg)) {
  let sample_badges = [
    Badge("Pioneer", "/icons/badge_pioneer.png", "Early contributor"),
    Badge(
      "Problem Solver",
      "/icons/badge_solver.png",
      "Helped fix critical bugs",
    ),
    Badge(
      "Community Helper",
      "/icons/badge_helper.png",
      "Active support on forums",
    ),
  ]

  let sample_skills = [
    Skill("Gleam Programming", 85, Some(60.0)),
    Skill("Frontend Development", 75, Some(80.0)),
    Skill("UI/UX Design", 60, None),
    Skill("System Architecture", 70, Some(30.0)),
  ]

  let sample_quotes = [
    Quote(
      "\"Simplicity is the ultimate sophistication.\"",
      Some("Leonardo da Vinci"),
    ),
    Quote("\"Stay hungry, stay foolish.\"", Some("Steve Jobs")),
    Quote("Code is like humor. When you have to explain it, it's bad.", None),
  ]

  let sample_works = [
    Work(
      "Project Aura",
      "Real-time collaborative editor built with Gleam and Lustre.",
      Some("/images/work_aura.png"),
      Some("https://github.com/user/aura"),
      "2024-02-15",
    ),
    Work(
      "DataViz Library",
      "A lightweight data visualization library for web applications.",
      None,
      Some("https://github.com/user/dataviz"),
      "2023-11-01",
    ),
  ]

  #(
    Model(
      badges: sample_badges,
      skills: sample_skills,
      quotes: sample_quotes,
      works: sample_works,
      loading: False,
    ),
    effect.none(),
  )
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

// --- View ---

// Helper function to render a single badge
fn view_badge(badge: Badge) -> Element(Msg) {
  html.div([attribute.class("badge-item")], [
    html.img([
      attribute.src(badge.icon_url),
      attribute.alt(badge.name <> " Badge"),
      attribute.class("badge-icon"),
    ]),
    html.div([attribute.class("badge-info")], [
      html.span([attribute.class("badge-name")], [html.text(badge.name)]),
      html.p([attribute.class("badge-description")], [
        html.text(badge.description),
      ]),
    ]),
  ])
}

// Helper function to render a single work item
fn view_work(work: Work) -> Element(Msg) {
  html.div([attribute.class("work-item")], [
    // Optional image
    case work.image_url {
      Some(url) ->
        html.img([
          attribute.src(url),
          attribute.alt(work.title <> " preview"),
          attribute.class("work-image"),
        ])
      None -> html.div([], [])
      // Or a placeholder image/icon
    },
    html.div([attribute.class("work-info")], [
      html.h4([attribute.class("work-title")], [html.text(work.title)]),
      html.p([attribute.class("work-description")], [
        html.text(work.description),
      ]),
      html.span([attribute.class("work-date")], [
        html.text("Date: " <> work.date),
      ]),
      // Optional link
      case work.link {
        Some(href) ->
          html.a([attribute.href(href), attribute.target("_blank")], [
            html.text("View Project"),
          ])
        None -> html.div([], [])
      },
    ]),
  ])
}

// Helper function to render a single quote
fn view_quote(quote: Quote) -> Element(Msg) {
  html.blockquote([attribute.class("quote-item")], [
    html.p([attribute.class("quote-text")], [html.text(quote.text)]),
    case quote.source {
      Some(src) ->
        html.footer([attribute.class("quote-source")], [html.text("— " <> src)])
      None -> html.div([], [])
      // Don't render footer if source is unknown
    },
  ])
}

// Helper function to render a single skill
fn view_skill(skill: Skill) -> Element(Msg) {
  html.div([attribute.class("skill-item")], [
    html.span([attribute.class("skill-name")], [html.text(skill.name)]),
    html.span([attribute.class("skill-level")], [
      html.text("Level: " <> int.to_string(skill.level)),
    ]),
    // Optional progress bar
    case skill.progress {
      Some(prog) ->
        html.div([attribute.class("skill-progress-bar-container")], [
          html.div(
            [
              attribute.class("skill-progress-bar"),
              // Set width based on progress percentage
              attribute.style("width", float.to_string(prog) <> "%"),
            ],
            [
              // Optional: Show percentage text inside bar
              // html.span([], [html.text(float.to_string(prog) <> "%")])
              html.text(""),
              // Empty text node needed for self-closing div effect in some cases
            ],
          ),
        ])
      None -> html.div([], [])
      // No progress bar if progress is None
    },
  ])
}

// Basic placeholder view
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("character-progress-container")], [
    html.h2([], [html.text("Character Progress")]),
    // Badges Section
    html.section([attribute.class("progress-section badges-section")], [
      html.h3([], [html.text("Badges")]),
      // Replace placeholder with badge rendering
      // html.p([], [html.text("Badges will be displayed here.")]),
      html.div(
        [attribute.class("badges-grid")],
        // Use a grid for layout
        list.map(model.badges, view_badge),
      ),
    ]),
    // Skills Section
    html.section([attribute.class("progress-section skills-section")], [
      html.h3([], [html.text("Skills")]),
      // Replace placeholder with skill rendering
      // html.p([], [html.text("Skills will be displayed here.")]),
      html.div(
        [attribute.class("skills-list")],
        list.map(model.skills, view_skill),
      ),
    ]),
    // Quotes Section
    html.section([attribute.class("progress-section quotes-section")], [
      html.h3([], [html.text("Quotes")]),
      // Replace placeholder with quote rendering
      // html.p([], [html.text("Quotes will be displayed here.")]),
      html.div(
        [attribute.class("quotes-list")],
        list.map(model.quotes, view_quote),
      ),
    ]),
    // Works Section
    html.section([attribute.class("progress-section works-section")], [
      html.h3([], [html.text("Works")]),
      // Replace placeholder with work rendering
      // html.p([], [html.text("Works will be displayed here.")]),
      html.div(
        [attribute.class("works-list")],
        // Use a list layout
        list.map(model.works, view_work),
      ),
    ]),
  ])
}
