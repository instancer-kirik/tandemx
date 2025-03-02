import components/nav
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    partners: Dict(Int, Partner),
    goals: Dict(Int, Goal),
    interactions: Dict(Int, Interaction),
    reports: Dict(Int, Report),
    last_id: Int,
    nav_open: Bool,
  )
}

pub type Partner {
  Partner(
    id: Int,
    name: String,
    category: PartnerCategory,
    status: PartnerStatus,
    trust_score: Int,
    verification_level: VerificationLevel,
    goals_completed: Int,
    goals_in_progress: Int,
    balance_usd: Float,
    balance_ngn: Float,
    payment_currency: Currency,
    last_transaction_date: String,
  )
}

pub type PartnerCategory {
  Vendor
  Supplier
  Distributor
  ServiceProvider
  Investor
  Strategic
}

pub type PartnerStatus {
  Active
  OnHold
  Inactive
  Terminated
}

pub type VerificationLevel {
  Basic
  Verified
  Institution
  Premium
}

pub type Goal {
  Goal(
    id: Int,
    partner_id: Int,
    title: String,
    description: String,
    target_date: String,
    status: GoalStatus,
    progress: Float,
    metrics: List(Metric),
  )
}

pub type GoalStatus {
  Planned
  InProgress
  Completed
  Cancelled
}

pub type Metric {
  Metric(name: String, target: Float, current: Float)
}

pub type Interaction {
  Interaction(
    id: Int,
    partner_id: Int,
    date: String,
    interaction_type: InteractionType,
    outcome: InteractionOutcome,
    notes: String,
  )
}

pub type InteractionType {
  Meeting
  Negotiation
  Review
  Proposal
  Contract
}

pub type InteractionOutcome {
  Successful
  Pending
  Rejected
  Inconclusive
}

pub type Report {
  Report(
    id: Int,
    partner_id: Int,
    period: String,
    goals_summary: GoalsSummary,
    interactions_summary: InteractionsSummary,
    recommendations: List(String),
  )
}

pub type GoalsSummary {
  GoalsSummary(
    total: Int,
    completed: Int,
    in_progress: Int,
    success_rate: Float,
  )
}

pub type InteractionsSummary {
  InteractionsSummary(
    total: Int,
    successful: Int,
    rejected: Int,
    success_rate: Float,
  )
}

pub type Currency {
  USD
  NGN
}

