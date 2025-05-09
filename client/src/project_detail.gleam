import access_content.{type FetchState, Errored, Idle, Loaded, Loading}

// import components/nav // No longer directly used by project_detail for rendering or msg handling
import gleam/dynamic.{type Dynamic}

import gleam/list
import gleam/option.{type Option, None, Some}

import gleam/string

import lustre/attribute.{class, href, target}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- Enum Types ---

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
  // Single definition
  Research
  // Single definition
  OtherCategory
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

pub type TaskStatus {
  Todo
  InProgress
  Review
  Blocked
  Done
}

pub type ComponentCategory {
  Feature
  Hardware
  SoftwareModule
  ArtAsset
  DataVisualization
  DocumentationSet
  Generic
  Ui
  Page
  Service
  Api
  Database
  Infrastructure
  OtherComponentCategory
}

pub type ComponentStatus {
  ComponentPlanned
  ComponentInProgress
  ComponentOnHold
  ComponentInReview
  ComponentCompleted
  ComponentDeprecated
  ComponentBlocked
}

// --- Core Data Types ---

pub type ProjectComponent {
  ProjectComponent(
    id: String,
    // Maps to UUID from DB
    project_id: String,
    // Maps to UUID from DB
    name: String,
    description: Option(String),
    category: ComponentCategory,
    status: ComponentStatus,
    attributes: Option(Dynamic),
    // For JSONB data
    dependencies: List(String),
    // List of other component IDs (UUIDs)
    created_at: String,
    // Timestamp string
    updated_at: String,
    // Timestamp string
  )
}

pub type Task {
  Task(
    id: String,
    // Maps to UUID
    project_id: String,
    // Maps to UUID
    component_id: Option(String),
    // Optional link to a ProjectComponent ID (UUID)
    title: String,
    description: Option(String),
    status: TaskStatus,
    priority: Priority,
    assignee_ids: List(String),
    // List of user IDs (UUIDs)
    target_date: Option(String),
    // Date string
    work_hours_estimated: Option(Float),
    progress_percent: Option(Int),
    dependencies: List(String),
    // List of other task IDs (UUIDs)
    tags: List(String),
    created_at: String,
    // Timestamp string
    updated_at: String,
    // Timestamp string
  )
}

// Placeholder types for potential data in ProjectComponent.attributes
// These can be used with dynamic.decode later if needed.
pub type ChartDetails {
  ChartDetails(chart_type: String, data_source: String)
}

pub type WorkDetails {
  WorkDetails(work_medium: String, primary_artifact_url: Option(String))
}

// Artifacts would likely be in a separate 'attachments' table linking to tasks or components.
// For now, an Artifact type if it were part of component attributes:
pub type ArtifactAttribute {
  ArtifactAttribute(name: String, file_type: String, url: String)
}

pub type Project {
  Project(
    id: String,
    // Maps to UUID
    name: String,
    description: Option(String),
    status: ProjectStatus,
    category: ProjectCategory,
    owner_id: Option(String),
    // User ID (UUID)
    repo_url: Option(String),
    tags: List(String),
    system_environment_info: Option(Dynamic),
    // JSONB
    source_control_details: Option(Dynamic),
    // JSONB
    documentation_references: Option(Dynamic),
    // JSONB
    created_at: String,
    // Timestamp string
    updated_at: String,
    // Timestamp string
    // Nested data
    tasks: List(Task),
    components: List(ProjectComponent),
  )
}

// --- Model for this page ---
pub type Model {
  Model(
    project_id: String,
    project_data: FetchState(Project),
    // nav_model: nav.Model, // Removed
  )
}

// --- Messages ---
pub type Msg {
  // NavMsg(nav.Msg) // Removed
  FetchProject
  ProjectFetched(Result(Project, String))
  CreateComponentFormSubmitted
  NewComponentNameChanged(String)
  NewComponentCategoryChanged(ComponentCategory)
  SaveNewComponent
  ComponentCreated(Result(ProjectComponent, String))
}

// --- Init ---
pub type Flags {
  Flags(project_id: String)
}

pub fn init(flags: Flags) -> #(Model, Effect(Msg)) {
  // let initial_nav_model = nav.init(Idle) // Removed
  let model =
    Model(
      project_id: flags.project_id,
      project_data: Loading,
      // nav_model: initial_nav_model, // Removed
    )
  #(model, fetch_project_effect(flags.project_id))
}

