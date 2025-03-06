import components/nav
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

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

pub fn main(_: Nil) -> Nil {
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

pub fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [
      element.map(nav.view(), NavMsg),
      html.main([attribute.class("projects-app")], [
        view_header(),
        view_tabs(model.selected_tab),
        html.div([attribute.class("main-content")], [
          case model.selected_tab {
            Overview -> view_overview(model)
            Projects -> view_projects(model)
            Tasks -> view_tasks(model)
            Charts -> view_charts(model)
            Works -> view_works(model)
          },
        ]),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Project Organization")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage projects, tasks, charts, and works in one place"),
    ]),
  ])
}

fn view_tabs(selected_tab: Tab) -> Element(Msg) {
  html.div([attribute.class("tabs")], [
    view_tab(Overview, "Overview", selected_tab),
    view_tab(Projects, "Projects", selected_tab),
    view_tab(Tasks, "Tasks", selected_tab),
    view_tab(Charts, "Charts", selected_tab),
    view_tab(Works, "Works", selected_tab),
  ])
}

fn view_tab(tab: Tab, label: String, selected_tab: Tab) -> Element(Msg) {
  html.button(
    [
      attribute.class(case selected_tab == tab {
        True -> "tab active"
        False -> "tab"
      }),
      event.on_click(SelectTab(tab)),
    ],
    [html.text(label)],
  )
}

fn view_overview(model: Model) -> Element(Msg) {
  html.div([attribute.class("overview-section")], [
    html.div([attribute.class("stats-grid")], [
      view_stat_card(
        "Total Projects",
        int.to_string(list.length(model.projects)),
      ),
      view_stat_card(
        "Active Tasks",
        int.to_string(
          list.filter(model.tasks, fn(t) { t.status == InProgress })
          |> list.length,
        ),
      ),
      view_stat_card("Charts", int.to_string(list.length(model.charts))),
      view_stat_card("Works", int.to_string(list.length(model.works))),
    ]),
    html.div([attribute.class("recent-activity")], [
      html.h2([], [html.text("Recent Activity")]),
      view_recent_tasks(model.tasks),
    ]),
  ])
}

fn view_stat_card(label: String, value: String) -> Element(Msg) {
  html.div([attribute.class("stat-card")], [
    html.div([attribute.class("stat-value")], [html.text(value)]),
    html.div([attribute.class("stat-label")], [html.text(label)]),
  ])
}

fn view_recent_tasks(tasks: List(Task)) -> Element(Msg) {
  html.div(
    [attribute.class("recent-tasks")],
    list.sort(tasks, fn(a, b) { string.compare(a.id, b.id) })
      |> list.take(5)
      |> list.map(view_task_card),
  )
}

fn view_task_card(task: Task) -> Element(Msg) {
  html.div([attribute.class("task-card")], [
    html.div([attribute.class("task-header")], [
      html.h3([], [html.text(task.title)]),
      html.span(
        [
          attribute.class(
            "task-status "
            <> case task.status {
              Todo -> "status-todo"
              InProgress -> "status-progress"
              Review -> "status-review"
              Done -> "status-done"
              Blocked -> "status-blocked"
            },
          ),
        ],
        [
          html.text(case task.status {
            Todo -> "To Do"
            InProgress -> "In Progress"
            Review -> "In Review"
            Done -> "Done"
            Blocked -> "Blocked"
          }),
        ],
      ),
    ]),
    html.div([attribute.class("task-details")], [
      html.p([], [html.text(task.description)]),
      case task.assignee {
        Some(assignee) ->
          html.div([attribute.class("task-assignee")], [
            html.text("Assigned to: " <> assignee),
          ])
        None -> html.text("")
      },
      case task.due_date {
        Some(date) ->
          html.div([attribute.class("task-due-date")], [
            html.text("Due: " <> date),
          ])
        None -> html.text("")
      },
    ]),
    html.div([attribute.class("task-progress")], [
      html.div(
        [
          attribute.class("progress-bar"),
          attribute.style(
            "width: "
            <> int.to_string(task.progress)
            <> "%; background: #4CAF50",
          ),
        ],
        [],
      ),
    ]),
  ])
}

fn view_projects(model: Model) -> Element(Msg) {
  html.div([attribute.class("projects-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Projects")]),
      html.button([attribute.class("btn-primary")], [html.text("New Project")]),
    ]),
    html.div(
      [attribute.class("projects-grid")],
      list.map(model.projects, view_project_card),
    ),
  ])
}

fn view_project_card(project: Project) -> Element(Msg) {
  html.div([attribute.class("project-card")], [
    html.div([attribute.class("project-header")], [
      html.h3([], [html.text(project.name)]),
      html.span(
        [
          attribute.class(
            "project-status "
            <> case project.status {
              Planning -> "status-planning"
              Active -> "status-active"
              OnHold -> "status-hold"
              ProjectCompleted -> "status-completed"
              Archived -> "status-archived"
            },
          ),
        ],
        [
          html.text(case project.status {
            Planning -> "Planning"
            Active -> "Active"
            OnHold -> "On Hold"
            ProjectCompleted -> "Completed"
            Archived -> "Archived"
          }),
        ],
      ),
    ]),
    html.p([attribute.class("project-description")], [
      html.text(project.description),
    ]),
    html.div([attribute.class("project-meta")], [
      html.div([attribute.class("project-owner")], [
        html.text("Owner: " <> project.owner),
      ]),
      case project.due_date {
        Some(date) ->
          html.div([attribute.class("project-due-date")], [
            html.text("Due: " <> date),
          ])
        None -> html.text("")
      },
    ]),
    html.div([attribute.class("project-stats")], [
      html.div([attribute.class("stat")], [
        html.text("Tasks: " <> int.to_string(list.length(project.tasks))),
      ]),
      html.div([attribute.class("stat")], [
        html.text("Charts: " <> int.to_string(list.length(project.charts))),
      ]),
      html.div([attribute.class("stat")], [
        html.text("Works: " <> int.to_string(list.length(project.works))),
      ]),
    ]),
    html.div([attribute.class("project-tags")], [
      html.div(
        [attribute.class("tags")],
        list.map(project.tags, fn(tag) {
          html.span([attribute.class("tag")], [html.text(tag)])
        }),
      ),
    ]),
  ])
}

