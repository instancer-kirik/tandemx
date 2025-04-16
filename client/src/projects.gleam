import components/nav
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import project_catalog.{type ProjectInfo}

pub type Model {
  Model(
    nav_open: Bool,
    selected_tab: Tab,
    projects: List(Project),
    tasks: List(Task),
    charts: List(Chart),
    works: List(Work),
    filters: Filters,
  )
}

pub type Tab {
  Overview
  Projects
  Tasks
  Charts
  Works
}

pub type Project {
  Project(
    id: String,
    name: String,
    description: String,
    status: ProjectStatus,
    created_at: String,
    due_date: Option(String),
    owner: String,
    collaborators: List(String),
    tasks: List(String),
    charts: List(String),
    works: List(String),
    tags: List(String),
    priority: Priority,
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

pub type Task {
  Task(
    id: String,
    title: String,
    description: String,
    status: TaskStatus,
    project_id: Option(String),
    assignee: Option(String),
    due_date: Option(String),
    priority: Priority,
    tags: List(String),
    dependencies: List(String),
    work_hours: Float,
    progress: Int,
  )
}

pub type TaskStatus {
  Todo
  InProgress
  Review
  Done
  Blocked
}

pub type Chart {
  Chart(
    id: String,
    title: String,
    description: String,
    project_id: Option(String),
    chart_type: ChartType,
    data_source: String,
    created_at: String,
    last_updated: String,
    creator: String,
    shared_with: List(String),
  )
}

pub type ChartType {
  Timeline
  Gantt
  Kanban
  Mindmap
  Flowchart
  Custom(String)
}

pub type Work {
  Work(
    id: String,
    title: String,
    description: String,
    project_id: Option(String),
    work_type: WorkType,
    status: WorkStatus,
    creator: String,
    assignees: List(String),
    dependencies: List(String),
    artifacts: List(Artifact),
  )
}

pub type WorkType {
  Design
  Development
  Research
  Documentation
  Testing
  Other(String)
}

pub type WorkStatus {
  Draft
  InReview
  Approved
  Rejected
  WorkCompleted
}

pub type Artifact {
  Artifact(
    id: String,
    name: String,
    file_type: String,
    url: String,
    created_at: String,
    creator: String,
  )
}

pub type Filters {
  Filters(
    status: Option(ProjectStatus),
    priority: Option(Priority),
    assignee: Option(String),
    tags: List(String),
    date_range: Option(#(String, String)),
  )
}

pub type Msg {
  NavigateTo(String)
  ExpressInterest(String)
  NavMsg(nav.Msg)
  SelectTab(Tab)
  CreateProject(Project)
  UpdateProject(Project)
  DeleteProject(String)
  CreateTask(Task)
  UpdateTask(Task)
  DeleteTask(String)
  CreateChart(Chart)
  UpdateChart(Chart)
  DeleteChart(String)
  CreateWork(Work)
  UpdateWork(Work)
  DeleteWork(String)
  UpdateFilters(Filters)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_: Nil) -> #(Model, effect.Effect(Msg)) {
  let sample_project =
    Project(
      id: "proj_001",
      name: "Platform Integration",
      description: "Integrate chartspace and construct works with task management",
      status: Active,
      created_at: "2024-03-20",
      due_date: Some("2024-04-20"),
      owner: "admin",
      collaborators: ["user1", "user2"],
      tasks: ["task_001", "task_002"],
      charts: ["chart_001"],
      works: ["work_001"],
      tags: ["integration", "platform"],
      priority: High,
    )

  let sample_tasks = [
    Task(
      id: "task_001",
      title: "Design Integration Architecture",
      description: "Create system architecture for platform integration",
      status: InProgress,
      project_id: Some("proj_001"),
      assignee: Some("user1"),
      due_date: Some("2024-03-25"),
      priority: High,
      tags: ["design", "architecture"],
      dependencies: [],
      work_hours: 20.0,
      progress: 60,
    ),
    Task(
      id: "task_002",
      title: "Implement Chart Integration",
      description: "Integrate chartspace functionality with project view",
      status: Todo,
      project_id: Some("proj_001"),
      assignee: Some("user2"),
      due_date: Some("2024-03-30"),
      priority: High,
      tags: ["development", "charts"],
      dependencies: ["task_001"],
      work_hours: 30.0,
      progress: 0,
    ),
  ]

  let sample_chart =
    Chart(
      id: "chart_001",
      title: "Project Timeline",
      description: "Integration project timeline and milestones",
      project_id: Some("proj_001"),
      chart_type: Gantt,
      data_source: "project_timeline.json",
      created_at: "2024-03-20",
      last_updated: "2024-03-20",
      creator: "admin",
      shared_with: ["user1", "user2"],
    )

  let sample_work =
    Work(
      id: "work_001",
      title: "Integration Design Document",
      description: "Technical design document for platform integration",
      project_id: Some("proj_001"),
      work_type: Design,
      status: InReview,
      creator: "user1",
      assignees: ["user1", "user2"],
      dependencies: [],
      artifacts: [
        Artifact(
          id: "art_001",
          name: "design_doc.pdf",
          file_type: "pdf",
          url: "/artifacts/design_doc.pdf",
          created_at: "2024-03-20",
          creator: "user1",
        ),
      ],
    )

  #(
    Model(
      nav_open: False,
      selected_tab: Overview,
      projects: [sample_project],
      tasks: sample_tasks,
      charts: [sample_chart],
      works: [sample_work],
      filters: Filters(
        status: None,
        priority: None,
        assignee: None,
        tags: [],
        date_range: None,
      ),
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NavigateTo(path) -> {
      let _ = set_window_location(path)
      #(model, effect.none())
    }
    ExpressInterest(project) -> {
      let _ = set_window_location("/" <> project <> "/interest")
      #(model, effect.none())
    }
    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> #(
          Model(..model, nav_open: !model.nav_open),
          effect.none(),
        )
      }
    }
    SelectTab(tab) -> #(Model(..model, selected_tab: tab), effect.none())
    CreateProject(project) -> #(
      Model(..model, projects: [project, ..model.projects]),
      effect.none(),
    )
    UpdateProject(project) -> #(
      Model(
        ..model,
        projects: list.map(model.projects, fn(p) {
          case p.id == project.id {
            True -> project
            False -> p
          }
        }),
      ),
      effect.none(),
    )
    DeleteProject(id) -> #(
      Model(
        ..model,
        projects: list.filter(model.projects, fn(p) { p.id != id }),
      ),
      effect.none(),
    )
    CreateTask(task) -> #(
      Model(..model, tasks: [task, ..model.tasks]),
      effect.none(),
    )
    UpdateTask(task) -> #(
      Model(
        ..model,
        tasks: list.map(model.tasks, fn(t) {
          case t.id == task.id {
            True -> task
            False -> t
          }
        }),
      ),
      effect.none(),
    )
    DeleteTask(id) -> #(
      Model(..model, tasks: list.filter(model.tasks, fn(t) { t.id != id })),
      effect.none(),
    )
    CreateChart(chart) -> #(
      Model(..model, charts: [chart, ..model.charts]),
      effect.none(),
    )
    UpdateChart(chart) -> #(
      Model(
        ..model,
        charts: list.map(model.charts, fn(c) {
          case c.id == chart.id {
            True -> chart
            False -> c
          }
        }),
      ),
      effect.none(),
    )
    DeleteChart(id) -> #(
      Model(..model, charts: list.filter(model.charts, fn(c) { c.id != id })),
      effect.none(),
    )
    CreateWork(work) -> #(
      Model(..model, works: [work, ..model.works]),
      effect.none(),
    )
    UpdateWork(work) -> #(
      Model(
        ..model,
        works: list.map(model.works, fn(w) {
          case w.id == work.id {
            True -> work
            False -> w
          }
        }),
      ),
      effect.none(),
    )
    DeleteWork(id) -> #(
      Model(..model, works: list.filter(model.works, fn(w) { w.id != id })),
      effect.none(),
    )
    UpdateFilters(filters) -> #(Model(..model, filters: filters), effect.none())
  }
}