// --- Update ---
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    // NavMsg case removed
    FetchProject -> {
      #(
        Model(..model, project_data: Loading),
        fetch_project_effect(model.project_id),
      )
    }
    ProjectFetched(result) -> {
      case result {
        Ok(project) if project.id == model.project_id -> #(
          Model(..model, project_data: Loaded(project)),
          effect.none(),
        )
        Ok(wrong_project) -> {
          echo {
            "Fetched project ID "
            <> wrong_project.id
            <> " mismatches current ID "
            <> model.project_id
          }
          #(
            Model(..model, project_data: Errored("Fetched wrong project data")),
            effect.none(),
          )
        }
        Error(err) -> {
          echo { "Error fetching project details: " <> err }
          #(Model(..model, project_data: Errored(err)), effect.none())
        }
      }
    }
    NewComponentNameChanged(name) -> {
      echo { "New component name changed: " <> name }
      #(model, effect.none())
    }
    NewComponentCategoryChanged(category) -> {
      let _ = category
      echo { "New component category changed" }
      #(model, effect.none())
    }
    SaveNewComponent -> {
      echo { "Attempting to save new component..." }
      #(model, effect.none())
    }
    ComponentCreated(result) -> {
      case result {
        Ok(new_component) -> {
          case model.project_data {
            Loaded(p) -> {
              let updated_project =
                Project(
                  ..p,
                  components: list.append(p.components, [new_component]),
                )
              #(
                Model(..model, project_data: Loaded(updated_project)),
                effect.none(),
              )
            }
            _ -> {
              echo { "ComponentCreated received but no project loaded." }
              #(model, effect.none())
            }
          }
        }
        Error(err) -> {
          echo { "Failed to create component: " <> err }
          #(model, effect.none())
        }
      }
    }
    CreateComponentFormSubmitted -> {
      echo { "Create component form submitted" }
      #(model, effect.none())
    }
  }
}

@external(javascript, "./project_detail_ffi.js", "fetchProjectById")
fn fetch_project_by_id_ffi(id: String) -> Result(Project, String)

fn fetch_project_effect(id: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    dispatch(ProjectFetched(fetch_project_by_id_ffi(id)))
  })
}

// --- View ---
pub fn view(
  model: Model,
  // user_state: FetchState(Option(SupabaseUser)), // No longer needed if only for nav
) -> Element(Msg) {
  // Nav rendering removed, handled by app.gleam
  html.div([class("main-content project-detail-page")], [
    // Changed outer div to reflect it's now just the page content
    case model.project_data {
      Idle -> html.text("Initializing project details...")
      Loading -> html.div([class("loading-spinner")], [html.text("Loading...")])
      Errored(err) -> view_error_state(err)
      Loaded(project) -> view_project_loaded_state(project)
    },
  ])
}

fn view_error_state(error_message: String) -> Element(Msg) {
  html.div([class("error-message")], [
    html.h2([], [html.text("Error Loading Project")]),
    html.p([], [html.text(error_message)]),
    html.button([event.on_click(FetchProject)], [html.text("Retry")]),
  ])
}

fn view_project_loaded_state(project: Project) -> Element(Msg) {
  html.div([class("project-content")], [
    html.header([class("project-detail-header")], [
      html.h1([], [html.text(project.name)]),
      project.description
        |> option.map(fn(d) {
          html.p([class("project-description-text")], [html.text(d)])
        })
        |> option.unwrap(element.none()),
      html.div([class("project-meta")], [
        html.span([class("meta-item")], [
          html.text("Status: " <> project_status_to_string(project.status)),
        ]),
        html.span([class("meta-item")], [
          html.text(
            "Category: " <> project_category_to_string(project.category),
          ),
        ]),
        project.owner_id
          |> option.map(fn(o) {
            html.span([class("meta-item")], [html.text("Owner ID: " <> o)])
          })
          |> option.unwrap(element.none()),
        project.repo_url
          |> option.map(fn(r) {
            html.a([href(r), target("_blank"), class("meta-item repo-link")], [
              html.text("Repository"),
            ])
          })
          |> option.unwrap(element.none()),
      ]),
      view_dynamic_field_section(
        "System Environment",
        project.system_environment_info,
      ),
      view_dynamic_field_section(
        "Source Control Details",
        project.source_control_details,
      ),
      view_dynamic_field_section(
        "Documentation References",
        project.documentation_references,
      ),
    ]),
    html.section([class("project-components-section card-section")], [
      html.div([class("section-header")], [
        html.h2([], [html.text("Components")]),
      ]),
      case project.components {
        [] -> html.p([], [html.text("No components defined for this project.")])
        components ->
          html.ul(
            [class("component-list item-list")],
            list.map(components, view_component_item),
          )
      },
    ]),
    html.section([class("project-tasks-section card-section")], [
      html.div([class("section-header")], [html.h2([], [html.text("Tasks")])]),
      case project.tasks {
        [] -> html.p([], [html.text("No tasks assigned to this project.")])
        tasks ->
          html.ul(
            [class("task-list item-list")],
            list.map(tasks, view_task_item),
          )
      },
    ]),
  ])
}

