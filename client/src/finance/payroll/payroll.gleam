import components/nav
import finance/payroll/types.{
  type Employee, type PayCycle, type PayrollEntry, type PayrollEntryStatus,
  type PayrollPeriod, Biweekly, Employee, EntryCompleted, EntryFailed,
  EntryPending, EntryProcessing, Monthly, PayrollEntry, PayrollPeriod,
  PeriodDraft, Weekly,
}
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
    current_period: Option(PayrollPeriod),
    employees: List(Employee),
    payroll_entries: List(PayrollEntry),
    selected_tab: Tab,
  )
}

pub type Tab {
  Overview
  Employees
  Payroll
  Reports
}

pub type Msg {
  NavMsg(nav.Msg)
  SelectTab(Tab)
  AddEmployee(Employee)
  UpdateEmployee(Employee)
  RemoveEmployee(String)
  StartPayrollPeriod(PayrollPeriod)
  ProcessPayroll
  GenerateReport
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub fn init(_) {
  #(
    Model(
      nav_open: False,
      current_period: None,
      employees: [],
      payroll_entries: [],
      selected_tab: Overview,
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
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

    AddEmployee(employee) -> {
      let employees = [employee, ..model.employees]
      #(Model(..model, employees: employees), effect.none())
    }

    UpdateEmployee(updated_employee) -> {
      let employees =
        list.map(model.employees, fn(emp) {
          case emp.id == updated_employee.id {
            True -> updated_employee
            False -> emp
          }
        })
      #(Model(..model, employees: employees), effect.none())
    }

    RemoveEmployee(id) -> {
      let employees = list.filter(model.employees, fn(emp) { emp.id != id })
      #(Model(..model, employees: employees), effect.none())
    }

    StartPayrollPeriod(period) -> {
      let current_period = Some(period)
      let payroll_entries =
        list.map(model.employees, fn(emp) {
          PayrollEntry(
            employee: emp,
            base_salary: emp.salary,
            deductions: [],
            allowances: [],
            net_pay: emp.salary,
            status: EntryPending,
          )
        })
      #(
        Model(
          ..model,
          current_period: current_period,
          payroll_entries: payroll_entries,
        ),
        effect.none(),
      )
    }

    ProcessPayroll -> {
      // TODO: Implement payroll processing logic
      #(model, effect.none())
    }

    GenerateReport -> {
      // TODO: Implement report generation logic
      #(model, effect.none())
    }
  }
}

pub fn view(model: Model) -> Element(Msg) {
  let nav_element = element.map(nav.view(), NavMsg)
  let main_content =
    html.main([attribute.class("payroll-app")], [
      html.header([attribute.class("app-header")], [
        html.h1([], [html.text("Payroll Management")]),
        html.p([attribute.class("header-subtitle")], [
          html.text("Manage employee payroll and payments"),
        ]),
      ]),
      html.div([attribute.class("tabs")], [
        view_tab(Overview, "Overview", model),
        view_tab(Employees, "Employees", model),
        view_tab(Payroll, "Payroll", model),
        view_tab(Reports, "Reports", model),
      ]),
      html.div([attribute.class("main-content")], [
        case model.selected_tab {
          Overview -> view_overview(model)
          Employees -> view_employees(model)
          Payroll -> view_payroll(model)
          Reports -> view_reports(model)
        },
      ]),
    ])

  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [nav_element, main_content],
  )
}

fn view_tab(tab: Tab, label: String, model: Model) -> Element(Msg) {
  html.button(
    [
      attribute.class(case model.selected_tab == tab {
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
    html.div([attribute.class("summary-stats")], [
      view_stat_card(
        "Total Employees",
        int.to_string(list.length(model.employees)),
      ),
      view_stat_card("Current Period", case model.current_period {
        Some(period) -> period.start_date <> " - " <> period.end_date
        None -> "No active period"
      }),
      view_stat_card("Total Payroll", case model.current_period {
        Some(_) ->
          "$"
          <> float.to_string(
            list.fold(model.payroll_entries, 0.0, fn(acc, entry) {
              acc +. entry.net_pay
            }),
          )
        None -> "$0.00"
      }),
    ]),
    html.div([attribute.class("quick-actions")], [
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(
            StartPayrollPeriod(PayrollPeriod(
              start_date: "2024-03-01",
              end_date: "2024-03-31",
              pay_date: "2024-03-31",
              status: PeriodDraft,
            )),
          ),
        ],
        [html.text("Start New Period")],
      ),
      html.button(
        [attribute.class("btn-secondary"), event.on_click(ProcessPayroll)],
        [html.text("Process Payroll")],
      ),
      html.button(
        [attribute.class("btn-secondary"), event.on_click(GenerateReport)],
        [html.text("Generate Report")],
      ),
    ]),
  ])
}