pub type Msg {
  AddPartner(Partner)
  UpdatePartner(Int, Partner)
  DeletePartner(Int)
  AddGoal(Goal)
  UpdateGoal(Int, Goal)
  DeleteGoal(Int)
  AddInteraction(Interaction)
  UpdateInteraction(Int, Interaction)
  GenerateReport(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub fn init(_) {
  let sample_partners =
    [
      #(
        1,
        Partner(
          id: 1,
          name: "Tech Solutions Ltd",
          category: ServiceProvider,
          status: Active,
          trust_score: 85,
          verification_level: Verified,
          goals_completed: 3,
          goals_in_progress: 2,
          balance_usd: 25_000.0,
          balance_ngn: 21_500_000.0,
          payment_currency: NGN,
          last_transaction_date: "2024-03-20",
        ),
      ),
    ]
    |> dict.from_list()

  let sample_goals =
    [
      #(
        1,
        Goal(
          id: 1,
          partner_id: 1,
          title: "Integration Project Phase 1",
          description: "Complete system integration for core modules",
          target_date: "2024-06-30",
          status: InProgress,
          progress: 65.0,
          metrics: [
            Metric("Modules Integrated", 10.0, 6.0),
            Metric("Test Coverage", 90.0, 85.0),
          ],
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      partners: sample_partners,
      goals: sample_goals,
      interactions: dict.new(),
      reports: dict.new(),
      last_id: 1,
      nav_open: False,
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    AddPartner(partner) -> {
      let last_id = model.last_id + 1
      let partners =
        dict.insert(model.partners, last_id, Partner(..partner, id: last_id))
      #(Model(..model, partners: partners, last_id: last_id), effect.none())
    }

    UpdatePartner(id, partner) -> {
      let partners = dict.insert(model.partners, id, partner)
      #(Model(..model, partners: partners), effect.none())
    }

    DeletePartner(id) -> {
      let partners = dict.delete(model.partners, id)
      #(Model(..model, partners: partners), effect.none())
    }

    AddGoal(goal) -> {
      let last_id = model.last_id + 1
      let goals = dict.insert(model.goals, last_id, Goal(..goal, id: last_id))
      #(Model(..model, goals: goals, last_id: last_id), effect.none())
    }

    UpdateGoal(id, goal) -> {
      let goals = dict.insert(model.goals, id, goal)
      #(Model(..model, goals: goals), effect.none())
    }

    DeleteGoal(id) -> {
      let goals = dict.delete(model.goals, id)
      #(Model(..model, goals: goals), effect.none())
    }

    AddInteraction(interaction) -> {
      let last_id = model.last_id + 1
      let interactions =
        dict.insert(
          model.interactions,
          last_id,
          Interaction(..interaction, id: last_id),
        )
      #(
        Model(..model, interactions: interactions, last_id: last_id),
        effect.none(),
      )
    }

    UpdateInteraction(id, interaction) -> {
      let interactions = dict.insert(model.interactions, id, interaction)
      #(Model(..model, interactions: interactions), effect.none())
    }

    GenerateReport(partner_id) -> {
      let partner_goals =
        dict.values(model.goals)
        |> list.filter(fn(g) { g.partner_id == partner_id })

      let partner_interactions =
        dict.values(model.interactions)
        |> list.filter(fn(i) { i.partner_id == partner_id })

      let goals_summary =
        GoalsSummary(
          total: list.length(partner_goals),
          completed: list.filter(partner_goals, fn(g) { g.status == Completed })
            |> list.length(),
          in_progress: list.filter(partner_goals, fn(g) {
            g.status == InProgress
          })
            |> list.length(),
          success_rate: case list.length(partner_goals) {
            0 -> 0.0
            total ->
              int.to_float(
                list.filter(partner_goals, fn(g) { g.status == Completed })
                |> list.length(),
              )
              /. int.to_float(total)
              *. 100.0
          },
        )

      let interactions_summary =
        InteractionsSummary(
          total: list.length(partner_interactions),
          successful: list.filter(partner_interactions, fn(i) {
            i.outcome == Successful
          })
            |> list.length(),
          rejected: list.filter(partner_interactions, fn(i) {
            i.outcome == Rejected
          })
            |> list.length(),
          success_rate: case list.length(partner_interactions) {
            0 -> 0.0
            total ->
              int.to_float(
                list.filter(partner_interactions, fn(i) {
                  i.outcome == Successful
                })
                |> list.length(),
              )
              /. int.to_float(total)
              *. 100.0
          },
        )

      let last_id = model.last_id + 1
      let report =
        Report(
          id: last_id,
          partner_id: partner_id,
          period: "2024-Q1",
          goals_summary: goals_summary,
          interactions_summary: interactions_summary,
          recommendations: generate_recommendations(
            goals_summary,
            interactions_summary,
          ),
        )

      let reports = dict.insert(model.reports, last_id, report)
      #(Model(..model, reports: reports, last_id: last_id), effect.none())
    }

    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> #(
          Model(..model, nav_open: !model.nav_open),
          effect.none(),
        )
      }
    }
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
      html.main([attribute.class("partner-progress-app")], [
        view_header(),
        html.div([attribute.class("dashboard-grid")], [
          // Left sidebar with quick actions and stats
          html.div([attribute.class("dashboard-sidebar")], [
            view_quick_stats(model),
            view_action_menu(),
          ]),
          // Main content area
          html.div([attribute.class("dashboard-main")], [
            // Top row of cards
            html.div([attribute.class("dashboard-cards")], [
              view_goals_overview(model),
              view_recent_activity(model),
              view_upcoming_deadlines(model),
            ]),
            // Tools and resources section
            html.section([attribute.class("tools-section")], [
              html.h2([], [html.text("Tools & Resources")]),
              html.div([attribute.class("tools-grid")], [
                view_document_center(),
                view_support_resources(),
                view_collaboration_tools(),
              ]),
            ]),
            // Detailed sections
            view_goals_section(model),
            view_interactions_section(model),
            view_reports_section(model),
          ]),
        ]),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Partner Progress")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Track business partner goals, interactions, and outcomes"),
    ]),
  ])
}

