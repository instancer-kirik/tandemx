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
    loans: Dict(Int, Loan),
    filter: Filter,
    last_id: Int,
    new_loan_input: String,
    nav_open: Bool,
    selected_tab: Tab,
    trust_metrics: Dict(String, TrustMetric),
    playlists: Dict(String, Playlist),
  )
}

pub type Tab {
  TabLoans
  TabContracts
  TabPayments
  TabMetrics
}

pub type TrustMetric {
  TrustMetric(
    score: Float,
    level: TrustLevel,
    verified: Bool,
    achievements: List(String),
  )
}

pub type TrustLevel {
  TrustLevelBasic
  TrustLevelVerified
  TrustLevelInstitution
  TrustLevelPremium
}

pub type Loan {
  Loan(
    id: Int,
    borrower: String,
    amount: Float,
    status: LoanStatus,
    school: Option(String),
    lender: Option(String),
    trust_score: Float,
    verification_status: VerificationStatus,
    payment_schedule: Option(PaymentSchedule),
    contract_type: ContractType,
    parties: List(Party),
  )
}

pub type LoanStatus {
  LoanPending
  LoanActive
  LoanRepaying
  LoanCompleted
  LoanDefaulted
}

pub type Filter {
  FilterAll
  FilterActive
  FilterPending
  FilterDefaulted
}

pub type VerificationStatus {
  VerificationUnverified
  VerificationPending
  VerificationVerified
  VerificationInstitution
}

pub type PaymentSchedule {
  PaymentSchedule(
    frequency: PaymentFrequency,
    amount: Float,
    next_date: String,
    total_payments: Int,
    completed_payments: Int,
  )
}

pub type PaymentFrequency {
  Weekly
  Biweekly
  Monthly
  Quarterly
}

pub type ContractType {
  Standard
  SmartContract
  MultiParty
  Institutional
}

pub type Party {
  Party(name: String, role: PartyRole, status: PartyStatus, trust_score: Float)
}

pub type PartyRole {
  Lender
  Borrower
  Guarantor
  Validator
  Institution
}

pub type PartyStatus {
  Pending
  Accepted
  Rejected
}

pub type Video {
  Video(
    id: String,
    title: String,
    thumbnail: String,
    duration: String,
    added_by: String,
    added_at: String,
    annotations: List(VideoAnnotation),
  )
}

pub type VideoAnnotation {
  VideoAnnotation(
    id: String,
    timestamp: Float,
    text: String,
    author: String,
    created_at: String,
  )
}

pub type Playlist {
  Playlist(
    id: String,
    agreement_id: String,
    videos: List(Video),
    created_at: String,
    updated_at: String,
  )
}

