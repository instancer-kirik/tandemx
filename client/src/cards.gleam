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
    cards: Dict(Int, Card),
    transactions: Dict(Int, Transaction),
    subscriptions: Dict(Int, Subscription),
    last_id: Int,
    nav_open: Bool,
  )
}

pub type Card {
  Card(
    id: Int,
    name: String,
    number: String,
    balance: Float,
    status: CardStatus,
    limit: Float,
  )
}

pub type CardStatus {
  CardActive
  CardFrozen
  CardCancelled
}

pub type Transaction {
  Transaction(
    id: Int,
    card_id: Int,
    amount: Float,
    merchant: String,
    date: String,
    status: TransactionStatus,
  )
}

pub type TransactionStatus {
  TransactionPending
  TransactionCompleted
  TransactionDeclined
}

pub type Subscription {
  Subscription(
    id: Int,
    name: String,
    amount: Float,
    frequency: String,
    next_charge: String,
    card_id: Int,
  )
}

pub type Msg {
  UserClickedFreezeCard(Int)
  UserClickedUnfreezeCard(Int)
  UserClickedCancelCard(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_cards =
    [
      #(
        1,
        Card(
          id: 1,
          name: "Daily Expenses",
          number: "**** **** **** 1234",
          balance: 1500.0,
          status: CardActive,
          limit: 2000.0,
        ),
      ),
      #(
        2,
        Card(
          id: 2,
          name: "Business Travel",
          number: "**** **** **** 5678",
          balance: 3000.0,
          status: CardActive,
          limit: 5000.0,
        ),
      ),
    ]
    |> dict.from_list()

  let sample_transactions =
    [
      #(
        1,
        Transaction(
          id: 1,
          card_id: 1,
          amount: 42.5,
          merchant: "Coffee Shop",
          date: "2024-03-20",
          status: TransactionCompleted,
        ),
      ),
      #(
        2,
        Transaction(
          id: 2,
          card_id: 1,
          amount: 89.99,
          merchant: "Online Store",
          date: "2024-03-19",
          status: TransactionPending,
        ),
      ),
    ]
    |> dict.from_list()

  let sample_subscriptions =
    [
      #(
        1,
        Subscription(
          id: 1,
          name: "Streaming Service",
          amount: 14.99,
          frequency: "Monthly",
          next_charge: "2024-04-01",
          card_id: 1,
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      cards: sample_cards,
      transactions: sample_transactions,
      subscriptions: sample_subscriptions,
      last_id: 2,
      nav_open: False,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserClickedFreezeCard(id) -> {
      let cards = case dict.get(model.cards, id) {
        Ok(card) ->
          dict.insert(model.cards, id, Card(..card, status: CardFrozen))
        Error(_) -> model.cards
      }
      #(Model(..model, cards: cards), effect.none())
    }

    UserClickedUnfreezeCard(id) -> {
      let cards = case dict.get(model.cards, id) {
        Ok(card) ->
          dict.insert(model.cards, id, Card(..card, status: CardActive))
        Error(_) -> model.cards
      }
      #(Model(..model, cards: cards), effect.none())
    }

    UserClickedCancelCard(id) -> {
      let cards = case dict.get(model.cards, id) {
        Ok(card) ->
          dict.insert(model.cards, id, Card(..card, status: CardCancelled))
        Error(_) -> model.cards
      }
      #(Model(..model, cards: cards), effect.none())
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
      html.main([attribute.class("cards-app")], [
        view_header(),
        view_summary_stats(model),
        view_cards(model.cards),
        view_transactions(model.transactions),
        view_subscriptions(model.subscriptions),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Payment Cards")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage your virtual cards and transactions"),
    ]),
  ])
}

