// The actual file starts here:
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre
import lustre/attribute

// Removed unused: attribute, class, disabled, for, href, id, placeholder, property, required,
// src, style, type_, value

// Added missing imports based on original file
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- Types ---

// Represents a content post from Supabase
// Ensure this matches your actual Supabase table structure
// Using dynamic.optional_field for potentially missing fields
// Removed unused private function decode_post

// Simplified Post type for easier handling
// Add excerpt and image if needed later
pub type Post {
  Post(
    id: String,
    slug: Option(String),
    title: Option(String),
    content: Option(String),
    date: Option(String),
    author: Option(String),
    category: Option(String),
    // excerpt: Option(String),
    // image: Option(String),
  )
}

// Supabase configuration
pub type SupabaseConfig {
  SupabaseConfig(supabase_url: String, supabase_anon_key: String)
}

// Represents the different views the app can be in
pub type ViewState {
  ListView
  SingleView(slug: String)
  EditorView
}

// Represents the current state of fetching data
pub type FetchState(data) {
  Idle
  Loading
  Loaded(data)
  Errored(String)
}

// Represents user data from Supabase Auth
pub type SupabaseUser {
  SupabaseUser(id: String, email: Option(String))
}

// --- Model ---

pub type Model {
  Model(
    current_view: ViewState,
    supabase_config: FetchState(SupabaseConfig),
    posts: FetchState(List(Post)),
    current_post: FetchState(Option(Post)),
    supabase_user: FetchState(Option(SupabaseUser)),
    // Editor state
    editor_title: String,
    editor_category: String,
    editor_excerpt: String,
    editor_image_url: String,
    editor_submit_error: Option(String),
    is_tiptap_initialized: Bool,
  )
}

// --- FFI Declarations ---

// Define a type for the data structure expected by the createPost FFI function
// This makes the Gleam code type-safe when calling the JS function.
pub type PostDataForFFI {
  PostDataForFFI(
    title: String,
    content: String,
    category: String,
    author: String,
    date: String,
    // Assuming ISO string format
    slug: String,
    excerpt: String,
    // Optional fields should ideally be handled
    image: String,
    // by the JS FFI function if null/empty
  )
}

@external(javascript, "./access_content_ffi.js", "fetchConfig")
fn fetch_config() -> Result(SupabaseConfig, String)

@external(javascript, "./access_content_ffi.js", "initSupabase")
fn init_supabase(url: String, key: String) -> Result(Nil, String)

@external(javascript, "./access_content_ffi.js", "initTiptap")
fn init_tiptap(selector: String, initial_content: String) -> Result(Nil, String)

@external(javascript, "./access_content_ffi.js", "destroyTiptap")
fn destroy_tiptap() -> Nil

@external(javascript, "./access_content_ffi.js", "getTiptapHTML")
fn get_tiptap_html() -> Result(String, String)

// FFI for createPost, now using the specific PostDataForFFI type
@external(javascript, "./access_content_ffi.js", "createPost")
fn create_post(post_data: PostDataForFFI) -> Result(Post, String)

@external(javascript, "./access_content_ffi.js", "fetchPosts")
fn fetch_posts() -> Result(List(Post), String)

@external(javascript, "./access_content_ffi.js", "fetchPostBySlug")
fn fetch_post_by_slug(slug: String) -> Result(Option(Post), String)

@external(javascript, "./access_content_ffi.js", "getSlugFromUrl")
fn get_slug_from_url() -> Result(Option(String), String)

@external(javascript, "./access_content_ffi.js", "showToast")
fn show_toast(message: String, toast_type: String) -> Result(Nil, String)

@external(javascript, "./access_content_ffi.js", "checkAdminAuth")
fn check_admin_auth() -> Result(Bool, String)

@external(javascript, "./access_content_ffi.js", "setAdminAuth")
fn set_admin_auth() -> Result(Nil, String)

@external(javascript, "./access_content_ffi.js", "checkPasswordFFI")
fn check_password_ffi(input_id: String) -> Result(Bool, String)

@external(javascript, "./access_content_ffi.js", "generateSlugFFI")
fn generate_slug_ffi(title: String) -> Result(String, String)

// FFI for getting current date - Placeholder, needs JS FFI implementation
@external(javascript, "./access_content_ffi.js", "getCurrentIsoDate")
fn get_current_iso_date_ffi() -> Result(String, String)

fn current_iso_date() -> String {
  result.unwrap(get_current_iso_date_ffi(), "")
}