pub type Msg {
  UserAddedLoan
  UserUpdatedNewLoan(String)
  UserClickedFilter(Filter)
  UserClickedApprove(Int)
  UserClickedDefault(Int)
  UserClickedComplete(Int)
  UserSelectedTab(Tab)
  UserAddedVideo(String, String)
  UserRemovedVideo(String, String)
  UserAddedAnnotation(String, String, Float, String)
  UserRemovedAnnotation(String, String, String)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub fn init(_) {
  let sample_loans =
    [
      #(
        1,
        Loan(
          id: 1,
          borrower: "Alice Chen",
          amount: 25_000.0,
          status: LoanActive,
          school: Some("Stanford University"),
          lender: Some("First National Bank"),
          trust_score: 0.8,
          verification_status: VerificationVerified,
          payment_schedule: Some(PaymentSchedule(
            frequency: Monthly,
            amount: 2083.33,
            next_date: "2024-04-01",
            total_payments: 12,
            completed_payments: 6,
          )),
          contract_type: Standard,
          parties: [],
        ),
      ),
      #(
        2,
        Loan(
          id: 2,
          borrower: "Bob Smith",
          amount: 15_000.0,
          status: LoanPending,
          school: Some("MIT"),
          lender: None,
          trust_score: 0.0,
          verification_status: VerificationUnverified,
          payment_schedule: None,
          contract_type: Standard,
          parties: [],
        ),
      ),
      #(
        3,
        Loan(
          id: 3,
          borrower: "Carol Johnson",
          amount: 30_000.0,
          status: LoanCompleted,
          school: Some("Harvard University"),
          lender: Some("Education First Credit"),
          trust_score: 0.9,
          verification_status: VerificationInstitution,
          payment_schedule: Some(PaymentSchedule(
            frequency: Quarterly,
            amount: 7500.0,
            next_date: "2024-07-01",
            total_payments: 4,
            completed_payments: 4,
          )),
          contract_type: Institutional,
          parties: [],
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      loans: sample_loans,
      filter: FilterAll,
      last_id: 3,
      new_loan_input: "",
      nav_open: False,
      selected_tab: TabLoans,
      trust_metrics: dict.new(),
      playlists: dict.new(),
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserAddedLoan -> {
      let last_id = model.last_id + 1
      let new_loan =
        Loan(
          id: last_id,
          borrower: model.new_loan_input,
          amount: 0.0,
          status: LoanPending,
          school: None,
          lender: None,
          trust_score: 0.0,
          verification_status: VerificationUnverified,
          payment_schedule: None,
          contract_type: Standard,
          parties: [],
        )
      let loans = dict.insert(model.loans, last_id, new_loan)
      #(
        Model(..model, loans: loans, last_id: last_id, new_loan_input: ""),
        effect.none(),
      )
    }
    UserUpdatedNewLoan(value) -> {
      #(Model(..model, new_loan_input: value), effect.none())
    }
    UserClickedFilter(filter) -> {
      #(Model(..model, filter: filter), effect.none())
    }
    UserClickedApprove(id) -> {
      let loans = case dict.get(model.loans, id) {
        Ok(loan) ->
          dict.insert(model.loans, id, Loan(..loan, status: LoanActive))
        Error(_) -> model.loans
      }
      #(Model(..model, loans: loans), effect.none())
    }
    UserClickedDefault(id) -> {
      let loans = case dict.get(model.loans, id) {
        Ok(loan) ->
          dict.insert(model.loans, id, Loan(..loan, status: LoanDefaulted))
        Error(_) -> model.loans
      }
      #(Model(..model, loans: loans), effect.none())
    }
    UserClickedComplete(id) -> {
      let loans = case dict.get(model.loans, id) {
        Ok(loan) ->
          dict.insert(model.loans, id, Loan(..loan, status: LoanCompleted))
        Error(_) -> model.loans
      }
      #(Model(..model, loans: loans), effect.none())
    }
    UserSelectedTab(tab) -> {
      #(Model(..model, selected_tab: tab), effect.none())
    }
    UserAddedVideo(agreement_id, video_url) -> {
      #(model, effect.none())
    }
    UserRemovedVideo(agreement_id, video_id) -> {
      #(model, effect.none())
    }
    UserAddedAnnotation(agreement_id, video_id, timestamp, text) -> {
      #(model, effect.none())
    }
    UserRemovedAnnotation(agreement_id, video_id, annotation_id) -> {
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
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    element.map(nav.view(), NavMsg),
    html.div([attribute.class("divvyqueue-app")], [
      html.header([attribute.class("app-header")], [
        html.div([attribute.class("header-content")], [
          html.h1([], [html.text("DivvyQueue")]),
          html.p([attribute.class("header-subtitle")], [
            html.text("Multi-Party Contract & Payment Management"),
          ]),
        ]),
        html.div([attribute.class("header-actions")], [
          html.button(
            [attribute.class("btn-primary"), event.on_click(UserAddedLoan)],
            [html.text("New Agreement")],
          ),
        ]),
      ]),
      view_tabs(model.selected_tab),
      html.div([attribute.class("main-content")], case model.selected_tab {
        TabLoans -> [
          view_summary_stats(model.loans),
          html.div([attribute.class("action-bar")], [
            html.div([attribute.class("filters-group")], [
              view_filters(model.filter),
            ]),
            html.div([attribute.class("view-options")], [
              html.select([attribute.class("view-select")], [
                html.option([attribute.value("card")], "Card View"),
                html.option([attribute.value("list")], "List View"),
              ]),
            ]),
          ]),
          view_enhanced_loans(model.loans, model.filter),
        ]
        TabContracts -> [
          html.div([attribute.class("contracts-view")], [
            html.div([attribute.class("section-header")], [
              html.h2([], [html.text("Contract Management")]),
              html.p([], [
                html.text(
                  "Create and manage multi-party agreements with automated compliance.",
                ),
              ]),
            ]),
            html.div([attribute.class("coming-soon")], [
              html.div([attribute.class("feature-preview")], [
                html.h3([], [html.text("Coming Soon")]),
                html.p([], [
                  html.text(
                    "Smart contract templates, multi-party verification, and automated compliance checks.",
                  ),
                ]),
                html.ul([attribute.class("feature-list")], [
                  html.li([], [html.text("✓ Document Management")]),
                  html.li([], [html.text("✓ Multi-party Signatures")]),
                  html.li([], [html.text("✓ Compliance Automation")]),
                  html.li([], [html.text("✓ Verification Workflows")]),
                ]),
              ]),
            ]),
          ]),
        ]
        TabPayments -> [
          html.div([attribute.class("payments-view")], [
            html.div([attribute.class("section-header")], [
              html.h2([], [html.text("Payment Management")]),
              html.p([], [
                html.text(
                  "Track and manage payment schedules, transactions, and automation.",
                ),
              ]),
            ]),
            html.div([attribute.class("coming-soon")], [
              html.div([attribute.class("feature-preview")], [
                html.h3([], [html.text("Coming Soon")]),
                html.p([], [
                  html.text(
                    "Automated payment scheduling, tracking, and reconciliation.",
                  ),
                ]),
                html.ul([attribute.class("feature-list")], [
                  html.li([], [html.text("✓ Payment Automation")]),
                  html.li([], [html.text("✓ Schedule Management")]),
                  html.li([], [html.text("✓ Transaction History")]),
                  html.li([], [html.text("✓ Payment Analytics")]),
                ]),
              ]),
            ]),
          ]),
        ]
        TabMetrics -> [
          html.div([attribute.class("metrics-view")], [
            html.div([attribute.class("section-header")], [
              html.h2([], [html.text("Trust Metrics")]),
              html.p([], [
                html.text(
                  "Monitor trust scores, verification status, and compliance metrics.",
                ),
              ]),
            ]),
            html.div([attribute.class("coming-soon")], [
              html.div([attribute.class("feature-preview")], [
                html.h3([], [html.text("Coming Soon")]),
                html.p([], [
                  html.text(
                    "Advanced analytics and trust metrics for all parties.",
                  ),
                ]),
                html.ul([attribute.class("feature-list")], [
                  html.li([], [html.text("✓ Trust Scoring")]),
                  html.li([], [html.text("✓ Verification Analytics")]),
                  html.li([], [html.text("✓ Compliance Monitoring")]),
                  html.li([], [html.text("✓ Risk Assessment")]),
                ]),
              ]),
            ]),
          ]),
        ]
      }),
    ]),
  ])
}