fn view_summary_stats(model: Model) -> Element(Msg) {
  let total_balance =
    dict.values(model.cards)
    |> list.fold(0.0, fn(acc, card) { acc +. card.balance })

  html.section([attribute.class("summary-stats")], [
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Total Balance")]),
      html.span([attribute.class("stat-value")], [
        html.text("$" <> float.to_string(total_balance)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Active Cards")]),
      html.span([attribute.class("stat-value")], [
        html.text(
          dict.values(model.cards)
          |> list.filter(fn(c) { c.status == CardActive })
          |> list.length
          |> int.to_string,
        ),
      ]),
    ]),
  ])
}

fn view_cards(cards: Dict(Int, Card)) -> Element(Msg) {
  html.section([attribute.class("cards-section")], [
    html.h2([], [html.text("Your Cards")]),
    html.div(
      [attribute.class("cards-grid")],
      dict.values(cards)
        |> list.map(view_card),
    ),
  ])
}

fn view_card(card: Card) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "card-item "
        <> case card.status {
          CardActive -> "active"
          CardFrozen -> "frozen"
          CardCancelled -> "cancelled"
        },
      ),
    ],
    [
      html.div([attribute.class("card-header")], [
        html.div([attribute.class("card-name")], [html.text(card.name)]),
        html.div([attribute.class("card-number")], [html.text(card.number)]),
      ]),
      html.div([attribute.class("card-details")], [
        html.div([attribute.class("card-balance")], [
          html.span([], [html.text("Balance")]),
          html.strong([], [html.text("$" <> float.to_string(card.balance))]),
        ]),
        html.div([attribute.class("card-limit")], [
          html.span([], [html.text("Limit")]),
          html.strong([], [html.text("$" <> float.to_string(card.limit))]),
        ]),
      ]),
      html.div([attribute.class("card-status")], [
        html.text(case card.status {
          CardActive -> "Active"
          CardFrozen -> "Frozen"
          CardCancelled -> "Cancelled"
        }),
      ]),
      html.div([attribute.class("card-actions")], case card.status {
        CardActive -> [
          html.button([event.on_click(UserClickedFreezeCard(card.id))], [
            html.text("Freeze"),
          ]),
          html.button([event.on_click(UserClickedCancelCard(card.id))], [
            html.text("Cancel"),
          ]),
        ]
        CardFrozen -> [
          html.button([event.on_click(UserClickedUnfreezeCard(card.id))], [
            html.text("Unfreeze"),
          ]),
        ]
        CardCancelled -> []
      }),
    ],
  )
}

fn view_transactions(transactions: Dict(Int, Transaction)) -> Element(Msg) {
  html.section([attribute.class("transactions-section")], [
    html.h2([], [html.text("Recent Transactions")]),
    html.div(
      [attribute.class("transactions-list")],
      dict.values(transactions)
        |> list.map(view_transaction),
    ),
  ])
}

fn view_transaction(transaction: Transaction) -> Element(Msg) {
  html.div([attribute.class("transaction-item")], [
    html.div([attribute.class("transaction-merchant")], [
      html.text(transaction.merchant),
    ]),
    html.div([attribute.class("transaction-amount")], [
      html.text("$" <> float.to_string(transaction.amount)),
    ]),
    html.div([attribute.class("transaction-date")], [
      html.text(transaction.date),
    ]),
    html.div([attribute.class("transaction-status")], [
      html.text(transaction_status_text(transaction.status)),
    ]),
  ])
}

fn view_subscriptions(subscriptions: Dict(Int, Subscription)) -> Element(Msg) {
  html.section([attribute.class("subscriptions-section")], [
    html.h2([], [html.text("Active Subscriptions")]),
    html.div(
      [attribute.class("subscriptions-list")],
      dict.values(subscriptions)
        |> list.map(view_subscription),
    ),
  ])
}

fn view_subscription(subscription: Subscription) -> Element(Msg) {
  html.div([attribute.class("subscription-item")], [
    html.div([attribute.class("subscription-name")], [
      html.text(subscription.name),
    ]),
    html.div([attribute.class("subscription-amount")], [
      html.text(
        "$"
        <> float.to_string(subscription.amount)
        <> " "
        <> subscription.frequency,
      ),
    ]),
    html.div([attribute.class("subscription-next-charge")], [
      html.text("Next charge: " <> subscription.next_charge),
    ]),
  ])
}

fn status_text(status: CardStatus) -> String {
  case status {
    CardActive -> "Active"
    CardFrozen -> "Frozen"
    CardCancelled -> "Cancelled"
  }
}

fn transaction_status_text(status: TransactionStatus) -> String {
  case status {
    TransactionPending -> "Pending"
    TransactionCompleted -> "Completed"
    TransactionDeclined -> "Declined"
  }
}