fn view_dynamic_field_section(
  title: String,
  data: Option(Dynamic),
) -> Element(Msg) {
  case data {
    None -> element.none()
    Some(dyn_data) ->
      html.div([class("dynamic-data-preview card")], [
        html.h3([], [html.text(title)]),
        html.pre([class("code-block")], [html.text(string.inspect(dyn_data))]),
      ])
  }
}

fn view_component_item(component: ProjectComponent) -> Element(Msg) {
  html.li([class("component-item card")], [
    html.h4([class("item-title")], [html.text(component.name)]),
    component.description
      |> option.map(fn(d) {
        html.p([class("item-description")], [html.text(d)])
      })
      |> option.unwrap(element.none()),
    html.div([class("item-meta")], [
      html.span([class("meta-tag category")], [
        html.text(component_category_to_string(component.category)),
      ]),
      html.span(
        [class("meta-tag status " <> component_status_class(component.status))],
        [html.text(component_status_to_string(component.status))],
      ),
    ]),
    case component.attributes {
      Some(attrs) ->
        html.div([class("attributes-preview")], [
          html.text("Attributes: " <> string.inspect(attrs)),
        ])
      None -> element.none()
    },
    case component.dependencies {
      [] -> element.none()
      deps ->
        html.div([class("dependencies-list")], [
          html.h5([], [html.text("Depends on:")]),
          html.ul(
            [],
            list.map(deps, fn(dep_id) { html.li([], [html.text(dep_id)]) }),
          ),
        ])
    },
  ])
}

fn view_task_item(task: Task) -> Element(Msg) {
  html.li([class("task-item card")], [
    html.h4([class("item-title")], [html.text(task.title)]),
    task.description
      |> option.map(fn(d) {
        html.p([class("item-description")], [html.text(d)])
      })
      |> option.unwrap(element.none()),
    html.div([class("item-meta")], [
      html.span([class("meta-tag status " <> task_status_class(task.status))], [
        html.text(task_status_to_string(task.status)),
      ]),
      html.span([class("meta-tag priority")], [
        html.text(priority_to_string(task.priority)),
      ]),
      task.component_id
        |> option.map(fn(cid) {
          html.span([class("meta-tag component-link")], [
            html.text("C: " <> cid),
          ])
        })
        |> option.unwrap(element.none()),
    ]),
  ])
}

// --- Helper to_string and to_class functions for Enums ---

fn project_category_to_string(category: ProjectCategory) -> String {
  case category {
    WebApplication -> "Web App"
    MobileApplication -> "Mobile App"
    DesktopApplication -> "Desktop App"
    Game -> "Game"
    LibraryOrFramework -> "Library/Framework"
    ApiService -> "API Service"
    HardwareOrIot -> "Hardware/IoT"
    DataScienceOrMl -> "Data Science/ML"
    CreativeAssetBlender -> "Blender Asset"
    CreativeAssetOther -> "Creative Asset"
    ScriptOrUtility -> "Script/Utility"
    Documentation -> "Docs"
    Research -> "Research"
    OtherCategory -> "Other"
  }
}

fn project_status_to_string(status: ProjectStatus) -> String {
  case status {
    Planning -> "Planning"
    Active -> "Active"
    OnHold -> "On Hold"
    ProjectCompleted -> "Completed"
    Archived -> "Archived"
  }
}

fn priority_to_string(priority: Priority) -> String {
  case priority {
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
    Urgent -> "Urgent"
  }
}

fn task_status_to_string(status: TaskStatus) -> String {
  case status {
    Todo -> "To Do"
    InProgress -> "In Progress"
    Review -> "Review"
    Blocked -> "Blocked"
    Done -> "Done"
  }
}

fn task_status_class(status: TaskStatus) -> String {
  "status-"
  <> string.lowercase(task_status_to_string(status) |> string.replace(" ", "-"))
}

fn component_category_to_string(category: ComponentCategory) -> String {
  case category {
    Feature -> "Feature"
    Hardware -> "Hardware"
    SoftwareModule -> "Software Module"
    ArtAsset -> "Art Asset"
    DataVisualization -> "Data Visualization"
    DocumentationSet -> "Documentation Set"
    Generic -> "Generic"
    Ui -> "UI"
    Page -> "Page/Screen"
    Service -> "Service"
    Api -> "API"
    Database -> "Database"
    Infrastructure -> "Infrastructure"
    OtherComponentCategory -> "Other Component"
  }
}

fn component_status_to_string(status: ComponentStatus) -> String {
  case status {
    ComponentPlanned -> "Planned"
    ComponentInProgress -> "In Progress"
    ComponentOnHold -> "On Hold"
    ComponentInReview -> "In Review"
    ComponentCompleted -> "Completed"
    ComponentDeprecated -> "Deprecated"
    ComponentBlocked -> "Blocked"
  }
}

fn component_status_class(status: ComponentStatus) -> String {
  "status-"
  <> string.lowercase(
    component_status_to_string(status) |> string.replace(" ", "-"),
  )
}
