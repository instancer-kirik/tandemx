import components/nav
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    audit_logs: Dict(Int, AuditLog),
    compliance_reports: Dict(Int, ComplianceReport),
    regulatory_alerts: Dict(Int, RegulatoryAlert),
    tax_filings: Dict(Int, TaxFiling),
    last_id: Int,
    nav_open: Bool,
    selected_jurisdiction: Jurisdiction,
    date_range: DateRange,
    spending_controls_expanded: Dict(Int, Bool),
  )
}

pub type AuditLog {
  AuditLog(
    id: Int,
    timestamp: String,
    event_type: AuditEventType,
    user_id: String,
    details: String,
    related_entity: String,
    jurisdiction: Jurisdiction,
    severity: Severity,
  )
}

pub type AuditEventType {
  TransactionEvent
  UserAccessEvent
  ConfigurationChange
  ComplianceCheck
  RegulatoryFiling
  SystemAlert
}

pub type ComplianceReport {
  ComplianceReport(
    id: Int,
    report_type: ReportType,
    jurisdiction: Jurisdiction,
    period: String,
    status: ReportStatus,
    findings: List(Finding),
    due_date: String,
    submitted_date: Option(String),
  )
}

pub type ReportType {
  AnnualCompliance
  QuarterlyAudit
  RegulatoryExamination
  RiskAssessment
  IncidentReport
}

pub type ReportStatus {
  ReportDraft
  ReportUnderReview
  ReportSubmitted
  ReportAccepted
  ReportRejected
}

pub type Finding {
  Finding(
    id: Int,
    severity: Severity,
    description: String,
    recommendation: String,
    status: FindingStatus,
    due_date: String,
  )
}

pub type FindingStatus {
  Open
  InProgress
  Resolved
  Verified
}

pub type Severity {
  Critical
  High
  Medium
  Low
  Info
}

pub type RegulatoryAlert {
  RegulatoryAlert(
    id: Int,
    title: String,
    description: String,
    jurisdiction: Jurisdiction,
    due_date: String,
    status: AlertStatus,
    impact_areas: List(String),
    required_actions: List(String),
  )
}

pub type AlertStatus {
  AlertPending
  AlertInProgress
  AlertCompleted
  AlertOverdue
}

pub type TaxFiling {
  TaxFiling(
    id: Int,
    tax_type: TaxType,
    jurisdiction: Jurisdiction,
    period: String,
    amount: Float,
    status: FilingStatus,
    due_date: String,
    filed_date: Option(String),
    supporting_docs: List(String),
  )
}

pub type TaxType {
  VAT
  CorporateIncomeTax
  PayrollTax
  WithholdingTax
}

pub type FilingStatus {
  FilingDraft
  FilingSubmitted
  FilingAccepted
  FilingRejected
  FilingAmended
}

pub type Jurisdiction {
  Nigeria
  Kenya
  SouthAfrica
  PanAfrican
}

pub type DateRange {
  DateRange(start: String, end: String)
}

