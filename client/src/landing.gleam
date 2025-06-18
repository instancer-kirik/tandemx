import gleam/list

import gleam/string

import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

import project_catalog

// Helper function for joining a list of strings with a separator
fn join_strings(strings: List(String), separator: String) -> String {
  case strings {
    [] -> ""
    [only] -> only
    [first, ..rest] -> first <> separator <> join_strings(rest, separator)
  }
}

pub type Msg {
  RequestNavigation(String)
  ToggleCategory(String)
  NavigateToShop
  GetCustomQuote
}

pub type Model {
  Model(expanded_categories: List(String))
}

pub fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(expanded_categories: ["elixir", "web"]), effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RequestNavigation(_path) -> {
      #(model, effect.none())
    }
    NavigateToShop -> {
      #(model, effect.none())
    }
    GetCustomQuote -> {
      #(model, effect.none())
    }
    ToggleCategory(category) -> {
      case list.contains(model.expanded_categories, category) {
        True -> #(
          Model(
            expanded_categories: list.filter(model.expanded_categories, fn(c) {
              c != category
            }),
          ),
          effect.none(),
        )
        False -> #(
          Model(expanded_categories: [category, ..model.expanded_categories]),
          effect.none(),
        )
      }
    }
  }
}

fn view_hero() -> Element(Msg) {
  html.div([class("hero-section")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [html.text("instance.select Spaceport")]),
      html.p([class("hero-subtitle")], [
        html.text(
          "Launch your development journey with our specialized tools and platforms.",
        ),
      ]),
    ]),
  ])
}

fn view_featured_articles() -> Element(Msg) {
  html.div([class("featured-articles")], [
    html.h2([class("section-title")], [html.text("Featured Content")]),
    html.div([class("articles-grid")], [
      // Article 1
      html.a(
        [
          class("article-card card-item"),
          attribute.href("/access-content/spaceport-launch"),
          event.on_click(RequestNavigation("/access-content/spaceport-launch")),
        ],
        [
          html.div([class("article-header")], [
            html.span([class("article-category")], [html.text("Announcement")]),
            html.h3([class("article-title")], [
              html.text("instance.select Spaceport Launch"),
            ]),
          ]),
          html.div([class("article-content")], [
            html.p([class("article-excerpt")], [
              html.text(
                "Introducing our new dark mode interface for developers, built to enhance your workflow with a space-inspired theme.",
              ),
            ]),
          ]),
          html.div([class("article-footer")], [
            html.span([class("article-date")], [html.text("July 15, 2024")]),
            html.span([class("article-read-more")], [html.text("Read more →")]),
          ]),
        ],
      ),
      // Article 2
      html.a(
        [
          class("article-card card-item"),
          attribute.href("/access-content/chart-space-navigation"),
          event.on_click(RequestNavigation(
            "/access-content/chart-space-navigation",
          )),
        ],
        [
          html.div([class("article-header")], [
            html.span([class("article-category")], [html.text("Tutorial")]),
            html.h3([class("article-title")], [
              html.text("Navigating Chart Space"),
            ]),
          ]),
          html.div([class("article-content")], [
            html.p([class("article-excerpt")], [
              html.text(
                "Learn how to effectively use the new Chart Space feature to visualize complex data flows and relationships.",
              ),
            ]),
          ]),
          html.div([class("article-footer")], [
            html.span([class("article-date")], [html.text("July 10, 2024")]),
            html.span([class("article-read-more")], [html.text("Read more →")]),
          ]),
        ],
      ),
      // Article 3
      html.a(
        [
          class("article-card card-item"),
          attribute.href("/access-content/multiverse-development"),
          event.on_click(RequestNavigation(
            "/access-content/multiverse-development",
          )),
        ],
        [
          html.div([class("article-header")], [
            html.span([class("article-category")], [html.text("Development")]),
            html.h3([class("article-title")], [
              html.text("Multi-Verse Development"),
            ]),
          ]),
          html.div([class("article-content")], [
            html.p([class("article-excerpt")], [
              html.text(
                "Exploring parallel development environments for maximum productivity and experimental workflows.",
              ),
            ]),
          ]),
          html.div([class("article-footer")], [
            html.span([class("article-date")], [html.text("July 5, 2024")]),
            html.span([class("article-read-more")], [html.text("Read more →")]),
          ]),
        ],
      ),
    ]),
  ])
}