// Helper function to handle the result of decoding the category change event
// fn handle_category_change(result: Result(String, List(DecodeError))) -> Msg {
//   case result {
//     Ok(value) -> UpdateEditorField("category", value)
//     Error(_) -> NoOp
//     // Or a specific error message
//   }
// }

// Decoder for extracting target.value from an event object using gleam/dynamic/decode
// fn target_value_decoder() -> dynamic_decode.Decoder(String) {
//   dynamic_decode.at(["target", "value"], dynamic_decode.string)
// }

// --- FFI Declarations (Supabase Auth) ---
// @external(javascript, "./access_content_ffi.js", "getCurrentUser")
// fn get_current_user() -> Result(Option(SupabaseUser), String)

// @external(javascript, "./access_content_ffi.js", "signInWithGitHub")
// fn sign_in_with_github() -> Result(Nil, String)

// @external(javascript, "./access_content_ffi.js", "signOutUser")
// fn sign_out_user() -> Result(Nil, String)

// --- Update Helper Functions ---

fn handle_config_result(
  model: Model,
  result: Result(SupabaseConfig, String),
) -> #(Model, Effect(Msg)) {
  case result {
    Ok(config) -> {
      let updated_model = Model(..model, supabase_config: Loaded(config))
      #(
        updated_model,
        effect.from(fn(dispatch) {
          case init_supabase(config.supabase_url, config.supabase_anon_key) {
            Ok(_) -> dispatch(SupabaseReady)
            Error(err) -> dispatch(FetchError("Supabase Init Failed: " <> err))
          }
        }),
      )
    }
    Error(err) -> #(
      Model(..model, supabase_config: Errored(err)),
      show_toast_effect("Failed to load config: " <> err, "error"),
    )
  }
}

// Determines initial data load based on view state, only if Supabase is ready
fn handle_initial_slug(
  model: Model,
  view_state: ViewState,
) -> #(Model, Effect(Msg)) {
  case model.supabase_config {
    Loaded(_) -> {
      case view_state {
        SingleView(slug) -> #(
          Model(..model, current_post: Loading),
          load_single_post(slug),
        )
        ListView | EditorView -> #(
          Model(..model, posts: Loading),
          load_all_posts(),
        )
      }
    }
    _ -> #(model, effect.none())
  }
}

fn handle_tiptap_ready(
  model: Model,
  result: Result(Nil, String),
) -> #(Model, Effect(Msg)) {
  case result {
    Ok(_) -> #(Model(..model, is_tiptap_initialized: True), effect.none())
    Error(err) -> {
      #(
        model,
        show_toast_effect("Tiptap failed to initialize: " <> err, "error"),
      )
    }
  }
}

pub fn init(_flags) -> #(Model, Effect(Msg)) {
  let initial_model =
    Model(
      current_view: ListView,
      supabase_config: Loading,
      posts: Idle,
      current_post: Idle,
      supabase_user: Idle,
      editor_title: "",
      editor_category: "other",
      editor_excerpt: "",
      editor_image_url: "",
      editor_submit_error: None,
      is_tiptap_initialized: False,
    )

  let initial_effects = [
    effect.from(fn(dispatch) {
      let result = fetch_config()
      dispatch(ReceiveConfig(result))
    }),
    effect.from(fn(dispatch) {
      case get_slug_from_url() {
        Ok(maybe_slug) -> dispatch(ReceiveUrlSlug(maybe_slug))
        Error(_) -> dispatch(ReceiveUrlSlug(None))
      }
    }),
    // REMOVED: Initial auth checks
  ]

  #(initial_model, effect.batch(initial_effects))
}

// --- Messages ---