pub type Msg {
  SetJurisdiction(Jurisdiction)
  SetDateRange(DateRange)
  AddAuditLog(AuditLog)
  UpdateComplianceReport(Int, ComplianceReport)
  AddRegulatoryAlert(RegulatoryAlert)
  UpdateTaxFiling(Int, TaxFiling)
  ToggleSpendingControls(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_audit_logs =
    [
      #(
        1,
        AuditLog(
          id: 1,
          timestamp: "2024-03-20T10:30:00Z",
          event_type: TransactionEvent,
          user_id: "USER123",
          details: "High-value transaction approval",
          related_entity: "TRANSACTION456",
          jurisdiction: Nigeria,
          severity: High,
        ),
      ),
    ]
    |> dict.from_list()

  let sample_compliance_reports =
    [
      #(
        1,
        ComplianceReport(
          id: 1,
          report_type: QuarterlyAudit,
          jurisdiction: Nigeria,
          period: "Q1 2024",
          status: ReportUnderReview,
          findings: [
            Finding(
              id: 1,
              severity: Medium,
              description: "Incomplete transaction documentation",
              recommendation: "Implement automated document collection",
              status: InProgress,
              due_date: "2024-04-15",
            ),
          ],
          due_date: "2024-04-30",
          submitted_date: None,
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      audit_logs: sample_audit_logs,
      compliance_reports: sample_compliance_reports,
      regulatory_alerts: dict.new(),
      tax_filings: dict.new(),
      last_id: 1,
      nav_open: False,
      selected_jurisdiction: Nigeria,
      date_range: DateRange(start: "2024-01-01", end: "2024-12-31"),
      spending_controls_expanded: dict.new(),
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SetJurisdiction(jurisdiction) -> {
      #(Model(..model, selected_jurisdiction: jurisdiction), effect.none())
    }

    SetDateRange(date_range) -> {
      #(Model(..model, date_range: date_range), effect.none())
    }

    AddAuditLog(log) -> {
      let last_id = model.last_id + 1
      let audit_logs =
        dict.insert(model.audit_logs, last_id, AuditLog(..log, id: last_id))
      #(Model(..model, audit_logs: audit_logs, last_id: last_id), effect.none())
    }

    UpdateComplianceReport(id, report) -> {
      let compliance_reports = dict.insert(model.compliance_reports, id, report)
      #(Model(..model, compliance_reports: compliance_reports), effect.none())
    }

    AddRegulatoryAlert(alert) -> {
      let last_id = model.last_id + 1
      let regulatory_alerts =
        dict.insert(
          model.regulatory_alerts,
          last_id,
          RegulatoryAlert(..alert, id: last_id),
        )
      #(
        Model(..model, regulatory_alerts: regulatory_alerts, last_id: last_id),
        effect.none(),
      )
    }

    UpdateTaxFiling(id, filing) -> {
      let tax_filings = dict.insert(model.tax_filings, id, filing)
      #(Model(..model, tax_filings: tax_filings), effect.none())
    }

    ToggleSpendingControls(id) -> {
      let is_expanded = case dict.get(model.spending_controls_expanded, id) {
        Ok(expanded) -> !expanded
        Error(_) -> True
      }
      let spending_controls_expanded =
        dict.insert(model.spending_controls_expanded, id, is_expanded)
      #(
        Model(..model, spending_controls_expanded: spending_controls_expanded),
        effect.none(),
      )
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

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [
      element.map(nav.view(), NavMsg),
      html.main([attribute.class("compliance-app")], [
        view_header(),
        view_filters(model),
        view_audit_logs(model),
        view_compliance_reports(model),
        view_regulatory_alerts(model),
        view_tax_filings(model),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Compliance & Audit")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Monitor compliance, audit trails, and regulatory requirements"),
    ]),
  ])
}

fn view_filters(model: Model) -> Element(Msg) {
  html.section([attribute.class("filters-section")], [
    html.div([attribute.class("filter-group")], [
      html.label([], [html.text("Jurisdiction")]),
      html.select(
        [
          event.on_input(fn(value) {
            SetJurisdiction(case value {
              "Nigeria" -> Nigeria
              "Kenya" -> Kenya
              "SouthAfrica" -> SouthAfrica
              "PanAfrican" -> PanAfrican
              _ -> Nigeria
            })
          }),
        ],
        [
          html.option(
            [
              attribute.value("Nigeria"),
              attribute.selected(model.selected_jurisdiction == Nigeria),
            ],
            "Nigeria",
          ),
          html.option(
            [
              attribute.value("Kenya"),
              attribute.selected(model.selected_jurisdiction == Kenya),
            ],
            "Kenya",
          ),
          html.option(
            [
              attribute.value("SouthAfrica"),
              attribute.selected(model.selected_jurisdiction == SouthAfrica),
            ],
            "South Africa",
          ),
          html.option(
            [
              attribute.value("PanAfrican"),
              attribute.selected(model.selected_jurisdiction == PanAfrican),
            ],
            "Pan-African",
          ),
        ],
      ),
    ]),
    html.div([attribute.class("filter-group")], [
      html.label([], [html.text("Date Range")]),
      html.div([attribute.class("date-inputs")], [
        html.input([
          attribute.type_("date"),
          attribute.value(model.date_range.start),
          event.on_input(fn(start) {
            SetDateRange(DateRange(start: start, end: model.date_range.end))
          }),
        ]),
        html.input([
          attribute.type_("date"),
          attribute.value(model.date_range.end),
          event.on_input(fn(end) {
            SetDateRange(DateRange(start: model.date_range.start, end: end))
          }),
        ]),
      ]),
    ]),
  ])
}

fn view_audit_logs(model: Model) -> Element(Msg) {
  html.section([attribute.class("audit-logs-section")], [
    html.h2([], [html.text("Audit Trail")]),
    html.div(
      [attribute.class("audit-logs-list")],
      dict.values(model.audit_logs)
        |> list.filter(fn(log) {
          log.jurisdiction == model.selected_jurisdiction
        })
        |> list.map(view_audit_log),
    ),
  ])
}