fn view_featured_tools() -> Element(Msg) {
  html.div([class("featured-tools")], [
    html.h2([class("section-title")], [html.text("Featured Tools")]),
    html.div([class("featured-grid")], [
      // Findry
      html.a(
        [
          class("tool-card featured findry"),
          attribute.href("https://findry.lovable.app"),
        ],
        [
          html.div([class("featured-header")], [
            html.h3([class("featured-title")], [html.text("Findry")]),
            html.span([class("featured-badge")], [html.text("Popular")]),
          ]),
          html.div([class("featured-body")], [
            html.p([class("featured-description")], [
              html.text(
                "Art and resource discovery platform with visual search capabilities and social features.",
              ),
            ]),
          ]),
          html.div([class("featured-footer")], [
            html.span([class("tag-label")], [
              html.span([class("tag tag-beta")], [html.text("Beta")]),
            ]),
            html.span([class("icon-arrow")], [html.text("→")]),
          ]),
        ],
      ),
      // Deepscape
      html.a(
        [
          class("tool-card featured deepscape"),
          attribute.href("/tools/deepscape"),
          event.on_click(RequestNavigation("/tools/deepscape")),
        ],
        [
          html.div([class("featured-header")], [
            html.h3([class("featured-title")], [html.text("Deepscape")]),
            html.span([class("featured-badge")], [html.text("New")]),
          ]),
          html.div([class("featured-body")], [
            html.p([class("featured-description")], [
              html.text(
                "Pannable chartspace with editor nodes for creating visual data flows and pipelines.",
              ),
            ]),
          ]),
          html.div([class("featured-footer")], [
            html.span([class("tag-label")], [
              html.span([class("tag tag-shelved")], [html.text("Shelved")]),
            ]),
            html.span([class("icon-arrow")], [html.text("→")]),
          ]),
        ],
      ),
      // DivvyQueue
      html.a(
        [
          class("tool-card featured divvyqueue"),
          attribute.href("https://divvyqueue.lovable.app"),
        ],
        [
          html.div([class("featured-header")], [
            html.h3([class("featured-title")], [html.text("DivvyQueue")]),
            html.span([class("featured-badge")], [html.text("Stable")]),
          ]),
          html.div([class("featured-body")], [
            html.p([class("featured-description")], [
              html.text(
                "Multiparty contracts and breach management system with automated workflows.",
              ),
            ]),
          ]),
          html.div([class("featured-footer")], [
            html.span([class("tag-label")], [
              html.span([class("tag tag-beta")], [html.text("Beta")]),
            ]),
            html.span([class("icon-arrow")], [html.text("→")]),
          ]),
        ],
      ),
      // Sledge
      html.a(
        [
          class("tool-card featured sledge"),
          attribute.href("/tools/sledge"),
          event.on_click(RequestNavigation("/tools/sledge")),
        ],
        [
          html.div([class("featured-header")], [
            html.h3([class("featured-title")], [html.text("Sledge")]),
            html.span([class("featured-badge")], [html.text("Popular")]),
          ]),
          html.div([class("featured-body")], [
            html.p([class("featured-description")], [
              html.text(
                "Web browser with anti-flashbang protection, improved tab management, and privacy features.",
              ),
            ]),
          ]),
          html.div([class("featured-footer")], [
            html.span([class("tag-label")], [
              html.span([class("tag tag-releasable")], [html.text("Releasable")]),
            ]),
            html.span([class("icon-arrow")], [html.text("→")]),
          ]),
        ],
      ),
      // Mediata
      html.a(
        [
          class("tool-card featured mediata"),
          attribute.href("/tools/mediata"),
          event.on_click(RequestNavigation("/tools/mediata")),
        ],
        [
          html.div([class("featured-header")], [
            html.h3([class("featured-title")], [html.text("Mediata")]),
            html.span([class("featured-badge")], [html.text("Productivity")]),
          ]),
          html.div([class("featured-body")], [
            html.p([class("featured-description")], [
              html.text(
                "Multimedia and posting workflow management for content creators and teams.",
              ),
            ]),
          ]),
          html.div([class("featured-footer")], [
            html.span([class("tag-label")], [
              html.span([class("tag tag-shelved")], [html.text("Shelved")]),
            ]),
            html.span([class("icon-arrow")], [html.text("→")]),
          ]),
        ],
      ),
    ]),
  ])
}

