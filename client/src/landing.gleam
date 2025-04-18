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
  ToggleCategory(String)
}

pub type Model {
  Model(expanded_categories: List(String))
}

pub fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(expanded_categories: ["elixir", "web"]), effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(path) -> {
      let _ = navigate(path)
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

@external(javascript, "./landing_ffi.js", "navigate")
fn navigate(path: String) -> Nil

fn view_hero() -> Element(Msg) {
  html.div([class("hero-section")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [html.text("TandemX Developer Tools")]),
      html.p([class("hero-subtitle")], [
        html.text(
          "A suite of specialized tools for development, creativity, and business management.",
        ),
      ]),
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
        [class("tool-card featured sledge"), attribute.href("/tools/sledge")],
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
        [class("tool-card featured mediata"), attribute.href("/tools/mediata")],
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
      html.tbody([], [
        // Web Applications
        create_table_row(
          "Findry",
          "Art and resource discovery platform",
          "Web",
          "Beta",
          "https://findry.lovable.app",
        ),
        create_table_row(
          "DivvyQueue",
          "Multiparty contracts and breach management",
          "Web",
          "Beta",
          "https://divvyqueue.lovable.app",
        ),
        create_table_row(
          "TandemX",
          "Project access, calendar, store access",
          "Web",
          "Beta",
          "/",
        ),
        // Elixir Applications
        create_table_row(
          "Deepscape",
          "Pannable chartspace with editor nodes for visual data flows",
          "Elixir",
          "Shelved",
          "/tools/deepscape",
        ),
        create_table_row(
          "Pause || Effect",
          "Dynamic multiplayer quests, maps, and stats engine",
          "Elixir",
          "Shelved",
          "/tools/pause-effect",
        ),
        create_table_row(
          "Resolvinator",
          "Data backend and form management system",
          "Elixir",
          "Shelved",
          "/tools/resolvinator",
        ),
        create_table_row(
          "Fonce",
          "D agent and Elixir multisecurity defense system",
          "Elixir",
          "Prototype",
          "/tools/fonce",
        ),
        create_table_row(
          "Seek",
          "Searching and indexing links and resources",
          "Elixir",
          "Shelved",
          "/tools/seek",
        ),
        create_table_row(
          "Veix",
          "The Elixir container and DAO LLC framework",
          "Elixir",
          "Planned",
          "/tools/veix",
        ),
        // Python Tools
        create_table_row(
          "Sledge",
          "Web browser with anti-flashbang protection and better tabs",
          "Python",
          "Releasable",
          "/tools/sledge",
        ),
        create_table_row(
          "Compyutinator Code",
          "Computer Science platform IDE with custom diff/merge tools",
          "Python",
          "Releasable",
          "/tools/compyutinator-code",
        ),
        create_table_row(
          "Mediata",
          "Multimedia and posting workflow management",
          "Elixir",
          "Shelved",
          "/tools/mediata",
        ),
        create_table_row(
          "Varchiver",
          "Archives and gitconfig with skip patterns",
          "Python",
          "Stable",
          "/tools/varchiver",
        ),
        // Blender Python
        create_table_row(
          "Bonify",
          "Rigging a train or arrangement along curves",
          "Blender",
          "Prototype",
          "/tools/bonify",
        ),
        create_table_row(
          "Nomine",
          "Blender Python utilities",
          "Blender",
          "Prototype",
          "/tools/nomine",
        ),
        // C Tools
        create_table_row(
          "Cround",
          "Bracelet Maker",
          "C",
          "Releasable",
          "/tools/cround",
        ),
        create_table_row(
          "Clipdirstructor",
          "Visual tree layouts converted into directories",
          "C",
          "Releasable",
          "/tools/clipdirstructor",
        ),
        // CLI Tools
        create_table_row(
          "Clipdirstructer",
          "CLI structures from visual hierarchies",
          "CLI",
          "Releasable",
          "/tools/clipdirstructer",
        ),
        create_table_row(
          "Explorinator",
          "Sort files by last modified (VSCode Plugin)",
          "CLI",
          "Stable",
          "/tools/explorinator",
        ),
        // Zig Tools
        create_table_row(
          "Combocounter",
          "Tracks variables and combination patterns",
          "Zig",
          "Prototype",
          "/tools/combocounter",
        ),
        create_table_row(
          "Video Editor",
          "Zig to WASM video editing tool",
          "Zig",
          "Prototype",
          "/tools/video-editor",
        ),
        create_table_row(
          "Trout/Grouper",
          "Group management tool",
          "Zig",
          "Prototype",
          "/tools/grouper",
        ),
      ]),
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
    _ -> "tag-beta"
  }

  html.tr([], [
    html.td([], [
      html.a([class("tool-link"), attribute.href(link)], [html.text(name)]),
    ]),
    html.td([], [html.text(description)]),
    html.td([], [html.text(category)]),
    html.td([], [
      html.span([class("tag " <> status_class)], [html.text(status)]),
    ]),
  ])
}

fn view_category_lists() -> Element(Msg) {
  html.div([class("categories-container")], [
    // Web Applications
    view_tool_list(
      "Web Applications",
      "Browser-based applications and services.",
      [
        #(
          "Findry",
          "Art and resource discovery platform",
          "https://findry.lovable.app",
        ),
        #(
          "DivvyQueue",
          "Multiparty contracts and breach management",
          "https://divvyqueue.lovable.app",
        ),
        #("TandemX", "Project access, calendar, store access", "/"),
      ],
    ),
    // Elixir Applications
    view_tool_list(
      "Elixir Applications",
      "High-performance backend services and interactive applications built with Elixir.",
      [
        #(
          "Deepscape",
          "Pannable chartspace with editor nodes for visual data flows",
          "/tools/deepscape",
        ),
        #(
          "Pause || Effect",
          "Dynamic multiplayer quests, maps, and stats engine",
          "/tools/pause-effect",
        ),
        #(
          "Resolvinator",
          "Data backend and form management system",
          "/tools/resolvinator",
        ),
        #(
          "Fonce",
          "D agent and Elixir multisecurity defense system",
          "/tools/fonce",
        ),
        #("Seek", "Searching and indexing links and resources", "/tools/seek"),
        #("Veix", "The Elixir container and DAO LLC framework", "/tools/veix"),
      ],
    ),
    // Python Tools
    view_tool_list(
      "Python Tools",
      "Python-based applications for development, media processing, and exploration.",
      [
        #(
          "Sledge",
          "Web browser with anti-flashbang protection and better tabs",
          "/tools/sledge",
        ),
        #(
          "Compyutinator Code",
          "Computer Science platform IDE with custom diff/merge tools",
          "/tools/compyutinator-code",
        ),
        #(
          "Mediata",
          "Multimedia and posting workflow management",
          "/tools/mediata",
        ),
        #(
          "Varchiver",
          "Archives and gitconfig with skip patterns",
          "/tools/varchiver",
        ),
      ],
    ),
    // Blender Python
    view_tool_list(
      "Blender Python",
      "Blender extensions and tools written in Python.",
      [
        #(
          "Bonify",
          "Rigging a train or arrangement along curves",
          "/tools/bonify",
        ),
        #("Nomine", "Blender Python utilities", "/tools/nomine"),
      ],
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

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("landing-page")], [
    view_hero(),
    view_featured_tools(),
    view_tools_table(),
    view_category_lists(),
    view_about_section(),
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
