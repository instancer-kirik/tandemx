import access_content.{
  type FetchState, type SupabaseUser, Errored, Idle, Loaded, Loading,
}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{class, id}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// No longer imports app

// --- Types ---

pub type MegamenuIdentifier {
  ProjectsMegamenu
  ContentMegamenu
  ScheduleMegamenu
}

pub type Model {
  Model(
    user_state: FetchState(Option(SupabaseUser)),
    open_megamenu: Option(MegamenuIdentifier),
  )
}

// nav.Msg now includes messages that parent will listen for
pub type Msg {
  ToggleMegamenu(MegamenuIdentifier)
  CloseAllMegamenus
  // Navigation/Auth events that the parent should handle:
  ParentShouldNavigate(String)
  ParentShouldLogin
  ParentShouldLogout
}

// --- Init ---

pub fn init(user_state: FetchState(Option(SupabaseUser))) -> Model {
  Model(user_state: user_state, open_megamenu: None)
}

// --- Update ---
// Update function now returns Effect(Msg) as parent will map these.
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ToggleMegamenu(identifier) -> {
      let new_open_megamenu = case model.open_megamenu {
        Some(currently_open) if currently_open == identifier -> None
        _ -> Some(identifier)
      }
      #(Model(..model, open_megamenu: new_open_megamenu), effect.none())
    }
    CloseAllMegamenus -> {
      #(Model(..model, open_megamenu: None), effect.none())
    }
    // These messages are primarily for the parent. 
    // The nav component itself might do minimal state change (like closing menus) 
    // and then re-dispatches or lets the parent handle it.
    // For simplicity here, we assume these are caught by parent via mapping.
    // If nav needed to react first (e.g. close menu) then do effect.self(ParentShouldNavigate)
    // it could do: #(Model(..model, open_megamenu: None), effect.self(ParentShouldNavigate(path)))
    ParentShouldNavigate(_path) -> {
      // Close megamenu when navigation occurs
      #(Model(..model, open_megamenu: None), effect.none())
      // Parent will get ParentShouldNavigate directly
    }
    ParentShouldLogin -> {
      #(model, effect.none())
      // Parent will get ParentShouldLogin
    }
    ParentShouldLogout -> {
      #(model, effect.none())
      // Parent will get ParentShouldLogout
    }
  }
}

// --- View ---

// Helper to create a nav link that dispatches ParentShouldNavigate
fn nav_link_item(href_val: String, text_val: String) -> Element(Msg) {
  html.a([event.on_click(ParentShouldNavigate(href_val))], [html.text(text_val)])
}

fn view_megamenu_panel(
  identifier: MegamenuIdentifier,
  model: Model,
) -> Element(Msg) {
  let is_open = case model.open_megamenu {
    Some(open_id) -> open_id == identifier
    None -> False
  }

  let base_classes = "megamenu-panel"
  let open_class = case is_open {
    True -> " open"
    False -> ""
  }

  html.div(
    [class(base_classes <> open_class), id(megamenu_id_string(identifier))],
    case identifier {
      ProjectsMegamenu -> [
        view_megamenu_column("View", [
          nav_link_item("/projects", "All Projects"),
          nav_link_item("/tasks", "My Tasks"),
        ]),
        view_megamenu_column("Create", [
          nav_link_item("/projects/new", "New Project"),
          nav_link_item("/tasks/new", "New Task"),
        ]),
      ]
      ContentMegamenu -> [
        view_megamenu_column("Browse", [
          nav_link_item("/access-content", "All Content"),
          nav_link_item("/access-content?category=article", "Articles"),
          nav_link_item("/art-techniques", "Art Techniques"),
        ]),
        view_megamenu_column("Create", [
          nav_link_item("/access-content/new", "New Post"),
        ]),
      ]
      ScheduleMegamenu -> [
        view_megamenu_column("View", [
          nav_link_item("/calendar", "My Schedule"),
          nav_link_item("/calendar/team", "Team Schedule"),
        ]),
        view_megamenu_column("Actions", [
          nav_link_item("/calendar/new", "Schedule Event"),
        ]),
      ]
    },
  )
}

fn megamenu_id_string(identifier: MegamenuIdentifier) -> String {
  case identifier {
    ProjectsMegamenu -> "megamenu-projects"
    ContentMegamenu -> "megamenu-content"
    ScheduleMegamenu -> "megamenu-schedule"
  }
}

fn view_megamenu_column(
  title: String,
  items: List(Element(Msg)),
) -> Element(Msg) {
  html.div([class("megamenu-column")], [
    html.h4([], [html.text(title)]),
    html.ul([], list.map(items, fn(item) { html.li([], [item]) })),
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  html.nav([class("navbar main-nav")], [
    html.div([class("nav-content")], [
      html.a([class("logo"), event.on_click(ParentShouldNavigate("/"))], [
        html.text("TandemX"),
      ]),
      html.div([class("nav-links")], [
        html.div([class("nav-item")], [
          html.a([event.on_click(ParentShouldNavigate("/"))], [
            html.text("Home"),
          ]),
        ]),
        html.div([class("nav-item has-megamenu")], [
          html.a([event.on_click(ToggleMegamenu(ProjectsMegamenu))], [
            html.text("Projects"),
          ]),
          view_megamenu_panel(ProjectsMegamenu, model),
        ]),
        html.div([class("nav-item has-megamenu")], [
          html.a([event.on_click(ToggleMegamenu(ContentMegamenu))], [
            html.text("Content"),
          ]),
          view_megamenu_panel(ContentMegamenu, model),
        ]),
        html.div([class("nav-item has-megamenu")], [
          html.a([event.on_click(ToggleMegamenu(ScheduleMegamenu))], [
            html.text("Schedule"),
          ]),
          view_megamenu_panel(ScheduleMegamenu, model),
        ]),
        html.div([class("nav-item")], [
          html.a([event.on_click(ParentShouldNavigate("/radio"))], [
            html.text("📻 Radio"),
          ]),
        ]),
      ]),
      html.div([class("nav-actions")], [
        case model.user_state {
          Loaded(Some(_user)) ->
            html.button(
              [class("nav-btn logout"), event.on_click(ParentShouldLogout)],
              [html.text("Logout")],
            )
          Loaded(None) | Idle | Errored(_) ->
            html.button(
              [class("nav-btn login"), event.on_click(ParentShouldLogin)],
              [html.text("Login with GitHub")],
            )
          Loading -> html.span([class("nav-loading")], [html.text("...")])
        },
      ]),
    ]),
  ])
}
