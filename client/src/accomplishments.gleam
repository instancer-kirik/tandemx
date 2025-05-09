import access_content.{type FetchState, Errored, Idle, Loaded, Loading}
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute.{class, placeholder, value}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- Types ---

// Represents a single accomplishment record, matching FFI/Supabase structure
pub type Accomplishment {
  Accomplishment(
    id: String,
    user_id: String,
    content: String,
    created_at: String,
    // Keep as string for simplicity, parse/format in view if needed
    tags: Option(List(String)),
    project_id: Option(String),
  )
}

// State for the Accomplishments component
pub type Model {
  Model(
    current_user_id: Option(String),
    input_content: String,
    accomplishments: FetchState(List(Accomplishment)),
    submit_state: FetchState(Nil),
    // Tracks the state of the submission process
  )
}

// Messages the component can handle
pub type Msg {
  // User Actions
  UpdateInputField(String)
  SubmitAccomplishment
  // Internal/Effect Results
  FetchAccomplishments(user_id: String)
  // Message to trigger fetching
  AccomplishmentsFetched(Result(List(Accomplishment), String))
  AccomplishmentSubmitted(Result(Accomplishment, String))
  SetUserId(Option(String))
  // Message from parent app with user ID
}

// --- FFI Declarations ---

// Matches the FFI functions in accomplishments_ffi.js
@external(javascript, "./accomplishments_ffi.js", "fetchAccomplishments")
fn fetch_accomplishments_ffi(
  user_id: String,
) -> Promise(Result(List(Accomplishment), String))

// Note: submit needs user_id, content, tags, project_id
// We'll simplify for now and assume tags/project_id are not yet handled in the UI
@external(javascript, "./accomplishments_ffi.js", "submitAccomplishment")
fn submit_accomplishment_ffi(
  user_id: String,
  content: String,
  tags: Option(List(String)),
  // Pass None for now
  project_id: Option(String),
  // Pass None for now
) -> Promise(Result(Accomplishment, String))

// --- Init ---

pub fn init(user_id: Option(String)) -> #(Model, Effect(Msg)) {
  let initial_model =
    Model(
      current_user_id: user_id,
      input_content: "",
      accomplishments: Idle,
      submit_state: Idle,
    )
  let initial_effect = case user_id {
    Some(id) -> fetch_accomplishments_effect(id)
    None -> effect.none()
    // Don't fetch if no user
  }
  #(initial_model, initial_effect)
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UpdateInputField(content) -> {
      #(Model(..model, input_content: content), effect.none())
    }

    SubmitAccomplishment -> {
      case model.current_user_id {
        None -> {
          // Should not happen if UI disables submit when not logged in
          io.println("Attempted to submit accomplishment without user ID")
          #(
            Model(..model, submit_state: Errored("Not logged in")),
            effect.none(),
          )
        }
        Some(user_id) -> {
          case string.trim(model.input_content) == "" {
            True -> {
              // Prevent submitting empty content
              #(
                Model(..model, submit_state: Errored("Content cannot be empty")),
                effect.none(),
              )
            }
            False -> {
              // Start submission process
              #(
                Model(..model, submit_state: Loading),
                submit_accomplishment_effect(user_id, model.input_content),
              )
            }
          }
        }
      }
    }

    FetchAccomplishments(user_id) -> {
      #(
        Model(..model, accomplishments: Loading),
        fetch_accomplishments_effect(user_id),
      )
    }

    AccomplishmentsFetched(result) -> {
      case result {
        Ok(list) -> #(
          Model(..model, accomplishments: Loaded(list)),
          effect.none(),
        )
        Error(err) -> #(
          Model(..model, accomplishments: Errored(err)),
          effect.none(),
        )
      }
    }

    AccomplishmentSubmitted(result) -> {
      case result {
        Ok(new_accomplishment) -> {
          // Add the new accomplishment to the top of the list
          let updated_list = case model.accomplishments {
            Loaded(existing_list) -> [new_accomplishment, ..existing_list]
            _ -> [new_accomplishment]
            // Start new list if idle/error/loading
          }
          // Reset input field and submit state
          #(
            Model(
              ..model,
              accomplishments: Loaded(updated_list),
              input_content: "",
              submit_state: Idle,
            ),
            effect.none(),
          )
        }
        Error(err) -> {
          #(Model(..model, submit_state: Errored(err)), effect.none())
        }
      }
    }

    SetUserId(maybe_id) -> {
      // If user ID changes (login/logout), update model and maybe fetch
      let #(new_model, fetch_effect) = case model.current_user_id, maybe_id {
        // User logged in, was logged out
        None, Some(id) -> #(
          Model(..model, current_user_id: Some(id)),
          fetch_accomplishments_effect(id),
        )
        // User logged out, was logged in
        Some(_), None -> #(
          Model(..model, current_user_id: None, accomplishments: Idle),
          effect.none(),
        )
        // User ID changed (unlikely but possible)
        Some(old), Some(new) if old != new -> #(
          Model(..model, current_user_id: Some(new)),
          fetch_accomplishments_effect(new),
        )
        // No change
        _, _ -> #(model, effect.none())
      }
      #(new_model, fetch_effect)
    }
  }
}