fn view_tools_table() -> Element(Msg) {
  html.div([], [
    html.h2([class("section-title")], [html.text("Tools Directory")]),
    html.table([class("tools-table")], [
      html.thead([], [
        html.tr([], [
          html.th([], [html.text("Tool Name")]),
          html.th([], [html.text("Description")]),
          html.th([], [html.text("Category")]),
          html.th([], [html.text("Status")]),
        ]),
      ]),
      html.tbody(
        [],
        // Generate table rows from project catalog
        list.map(project_catalog.get_projects(), fn(project) {
          // Extract main technology for category column
          let tech_string = join_strings(project.tech_stack, " ")
          let tech_lower = string.lowercase(tech_string)

          // Determine display category
          let category = case project.domain {
            "Development Tools & Environments" -> {
              case
                string.contains(tech_lower, "python")
                || string.contains(tech_lower, "pyqt")
              {
                True -> "Python"
                False ->
                  case string.contains(tech_lower, "gleam") {
                    True -> "Gleam"
                    False ->
                      case string.contains(tech_lower, "elixir") {
                        True -> "Elixir"
                        False ->
                          case string.contains(tech_lower, "zig") {
                            True -> "Zig"
                            False ->
                              case
                                string.contains(tech_lower, "c ")
                                || tech_lower == "c"
                              {
                                True -> "C"
                                False -> "Dev"
                              }
                          }
                      }
                  }
              }
            }
            "Creative Tools" -> "Creative"
            "Project Management" -> "PM"
            "Data & Search" -> "Data"
            "System Tools" -> "System"
            "Language Tools" -> "Lang"
            "Gaming & Entertainment" -> "Gaming"
            "Business & Contracts" -> "Business"
            _ -> "Other"
          }

          // Map status for display
          let display_status = case project.status {
            "Active" -> "Beta"
            status -> status
          }

          create_table_row(
            project.name,
            project.description,
            category,
            display_status,
            project.path,
          )
        }),
      ),
    ]),
  ])
}

fn create_table_row(
  name: String,
  description: String,
  category: String,
  status: String,
  link: String,
) -> Element(Msg) {
  let status_class = case status {
    "Stable" -> "tag-stable"
    "New" -> "tag-new"
    "Beta" -> "tag-beta"
    "Prototype" -> "tag-prototype"
    "Shelved" -> "tag-shelved"
    "Planned" -> "tag-planned"
    "Releasable" -> "tag-releasable"
    "Active" -> "tag-beta"
    // Map Active status to Beta for display
    _ -> "tag-beta"
  }

  html.tr([], [
    html.td([], [
      html.a(
        [
          class("tool-link"),
          attribute.href(link),
          event.on_click(RequestNavigation(link)),
        ],
        [html.text(name)],
      ),
    ]),
    html.td([], [html.text(description)]),
    html.td([], [html.text(category)]),
    html.td([], [
      html.span([class("tag " <> status_class)], [html.text(status)]),
    ]),
  ])
}

