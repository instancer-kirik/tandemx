// import gleam/io // Removed unused import
import access_content.{
  type FetchState, type Model as AccessContentModel,
  type Msg as AccessContentMsg, type SupabaseUser, Errored, Idle, Loaded,
  Loading,
}
import accomplishments.{
  type Model as AccomplishmentsModel, type Msg as AccomplishmentsMsg,
  init as init_accomplishments, update as update_accomplishments,
  view as view_accomplishments,
}
import components/nav

import gleam/option.{type Option, None, Some}

import gleam/string
import landing.{
  type Model as LandingModel, type Msg as LandingMsg, init as init_landing,
  update as update_landing, view as view_landing,
}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import partner_progress.{
  type Model as PartnerProgressModel, type Msg as PartnerProgressMsg,
}
import project_detail.{
  type Model as ProjectDetailModel, type Msg as ProjectDetailMsg,
  init as init_project_detail, update as update_project_detail,
  view as view_project_detail,
}
import projects.{type Model as ProjectsModel, type Msg as ProjectsMsg}
import settings.{
  type Model as SettingsModel, type Msg as SettingsMsg, init as init_settings,
  update as update_settings, view as view_settings,
}

// Added for debug

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
  NavMsg(nav.Msg)
  AccessContentMsg(AccessContentMsg)
  PartnerProgressMsg(PartnerProgressMsg)
  ProjectsMsg(ProjectsMsg)
  ProjectDetailMsg(ProjectDetailMsg)
  SettingsMsg(SettingsMsg)
  LandingMsg(LandingMsg)
  CheckSession
  SessionReceived(Result(Option(SupabaseUser), String))
  LogoutCompleted(Result(Nil, String))
  AccomplishmentsMsg(AccomplishmentsMsg)
}

// Define our app's state model
pub type Model {
  Model(
    current_path: String,
    title: String,
    supabase_user: FetchState(Option(SupabaseUser)),
    is_admin: Bool,
    nav_model: nav.Model,
    access_content_model: AccessContentModel,
    partner_progress_model: PartnerProgressModel,
    projects_model: ProjectsModel,
    project_detail_model: Option(ProjectDetailModel),
    settings_model: SettingsModel,
    landing_model: LandingModel,
    accomplishments_model: AccomplishmentsModel,
  )
}

// Initialize the app with default state
pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let initial_path = get_current_path()
  let #(ac_model, ac_effect) = access_content.init(Nil)
  let #(pp_model, pp_effect) = partner_progress.init(Nil)
  let #(proj_model, proj_effect) = projects.init(Nil)
  let #(set_model, set_effect) = init_settings(Nil)
  let #(initial_landing_model, landing_effect) = init_landing(Nil)
  let #(accom_model, accom_effect) = init_accomplishments(None)

  let initial_nav_model = nav.init(Idle)

  let model =
    Model(
      current_path: initial_path,
      title: "instance.select",
      supabase_user: Idle,
      is_admin: False,
      nav_model: initial_nav_model,
      access_content_model: ac_model,
      partner_progress_model: pp_model,
      projects_model: proj_model,
      project_detail_model: None,
      settings_model: set_model,
      landing_model: initial_landing_model,
      accomplishments_model: accom_model,
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
      effect.map(landing_effect, LandingMsg),
      route_effect,
      effect.map(accom_effect, AccomplishmentsMsg),
    ]),
  )
}

