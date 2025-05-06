import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute.{class, id}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- Types ---

// Basic structure for an art technique
pub type ArtTechnique {
  ArtTechnique(
    id: String,
    title: String,
    description: String,
    // categories: List(String),
    // steps: List(String),
    // media_urls: List(String), // For images/videos
    is_public: Bool,
    author_id: Option(String),
  )
}

// --- Model ---

pub type Model {
  Model(
    techniques: List(ArtTechnique),
    // current_view: ViewState, // e.g., ListView, SingleView(id), EditorView(Option(id))
    // user: Option(User), // For edit permissions
    // fetch_status: FetchStatus, // Idle, Loading, Error(String)
  )
}

// --- Messages ---

pub type Msg {
  // FetchTechniques
  // TechniquesReceived(Result(List(ArtTechnique), String))
  // ViewTechnique(String) // id
  // EditTechnique(Option(String)) // None for new, Some(id) for existing
  // TogglePublic(id: String, current_status: Bool)
  // SaveTechnique
  NoOp
  // Placeholder
}

// --- Init ---

// Flags could be used to pass initial data or user context if needed
pub type Flags {
  Flags
}

pub fn init(_flags: Flags) -> #(Model, Effect(Msg)) {
  let initial_model =
    Model(
      techniques: [],
      // Start with an empty list
    )
  // Potentially load techniques initially
  #(initial_model, effect.none())
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
    // Add other message handlers as functionality grows
  }
}

// --- View ---

pub fn view(model: Model) -> Element(Msg) {
  html.div([id("art-techniques-component")], [
    html.h2([], [html.text("Art Techniques")]),
    case model.techniques {
      [] -> html.p([], [html.text("No techniques loaded yet. Coming soon!")])
      _techniques_list ->
        // Later, map over _techniques_list to render each technique
        html.ul([], [
          html.li([], [html.text("Placeholder Technique 1")]),
          html.li([], [html.text("Placeholder Technique 2")]),
        ])
    },
    // Add buttons/forms for creating/editing later
  ])
}
// --- Main (if this module is to be run standalone by Lustre) ---
// You would typically have a main.gleam or similar that initializes your top-level app.
// If art_techniques.html is meant to be a self-contained Lustre app, 
// you'd add a main function here to start it.

// For example, if you want art_techniques.html to be its own app:
// pub fn main() {
//   let app = lustre.application(init, update, view)
//   let assert Ok(_) = lustre.start(app, "#art-techniques-app", Flags)
//   Nil
// }
// Otherwise, this module will be a component integrated into a larger app. 