fn view_audit_log(log: AuditLog) -> Element(Msg) {
  html.div([attribute.class("audit-log-item")], [
    html.div([attribute.class("log-header")], [
      html.span([attribute.class("log-timestamp")], [html.text(log.timestamp)]),
      html.span(
        [
          attribute.class(
            "log-severity "
            <> case log.severity {
              Critical -> "severity-critical"
              High -> "severity-high"
              Medium -> "severity-medium"
              Low -> "severity-low"
              Info -> "severity-info"
            },
          ),
        ],
        [html.text(severity_to_string(log.severity))],
      ),
    ]),
    html.div([attribute.class("log-details")], [
      html.div([attribute.class("log-type")], [
        html.text(audit_event_type_to_string(log.event_type)),
      ]),
      html.div([attribute.class("log-description")], [html.text(log.details)]),
      html.div([attribute.class("log-entity")], [
        html.text("Related: " <> log.related_entity),
      ]),
    ]),
  ])
}

fn view_compliance_reports(model: Model) -> Element(Msg) {
  html.section([attribute.class("compliance-reports-section")], [
    html.h2([], [html.text("Compliance Reports")]),
    html.div(
      [attribute.class("reports-list")],
      dict.values(model.compliance_reports)
        |> list.filter(fn(report) {
          report.jurisdiction == model.selected_jurisdiction
        })
        |> list.map(view_compliance_report),
    ),
  ])
}

fn view_compliance_report(report: ComplianceReport) -> Element(Msg) {
  html.div([attribute.class("report-item")], [
    html.div([attribute.class("report-header")], [
      html.h3([], [html.text(report_type_to_string(report.report_type))]),
      html.div(
        [
          attribute.class(
            "report-status "
            <> case report.status {
              ReportDraft -> "status-draft"
              ReportUnderReview -> "status-review"
              ReportSubmitted -> "status-submitted"
              ReportAccepted -> "status-accepted"
              ReportRejected -> "status-rejected"
            },
          ),
        ],
        [html.text(report_status_to_string(report.status))],
      ),
    ]),
    html.div([attribute.class("report-details")], [
      html.div([attribute.class("report-period")], [
        html.text("Period: " <> report.period),
      ]),
      html.div([attribute.class("report-dates")], [
        html.text("Due: " <> report.due_date),
        case report.submitted_date {
          Some(date) -> html.text(" | Submitted: " <> date)
          None -> html.text("")
        },
      ]),
    ]),
    html.div([attribute.class("report-findings")], [
      html.h4([], [
        html.text(
          "Findings (" <> int.to_string(list.length(report.findings)) <> ")",
        ),
      ]),
      html.div(
        [attribute.class("findings-list")],
        list.map(report.findings, view_finding),
      ),
    ]),
  ])
}

fn view_finding(finding: Finding) -> Element(Msg) {
  html.div([attribute.class("finding-item")], [
    html.div([attribute.class("finding-header")], [
      html.span(
        [
          attribute.class(
            "finding-severity "
            <> case finding.severity {
              Critical -> "severity-critical"
              High -> "severity-high"
              Medium -> "severity-medium"
              Low -> "severity-low"
              Info -> "severity-info"
            },
          ),
        ],
        [html.text(severity_to_string(finding.severity))],
      ),
      html.span(
        [
          attribute.class(
            "finding-status "
            <> case finding.status {
              Open -> "status-open"
              InProgress -> "status-progress"
              Resolved -> "status-resolved"
              Verified -> "status-verified"
            },
          ),
        ],
        [html.text(finding_status_to_string(finding.status))],
      ),
    ]),
    html.div([attribute.class("finding-description")], [
      html.text(finding.description),
    ]),
    html.div([attribute.class("finding-recommendation")], [
      html.text(finding.recommendation),
    ]),
    html.div([attribute.class("finding-due-date")], [
      html.text("Due: " <> finding.due_date),
    ]),
  ])
}

fn view_regulatory_alerts(model: Model) -> Element(Msg) {
  html.section([attribute.class("regulatory-alerts-section")], [
    html.h2([], [html.text("Regulatory Alerts")]),
    html.div(
      [attribute.class("alerts-list")],
      dict.values(model.regulatory_alerts)
        |> list.filter(fn(alert) {
          alert.jurisdiction == model.selected_jurisdiction
        })
        |> list.map(view_regulatory_alert),
    ),
  ])
}

fn view_regulatory_alert(alert: RegulatoryAlert) -> Element(Msg) {
  html.div([attribute.class("alert-item")], [
    html.div([attribute.class("alert-header")], [
      html.h3([], [html.text(alert.title)]),
      html.div(
        [
          attribute.class(
            "alert-status "
            <> case alert.status {
              AlertPending -> "status-pending"
              AlertInProgress -> "status-progress"
              AlertCompleted -> "status-completed"
              AlertOverdue -> "status-overdue"
            },
          ),
        ],
        [html.text(alert_status_to_string(alert.status))],
      ),
    ]),
    html.div([attribute.class("alert-description")], [
      html.text(alert.description),
    ]),
    html.div([attribute.class("alert-impact")], [
      html.h4([], [html.text("Impact Areas")]),
      html.ul(
        [],
        list.map(alert.impact_areas, fn(area) { html.li([], [html.text(area)]) }),
      ),
    ]),
    html.div([attribute.class("alert-actions")], [
      html.h4([], [html.text("Required Actions")]),
      html.ul(
        [],
        list.map(alert.required_actions, fn(action) {
          html.li([], [html.text(action)])
        }),
      ),
    ]),
    html.div([attribute.class("alert-due-date")], [
      html.text("Due: " <> alert.due_date),
    ]),
  ])
}

