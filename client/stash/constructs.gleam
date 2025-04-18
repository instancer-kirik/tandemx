import components/nav
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    nav_open: Bool,
    active_tab: Tab,
    works: List(Work),
    personas: List(Persona),
    social_metrics: SocialMetrics,
    platform_metrics: PlatformMetrics,
  )
}

pub type Tab {
  WorksTab
  PersonasTab
  SocialTab
  MetricsTab
}

pub type Work {
  Work(
    id: Int,
    title: String,
    category: String,
    status: WorkStatus,
    created_at: String,
    creator: User,
    collaborators: List(User),
    metrics: WorkMetrics,
  )
}

pub type WorkStatus {
  Draft
  InProgress
  Completed
  Archived
}

pub type User {
  User(
    id: Int,
    name: String,
    role: String,
    trust_score: Int,
    verification_level: VerificationLevel,
  )
}

pub type VerificationLevel {
  Basic
  Verified
  Institution
  Premium
}

pub type WorkMetrics {
  WorkMetrics(views: Int, shares: Int, reactions: Int, comments: Int)
}

pub type SocialMetrics {
  SocialMetrics(
    total_users: Int,
    verification_stats: VerificationStats,
    trust_distribution: List(#(Int, Int)),
    active_collaborations: Int,
    community_health: Int,
  )
}

pub type VerificationStats {
  VerificationStats(basic: Int, verified: Int, institution: Int, premium: Int)
}

pub type PlatformMetrics {
  PlatformMetrics(
    total_works: Int,
    active_works: Int,
    completion_rate: Float,
    avg_collaboration_size: Float,
    dispute_resolution_rate: Float,
  )
}

pub type Msg {
  NavMsg(nav.Msg)
  SetTab(Tab)
}

pub type Persona {
  Persona(
    id: Int,
    name: String,
    brand_type: BrandType,
    roles: List(Role),
    verification_level: VerificationLevel,
    trust_score: Int,
    bio: String,
    expertise: List(String),
    active_works: Int,
    completed_works: Int,
    metrics: PersonaMetrics,
  )
}

pub type BrandType {
  IndividualBrand
  InstitutionalBrand
  OrganizationalBrand
}

pub type Role {
  Role(title: String, category: String, experience_level: ExperienceLevel)
}

pub type ExperienceLevel {
  Novice
  Intermediate
  Expert
  Master
}

pub type PersonaMetrics {
  PersonaMetrics(
    reputation_score: Int,
    success_rate: Float,
    response_time: Int,
    endorsements: Int,
    total_collaborations: Int,
  )
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_works = [
    Work(
      id: 1,
      title: "Sample Work",
      category: "Demo",
      status: Draft,
      created_at: "2024-03-20",
      creator: User(1, "Demo User", "User", 80, Basic),
      collaborators: [],
      metrics: WorkMetrics(views: 0, shares: 0, reactions: 0, comments: 0),
    ),
  ]

  let sample_personas = [
    Persona(
      id: 1,
      name: "Demo Persona",
      brand_type: IndividualBrand,
      roles: [Role("User", "General", Novice)],
      verification_level: Basic,
      trust_score: 80,
      bio: "Demo persona for testing",
      expertise: ["Testing"],
      active_works: 1,
      completed_works: 0,
      metrics: PersonaMetrics(
        reputation_score: 80,
        success_rate: 1.0,
        response_time: 24,
        endorsements: 0,
        total_collaborations: 1,
      ),
    ),
  ]

  let social_metrics =
    SocialMetrics(
      total_users: 1,
      verification_stats: VerificationStats(
        basic: 1,
        verified: 0,
        institution: 0,
        premium: 0,
      ),
      trust_distribution: [#(80, 1)],
      active_collaborations: 1,
      community_health: 100,
    )

  let platform_metrics =
    PlatformMetrics(
      total_works: 1,
      active_works: 1,
      completion_rate: 0.0,
      avg_collaboration_size: 1.0,
      dispute_resolution_rate: 1.0,
    )

  #(
    Model(
      nav_open: False,
      active_tab: WorksTab,
      works: sample_works,
      personas: sample_personas,
      social_metrics: social_metrics,
      platform_metrics: platform_metrics,
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
    SetTab(tab) -> #(Model(..model, active_tab: tab), effect.none())
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
      html.main([attribute.class("constructs-app")], [
        html.header([attribute.class("app-header")], [
          html.h1([], [html.text("Platform Constructs")]),
          html.p([attribute.class("header-subtitle")], [
            html.text(
              "Explore created works, personas, social dynamics, and platform metrics",
            ),
          ]),
        ]),
        view_tabs(model.active_tab),
        case model.active_tab {
          WorksTab -> view_works(model.works)
          PersonasTab -> view_personas(model.personas)
          SocialTab -> view_social_metrics(model.social_metrics)
          MetricsTab -> view_platform_metrics(model.platform_metrics)
        },
      ]),
    ],
  )
}

fn view_tabs(active_tab: Tab) -> Element(Msg) {
  html.div([attribute.class("tabs")], [
    html.button(
      [
        attribute.class(case active_tab {
          WorksTab -> "tab active"
          _ -> "tab"
        }),
        event.on_click(SetTab(WorksTab)),
      ],
      [html.text("Works")],
    ),
    html.button(
      [
        attribute.class(case active_tab {
          PersonasTab -> "tab active"
          _ -> "tab"
        }),
        event.on_click(SetTab(PersonasTab)),
      ],
      [html.text("Personas")],
    ),
    html.button(
      [
        attribute.class(case active_tab {
          SocialTab -> "tab active"
          _ -> "tab"
        }),
        event.on_click(SetTab(SocialTab)),
      ],
      [html.text("Social")],
    ),
    html.button(
      [
        attribute.class(case active_tab {
          MetricsTab -> "tab active"
          _ -> "tab"
        }),
        event.on_click(SetTab(MetricsTab)),
      ],
      [html.text("Metrics")],
    ),
  ])
}

fn view_works(works: List(Work)) -> Element(Msg) {
  html.div([attribute.class("works-grid")], list.map(works, view_work))
}

fn view_work(work: Work) -> Element(Msg) {
  html.div([attribute.class("work-card")], [
    html.div([attribute.class("work-header")], [
      html.span([attribute.class("work-category")], [html.text(work.category)]),
      html.h3([attribute.class("work-title")], [html.text(work.title)]),
      html.span(
        [attribute.class("work-status " <> work_status_class(work.status))],
        [html.text(work_status_text(work.status))],
      ),
    ]),
    html.div([attribute.class("work-creator")], [
      html.div([attribute.class("user-info")], [
        html.span([attribute.class("user-name")], [html.text(work.creator.name)]),
        html.span([attribute.class("user-role")], [html.text(work.creator.role)]),
      ]),
      html.div([attribute.class("trust-score")], [
        html.text("Trust: " <> int.to_string(work.creator.trust_score)),
      ]),
    ]),
    html.div([attribute.class("work-collaborators")], [
      html.h4([], [html.text("Collaborators")]),
      html.div(
        [attribute.class("collaborator-list")],
        list.map(work.collaborators, view_collaborator),
      ),
    ]),
    html.div([attribute.class("work-metrics")], [
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Views")]),
        html.span([attribute.class("metric-value")], [
          html.text(int.to_string(work.metrics.views)),
        ]),
      ]),
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Shares")]),
        html.span([attribute.class("metric-value")], [
          html.text(int.to_string(work.metrics.shares)),
        ]),
      ]),
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Reactions")]),
        html.span([attribute.class("metric-value")], [
          html.text(int.to_string(work.metrics.reactions)),
        ]),
      ]),
    ]),
    html.div([attribute.class("work-footer")], [
      html.span([attribute.class("work-date")], [
        html.text("Created: " <> work.created_at),
      ]),
    ]),
  ])
}

