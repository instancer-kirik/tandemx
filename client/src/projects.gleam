import gleam/dynamic.{type Dynamic}
import gleam/io
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(projects: List(Project))
}

pub type ProjectCategory {
  WebApplication
  MobileApplication
  DesktopApplication
  Game
  LibraryOrFramework
  ApiService
  HardwareOrIot
  DataScienceOrMl
  CreativeAssetBlender
  CreativeAssetOther
  ScriptOrUtility
  Documentation
  Research
  OtherCategory
}

pub type Project {
  Project(
    id: String,
    name: String,
    description: String,
    status: ProjectStatus,
    category: ProjectCategory,
    created_at: String,
    due_date: Option(String),
    owner: String,
    collaborators: List(String),
    tags: List(String),
    priority: Priority,
    system_environment_info: Option(Dynamic),
    source_control_details: Option(Dynamic),
    documentation_references: Option(Dynamic),
  )
}

pub type ProjectStatus {
  Planning
  Active
  OnHold
  ProjectCompleted
  Archived
}

pub type Priority {
  Low
  Medium
  High
  Urgent
}

pub type Msg {
  NavigateTo(String)
  ExpressInterest(String)
  CreateProject(Project)
  UpdateProject(Project)
  DeleteProject(String)
  ProjectsFetched(Result(List(Project), String))
  FetchProjects
}

pub fn init(_: Nil) -> #(Model, Effect(Msg)) {
  #(Model(projects: []), fetch_projects_effect())
  // #(Model(projects: []), effect.none()) // Return no initial effect
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(path) -> {
      let _ = set_window_location("/project/" <> path)
      #(model, effect.none())
    }
    ExpressInterest(project_name) -> {
      let _ = set_window_location("/interest/" <> project_name)
      #(model, effect.none())
    }
    CreateProject(project) -> {
      #(Model(projects: [project, ..model.projects]), effect.none())
    }
    UpdateProject(updated_project) -> {
      let updated_list =
        list.map(model.projects, fn(p) {
          case p.id == updated_project.id {
            True -> updated_project
            False -> p
          }
        })
      #(Model(projects: updated_list), effect.none())
    }
    DeleteProject(id) -> {
      let updated_list = list.filter(model.projects, fn(p) { p.id != id })
      #(Model(projects: updated_list), effect.none())
    }
    FetchProjects -> {
      #(model, fetch_projects_effect())
    }
    ProjectsFetched(result) -> {
      io.println(
        "Received ProjectsFetched with result (update projects.gleam):",
      )

      case result {
        Ok(projects) -> #(Model(projects: projects), effect.none())
        Error(err) -> {
          io.println("Error fetching projects: " <> err)
          #(model, effect.none())
        }
      }
    }
  }
}

@external(javascript, "./projects_ffi.js", "setWindowLocation")
fn set_window_location(path: String) -> Nil

@external(javascript, "./projects_ffi.js", "supabaseFetchProjects")
fn fetch_projects_from_supabase_ffi() -> Promise(Result(List(Project), String))

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("main-content")], [
    view_header(),
    html.div([class("projects-page")], [
      html.div(
        [class("projects-grid")],
        list.map(model.projects, view_project_card),
      ),
    ]),
  ])
}

fn view_header() -> Element(Msg) {
  html.div([class("page-header")], [
    html.h1([class("page-title")], [html.text("Projects Overview")]),
    html.p([class("page-description")], [
      html.text("List of all active and planned projects."),
    ]),
  ])
}

fn view_project_card(project: Project) -> Element(Msg) {
  html.div([class("project-card")], [
    html.div([class("project-header")], [
      html.h3([class("project-name")], [html.text(project.name)]),
      html.span([class("project-category")], [
        html.text("Category: " <> category_to_string(project.category)),
      ]),
    ]),
    html.span([class("project-status " <> status_to_class(project.status))], [
      html.text(status_to_string(project.status)),
    ]),
    html.p([class("project-description")], [html.text(project.description)]),
    html.div([class("project-footer")], [
      html.span([class("project-owner")], [
        html.text("Owner: " <> project.owner),
      ]),
      case project.due_date {
        Some(date) ->
          html.span([class("project-due-date")], [html.text("Due: " <> date)])
        None -> element.none()
      },
      case project.system_environment_info {
        Some(_) ->
          html.span([class("project-info-tag")], [html.text("Has Env Info")])
        None -> element.none()
      },
      case project.documentation_references {
        Some(_) ->
          html.span([class("project-info-tag")], [html.text("Has Docs")])
        None -> element.none()
      },
    ]),
    html.div([class("project-actions")], [
      html.button(
        [class("project-link"), event.on_click(NavigateTo(project.id))],
        [html.text("View Details")],
      ),
      html.button(
        [class("interest-btn"), event.on_click(ExpressInterest(project.name))],
        [html.text("Express Interest")],
      ),
    ]),
  ])
}

fn status_to_string(status: ProjectStatus) -> String {
  case status {
    Planning -> "Planning"
    Active -> "Active"
    OnHold -> "On Hold"
    ProjectCompleted -> "Completed"
    Archived -> "Archived"
  }
}

fn status_to_class(status: ProjectStatus) -> String {
  case status {
    Planning -> "status-planning"
    Active -> "status-active"
    OnHold -> "status-on-hold"
    ProjectCompleted -> "status-completed"
    Archived -> "status-archived"
  }
}

fn category_to_string(category: ProjectCategory) -> String {
  case category {
    WebApplication -> "Web Application"
    MobileApplication -> "Mobile Application"
    DesktopApplication -> "Desktop Application"
    Game -> "Game"
    LibraryOrFramework -> "Library/Framework"
    ApiService -> "API Service"
    HardwareOrIot -> "Hardware/IoT"
    DataScienceOrMl -> "Data Science/ML"
    CreativeAssetBlender -> "Creative Asset (Blender)"
    CreativeAssetOther -> "Creative Asset (Other)"
    ScriptOrUtility -> "Script/Utility"
    Documentation -> "Documentation"
    Research -> "Research"
    OtherCategory -> "Other"
  }
}

pub fn fetch_projects_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    fetch_projects_from_supabase_ffi()
    |> promise.map(fn(res) { ProjectsFetched(res) })
    |> promise.tap(fn(msg_to_dispatch) { dispatch(msg_to_dispatch) })

    Nil
  })
}

pub fn main() {
  let app = lustre.application(init, update, view)
  // Assuming projects page doesn't need flags, use Nil
  // Mount to the standard #app div
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
