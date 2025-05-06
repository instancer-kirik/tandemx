// import gleam/io // Removed unused import
import access_content.{
  type FetchState, type Model as AccessContentModel,
  type Msg as AccessContentMsg, type SupabaseUser, Errored, Idle, Loaded,
  Loading,
}
import components/nav
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element, map}
import lustre/element/html
import lustre/event
import partner_progress.{
  type Model as PartnerProgressModel, type Msg as PartnerProgressMsg,
}
import project_detail.{
  type Flags as ProjectDetailFlags, type Model as ProjectDetailModel,
  type Msg as ProjectDetailMsg, init as init_project_detail,
  update as update_project_detail, view as view_project_detail,
}
import projects.{type Model as ProjectsModel, type Msg as ProjectsMsg}
import settings.{
  type Model as SettingsModel, type Msg as SettingsMsg, init as init_settings,
  update as update_settings, view as view_settings,
}

// Assuming types defined in access_content can be imported

// import tandemx_client/pages/home // Removed incorrect import

// --- FFI Declarations (Supabase Auth) ---
// Assuming these are defined in a shared FFI file or app_ffi.js?
// Adjust path if necessary.
@external(javascript, "./app_ffi.js", "getCurrentUser")
fn get_current_user() -> Result(Option(SupabaseUser), String)

@external(javascript, "./app_ffi.js", "signInWithGitHub")
fn sign_in_with_github() -> Result(Nil, String)

@external(javascript, "./app_ffi.js", "signOutUser")
fn sign_out_user() -> Result(Nil, String)

// FFI to get initial URL path
@external(javascript, "./app_ffi.js", "getCurrentPath")
fn get_current_path() -> String

// Define the message types our app can handle
pub type Msg {
  NoOp
  PathChanged(String)
  Navigate(String)
  NavMsg(nav.Msg)
  AccessContentMsg(AccessContentMsg)
  PartnerProgressMsg(PartnerProgressMsg)
  ProjectsMsg(ProjectsMsg)
  ProjectDetailMsg(ProjectDetailMsg)
  SettingsMsg(SettingsMsg)
  CheckSession
  SessionReceived(Result(Option(SupabaseUser), String))
  LogoutCompleted(Result(Nil, String))
}

// Define our app's state model
pub type Model {
  Model(
    current_path: String,
    title: String,
    supabase_user: FetchState(Option(SupabaseUser)),
    is_admin: Bool,
    access_content_model: AccessContentModel,
    partner_progress_model: PartnerProgressModel,
    projects_model: ProjectsModel,
    project_detail_model: Option(ProjectDetailModel),
    settings_model: SettingsModel,
  )
}

// Initialize the app with default state
pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let initial_path = get_current_path()
  let #(ac_model, ac_effect) = access_content.init(Nil)
  let #(pp_model, pp_effect) = partner_progress.init(Nil)
  let #(proj_model, proj_effect) = projects.init(Nil)
  let #(set_model, set_effect) = init_settings(Nil)

  let initial_project_detail_effect = effect.none()

  let model =
    Model(
      current_path: initial_path,
      title: "instance.select",
      supabase_user: Idle,
      is_admin: False,
      access_content_model: ac_model,
      partner_progress_model: pp_model,
      projects_model: proj_model,
      project_detail_model: None,
      settings_model: set_model,
    )

  let #(model_after_route, route_effect) =
    handle_route_change(model, initial_path)

  #(
    model_after_route,
    effect.batch([
      effect.from(fn(dispatch) { dispatch(CheckSession) }),
      effect.map(ac_effect, AccessContentMsg),
      effect.map(pp_effect, PartnerProgressMsg),
      effect.map(proj_effect, ProjectsMsg),
      effect.map(set_effect, SettingsMsg),
      route_effect,
    ]),
  )
}