fn view_collaborator(user: User) -> Element(Msg) {
  html.div([attribute.class("collaborator-item")], [
    html.div([attribute.class("user-info")], [
      html.span([attribute.class("user-name")], [html.text(user.name)]),
      html.span([attribute.class("user-role")], [html.text(user.role)]),
    ]),
    html.div([attribute.class("verification-badge")], [
      html.text(verification_level_text(user.verification_level)),
    ]),
  ])
}

fn view_social_metrics(metrics: SocialMetrics) -> Element(Msg) {
  html.div([attribute.class("metrics-section")], [
    html.h2([], [html.text("Social Metrics")]),
    html.p([], [html.text("This is a placeholder for social metrics content")]),
  ])
}

fn view_platform_metrics(metrics: PlatformMetrics) -> Element(Msg) {
  html.div([attribute.class("metrics-section")], [
    html.h2([], [html.text("Platform Metrics")]),
    html.p([], [html.text("This is a placeholder for platform metrics content")]),
  ])
}

fn view_personas(personas: List(Persona)) -> Element(Msg) {
  html.div([attribute.class("personas-grid")], [
    html.div([attribute.class("personas-header")], [
      html.button([attribute.class("btn-primary")], [
        html.text("Create New Persona"),
      ]),
    ]),
    html.div(
      [attribute.class("personas-list")],
      list.map(personas, view_persona),
    ),
  ])
}