fn view_tasks(model: Model) -> Element(Msg) {
  html.div([attribute.class("tasks-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Tasks")]),
      html.button([attribute.class("btn-primary")], [html.text("New Task")]),
    ]),
    view_task_filters(model.filters),
    html.div(
      [attribute.class("tasks-grid")],
      list.map(model.tasks, view_task_card),
    ),
  ])
}

fn view_task_filters(filters: Filters) -> Element(Msg) {
  html.div([attribute.class("filters-section")], [
    html.div([attribute.class("filter-group")], [
      html.label([], [html.text("Status")]),
      html.select([], [
        html.option([attribute.value("")], [html.text("All")]),
        html.option([attribute.value("todo")], [html.text("To Do")]),
        html.option([attribute.value("progress")], [html.text("In Progress")]),
        html.option([attribute.value("review")], [html.text("In Review")]),
        html.option([attribute.value("done")], [html.text("Done")]),
        html.option([attribute.value("blocked")], [html.text("Blocked")]),
      ]),
    ]),
    html.div([attribute.class("filter-group")], [
      html.label([], [html.text("Priority")]),
      html.select([], [
        html.option([attribute.value("")], [html.text("All")]),
        html.option([attribute.value("low")], [html.text("Low")]),
        html.option([attribute.value("medium")], [html.text("Medium")]),
        html.option([attribute.value("high")], [html.text("High")]),
        html.option([attribute.value("urgent")], [html.text("Urgent")]),
      ]),
    ]),
  ])
}

fn view_charts(model: Model) -> Element(Msg) {
  html.div([attribute.class("charts-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Charts")]),
      html.button([attribute.class("btn-primary")], [html.text("New Chart")]),
    ]),
    html.div(
      [attribute.class("charts-grid")],
      list.map(model.charts, view_chart_card),
    ),
  ])
}

fn view_chart_card(chart: Chart) -> Element(Msg) {
  html.div([attribute.class("chart-card")], [
    html.div([attribute.class("chart-header")], [
      html.h3([], [html.text(chart.title)]),
      html.span([attribute.class("chart-type")], [
        html.text(case chart.chart_type {
          Timeline -> "Timeline"
          Gantt -> "Gantt"
          Kanban -> "Kanban"
          Mindmap -> "Mind Map"
          Flowchart -> "Flowchart"
          Custom(name) -> name
        }),
      ]),
    ]),
    html.p([attribute.class("chart-description")], [
      html.text(chart.description),
    ]),
    html.div([attribute.class("chart-meta")], [
      html.div([attribute.class("chart-creator")], [
        html.text("Created by: " <> chart.creator),
      ]),
      html.div([attribute.class("chart-date")], [
        html.text("Last updated: " <> chart.last_updated),
      ]),
    ]),
  ])
}

fn view_works(model: Model) -> Element(Msg) {
  html.div([attribute.class("works-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Works")]),
      html.button([attribute.class("btn-primary")], [html.text("New Work")]),
    ]),
    html.div(
      [attribute.class("works-grid")],
      list.map(model.works, view_work_card),
    ),
  ])
}

fn view_work_card(work: Work) -> Element(Msg) {
  html.div([attribute.class("work-card")], [
    html.div([attribute.class("work-header")], [
      html.h3([], [html.text(work.title)]),
      html.span(
        [
          attribute.class(
            "work-status "
            <> case work.status {
              Draft -> "status-draft"
              InReview -> "status-review"
              Approved -> "status-approved"
              Rejected -> "status-rejected"
              WorkCompleted -> "status-completed"
            },
          ),
        ],
        [
          html.text(case work.status {
            Draft -> "Draft"
            InReview -> "In Review"
            Approved -> "Approved"
            Rejected -> "Rejected"
            WorkCompleted -> "Completed"
          }),
        ],
      ),
    ]),
    html.p([attribute.class("work-description")], [html.text(work.description)]),
    html.div([attribute.class("work-meta")], [
      html.div([attribute.class("work-type")], [
        html.text(case work.work_type {
          Design -> "Design"
          Development -> "Development"
          Research -> "Research"
          Documentation -> "Documentation"
          Testing -> "Testing"
          Other(name) -> name
        }),
      ]),
      html.div([attribute.class("work-assignees")], [
        html.text("Assignees: " <> string.join(work.assignees, ", ")),
      ]),
    ]),
    html.div([attribute.class("work-artifacts")], [
      html.h4([], [html.text("Artifacts")]),
      html.div(
        [attribute.class("artifacts-list")],
        list.map(work.artifacts, view_artifact),
      ),
    ]),
  ])
}

fn view_artifact(artifact: Artifact) -> Element(Msg) {
  html.div([attribute.class("artifact-item")], [
    html.a([attribute.href(artifact.url), attribute.target("_blank")], [
      html.text(artifact.name),
    ]),
    html.span([attribute.class("artifact-meta")], [
      html.text(artifact.file_type <> " • " <> artifact.created_at),
    ]),
  ])
}