// --- Effects ---

fn fetch_accomplishments_effect(user_id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    fetch_accomplishments_ffi(user_id)
    |> promise.map(AccomplishmentsFetched)
    |> promise.tap(dispatch)
    Nil
  })
}

fn submit_accomplishment_effect(user_id: String, content: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Pass None for tags and project_id for now
    submit_accomplishment_ffi(user_id, content, None, None)
    |> promise.map(AccomplishmentSubmitted)
    |> promise.tap(dispatch)
    Nil
  })
}

// --- View ---

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("accomplishments-container")], [
    html.h2([], [html.text("Log Accomplishment")]),
    view_input_section(model),
    view_accomplishments_list(model),
  ])
}

fn view_input_section(model: Model) -> Element(Msg) {
  let is_logged_in = option.is_some(model.current_user_id)
  let is_submitting = model.submit_state == Loading

  html.div([class("accomplishment-input-section")], [
    html.textarea(
      [
        class("accomplishment-input"),
        placeholder("What did you accomplish today?"),
        value(model.input_content),
        event.on_input(UpdateInputField),
      ],
      "",
    ),
    html.button([class("submit-button"), event.on_click(SubmitAccomplishment)], [
      html.text(case is_submitting {
        True -> "Submitting..."
        False -> "Log It"
      }),
    ]),
    // Display submit errors
    case model.submit_state {
      Errored(msg) ->
        html.p([class("error-text")], [html.text("Submit Error: " <> msg)])
      _ -> element.none()
    },
    case is_logged_in {
      False ->
        html.p([class("info-text")], [
          html.text("Please log in to post accomplishments."),
        ])
      True -> element.none()
    },
  ])
}

fn view_accomplishments_list(model: Model) -> Element(Msg) {
  html.div([class("accomplishments-list-section")], [
    html.h3([], [html.text("History")]),
    case model.accomplishments {
      Idle -> html.p([], [html.text("Log in to see your accomplishments.")])
      Loading -> html.p([], [html.text("Loading accomplishments...")])
      Errored(msg) ->
        html.p([class("error-text")], [
          html.text("Error loading history: " <> msg),
        ])
      Loaded([]) -> html.p([], [html.text("No accomplishments logged yet.")])
      Loaded(accomplishments) ->
        html.ul(
          [class("accomplishments-list")],
          list.map(accomplishments, view_accomplishment_item),
        )
    },
  ])
}

fn view_accomplishment_item(item: Accomplishment) -> Element(Msg) {
  html.li([class("accomplishment-item")], [
    html.p([class("item-content")], [html.text(item.content)]),
    html.div([class("item-meta")], [
      html.span([class("item-timestamp")], [
        html.text("Logged: " <> format_timestamp(item.created_at)),
      ]),
      // Optionally display tags or project link here if needed later
    ]),
  ])
}

// Basic timestamp formatting (could be improved with a date library)
fn format_timestamp(iso_string: String) -> String {
  // Example: "2024-07-26T10:30:00Z" -> "2024-07-26 10:30"
  // This is a very basic split, assumes a specific format.
  case string.split(iso_string, "T") {
    [date, rest] -> {
      case string.split(rest, ".") {
        [time, _] -> date <> " " <> time
        _ -> date <> " " <> rest
        // Handle cases without milliseconds
      }
    }
    _ -> iso_string
    // Fallback
  }
}