pub type Msg {
  // Initialization & Config
  ReceiveConfig(Result(SupabaseConfig, String))
  SupabaseReady
  TiptapReady(Result(Nil, String))

  // Navigation & View State
  ViewList
  ViewPost(slug: String)
  ShowEditor
  HideEditor
  ReceiveUrlSlug(Option(String))

  // Data Fetching
  ReceivePosts(Result(List(Post), String))
  ReceiveSinglePost(Result(Option(Post), String))
  FetchError(String)

  // Editor Interaction
  UpdateEditorField(field: String, value: String)
  SubmitEditor
  TiptapHtmlReceived(Result(String, String))
  PostCreated(Result(Post, String))
  NoOp
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // --- Initialization & Config ---
    ReceiveConfig(config_result) -> handle_config_result(model, config_result)

    SupabaseReady -> {
      // Supabase is ready, determine what to load based on initial URL slug
      let #(updated_model, effect) =
        handle_initial_slug(model, model.current_view)
      // Pass current view state
      #(updated_model, effect)
    }

    TiptapReady(result) -> handle_tiptap_ready(model, result)

    // --- Navigation & View State ---
    ViewList -> {
      let effects = case model.current_view {
        EditorView -> [load_all_posts(), destroy_tiptap_effect()]
        _ -> [load_all_posts()]
        // Just reload list
      }
      // Ensure Tiptap state is reset if we came from editor
      #(
        Model(
          ..model,
          current_view: ListView,
          is_tiptap_initialized: False,
          editor_submit_error: None,
        ),
        effect.batch(effects),
      )
    }

    ViewPost(slug) -> {
      let effects = case model.current_view {
        EditorView -> [load_single_post(slug), destroy_tiptap_effect()]
        _ -> [load_single_post(slug)]
      }
      // Ensure Tiptap state is reset
      #(
        Model(
          ..model,
          current_view: SingleView(slug),
          current_post: Loading,
          is_tiptap_initialized: False,
        ),
        effect.batch(effects),
      )
    }

    ShowEditor -> {
      // Modify this to check passed-in admin status
      // This logic now needs the `is_admin` status passed to `update` or view
      // For now, let's assume it can proceed, but it will need adjustment
      let updated_model =
        Model(
          ..model,
          current_view: EditorView,
          editor_title: "",
          editor_category: "other",
          editor_excerpt: "",
          editor_image_url: "",
          editor_submit_error: None,
          is_tiptap_initialized: False,
          current_post: Idle,
        )
      #(updated_model, init_tiptap_effect("#tiptap-editor", "<p></p>"))
    }

    HideEditor ->
      // Go back to list view, clear editor state, destroy tiptap
      #(
        Model(
          ..model,
          current_view: ListView,
          is_tiptap_initialized: False,
          editor_title: "",
          editor_category: "other",
          editor_excerpt: "",
          editor_image_url: "",
          editor_submit_error: None,
        ),
        destroy_tiptap_effect(),
      )

    ReceiveUrlSlug(maybe_slug) -> {
      // Update view state based on slug, actual loading depends on Supabase state
      let new_view_state = case maybe_slug {
        Some(slug) -> SingleView(slug)
        None -> ListView
      }
      // Re-trigger loading logic now that we know the intended view
      handle_initial_slug(
        Model(..model, current_view: new_view_state),
        new_view_state,
      )
    }

    // --- Data Fetching ---
    ReceivePosts(result) ->
      case result {
        Ok(posts_data) -> #(
          Model(..model, posts: Loaded(posts_data)),
          effect.none(),
        )
        Error(err) -> #(
          Model(..model, posts: Errored(err)),
          show_toast_effect("Error loading posts: " <> err, "error"),
        )
      }

    ReceiveSinglePost(result) ->
      case result {
        Ok(maybe_post_data) ->
          // Result contains Option(Post)
          #(
            Model(..model, current_post: Loaded(maybe_post_data)),
            effect.none(),
          )
        Error(err) -> #(
          Model(..model, current_post: Errored(err)),
          show_toast_effect("Error loading content: " <> err, "error"),
        )
      }

    FetchError(error_message) -> {
      io.println("Fetch Error: " <> error_message)
      #(model, show_toast_effect("Error: " <> error_message, "error"))
    }

    // --- Editor Interaction ---
    UpdateEditorField(field, value) -> {
      let updated_model = case field {
        "title" -> Model(..model, editor_title: value)
        "category" -> Model(..model, editor_category: value)
        "excerpt" -> Model(..model, editor_excerpt: value)
        "image_url" -> Model(..model, editor_image_url: value)
        _ -> model
      }
      #(updated_model, effect.none())
    }

    SubmitEditor -> {
      #(
        model,
        effect.from(fn(dispatch) {
          let result = get_tiptap_html()
          dispatch(TiptapHtmlReceived(result))
        }),
      )
    }

    TiptapHtmlReceived(html_content_result) -> {
      case html_content_result {
        Ok(html_content) -> {
          case
            model.editor_title == ""
            || html_content == ""
            || html_content == "<p></p>"
          {
            True -> #(
              Model(
                ..model,
                editor_submit_error: Some("Title and content cannot be empty."),
              ),
              effect.none(),
            )
            False -> #(
              model,
              effect.from(fn(dispatch) {
                case generate_slug_ffi(model.editor_title) {
                  Ok(slug) -> {
                    let post_data =
                      PostDataForFFI(
                        title: model.editor_title,
                        slug: slug,
                        content: html_content,
                        category: model.editor_category,
                        author: "Admin",
                        date: current_iso_date(),
                        excerpt: model.editor_excerpt,
                        image: model.editor_image_url,
                      )
                    dispatch(PostCreated(create_post(post_data)))
                  }
                  Error(err) ->
                    dispatch(
                      PostCreated(Error("Slug generation failed: " <> err)),
                    )
                }
              }),
            )
          }
        }
        Error(err) -> {
          #(
            Model(
              ..model,
              editor_submit_error: Some("Failed to get editor content: " <> err),
            ),
            effect.none(),
          )
        }
      }
    }

    PostCreated(result) ->
      case result {
        Ok(_) -> #(
          Model(
            ..model,
            current_view: ListView,
            editor_submit_error: None,
            editor_title: "",
            editor_category: "other",
            editor_excerpt: "",
            editor_image_url: "",
            is_tiptap_initialized: False,
          ),
          effect.batch([
            show_toast_effect("Content created successfully!", "success"),
            load_all_posts(),
            destroy_tiptap_effect(),
          ]),
        )
        Error(err) -> #(
          Model(..model, editor_submit_error: Some(err)),
          show_toast_effect("Failed to create content: " <> err, "error"),
        )
      }

    NoOp -> #(model, effect.none())
    // Handle NoOp: do nothing
  }
}