// Handle messages and update the model accordingly
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())

    PathChanged(new_path) -> handle_route_change(model, new_path)

    NavMsg(nav_sub_msg) -> {
      let #(updated_nav_model, nav_effect_from_child) =
        nav.update(model.nav_model, nav_sub_msg)
      let new_model_with_updated_nav =
        Model(..model, nav_model: updated_nav_model)

      case nav_sub_msg {
        nav.ParentShouldNavigate(path) -> {
          let #(final_model, route_effect) =
            handle_route_change(new_model_with_updated_nav, path)
          #(
            final_model,
            effect.batch([
              effect.map(nav_effect_from_child, NavMsg),
              route_effect,
            ]),
          )
        }
        nav.ParentShouldLogin -> {
          echo { "App: Login Attempted via Nav" }
          let login_effect =
            effect.from(fn(dispatch) {
              case sign_in_with_github() {
                Ok(_) -> dispatch(CheckSession)
                Error(err) -> {
                  echo { "Login FFI error: " <> err }
                  dispatch(NoOp)
                }
              }
            })
          #(
            new_model_with_updated_nav,
            effect.batch([
              effect.map(nav_effect_from_child, NavMsg),
              login_effect,
            ]),
          )
        }
        nav.ParentShouldLogout -> {
          echo { "App: Logout Attempted via Nav" }
          let logout_effect =
            effect.from(fn(dispatch) {
              dispatch(LogoutCompleted(sign_out_user()))
            })
          #(
            new_model_with_updated_nav,
            effect.batch([
              effect.map(nav_effect_from_child, NavMsg),
              logout_effect,
            ]),
          )
        }
        nav.ToggleMegamenu(_) | nav.CloseAllMegamenus -> {
          #(
            new_model_with_updated_nav,
            effect.map(nav_effect_from_child, NavMsg),
          )
        }
      }
    }

    AccessContentMsg(ac_msg) -> {
      let #(new_ac_model, ac_effect) =
        access_content.update(model.access_content_model, ac_msg)
      #(
        Model(..model, access_content_model: new_ac_model),
        effect.map(ac_effect, AccessContentMsg),
      )
    }

    PartnerProgressMsg(pp_msg) -> {
      let #(new_pp_model, pp_effect) =
        partner_progress.update(model.partner_progress_model, pp_msg)
      #(
        Model(..model, partner_progress_model: new_pp_model),
        effect.map(pp_effect, PartnerProgressMsg),
      )
    }

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

    LandingMsg(l_msg) -> {
      let #(updated_landing_model, landing_effect_from_child) =
        update_landing(model.landing_model, l_msg)
      let new_model_with_updated_landing =
        Model(..model, landing_model: updated_landing_model)

      case l_msg {
        landing.RequestNavigation(path) -> {
          echo { "App: Landing page requested navigation to: " <> path }
          let #(final_model, route_effect) =
            handle_route_change(new_model_with_updated_landing, path)
          #(
            final_model,
            effect.batch([
              effect.map(landing_effect_from_child, LandingMsg),
              route_effect,
            ]),
          )
        }
        _ -> {
          #(
            new_model_with_updated_landing,
            effect.map(landing_effect_from_child, LandingMsg),
          )
        }
      }
    }

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
      echo {
        "App received SessionReceived with result:" <> string.inspect(result)
      }

      // Determine new state and trigger child update based on the FFI result
      let #(new_model, child_effect) = case result {
        Ok(Some(user)) -> {
          // User successfully fetched
          let user_id = Some(user.id)
          let is_admin_status = case user.email {
            Some(email) -> string.ends_with(email, "@example.com")
            None -> False
          }
          let new_fetch_state = Loaded(Some(user))
          // Update child model synchronously
          let #(updated_accom_model, accom_effect) =
            update_accomplishments(
              model.accomplishments_model,
              accomplishments.SetUserId(user_id),
            )
          let updated_parent_model =
            Model(
              ..model,
              supabase_user: new_fetch_state,
              is_admin: is_admin_status,
              accomplishments_model: updated_accom_model,
            )
          #(updated_parent_model, accom_effect)
          // Return updated parent model and effect from child
        }
        Ok(None) -> {
          // No user found (successful fetch, empty result)
          let user_id = None
          let is_admin_status = False
          let new_fetch_state = Loaded(None)
          // Update child model synchronously
          let #(updated_accom_model, accom_effect) =
            update_accomplishments(
              model.accomplishments_model,
              accomplishments.SetUserId(user_id),
            )
          let updated_parent_model =
            Model(
              ..model,
              supabase_user: new_fetch_state,
              is_admin: is_admin_status,
              accomplishments_model: updated_accom_model,
            )
          #(updated_parent_model, accom_effect)
        }
        Error(err_msg) -> {
          // Error fetching user
          let user_id = None
          // No user ID available
          let is_admin_status = False
          // Assume not admin on error
          let new_fetch_state = Errored(err_msg)
          // Update child model synchronously (with None user)
          let #(updated_accom_model, accom_effect) =
            update_accomplishments(
              model.accomplishments_model,
              accomplishments.SetUserId(user_id),
            )
          let updated_parent_model =
            Model(
              ..model,
              supabase_user: new_fetch_state,
              is_admin: is_admin_status,
              accomplishments_model: updated_accom_model,
            )
          #(updated_parent_model, accom_effect)
        }
      }

      // Map the child effect before returning
      #(new_model, effect.map(child_effect, AccomplishmentsMsg))
    }

    LogoutCompleted(result) -> {
      // When logout completes, update parent state and child state
      case result {
        Ok(_) -> {
          let #(updated_accom_model, accom_effect) =
            update_accomplishments(
              model.accomplishments_model,
              accomplishments.SetUserId(None),
            )
          let updated_parent_model =
            Model(
              ..model,
              supabase_user: Loaded(None),
              is_admin: False,
              accomplishments_model: updated_accom_model,
            )
          #(updated_parent_model, effect.map(accom_effect, AccomplishmentsMsg))
        }
        Error(err) -> {
          // Don't update child state if logout itself failed?
          // Or maybe still set child user to None?
          // Let's not update child on logout failure for now.
          echo { "Logout FFI error: " <> err }
          #(model, effect.none())
        }
      }
    }

    AccomplishmentsMsg(acc_msg) -> {
      let #(new_acc_model, acc_effect) =
        update_accomplishments(model.accomplishments_model, acc_msg)
      #(
        Model(..model, accomplishments_model: new_acc_model),
        effect.map(acc_effect, AccomplishmentsMsg),
      )
    }
  }
}