// Handle messages and update the model accordingly
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())

    PathChanged(new_path) -> handle_route_change(model, new_path)

    Navigate(path) -> {
      let new_model = Model(..model, current_path: path)
      #(new_model, effect.none())
    }

    // Handle messages forwarded from the nav component
    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.Navigated(path_segment) -> {
          let new_path = "/" <> path_segment
          handle_route_change(model, new_path)
        }
        nav.LoginAttempted -> {
          #(
            model,
            effect.from(fn(dispatch) {
              case sign_in_with_github() {
                Ok(_) -> dispatch(NoOp)
                Error(err) -> dispatch(NoOp)
              }
            }),
          )
        }
        nav.LogoutAttempted -> {
          #(
            model,
            effect.from(fn(dispatch) {
              let result = sign_out_user()
              dispatch(LogoutCompleted(result))
            }),
          )
        }
      }
    }

    // Handle access_content messages
    AccessContentMsg(ac_msg) -> {
      let #(new_ac_model, ac_effect) =
        access_content.update(model.access_content_model, ac_msg)
      #(
        Model(..model, access_content_model: new_ac_model),
        effect.map(ac_effect, AccessContentMsg),
      )
    }

    // Handle partner_progress messages
    PartnerProgressMsg(pp_msg) -> {
      let #(new_pp_model, pp_effect) =
        partner_progress.update(model.partner_progress_model, pp_msg)
      #(
        Model(..model, partner_progress_model: new_pp_model),
        effect.map(pp_effect, PartnerProgressMsg),
      )
    }

    // Handle projects messages
    ProjectsMsg(proj_msg) -> {
      let #(new_proj_model, proj_effect) =
        projects.update(model.projects_model, proj_msg)
      #(
        Model(..model, projects_model: new_proj_model),
        effect.map(proj_effect, ProjectsMsg),
      )
    }

    ProjectDetailMsg(pd_msg) -> {
      case model.project_detail_model {
        Some(current_pd_model) -> {
          let #(new_pd_model, pd_effect) =
            update_project_detail(current_pd_model, pd_msg)
          #(
            Model(..model, project_detail_model: Some(new_pd_model)),
            effect.map(pd_effect, ProjectDetailMsg),
          )
        }
        None -> #(model, effect.none())
      }
    }

    SettingsMsg(s_msg) -> {
      let #(new_s_model, s_effect) =
        update_settings(model.settings_model, s_msg)
      #(
        Model(..model, settings_model: new_s_model),
        effect.map(s_effect, SettingsMsg),
      )
    }

    // --- Auth Handlers ---
    CheckSession -> {
      #(
        Model(..model, supabase_user: Loading),
        effect.from(fn(dispatch) {
          let result = get_current_user()
          dispatch(SessionReceived(result))
        }),
      )
    }

    SessionReceived(result) -> {
      case result {
        Ok(maybe_user) -> {
          let user_is_admin = case maybe_user {
            Some(user) -> user.email == Some("admin@example.com")
            None -> False
          }
          #(
            Model(
              ..model,
              supabase_user: Loaded(maybe_user),
              is_admin: user_is_admin,
            ),
            effect.none(),
          )
        }
        Error(err) -> #(
          Model(..model, supabase_user: Errored(err), is_admin: False),
          effect.none(),
        )
      }
    }

    LogoutCompleted(result) -> {
      case result {
        Ok(_) -> #(
          Model(..model, supabase_user: Loaded(None), is_admin: False),
          effect.none(),
        )
        Error(err) -> #(model, effect.none())
      }
    }
  }
}

// Render the app UI
pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("app-container")], [
    element.map(nav.view(model.supabase_user), NavMsg),
    view_main_content(model),
  ])
}

// Helper function to render the main content based on the current page
fn view_main_content(model: Model) -> Element(Msg) {
  case string.split(model.current_path, "/") {
    ["", "project", _id] -> {
      case model.project_detail_model {
        Some(pd_model) ->
          element.map(
            view_project_detail(pd_model, model.supabase_user),
            ProjectDetailMsg,
          )
        None -> html.div([], [html.text("Loading project details page...")])
      }
    }
    ["", "projects"] ->
      element.map(
        projects.view(model.projects_model, model.supabase_user),
        ProjectsMsg,
      )
    ["", "access-content"] ->
      element.map(
        access_content.view(model.access_content_model, model.is_admin),
        AccessContentMsg,
      )
    ["", "partner-progress"] ->
      element.map(
        partner_progress.view(model.partner_progress_model, model.supabase_user),
        PartnerProgressMsg,
      )
    ["", "settings"] ->
      element.map(
        view_settings(model.settings_model, model.supabase_user),
        SettingsMsg,
      )
    _ -> view_home_page()
  }
}

// Home page content
fn view_home_page() -> Element(Msg) {
  html.div([attribute.class("page home-page")], [
    html.h2([], [html.text("Welcome to instance.select")]),
    html.p([], [
      html.text(
        "A collection of specialized development and creative tools organized by language and purpose.",
      ),
    ]),
  ])
}

// Tools page content
fn view_tools_page() -> Element(Msg) {
  html.div([attribute.class("page tools-page")], [
    html.h2([], [html.text("Developer Tools")]),
    html.p([], [html.text("Browse our collection of development tools.")]),
  ])
}

// About page content
fn view_about_page() -> Element(Msg) {
  html.div([attribute.class("page about-page")], [
    html.h2([], [html.text("About instance.select")]),
    html.p([], [
      html.text(
        "instance.select provides specialized tools for developers and creative professionals.",
      ),
    ]),
  ])
}

// Helper function to handle routing logic
fn handle_route_change(model: Model, path: String) -> #(Model, Effect(Msg)) {
  case string.split(path, "/") {
    ["", "project", id] -> {
      let flags = project_detail.Flags(project_id: id)
      let #(pd_model, pd_effect) = init_project_detail(flags)
      #(
        Model(..model, current_path: path, project_detail_model: Some(pd_model)),
        effect.map(pd_effect, ProjectDetailMsg),
      )
    }
    ["", "settings"] -> {
      #(
        Model(..model, current_path: path, project_detail_model: None),
        effect.none(),
      )
    }
    ["", "projects"] -> {
      #(
        Model(..model, current_path: path, project_detail_model: None),
        effect.none(),
      )
    }
    ["", "access-content"] | ["", "partner-progress"] | ["", ""] -> {
      #(
        Model(..model, current_path: path, project_detail_model: None),
        effect.none(),
      )
    }
    _ -> {
      #(
        Model(..model, current_path: path, project_detail_model: None),
        effect.none(),
      )
    }
  }
}