fn view_quick_stats(model: Model) -> Element(Msg) {
  html.div([attribute.class("quick-stats")], [
    html.h3([], [html.text("Overview")]),
    html.div([attribute.class("stats-list")], [
      html.div([attribute.class("stat-item")], [
        html.span([attribute.class("stat-label")], [html.text("Active Goals")]),
        html.span([attribute.class("stat-value")], [
          html.text(
            dict.values(model.goals)
            |> list.filter(fn(g) { g.status == InProgress })
            |> list.length
            |> int.to_string,
          ),
        ]),
      ]),
      html.div([attribute.class("stat-item")], [
        html.span([attribute.class("stat-label")], [html.text("Success Rate")]),
        html.span([attribute.class("stat-value")], [
          html.text(
            dict.values(model.goals)
            |> list.filter(fn(g) { g.status == Completed })
            |> list.length
            |> int.to_float
            |> fn(completed) {
              case dict.size(model.goals) {
                0 -> 0.0
                total -> completed /. int.to_float(total) *. 100.0
              }
            }
            |> float.to_string
            |> fn(rate) { rate <> "%" },
          ),
        ]),
      ]),
    ]),
  ])
}

fn view_action_menu() -> Element(Msg) {
  html.div([attribute.class("action-menu")], [
    html.h3([], [html.text("Quick Actions")]),
    html.div([attribute.class("action-buttons")], [
      html.button([attribute.class("action-btn")], [
        html.text("Create New Goal"),
      ]),
      html.button([attribute.class("action-btn")], [
        html.text("Schedule Meeting"),
      ]),
      html.button([attribute.class("action-btn")], [
        html.text("Upload Document"),
      ]),
      html.button([attribute.class("action-btn")], [
        html.text("Request Support"),
      ]),
    ]),
  ])
}

fn view_goals_overview(model: Model) -> Element(Msg) {
  html.div([attribute.class("overview-card goals-overview")], [
    html.h3([], [html.text("Goals Progress")]),
    html.div([attribute.class("progress-chart")], [
      // Add visualization here
    ]),
    html.div([attribute.class("goals-metrics")], [
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("Completed")]),
        html.span([attribute.class("metric-value")], [
          html.text(
            dict.values(model.goals)
            |> list.filter(fn(g) { g.status == Completed })
            |> list.length
            |> int.to_string,
          ),
        ]),
      ]),
      html.div([attribute.class("metric")], [
        html.span([attribute.class("metric-label")], [html.text("In Progress")]),
        html.span([attribute.class("metric-value")], [
          html.text(
            dict.values(model.goals)
            |> list.filter(fn(g) { g.status == InProgress })
            |> list.length
            |> int.to_string,
          ),
        ]),
      ]),
    ]),
  ])
}

fn view_recent_activity(model: Model) -> Element(Msg) {
  html.div([attribute.class("overview-card recent-activity")], [
    html.h3([], [html.text("Recent Activity")]),
    html.div(
      [attribute.class("activity-list")],
      dict.values(model.interactions)
        |> list.sort(fn(a, b) { string.compare(b.date, a.date) })
        |> list.take(5)
        |> list.map(fn(interaction) {
          html.div([attribute.class("activity-item")], [
            html.span([attribute.class("activity-type")], [
              html.text(case interaction.interaction_type {
                Meeting -> "📅 Meeting"
                Negotiation -> "🤝 Negotiation"
                Review -> "📋 Review"
                Proposal -> "📝 Proposal"
                Contract -> "📄 Contract"
              }),
            ]),
            html.span([attribute.class("activity-date")], [
              html.text(interaction.date),
            ]),
          ])
        }),
    ),
  ])
}

