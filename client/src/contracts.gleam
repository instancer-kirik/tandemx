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
  Model(contracts: Dict(Int, Contract), last_id: Int, nav_open: Bool)
}

pub type Contract {
  Contract(
    id: Int,
    title: String,
    amount: Float,
    status: ContractStatus,
    parties: List(Party),
    terms: String,
    created_at: String,
  )
}

pub type ContractStatus {
  ContractDraft
  ContractPending
  ContractActive
  ContractCompleted
  ContractDisputed
}

pub type Party {
  Party(name: String, role: String, status: PartyStatus)
}

pub type PartyStatus {
  PartyPending
  PartyAccepted
  PartyRejected
}

pub type Msg {
  UserClickedAcceptContract(Int)
  UserClickedRejectContract(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_contracts =
    [
      #(
        1,
        Contract(
          id: 1,
          title: "Student Loan Agreement",
          amount: 25_000.0,
          status: ContractPending,
          parties: [
            Party("Alice Chen", "Borrower", PartyAccepted),
            Party("First National Bank", "Lender", PartyPending),
            Party("Stanford University", "School", PartyAccepted),
          ],
          terms: "Standard student loan terms...",
          created_at: "2024-03-20",
        ),
      ),
      #(
        2,
        Contract(
          id: 2,
          title: "Income Share Agreement",
          amount: 15_000.0,
          status: ContractActive,
          parties: [
            Party("Bob Smith", "Student", PartyAccepted),
            Party("Tech Academy", "School", PartyAccepted),
            Party("ISA Fund LLC", "Investor", PartyAccepted),
          ],
          terms: "Income share agreement terms...",
          created_at: "2024-03-15",
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(contracts: sample_contracts, last_id: 2, nav_open: False),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserClickedAcceptContract(id) -> {
      let contracts = case dict.get(model.contracts, id) {
        Ok(contract) ->
          dict.insert(
            model.contracts,
            id,
            Contract(..contract, status: ContractActive),
          )
        Error(_) -> model.contracts
      }
      #(Model(..model, contracts: contracts), effect.none())
    }

    UserClickedRejectContract(id) -> {
      let contracts = case dict.get(model.contracts, id) {
        Ok(contract) ->
          dict.insert(
            model.contracts,
            id,
            Contract(..contract, status: ContractDisputed),
          )
        Error(_) -> model.contracts
      }
      #(Model(..model, contracts: contracts), effect.none())
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
      html.main([attribute.class("contracts-app")], [
        view_header(),
        view_contracts(model.contracts),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Multiparty Contracts")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage loan agreements and income share contracts"),
    ]),
  ])
}

fn view_contracts(contracts: Dict(Int, Contract)) -> Element(Msg) {
  html.div(
    [attribute.class("contracts-grid")],
    dict.values(contracts)
      |> list.map(view_contract),
  )
}

fn view_contract(contract: Contract) -> Element(Msg) {
  html.div([attribute.class("contract-card")], [
    html.div([attribute.class("contract-header")], [
      html.h3([attribute.class("contract-title")], [html.text(contract.title)]),
      html.span(
        [attribute.class("contract-status " <> status_class(contract.status))],
        [html.text(status_text(contract.status))],
      ),
    ]),
    html.div([attribute.class("contract-amount")], [
      html.text("$" <> float.to_string(contract.amount)),
    ]),
    html.div([attribute.class("contract-parties")], [
      html.h4([], [html.text("Parties")]),
      html.div(
        [attribute.class("party-list")],
        list.map(contract.parties, view_party),
      ),
    ]),
    html.div([attribute.class("contract-terms")], [
      html.h4([], [html.text("Terms")]),
      html.p([], [html.text(contract.terms)]),
    ]),
    html.div([attribute.class("contract-footer")], [
      html.div([attribute.class("contract-date")], [
        html.text("Created: " <> contract.created_at),
      ]),
      case contract.status {
        ContractPending ->
          html.div([attribute.class("contract-actions")], [
            html.button(
              [
                attribute.class("btn-accept"),
                event.on_click(UserClickedAcceptContract(contract.id)),
              ],
              [html.text("Accept")],
            ),
            html.button(
              [
                attribute.class("btn-reject"),
                event.on_click(UserClickedRejectContract(contract.id)),
              ],
              [html.text("Reject")],
            ),
          ])
        _ -> html.text("")
      },
    ]),
  ])
}

fn view_party(party: Party) -> Element(Msg) {
  html.div([attribute.class("party-item")], [
    html.div([attribute.class("party-info")], [
      html.span([attribute.class("party-name")], [html.text(party.name)]),
      html.span([attribute.class("party-role")], [html.text(party.role)]),
    ]),
    html.span(
      [attribute.class("party-status " <> party_status_class(party.status))],
      [html.text(party_status_text(party.status))],
    ),
  ])
}

fn status_class(status: ContractStatus) -> String {
  case status {
    ContractDraft -> "status-draft"
    ContractPending -> "status-pending"
    ContractActive -> "status-active"
    ContractCompleted -> "status-completed"
    ContractDisputed -> "status-disputed"
  }
}

fn status_text(status: ContractStatus) -> String {
  case status {
    ContractDraft -> "Draft"
    ContractPending -> "Pending"
    ContractActive -> "Active"
    ContractCompleted -> "Completed"
    ContractDisputed -> "Disputed"
  }
}

fn party_status_class(status: PartyStatus) -> String {
  case status {
    PartyPending -> "status-pending"
    PartyAccepted -> "status-accepted"
    PartyRejected -> "status-rejected"
  }
}

fn party_status_text(status: PartyStatus) -> String {
  case status {
    PartyPending -> "Pending"
    PartyAccepted -> "Accepted"
    PartyRejected -> "Rejected"
  }
}