fn view_employees(model: Model) -> Element(Msg) {
  html.div([attribute.class("employees-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Employees")]),
      html.button([attribute.class("btn-primary")], [html.text("Add Employee")]),
    ]),
    html.div(
      [attribute.class("employees-grid")],
      list.map(model.employees, view_employee_card),
    ),
  ])
}

fn view_employee_card(employee: Employee) -> Element(Msg) {
  html.div([attribute.class("employee-card")], [
    html.div([attribute.class("employee-header")], [
      html.h3([], [html.text(employee.name)]),
      html.p([attribute.class("employee-role")], [html.text(employee.role)]),
    ]),
    html.div([attribute.class("employee-details")], [
      html.p([], [html.text("Salary: $" <> float.to_string(employee.salary))]),
      html.p([], [
        html.text(
          "Pay Cycle: "
          <> case employee.pay_cycle {
            Weekly -> "Weekly"
            Biweekly -> "Bi-weekly"
            Monthly -> "Monthly"
          },
        ),
      ]),
    ]),
    html.div([attribute.class("employee-actions")], [
      html.button(
        [
          attribute.class("btn-secondary"),
          event.on_click(UpdateEmployee(employee)),
        ],
        [html.text("Edit")],
      ),
      html.button(
        [
          attribute.class("btn-danger"),
          event.on_click(RemoveEmployee(employee.id)),
        ],
        [html.text("Remove")],
      ),
    ]),
  ])
}

fn view_payroll(model: Model) -> Element(Msg) {
  html.div([attribute.class("payroll-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Current Payroll")]),
      case model.current_period {
        Some(period) ->
          html.p([], [html.text(period.start_date <> " - " <> period.end_date)])
        None -> html.p([], [html.text("No active payroll period")])
      },
    ]),
    html.div(
      [attribute.class("payroll-entries")],
      list.map(model.payroll_entries, view_payroll_entry),
    ),
  ])
}

fn view_payroll_entry(entry: PayrollEntry) -> Element(Msg) {
  html.div([attribute.class("payroll-entry")], [
    html.div([attribute.class("entry-header")], [
      html.h3([], [html.text(entry.employee.name)]),
      html.p([attribute.class("entry-status")], [
        html.text(case entry.status {
          EntryPending -> "Pending"
          EntryProcessing -> "Processing"
          EntryCompleted -> "Completed"
          EntryFailed -> "Failed"
        }),
      ]),
    ]),
    html.div([attribute.class("entry-details")], [
      html.p([], [
        html.text("Base Salary: $" <> float.to_string(entry.base_salary)),
      ]),
      html.p([], [html.text("Net Pay: $" <> float.to_string(entry.net_pay))]),
    ]),
  ])
}

fn view_reports(model: Model) -> Element(Msg) {
  html.div([attribute.class("reports-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Reports")]),
    ]),
    html.div([attribute.class("reports-grid")], [
      view_report_card("Payroll Summary", "Monthly payroll summary report"),
      view_report_card("Tax Report", "Tax deductions and compliance report"),
      view_report_card(
        "Employee Statistics",
        "Employee salary and payment statistics",
      ),
    ]),
  ])
}

fn view_report_card(title: String, description: String) -> Element(Msg) {
  html.div([attribute.class("report-card")], [
    html.h3([], [html.text(title)]),
    html.p([], [html.text(description)]),
    html.button(
      [attribute.class("btn-secondary"), event.on_click(GenerateReport)],
      [html.text("Generate")],
    ),
  ])
}

fn view_stat_card(label: String, value: String) -> Element(Msg) {
  html.div([attribute.class("stat-card")], [
    html.div([attribute.class("stat-value")], [html.text(value)]),
    html.div([attribute.class("stat-label")], [html.text(label)]),
  ])
}