fn view_tabs(selected: Tab) -> Element(Msg) {
  html.div([attribute.class("tabs")], [
    tab_button("Loans", TabLoans, selected),
    tab_button("Contracts", TabContracts, selected),
    tab_button("Payments", TabPayments, selected),
    tab_button("Trust Metrics", TabMetrics, selected),
  ])
}

fn tab_button(label: String, tab: Tab, selected: Tab) -> Element(Msg) {
  html.button(
    [
      attribute.class(case tab == selected {
        True -> "tab active"
        False -> "tab"
      }),
      event.on("click", fn(_) { Ok(UserSelectedTab(tab)) }),
    ],
    [html.text(label)],
  )
}

fn view_summary_stats(loans: Dict(Int, Loan)) -> Element(Msg) {
  let total_active =
    dict.values(loans)
    |> list.filter(fn(loan) { loan.status == LoanActive })
    |> list.length()

  let total_pending =
    dict.values(loans)
    |> list.filter(fn(loan) { loan.status == LoanPending })
    |> list.length()

  let total_amount =
    dict.values(loans)
    |> list.fold(0.0, fn(acc, loan) { acc +. loan.amount })

  html.div([attribute.class("summary-stats")], [
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Active Loans")]),
      html.span([attribute.class("stat-value")], [
        html.text(int.to_string(total_active)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Pending Loans")]),
      html.span([attribute.class("stat-value")], [
        html.text(int.to_string(total_pending)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Total Amount")]),
      html.span([attribute.class("stat-value")], [
        html.text("$" <> float.to_string(total_amount)),
      ]),
    ]),
  ])
}

fn view_filters(current: Filter) -> Element(Msg) {
  html.div([attribute.class("loan-filters")], [
    filter_button("All", FilterAll, current),
    filter_button("Active", FilterActive, current),
    filter_button("Pending", FilterPending, current),
    filter_button("Defaulted", FilterDefaulted, current),
  ])
}

fn filter_button(label: String, filter: Filter, current: Filter) -> Element(Msg) {
  let is_selected = filter == current
  html.button(
    [
      attribute.class(case is_selected {
        True -> "selected"
        False -> ""
      }),
      event.on("click", fn(_) { Ok(UserClickedFilter(filter)) }),
    ],
    [html.text(label)],
  )
}

fn view_enhanced_loans(loans: Dict(Int, Loan), filter: Filter) -> Element(Msg) {
  html.div(
    [attribute.class("loan-list")],
    dict.values(loans)
      |> list.filter(fn(loan) {
        case filter {
          FilterAll -> True
          FilterActive -> loan.status == LoanActive
          FilterPending -> loan.status == LoanPending
          FilterDefaulted -> loan.status == LoanDefaulted
        }
      })
      |> list.map(view_enhanced_loan),
  )
}

fn view_enhanced_loan(loan: Loan) -> Element(Msg) {
  html.div([attribute.class("loan-card")], [
    html.div([attribute.class("loan-header")], [
      html.div([attribute.class("loan-title")], [
        html.h3([], [html.text(loan.borrower)]),
        html.div(
          [attribute.class("loan-status " <> status_class(loan.status))],
          [html.text(status_text(loan.status))],
        ),
        html.div([attribute.class("trust-badge")], [
          html.span([attribute.class("trust-score")], [
            html.text("Trust Score: " <> float.to_string(loan.trust_score)),
          ]),
          html.span(
            [
              attribute.class(
                "verification-status "
                <> verification_class(loan.verification_status),
              ),
            ],
            [html.text(verification_text(loan.verification_status))],
          ),
        ]),
      ]),
      html.div([attribute.class("loan-amount")], [
        html.text("$" <> float.to_string(loan.amount)),
      ]),
    ]),
    html.div([attribute.class("loan-details")], [
      case loan.school {
        Some(school) ->
          html.div([attribute.class("loan-school")], [
            html.span([attribute.class("detail-label")], [html.text("School")]),
            html.text(school),
          ])
        None -> html.text("")
      },
      case loan.lender {
        Some(lender) ->
          html.div([attribute.class("loan-lender")], [
            html.span([attribute.class("detail-label")], [html.text("Lender")]),
            html.text(lender),
          ])
        None -> html.text("")
      },
      html.div([attribute.class("contract-type")], [
        html.span([attribute.class("detail-label")], [
          html.text("Contract Type"),
        ]),
        html.text(contract_type_text(loan.contract_type)),
      ]),
      case loan.payment_schedule {
        Some(schedule) ->
          html.div([attribute.class("payment-schedule")], [
            html.span([attribute.class("detail-label")], [
              html.text("Payment Schedule"),
            ]),
            html.div([attribute.class("schedule-details")], [
              html.div([], [
                html.text(
                  payment_frequency_text(schedule.frequency)
                  <> " - $"
                  <> float.to_string(schedule.amount),
                ),
              ]),
              html.div([], [
                html.text(
                  "Progress: "
                  <> int.to_string(schedule.completed_payments)
                  <> "/"
                  <> int.to_string(schedule.total_payments),
                ),
              ]),
              html.div([], [html.text("Next: " <> schedule.next_date)]),
            ]),
          ])
        None -> html.text("")
      },
    ]),
    html.div([attribute.class("loan-parties")], [
      html.h4([], [html.text("Parties")]),
      html.div(
        [attribute.class("party-list")],
        list.map(loan.parties, view_party),
      ),
    ]),
    html.div([attribute.class("loan-actions")], case loan.status {
      LoanPending -> [
        html.button(
          [
            attribute.class("btn-success"),
            event.on_click(UserClickedApprove(loan.id)),
          ],
          [html.text("Approve")],
        ),
        html.button(
          [
            attribute.class("btn-danger"),
            event.on_click(UserClickedDefault(loan.id)),
          ],
          [html.text("Default")],
        ),
      ]
      LoanActive -> [
        html.button(
          [
            attribute.class("btn-primary"),
            event.on_click(UserClickedComplete(loan.id)),
          ],
          [html.text("Complete")],
        ),
      ]
      _ -> []
    }),
  ])
}

fn view_party(party: Party) -> Element(Msg) {
  html.div([attribute.class("party-item")], [
    html.div([attribute.class("party-info")], [
      html.span([attribute.class("party-name")], [html.text(party.name)]),
      html.span([attribute.class("party-role")], [
        html.text(party_role_text(party.role)),
      ]),
      html.span(
        [attribute.class("party-status " <> party_status_class(party.status))],
        [html.text(party_status_text(party.status))],
      ),
    ]),
    html.div([attribute.class("party-trust")], [
      html.span([attribute.class("trust-score")], [
        html.text("Trust: " <> float.to_string(party.trust_score)),
      ]),
    ]),
  ])
}

fn verification_class(status: VerificationStatus) -> String {
  case status {
    VerificationUnverified -> "status-unverified"
    VerificationPending -> "status-pending-verification"
    VerificationVerified -> "status-verified"
    VerificationInstitution -> "status-institution-verified"
  }
}

fn verification_text(status: VerificationStatus) -> String {
  case status {
    VerificationUnverified -> "Unverified"
    VerificationPending -> "Pending Verification"
    VerificationVerified -> "Verified"
    VerificationInstitution -> "Institution Verified"
  }
}

fn contract_type_text(contract_type: ContractType) -> String {
  case contract_type {
    Standard -> "Standard"
    SmartContract -> "Smart Contract"
    MultiParty -> "Multi-Party"
    Institutional -> "Institutional"
  }
}

fn payment_frequency_text(frequency: PaymentFrequency) -> String {
  case frequency {
    Weekly -> "Weekly"
    Biweekly -> "Bi-weekly"
    Monthly -> "Monthly"
    Quarterly -> "Quarterly"
  }
}

fn party_role_text(role: PartyRole) -> String {
  case role {
    Lender -> "Lender"
    Borrower -> "Borrower"
    Guarantor -> "Guarantor"
    Validator -> "Validator"
    Institution -> "Institution"
  }
}

fn party_status_text(status: PartyStatus) -> String {
  case status {
    Pending -> "Pending"
    Accepted -> "Accepted"
    Rejected -> "Rejected"
  }
}

fn party_status_class(status: PartyStatus) -> String {
  case status {
    Pending -> "status-pending"
    Accepted -> "status-accepted"
    Rejected -> "status-rejected"
  }
}

fn status_class(status: LoanStatus) -> String {
  case status {
    LoanPending -> "status-pending"
    LoanActive -> "status-active"
    LoanRepaying -> "status-repaying"
    LoanCompleted -> "status-completed"
    LoanDefaulted -> "status-defaulted"
  }
}

fn status_text(status: LoanStatus) -> String {
  case status {
    LoanPending -> "Pending"
    LoanActive -> "Active"
    LoanRepaying -> "Repaying"
    LoanCompleted -> "Completed"
    LoanDefaulted -> "Defaulted"
  }
}