// Render the app UI
pub fn view(model: Model) -> Element(Msg) {
  let current_nav_model_for_view =
    nav.Model(..model.nav_model, user_state: model.supabase_user)

  html.div([attribute.class("app-container")], [
    element.map(nav.view(current_nav_model_for_view), NavMsg),
    view_main_content(model),
  ])
}

// Helper function to render the main content based on the current page
fn view_main_content(model: Model) -> Element(Msg) {
  case string.split(model.current_path, "/") {
    ["", ""] -> {
      element.map(view_landing(model.landing_model), LandingMsg)
    }
    ["", "project", _id] -> {
      case model.project_detail_model {
        Some(pd_model) ->
          element.map(view_project_detail(pd_model), ProjectDetailMsg)
        None -> html.div([], [html.text("Loading project details page...")])
      }
    }
    ["", "projects"] ->
      element.map(projects.view(model.projects_model), ProjectsMsg)
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
      element.map(view_settings(model.settings_model), SettingsMsg)
    ["", "accomplishments"] ->
      element.map(
        view_accomplishments(model.accomplishments_model),
        AccomplishmentsMsg,
      )
    _ -> view_fallback_page()
  }
}

// Fallback page content (previously view_home_page)
fn view_fallback_page() -> Element(Msg) {
  html.div([attribute.class("page fallback-page")], [
    html.h2([], [html.text("Page Not Found")]),
    html.p([], [
      html.text("The page you are looking for does not exist."),
      html.a([attribute.href("/"), event.on_click(PathChanged("/"))], [
        html.text("Go to Homepage"),
      ]),
    ]),
  ])
}

// Tools page content
// fn view_tools_page() -> Element(Msg) {
//   html.div([attribute.class("page tools-page")], [
//     html.h2([], [html.text("Developer Tools")]),
//     html.p([], [html.text("Browse our collection of development tools.")]),
//   ])
// }

// // About page content
// fn view_about_page() -> Element(Msg) {
//   html.div([attribute.class("page about-page")], [
//     html.h2([], [html.text("About instance.select")]),
//     html.p([], [
//       html.text(
//         "instance.select provides specialized tools for developers and creative professionals.",
//       ),
//     ]),
//   ])
// }

// Helper function to handle routing logic
fn handle_route_change(model: Model, path: String) -> #(Model, Effect(Msg)) {
  echo { "Handle route change to: " <> path }
  let new_model = Model(..model, current_path: path)

  case string.split(path, "/") {
    ["", ""] -> {
      #(Model(..new_model, project_detail_model: None), effect.none())
    }
    ["", "project", id] -> {
      let flags = project_detail.Flags(project_id: id)
      let #(pd_model, pd_effect) = init_project_detail(flags)
      #(
        Model(..new_model, project_detail_model: Some(pd_model)),
        effect.map(pd_effect, ProjectDetailMsg),
      )
    }
    ["", "settings"]
    | ["", "projects"]
    | ["", "access-content"]
    | ["", "partner-progress"]
    | ["", "accomplishments"] -> {
      #(Model(..new_model, project_detail_model: None), effect.none())
    }
    _ -> {
      #(Model(..new_model, project_detail_model: None), effect.none())
    }
  }
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