// --- Effects ---

fn load_all_posts() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let result = fetch_posts()
    dispatch(ReceivePosts(result))
  })
}

fn load_single_post(slug: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let result = fetch_post_by_slug(slug)
    dispatch(ReceiveSinglePost(result))
  })
}

fn show_toast_effect(message: String, toast_type: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case show_toast(message, toast_type) {
      Ok(_) -> dispatch(NoOp)
      Error(err) -> dispatch(FetchError("Toast effect failed: " <> err))
    }
  })
}

fn set_admin_auth_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case set_admin_auth() {
      Ok(_) -> dispatch(NoOp)
      Error(err) -> dispatch(FetchError("setAdminAuth Failed: " <> err))
    }
  })
}

fn destroy_tiptap_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    destroy_tiptap()
    // Dispatch NoOp after the side effect completes
    dispatch(NoOp)
  })
}

fn init_tiptap_effect(selector: String, initial_content: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    let result = init_tiptap(selector, initial_content)
    dispatch(TiptapReady(result))
  })
}

// --- Views ---

// Placeholder for the list view
fn view_list(model: Model) -> Element(Msg) {
  html.div([], [html.h1([], [html.text("List View")])])
  // Simple placeholder
}

// Placeholder for the single post view
fn view_single(model: Model, slug: String) -> Element(Msg) {
  html.div([], [html.h1([], [html.text("Single Post View")])])
  // Simple placeholder
}

pub fn view(model: Model, is_admin: Bool) -> Element(Msg) {
  html.main([], [
    // Conditionally render 'Create New Post' button
    case is_admin {
      True ->
        html.button([event.on_click(ShowEditor)], [
          html.text("Create New Content"),
        ])
      False -> element.none()
    },
    case model.current_view {
      ListView -> view_list(model)
      SingleView(slug) -> view_single(model, slug)
      EditorView -> view_editor(model)
    },
  ])
}

fn view_editor(model: Model) -> Element(Msg) {
  // Define the decoder outside the handler
  // let category_decoder =
  //   dynamic_decode.at(["target", "value"], dynamic_decode.string)

  html.div(
    [attribute.id("editor-container"), attribute.class("editor-container")],
    [
      html.h2([], [html.text("Create New Content")]),
      case model.editor_submit_error {
        Some(err) ->
          html.p([attribute.class("error-text")], [html.text("Error: " <> err)])
        None -> html.div([], [])
      },
      html.div([attribute.class("editor-form-group")], [
        html.label([attribute.for("editor-title")], [html.text("Title")]),
        html.input([
          attribute.id("editor-title"),
          attribute.value(model.editor_title),
          attribute.placeholder("Enter content title"),
          event.on_input(fn(val) { UpdateEditorField("title", val) }),
        ]),
      ]),
      html.div([attribute.class("editor-form-group")], [
        html.label([attribute.for("editor-category")], [html.text("Category")]),
        html.select(
          [
            attribute.id("editor-category"),
            attribute.value(model.editor_category),
            // Use Lustre's on_change handler
            event.on_change(fn(value) { UpdateEditorField("category", value) }),
          ],
          [
            html.option([attribute.value("other")], "Other"),
            html.option([attribute.value("3d-model")], "3D Model"),
            html.option([attribute.value("game")], "Game"),
            html.option([attribute.value("code-snippet")], "Code Snippet"),
            html.option([attribute.value("article")], "Article"),
          ],
        ),
      ]),
    ],
  )
}