fn view_tax_filings(model: Model) -> Element(Msg) {
  html.section([attribute.class("tax-filings-section")], [
    html.h2([], [html.text("Tax Filings")]),
    html.div(
      [attribute.class("filings-list")],
      dict.values(model.tax_filings)
        |> list.filter(fn(filing) {
          filing.jurisdiction == model.selected_jurisdiction
        })
        |> list.map(view_tax_filing),
    ),
  ])
}

fn view_tax_filing(filing: TaxFiling) -> Element(Msg) {
  html.div([attribute.class("filing-item")], [
    html.div([attribute.class("filing-header")], [
      html.h3([], [html.text(tax_type_to_string(filing.tax_type))]),
      html.div(
        [
          attribute.class(
            "filing-status "
            <> case filing.status {
              FilingDraft -> "status-draft"
              FilingSubmitted -> "status-submitted"
              FilingAccepted -> "status-accepted"
              FilingRejected -> "status-rejected"
              FilingAmended -> "status-amended"
            },
          ),
        ],
        [html.text(filing_status_to_string(filing.status))],
      ),
    ]),
    html.div([attribute.class("filing-details")], [
      html.div([attribute.class("filing-period")], [
        html.text("Period: " <> filing.period),
      ]),
      html.div([attribute.class("filing-amount")], [
        html.text("Amount: $" <> float.to_string(filing.amount)),
      ]),
    ]),
    html.div([attribute.class("filing-dates")], [
      html.text("Due: " <> filing.due_date),
      case filing.filed_date {
        Some(date) -> html.text(" | Filed: " <> date)
        None -> html.text("")
      },
    ]),
    html.div([attribute.class("filing-documents")], [
      html.h4([], [html.text("Supporting Documents")]),
      html.ul(
        [],
        list.map(filing.supporting_docs, fn(doc) {
          html.li([], [html.text(doc)])
        }),
      ),
    ]),
  ])
}

fn severity_to_string(severity: Severity) -> String {
  case severity {
    Critical -> "Critical"
    High -> "High"
    Medium -> "Medium"
    Low -> "Low"
    Info -> "Info"
  }
}

fn audit_event_type_to_string(event_type: AuditEventType) -> String {
  case event_type {
    TransactionEvent -> "Transaction"
    UserAccessEvent -> "User Access"
    ConfigurationChange -> "Configuration"
    ComplianceCheck -> "Compliance Check"
    RegulatoryFiling -> "Regulatory Filing"
    SystemAlert -> "System Alert"
  }
}

fn report_type_to_string(report_type: ReportType) -> String {
  case report_type {
    AnnualCompliance -> "Annual Compliance"
    QuarterlyAudit -> "Quarterly Audit"
    RegulatoryExamination -> "Regulatory Examination"
    RiskAssessment -> "Risk Assessment"
    IncidentReport -> "Incident Report"
  }
}

fn report_status_to_string(status: ReportStatus) -> String {
  case status {
    ReportDraft -> "Draft"
    ReportUnderReview -> "Under Review"
    ReportSubmitted -> "Submitted"
    ReportAccepted -> "Accepted"
    ReportRejected -> "Rejected"
  }
}

fn finding_status_to_string(status: FindingStatus) -> String {
  case status {
    Open -> "Open"
    InProgress -> "In Progress"
    Resolved -> "Resolved"
    Verified -> "Verified"
  }
}

fn alert_status_to_string(status: AlertStatus) -> String {
  case status {
    AlertPending -> "Pending"
    AlertInProgress -> "In Progress"
    AlertCompleted -> "Completed"
    AlertOverdue -> "Overdue"
  }
}

fn tax_type_to_string(tax_type: TaxType) -> String {
  case tax_type {
    VAT -> "VAT"
    CorporateIncomeTax -> "Corporate Income Tax"
    PayrollTax -> "Payroll Tax"
    WithholdingTax -> "Withholding Tax"
  }
}

fn filing_status_to_string(status: FilingStatus) -> String {
  case status {
    FilingDraft -> "Draft"
    FilingSubmitted -> "Submitted"
    FilingAccepted -> "Accepted"
    FilingRejected -> "Rejected"
    FilingAmended -> "Amended"
  }
}