fn view_persona(persona: Persona) -> Element(Msg) {
  html.div([attribute.class("persona-card")], [
    html.div([attribute.class("persona-header")], [
      html.span(
        [
          attribute.class(
            "brand-type-badge " <> brand_type_class(persona.brand_type),
          ),
        ],
        [html.text(brand_type_text(persona.brand_type))],
      ),
      html.h3([attribute.class("persona-name")], [html.text(persona.name)]),
      html.div([attribute.class("verification-level")], [
        html.text(verification_level_text(persona.verification_level)),
      ]),
    ]),
    html.div([attribute.class("persona-bio")], [html.text(persona.bio)]),
    html.div([attribute.class("persona-roles")], [
      html.h4([], [html.text("Roles")]),
      html.div(
        [attribute.class("roles-list")],
        list.map(persona.roles, view_role),
      ),
    ]),
    html.div([attribute.class("persona-expertise")], [
      html.h4([], [html.text("Expertise")]),
      html.div(
        [attribute.class("expertise-tags")],
        list.map(persona.expertise, fn(exp) {
          html.span([attribute.class("expertise-tag")], [html.text(exp)])
        }),
      ),
    ]),
    html.div([attribute.class("persona-metrics")], [
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Trust Score")]),
        html.span([attribute.class("metric-value")], [
          html.text(int.to_string(persona.trust_score)),
        ]),
      ]),
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Success Rate")]),
        html.span([attribute.class("metric-value")], [
          html.text(
            float.to_string(persona.metrics.success_rate *. 100.0) <> "%",
          ),
        ]),
      ]),
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Endorsements")]),
        html.span([attribute.class("metric-value")], [
          html.text(int.to_string(persona.metrics.endorsements)),
        ]),
      ]),
    ]),
    html.div([attribute.class("persona-footer")], [
      html.div([attribute.class("work-stats")], [
        html.span([], [
          html.text(
            int.to_string(persona.active_works)
            <> " Active / "
            <> int.to_string(persona.completed_works)
            <> " Completed Works",
          ),
        ]),
      ]),
      html.div([attribute.class("persona-actions")], [
        html.button([attribute.class("btn-secondary")], [
          html.text("Edit Persona"),
        ]),
      ]),
    ]),
  ])
}

fn view_role(role: Role) -> Element(Msg) {
  html.div([attribute.class("role-item")], [
    html.div([attribute.class("role-info")], [
      html.span([attribute.class("role-title")], [html.text(role.title)]),
      html.span([attribute.class("role-category")], [html.text(role.category)]),
    ]),
    html.span(
      [
        attribute.class(
          "experience-level " <> experience_level_class(role.experience_level),
        ),
      ],
      [html.text(experience_level_text(role.experience_level))],
    ),
  ])
}

fn work_status_class(status: WorkStatus) -> String {
  case status {
    Draft -> "status-draft"
    InProgress -> "status-progress"
    Completed -> "status-completed"
    Archived -> "status-archived"
  }
}

fn work_status_text(status: WorkStatus) -> String {
  case status {
    Draft -> "Draft"
    InProgress -> "In Progress"
    Completed -> "Completed"
    Archived -> "Archived"
  }
}

fn verification_level_text(level: VerificationLevel) -> String {
  case level {
    Basic -> "Basic"
    Verified -> "Verified"
    Institution -> "Institution"
    Premium -> "Premium"
  }
}

fn brand_type_class(brand_type: BrandType) -> String {
  case brand_type {
    IndividualBrand -> "brand-individual"
    InstitutionalBrand -> "brand-institution"
    OrganizationalBrand -> "brand-organization"
  }
}

fn brand_type_text(brand_type: BrandType) -> String {
  case brand_type {
    IndividualBrand -> "Individual"
    InstitutionalBrand -> "Institution"
    OrganizationalBrand -> "Organization"
  }
}

fn experience_level_class(level: ExperienceLevel) -> String {
  case level {
    Novice -> "level-novice"
    Intermediate -> "level-intermediate"
    Expert -> "level-expert"
    Master -> "level-master"
  }
}

fn experience_level_text(level: ExperienceLevel) -> String {
  case level {
    Novice -> "Novice"
    Intermediate -> "Intermediate"
    Expert -> "Expert"
    Master -> "Master"
  }
}