fn view_upcoming_deadlines(model: Model) -> Element(Msg) {
  html.div([attribute.class("overview-card upcoming-deadlines")], [
    html.h3([], [html.text("Upcoming Deadlines")]),
    html.div(
      [attribute.class("deadlines-list")],
      dict.values(model.goals)
        |> list.filter(fn(goal) { goal.status == InProgress })
        |> list.sort(fn(a, b) { string.compare(a.target_date, b.target_date) })
        |> list.take(3)
        |> list.map(fn(goal) {
          html.div([attribute.class("deadline-item")], [
            html.span([attribute.class("deadline-title")], [
              html.text(goal.title),
            ]),
            html.span([attribute.class("deadline-date")], [
              html.text(goal.target_date),
            ]),
          ])
        }),
    ),
  ])
}

fn view_document_center() -> Element(Msg) {
  html.div([attribute.class("tool-card document-center")], [
    html.h3([], [html.text("Document Center")]),
    html.div([attribute.class("document-categories")], [
      html.div([attribute.class("document-category")], [
        html.h4([], [html.text("Contracts & Agreements")]),
        html.div([attribute.class("document-list")], [
          html.div([attribute.class("document-item")], [
            html.text("📄 Partnership Agreement"),
          ]),
          html.div([attribute.class("document-item")], [
            html.text("📄 Service Level Agreement"),
          ]),
        ]),
      ]),
      html.div([attribute.class("document-category")], [
        html.h4([], [html.text("Reports & Analytics")]),
        html.div([attribute.class("document-list")], [
          html.div([attribute.class("document-item")], [
            html.text("📊 Monthly Performance Report"),
          ]),
          html.div([attribute.class("document-item")], [
            html.text("📈 Growth Analysis"),
          ]),
        ]),
      ]),
    ]),
    html.button([attribute.class("btn-secondary")], [
      html.text("Upload New Document"),
    ]),
  ])
}

fn view_support_resources() -> Element(Msg) {
  html.div([attribute.class("tool-card support-resources")], [
    html.h3([], [html.text("Support Resources")]),
    html.div([attribute.class("resources-list")], [
      html.div([attribute.class("resource-item")], [
        html.text("📚 Partner Handbook"),
      ]),
      html.div([attribute.class("resource-item")], [
        html.text("🎓 Training Materials"),
      ]),
      html.div([attribute.class("resource-item")], [
        html.text("❓ FAQ & Guidelines"),
      ]),
      html.div([attribute.class("resource-item")], [
        html.text("🎯 Best Practices"),
      ]),
    ]),
    html.button([attribute.class("btn-secondary")], [
      html.text("Contact Support"),
    ]),
  ])
}

fn view_collaboration_tools() -> Element(Msg) {
  html.div([attribute.class("tool-card collaboration-tools")], [
    html.h3([], [html.text("Collaboration Tools")]),
    html.div([attribute.class("tools-list")], [
      html.div([attribute.class("tool-item")], [html.text("🗓️ Schedule Meeting")]),
      html.div([attribute.class("tool-item")], [html.text("💬 Message Center")]),
      html.div([attribute.class("tool-item")], [html.text("📋 Shared Tasks")]),
      html.div([attribute.class("tool-item")], [
        html.text("📊 Progress Tracking"),
      ]),
    ]),
    html.button([attribute.class("btn-secondary")], [
      html.text("Start Collaboration"),
    ]),
  ])
}

fn view_goals_section(model: Model) -> Element(Msg) {
  html.section([attribute.class("goals-section")], [
    html.h2([], [html.text("Partner Goals")]),
    html.div(
      [attribute.class("goals-grid")],
      dict.values(model.goals)
        |> list.map(view_goal_card),
    ),
  ])
}

