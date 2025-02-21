import components/nav
import gleam/dict.{type Dict}
import gleam/float
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
  )
}

pub type Loan {
  Loan(
    id: Int,
    borrower: String,
    amount: Float,
    status: LoanStatus,
    school: Option(String),
    lender: Option(String),
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

pub type Msg {
  UserAddedLoan
  UserUpdatedNewLoan(String)
  UserClickedFilter(Filter)
  UserClickedApprove(Int)
  UserClickedDefault(Int)
  UserClickedComplete(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
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
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
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
  html.div([], [
    element.map(nav.view(), NavMsg),
    html.div([attribute.class("divvyqueue-app")], [
      html.section([attribute.class("loan-header")], [
        html.h1([], [html.text("DivvyQueue")]),
      ]),
      html.section([attribute.class("loan-input")], [
        html.input([
          attribute.type_("text"),
          attribute.placeholder("Add new loan..."),
          attribute.value(model.new_loan_input),
          event.on_input(fn(str) { UserUpdatedNewLoan(str) }),
        ]),
        html.button([event.on_click(UserAddedLoan)], [html.text("Add")]),
      ]),
      view_filters(model.filter),
      view_loans(model.loans, model.filter),
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

fn view_loans(loans: Dict(Int, Loan), filter: Filter) -> Element(Msg) {
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
      |> list.map(view_loan),
  )
}

fn view_loan(loan: Loan) -> Element(Msg) {
  html.div([attribute.class("loan-item")], [
    html.div([attribute.class("loan-info")], [
      html.div([attribute.class("loan-borrower")], [html.text(loan.borrower)]),
      html.div([attribute.class("loan-amount")], [
        html.text("$" <> float.to_string(loan.amount)),
      ]),
      html.div([attribute.class("loan-status " <> status_class(loan.status))], [
        html.text(status_text(loan.status)),
      ]),
      case loan.school {
        Some(school) ->
          html.div([attribute.class("loan-school")], [html.text(school)])
        None -> html.text("")
      },
    ]),
    html.div([attribute.class("loan-actions")], case loan.status {
      LoanPending -> [
        action_button("Approve", UserClickedApprove(loan.id)),
        action_button("Default", UserClickedDefault(loan.id)),
      ]
      LoanActive -> [action_button("Complete", UserClickedComplete(loan.id))]
      _ -> []
    }),
  ])
}

fn action_button(label: String, msg: Msg) -> Element(Msg) {
  html.button([event.on("click", fn(_) { Ok(msg) })], [html.text(label)])
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