fn view_category_lists() -> Element(Msg) {
  let projects = project_catalog.get_projects()

  // Get Web Applications
  let web_apps =
    projects
    |> list.filter(fn(p) {
      let tech_string = join_strings(p.tech_stack, ", ")
      string.contains(tech_string, "eb")
    })
    |> list.take(3)
    |> list.map(fn(p) { #(p.name, p.description, p.path) })

  // Get Elixir Applications
  let elixir_apps =
    projects
    |> list.filter(fn(p) {
      let tech_string =
        join_strings(p.tech_stack, ", ")
        |> string.lowercase
      string.contains(tech_string, "elixir")
    })
    |> list.take(6)
    |> list.map(fn(p) { #(p.name, p.description, p.path) })

  // Get Python Tools
  let python_tools =
    projects
    |> list.filter(fn(p) {
      let tech_string =
        join_strings(p.tech_stack, ", ")
        |> string.lowercase
      string.contains(tech_string, "python")
      || string.contains(tech_string, "pyqt")
    })
    |> list.take(4)
    |> list.map(fn(p) { #(p.name, p.description, p.path) })

  // Get Blender Python
  let blender_tools =
    projects
    |> list.filter(fn(p) {
      let tech_string =
        join_strings(p.tech_stack, ", ")
        |> string.lowercase
      string.contains(tech_string, "blender")
    })
    |> list.take(3)
    |> list.map(fn(p) { #(p.name, p.description, p.path) })

  html.div([class("categories-container")], [
    // Web Applications
    view_tool_list(
      "Web Applications",
      "Browser-based applications and services.",
      web_apps,
    ),
    // Elixir Applications
    view_tool_list(
      "Elixir Applications",
      "High-performance backend services and interactive applications built with Elixir.",
      elixir_apps,
    ),
    // Python Tools
    view_tool_list(
      "Python Tools",
      "Python-based applications for development, media processing, and exploration.",
      python_tools,
    ),
    // Blender Python
    view_tool_list(
      "Blender Python",
      "Blender extensions and tools written in Python.",
      blender_tools,
    ),
  ])
}

fn view_tool_list(
  title: String,
  description: String,
  tools: List(#(String, String, String)),
) -> Element(Msg) {
  html.div([class("tool-list")], [
    html.div([class("tool-list-header")], [
      html.h3([class("tool-list-title")], [html.text(title)]),
    ]),
    html.div([class("category-description")], [
      html.p([], [html.text(description)]),
    ]),
    html.div(
      [class("tool-list-container")],
      list.map(tools, fn(tool) {
        let #(name, description, link) = tool
        html.div([class("tool-list-item")], [
          html.a([class("tool-list-link"), attribute.href(link)], [
            html.text(name),
          ]),
          html.span([class("tool-list-description")], [html.text(description)]),
        ])
      }),
    ),
  ])
}

fn view_about_section() -> Element(Msg) {
  html.div([class("about-section")], [
    html.h2([], [html.text("About This Toolset")]),
    html.p([], [
      html.text(
        "This collection represents tools at various stages of development, from experimental prototypes to production-ready applications. They're organized by primary language and purpose.",
      ),
    ]),
    html.div([class("tag-legend")], [
      html.div([class("tag-item")], [
        html.span([class("tag tag-stable")], [html.text("Stable")]),
        html.span([], [
          html.text("Production-ready tools with complete features"),
        ]),
      ]),
      html.div([class("tag-item")], [
        html.span([class("tag tag-releasable")], [html.text("Releasable")]),
        html.span([], [html.text("Ready to use with minimal limitations")]),
      ]),
      html.div([class("tag-item")], [
        html.span([class("tag tag-new")], [html.text("New")]),
        html.span([], [html.text("Recently released stable tools")]),
      ]),
      html.div([class("tag-item")], [
        html.span([class("tag tag-beta")], [html.text("Beta")]),
        html.span([], [html.text("Functional but may have limited features")]),
      ]),
      html.div([class("tag-item")], [
        html.span([class("tag tag-prototype")], [html.text("Prototype")]),
        html.span([], [
          html.text("Early development versions with basic functionality"),
        ]),
      ]),
      html.div([class("tag-item")], [
        html.span([class("tag tag-planned")], [html.text("Planned")]),
        html.span([], [
          html.text("Upcoming tools in planning or pre-development"),
        ]),
      ]),
      html.div([class("tag-item")], [
        html.span([class("tag tag-shelved")], [html.text("Shelved")]),
        html.span([], [html.text("Development paused or temporarily inactive")]),
      ]),
    ]),
  ])
}

// Update the main view function to include the navigation and footer
pub fn view(_model: Model) -> Element(Msg) {
  html.div([class("landing-page-content")], [
    view_moto_hero(),
    view_hero(),
    view_featured_articles(),
    view_featured_tools(),
    view_tools_table(),
    view_category_lists(),
    view_about_section(),
  ])
}

fn view_moto_hero() -> Element(Msg) {
  html.section([class("moto-hero")], [
    html.div([class("moto-hero-background")], []),
    html.div([class("moto-hero-content")], [
      html.div([class("moto-hero-text")], [
        html.h1([class("moto-hero-title")], [
          html.text("TandemX Moto"),
          html.br([]),
          html.span([class("moto-hero-subtitle")], [html.text("Performance & Custom")])
        ]),
        html.p([class("moto-hero-description")], [
          html.text("Premium motorcycle parts, expert service, and custom builds. Transform your ride with quality components and professional craftsmanship.")
        ]),
        html.div([class("moto-hero-actions")], [
          html.button([
            class("moto-btn primary"),
            event.on_click(NavigateToShop)
          ], [
            html.text("🏍️ Shop Parts"),
          ]),
          html.button([
            class("moto-btn secondary"),
            event.on_click(GetCustomQuote)
          ], [
            html.text("💬 Get Custom Quote"),
          ])
        ])
      ]),
      html.div([class("moto-hero-features")], [
        html.div([class("moto-feature")], [
          html.div([class("moto-feature-icon")], [html.text("🔧")]),
          html.h3([class("moto-feature-title")], [html.text("Expert Service")]),
          html.p([class("moto-feature-desc")], [html.text("Professional maintenance and repairs")])
        ]),
        html.div([class("moto-feature")], [
          html.div([class("moto-feature-icon")], [html.text("⚡")]),
          html.h3([class("moto-feature-title")], [html.text("Performance Parts")]),
          html.p([class("moto-feature-desc")], [html.text("Quality components for every ride")])
        ]),
        html.div([class("moto-feature")], [
          html.div([class("moto-feature-icon")], [html.text("🎨")]),
          html.h3([class("moto-feature-title")], [html.text("Custom Builds")]),
          html.p([class("moto-feature-desc")], [html.text("Unique motorcycles built to order")])
        ])
      ])
    ])
  ])
}