fn view_goal_card(goal: Goal) -> Element(Msg) {
  html.div([attribute.class("goal-card")], [
    html.div([attribute.class("goal-header")], [
      html.h3([], [html.text(goal.title)]),
      html.div(
        [
          attribute.class(
            "goal-status "
            <> case goal.status {
              Planned -> "status-planned"
              InProgress -> "status-progress"
              Completed -> "status-completed"
              Cancelled -> "status-cancelled"
            },
          ),
        ],
        [
          html.text(case goal.status {
            Planned -> "Planned"
            InProgress -> "In Progress"
            Completed -> "Completed"
            Cancelled -> "Cancelled"
          }),
        ],
      ),
    ]),
    html.p([attribute.class("goal-description")], [html.text(goal.description)]),
    html.div(
      [attribute.class("goal-metrics")],
      list.map(goal.metrics, fn(metric) {
        html.div([attribute.class("metric-item")], [
          html.span([attribute.class("metric-name")], [html.text(metric.name)]),
          html.div([attribute.class("metric-progress")], [
            html.div(
              [
                attribute.style([
                  #(
                    "width",
                    float.to_string(metric.current /. metric.target *. 100.0)
                      <> "%",
                  ),
                ]),
                attribute.class("progress-bar"),
              ],
              [],
            ),
          ]),
          html.span([attribute.class("metric-values")], [
            html.text(
              float.to_string(metric.current)
              <> " / "
              <> float.to_string(metric.target),
            ),
          ]),
        ])
      }),
    ),
    html.div([attribute.class("goal-footer")], [
      html.span([attribute.class("target-date")], [
        html.text("Target: " <> goal.target_date),
      ]),
      html.span([attribute.class("progress-percent")], [
        html.text(float.to_string(goal.progress) <> "%"),
      ]),
    ]),
  ])
}

fn view_interactions_section(model: Model) -> Element(Msg) {
  html.section([attribute.class("interactions-section")], [
    html.h2([], [html.text("Recent Interactions")]),
    html.div(
      [attribute.class("interactions-list")],
      dict.values(model.interactions)
        |> list.map(view_interaction_item),
    ),
  ])
}

fn view_interaction_item(interaction: Interaction) -> Element(Msg) {
  html.div([attribute.class("interaction-item")], [
    html.div([attribute.class("interaction-header")], [
      html.span([attribute.class("interaction-type")], [
        html.text(case interaction.interaction_type {
          Meeting -> "Meeting"
          Negotiation -> "Negotiation"
          Review -> "Review"
          Proposal -> "Proposal"
          Contract -> "Contract"
        }),
      ]),
      html.span([attribute.class("interaction-date")], [
        html.text(interaction.date),
      ]),
    ]),
    html.div(
      [
        attribute.class(
          "interaction-outcome "
          <> case interaction.outcome {
            Successful -> "outcome-success"
            Pending -> "outcome-pending"
            Rejected -> "outcome-rejected"
            Inconclusive -> "outcome-inconclusive"
          },
        ),
      ],
      [
        html.text(case interaction.outcome {
          Successful -> "Successful"
          Pending -> "Pending"
          Rejected -> "Rejected"
          Inconclusive -> "Inconclusive"
        }),
      ],
    ),
    html.p([attribute.class("interaction-notes")], [
      html.text(interaction.notes),
    ]),
  ])
}

fn view_reports_section(model: Model) -> Element(Msg) {
  html.section([attribute.class("reports-section")], [
    html.h2([], [html.text("Progress Reports")]),
    html.div(
      [attribute.class("reports-grid")],
      dict.values(model.reports)
        |> list.map(view_report_card(model, _)),
    ),
  ])
}