@external(javascript, "./projects_ffi.js", "setWindowLocation")
fn set_window_location(path: String) -> Nil

pub fn view(model: Model) -> Element(Msg) {
  let container_class = case model.nav_open {
    True -> "app-container nav-open"
    False -> "app-container"
  }

  html.div([class(container_class)], [
    element.map(nav.view(), NavMsg),
    html.div([class("main-content")], [
      view_header(),
      html.div(
        [class("projects-page")],
        list.map(project_catalog.get_domains(), fn(domain) {
          let #(title, description) = domain
          view_domain_section(
            title,
            description,
            project_catalog.get_projects_by_domain(title)
              |> list.map(view_project_card),
          )
        }),
      ),
    ]),
  ])
}

fn view_header() -> Element(Msg) {
  html.div([class("page-header")], [
    html.h1([class("page-title")], [html.text("Our Projects")]),
    html.p([class("page-description")], [
      html.text(
        "Explore our comprehensive suite of tools designed to revolutionize creative business operations. From space management to payment processing, each project addresses specific industry needs while maintaining seamless integration with our ecosystem.",
      ),
    ]),
  ])
}

fn view_domain_section(
  title: String,
  description: String,
  projects: List(Element(Msg)),
) -> Element(Msg) {
  html.div([class("domain-section")], [
    html.div([class("domain-header")], [
      html.h2([class("domain-title")], [html.text(title)]),
      html.p([class("domain-description")], [html.text(description)]),
    ]),
    html.div([class("projects-grid")], projects),
  ])
}

fn view_project_card(project: ProjectInfo) -> Element(Msg) {
  html.div([class("project-card")], [
    html.div([class("project-header")], [
      html.span([class("project-emoji")], [html.text(project.emoji)]),
      html.h3([class("project-name")], [html.text(project.name)]),
      case project.source_url {
        Some(url) ->
          html.a(
            [
              class("source-link"),
              attribute.href(url),
              attribute.target("_blank"),
            ],
            [
              html.img([
                class("source-icon"),
                attribute.src("/assets/github.svg"),
                attribute.alt("Source Code"),
              ]),
            ],
          )
        None -> element.none()
      },
    ]),
    html.span(
      [
        class(
          "project-status "
          <> case project.status {
            "Active" -> "status-active"
            "Upcoming" -> "status-upcoming"
            _ -> ""
          },
        ),
      ],
      [html.text(project.status)],
    ),
    html.p([class("project-description")], [html.text(project.description)]),
    html.ul(
      [class("project-features")],
      list.map(project.features, fn(feature) {
        html.li([], [
          html.span([class("feature-check")], [html.text("✓")]),
          html.text(feature),
        ])
      }),
    ),
    html.div([class("project-tech")], [
      html.h4([class("tech-title")], [html.text("Tech Stack")]),
      html.div(
        [class("tech-stack")],
        list.map(project.tech_stack, fn(tech) {
          html.span([class("tech-tag")], [html.text(tech)])
        }),
      ),
    ]),
    html.div([class("project-actions")], [
      html.a([class("project-link"), event.on_click(NavigateTo(project.path))], [
        html.text("Learn More"),
      ]),
      html.button(
        [class("interest-btn"), event.on_click(ExpressInterest(project.name))],
        [html.text("Express Interest")],
      ),
    ]),
  ])
}