fn view_report_card(model: Model, report: Report) -> Element(Msg) {
  let partner =
    dict.get(model.partners, report.partner_id)
    |> result.unwrap(Partner(
      id: 0,
      name: "Unknown",
      category: Vendor,
      status: Inactive,
      trust_score: 0,
      verification_level: Basic,
      goals_completed: 0,
      goals_in_progress: 0,
      balance_usd: 0.0,
      balance_ngn: 0.0,
      payment_currency: NGN,
      last_transaction_date: "",
    ))

  html.div([attribute.class("report-card")], [
    html.div([attribute.class("report-header")], [
      html.h3([], [html.text(partner.name <> " - " <> report.period)]),
    ]),
    html.div([attribute.class("report-content")], [
      html.div([attribute.class("goals-summary")], [
        html.h4([], [html.text("Goals")]),
        html.div([attribute.class("summary-stats")], [
          html.div([attribute.class("stat-item")], [
            html.span([attribute.class("stat-label")], [html.text("Total")]),
            html.span([attribute.class("stat-value")], [
              html.text(int.to_string(report.goals_summary.total)),
            ]),
          ]),
          html.div([attribute.class("stat-item")], [
            html.span([attribute.class("stat-label")], [html.text("Completed")]),
            html.span([attribute.class("stat-value")], [
              html.text(int.to_string(report.goals_summary.completed)),
            ]),
          ]),
          html.div([attribute.class("stat-item")], [
            html.span([attribute.class("stat-label")], [
              html.text("Success Rate"),
            ]),
            html.span([attribute.class("stat-value")], [
              html.text(
                float.to_string(report.goals_summary.success_rate) <> "%",
              ),
            ]),
          ]),
        ]),
      ]),
      html.div([attribute.class("interactions-summary")], [
        html.h4([], [html.text("Interactions")]),
        html.div([attribute.class("summary-stats")], [
          html.div([attribute.class("stat-item")], [
            html.span([attribute.class("stat-label")], [html.text("Total")]),
            html.span([attribute.class("stat-value")], [
              html.text(int.to_string(report.interactions_summary.total)),
            ]),
          ]),
          html.div([attribute.class("stat-item")], [
            html.span([attribute.class("stat-label")], [html.text("Successful")]),
            html.span([attribute.class("stat-value")], [
              html.text(int.to_string(report.interactions_summary.successful)),
            ]),
          ]),
          html.div([attribute.class("stat-item")], [
            html.span([attribute.class("stat-label")], [
              html.text("Success Rate"),
            ]),
            html.span([attribute.class("stat-value")], [
              html.text(
                float.to_string(report.interactions_summary.success_rate) <> "%",
              ),
            ]),
          ]),
        ]),
      ]),
      html.div([attribute.class("recommendations")], [
        html.h4([], [html.text("Recommendations")]),
        html.ul(
          [],
          list.map(report.recommendations, fn(rec) {
            html.li([], [html.text(rec)])
          }),
        ),
      ]),
    ]),
  ])
}

fn category_to_string(category: PartnerCategory) -> String {
  case category {
    Vendor -> "Vendor"
    Supplier -> "Supplier"
    Distributor -> "Distributor"
    ServiceProvider -> "Service Provider"
    Investor -> "Investor"
    Strategic -> "Strategic Partner"
  }
}

fn generate_recommendations(
  goals: GoalsSummary,
  interactions: InteractionsSummary,
) -> List(String) {
  let initial_recommendations = []

  case goals.success_rate <. 70.0 {
    True -> [
      "Improve goal completion rate by setting more achievable milestones",
      "Review failed goals to identify common blockers",
      ..initial_recommendations
    ]
    False -> initial_recommendations
  }
  |> fn(recommendations) {
    case
      int.to_float(goals.in_progress) /. int.to_float(goals.total) *. 100.0
      >. 50.0
    {
      True -> [
        "High number of in-progress goals - consider prioritizing completion",
        ..recommendations
      ]
      False -> recommendations
    }
  }
  |> fn(recommendations) {
    case interactions.success_rate <. 60.0 {
      True -> [
        "Improve interaction success rate through better preparation",
        "Schedule follow-up meetings for pending interactions",
        ..recommendations
      ]
      False -> recommendations
    }
  }
  |> fn(recommendations) {
    case int.to_float(interactions.total) <. 2.0 {
      True -> [
        "Increase meeting frequency to maintain better engagement",
        ..recommendations
      ]
      False -> recommendations
    }
  }
}
