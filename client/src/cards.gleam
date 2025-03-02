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
    cards: Dict(Int, Card),
    transactions: Dict(Int, Transaction),
    subscriptions: Dict(Int, Subscription),
    last_id: Int,
    nav_open: Bool,
    exchange_rates: Dict(String, Float),
    wallet_balances: Dict(String, Float),
    expanded_spending_controls: Dict(Int, Bool),
  )
}

pub type Currency {
  USD
  GBP
  EUR
  NGN
  KES
  ZAR
}

pub type Card {
  Card(
    id: Int,
    name: String,
    number: String,
    balance: Float,
    currency: Currency,
    status: CardStatus,
    limit: Float,
    spending_controls: SpendingControls,
  )
}

pub type SpendingControls {
  SpendingControls(
    merchant_categories: List(String),
    country_restrictions: List(String),
    max_transaction_amount: Float,
    daily_limit: Float,
    monthly_limit: Float,
    allowed_days: List(Int),
    allowed_hours: List(Int),
    requires_approval: Bool,
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
    original_amount: Float,
    original_currency: Currency,
    merchant: String,
    merchant_category: String,
    country: String,
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
  UserUpdatedSpendingControls(Int, SpendingControls)
  UserClickedApproveTransaction(Int)
  UserClickedDeclineTransaction(Int)
  UserChangedCardCurrency(Int, Currency)
  ToggleSpendingControls(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_exchange_rates =
    [
      #("USD", 1.0),
      #("GBP", 0.79),
      #("EUR", 0.92),
      #("NGN", 860.0),
      #("KES", 143.0),
      #("ZAR", 19.0),
    ]
    |> dict.from_list()

  let sample_wallet_balances =
    [#("USD", 2500.0), #("EUR", 1800.0), #("GBP", 1200.0)]
    |> dict.from_list()

  let sample_cards =
    [
      #(
        1,
        Card(
          id: 1,
          name: "Daily Expenses",
          number: "**** **** **** 1234",
          balance: 1500.0,
          currency: USD,
          status: CardActive,
          limit: 2000.0,
          spending_controls: SpendingControls(
            merchant_categories: [],
            country_restrictions: [],
            max_transaction_amount: 0.0,
            daily_limit: 0.0,
            monthly_limit: 0.0,
            allowed_days: [],
            allowed_hours: [],
            requires_approval: False,
          ),
        ),
      ),
      #(
        2,
        Card(
          id: 2,
          name: "Business Travel",
          number: "**** **** **** 5678",
          balance: 3000.0,
          currency: EUR,
          status: CardActive,
          limit: 5000.0,
          spending_controls: SpendingControls(
            merchant_categories: [],
            country_restrictions: [],
            max_transaction_amount: 0.0,
            daily_limit: 0.0,
            monthly_limit: 0.0,
            allowed_days: [],
            allowed_hours: [],
            requires_approval: False,
          ),
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
          original_amount: 42.5,
          original_currency: USD,
          merchant: "Coffee Shop",
          merchant_category: "Food",
          country: "USA",
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
          original_amount: 82.79,
          original_currency: EUR,
          merchant: "Online Store",
          merchant_category: "Electronics",
          country: "Germany",
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
      exchange_rates: sample_exchange_rates,
      wallet_balances: sample_wallet_balances,
      expanded_spending_controls: dict.new(),
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

    UserUpdatedSpendingControls(id, spending_controls) -> {
      let cards = case dict.get(model.cards, id) {
        Ok(card) ->
          dict.insert(
            model.cards,
            id,
            Card(..card, spending_controls: spending_controls),
          )
        Error(_) -> model.cards
      }
      #(Model(..model, cards: cards), effect.none())
    }

    UserClickedApproveTransaction(id) -> {
      let transactions = case dict.get(model.transactions, id) {
        Ok(transaction) ->
          dict.insert(
            model.transactions,
            id,
            Transaction(..transaction, status: TransactionCompleted),
          )
        Error(_) -> model.transactions
      }
      #(Model(..model, transactions: transactions), effect.none())
    }

    UserClickedDeclineTransaction(id) -> {
      let transactions = case dict.get(model.transactions, id) {
        Ok(transaction) ->
          dict.insert(
            model.transactions,
            id,
            Transaction(..transaction, status: TransactionDeclined),
          )
        Error(_) -> model.transactions
      }
      #(Model(..model, transactions: transactions), effect.none())
    }

    UserChangedCardCurrency(id, currency) -> {
      let cards = case dict.get(model.cards, id) {
        Ok(card) -> {
          let old_rate =
            dict.get(model.exchange_rates, currency_to_string(card.currency))
            |> result.unwrap(1.0)
          let new_rate =
            dict.get(model.exchange_rates, currency_to_string(currency))
            |> result.unwrap(1.0)
          let new_balance = card.balance *. old_rate /. new_rate
          let new_limit = card.limit *. old_rate /. new_rate

          dict.insert(
            model.cards,
            id,
            Card(
              ..card,
              currency: currency,
              balance: new_balance,
              limit: new_limit,
            ),
          )
        }
        Error(_) -> model.cards
      }
      #(Model(..model, cards: cards), effect.none())
    }

    ToggleSpendingControls(id) -> {
      let expanded_controls = case
        dict.get(model.expanded_spending_controls, id)
      {
        Ok(expanded) ->
          dict.insert(model.expanded_spending_controls, id, !expanded)
        Error(_) -> model.expanded_spending_controls
      }
      #(
        Model(..model, expanded_spending_controls: expanded_controls),
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
      html.main([attribute.class("cards-app")], [
        view_header(),
        view_summary_stats(model),
        view_cards(model),
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

fn view_cards(model: Model) -> Element(Msg) {
  html.section([attribute.class("cards-section")], [
    html.h2([], [html.text("Your Cards")]),
    html.div(
      [attribute.class("cards-grid")],
      dict.values(model.cards)
        |> list.map(fn(card) { view_card(model, card) }),
    ),
  ])
}

fn view_card(model: Model, card: Card) -> Element(Msg) {
  let wallet_balance =
    dict.get(model.wallet_balances, currency_to_string(card.currency))
    |> result.unwrap(0.0)

  let is_expanded = case dict.get(model.expanded_spending_controls, card.id) {
    Ok(expanded) -> expanded
    Error(_) -> False
  }

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
          html.strong([], [
            html.text(
              currency_symbol(card.currency) <> float.to_string(card.balance),
            ),
          ]),
        ]),
        html.div([attribute.class("card-limit")], [
          html.span([], [html.text("Limit")]),
          html.strong([], [
            html.text(
              currency_symbol(card.currency) <> float.to_string(card.limit),
            ),
          ]),
        ]),
      ]),
      html.div([attribute.class("wallet-balance")], [
        html.span([], [html.text("Available in Wallet")]),
        html.strong([], [
          html.text(
            currency_symbol(card.currency) <> float.to_string(wallet_balance),
          ),
        ]),
      ]),
      html.div([attribute.class("card-currency")], [
        html.label([], [html.text("Currency")]),
        html.select(
          [
            event.on_input(fn(value) {
              case value {
                "USD" -> UserChangedCardCurrency(card.id, USD)
                "GBP" -> UserChangedCardCurrency(card.id, GBP)
                "EUR" -> UserChangedCardCurrency(card.id, EUR)
                "NGN" -> UserChangedCardCurrency(card.id, NGN)
                "KES" -> UserChangedCardCurrency(card.id, KES)
                "ZAR" -> UserChangedCardCurrency(card.id, ZAR)
                _ -> UserChangedCardCurrency(card.id, USD)
              }
            }),
          ],
          [
            html.option(
              [attribute.value("USD"), attribute.selected(card.currency == USD)],
              "USD ($)",
            ),
            html.option(
              [attribute.value("GBP"), attribute.selected(card.currency == GBP)],
              "GBP (£)",
            ),
            html.option(
              [attribute.value("EUR"), attribute.selected(card.currency == EUR)],
              "EUR (€)",
            ),
            html.option(
              [attribute.value("NGN"), attribute.selected(card.currency == NGN)],
              "NGN (₦)",
            ),
            html.option(
              [attribute.value("KES"), attribute.selected(card.currency == KES)],
              "KES (KSh)",
            ),
            html.option(
              [attribute.value("ZAR"), attribute.selected(card.currency == ZAR)],
              "ZAR (R)",
            ),
          ],
        ),
      ]),
      html.div([attribute.class("card-status")], [
        html.text(case card.status {
          CardActive -> "Active"
          CardFrozen -> "Frozen"
          CardCancelled -> "Cancelled"
        }),
      ]),
      html.div([attribute.class("spending-controls")], [
        html.div(
          [
            attribute.class("spending-controls-header"),
            event.on_click(ToggleSpendingControls(card.id)),
          ],
          [
            html.h3([], [html.text("Spending Controls")]),
            html.span([attribute.class("toggle-icon")], [
              html.text(case is_expanded {
                True -> "▼"
                False -> "▶"
              }),
            ]),
          ],
        ),
        case is_expanded {
          True ->
            html.div([attribute.class("spending-controls-content")], [
              html.div([attribute.class("control-group")], [
                html.label([], [html.text("Max Transaction Amount")]),
                html.input([
                  attribute.type_("number"),
                  attribute.value(float.to_string(
                    card.spending_controls.max_transaction_amount,
                  )),
                  event.on_input(fn(value) {
                    let amount = case float.parse(value) {
                      Ok(amount) -> amount
                      Error(_) -> 0.0
                    }
                    UserUpdatedSpendingControls(
                      card.id,
                      SpendingControls(
                        ..card.spending_controls,
                        max_transaction_amount: amount,
                      ),
                    )
                  }),
                ]),
              ]),
              html.div([attribute.class("control-group")], [
                html.label([], [html.text("Daily Limit")]),
                html.input([
                  attribute.type_("number"),
                  attribute.value(float.to_string(
                    card.spending_controls.daily_limit,
                  )),
                  event.on_input(fn(value) {
                    let amount = case float.parse(value) {
                      Ok(amount) -> amount
                      Error(_) -> 0.0
                    }
                    UserUpdatedSpendingControls(
                      card.id,
                      SpendingControls(
                        ..card.spending_controls,
                        daily_limit: amount,
                      ),
                    )
                  }),
                ]),
              ]),
              html.div([attribute.class("control-group")], [
                html.label([], [html.text("Monthly Limit")]),
                html.input([
                  attribute.type_("number"),
                  attribute.value(float.to_string(
                    card.spending_controls.monthly_limit,
                  )),
                  event.on_input(fn(value) {
                    let amount = case float.parse(value) {
                      Ok(amount) -> amount
                      Error(_) -> 0.0
                    }
                    UserUpdatedSpendingControls(
                      card.id,
                      SpendingControls(
                        ..card.spending_controls,
                        monthly_limit: amount,
                      ),
                    )
                  }),
                ]),
              ]),
              html.div([attribute.class("control-group")], [
                html.label([], [html.text("Requires Approval")]),
                html.input([
                  attribute.type_("checkbox"),
                  attribute.checked(card.spending_controls.requires_approval),
                  event.on_check(fn(checked) {
                    UserUpdatedSpendingControls(
                      card.id,
                      SpendingControls(
                        ..card.spending_controls,
                        requires_approval: checked,
                      ),
                    )
                  }),
                ]),
              ]),
            ])
          False -> html.text("")
        },
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
      html.div([attribute.class("transaction-category")], [
        html.text(transaction.merchant_category),
      ]),
    ]),
    html.div([attribute.class("transaction-amount")], [
      html.text(
        currency_symbol(transaction.original_currency)
        <> float.to_string(transaction.original_amount),
      ),
      case transaction.original_currency == transaction.original_currency {
        True -> html.text("")
        False ->
          html.div([attribute.class("original-amount")], [
            html.text(
              currency_symbol(transaction.original_currency)
              <> float.to_string(transaction.amount),
            ),
          ])
      },
    ]),
    html.div([attribute.class("transaction-details")], [
      html.text(transaction.date),
      html.div([attribute.class("transaction-country")], [
        html.text(transaction.country),
      ]),
    ]),
    html.div([attribute.class("transaction-status")], [
      html.text(transaction_status_text(transaction.status)),
      case transaction.status {
        TransactionPending ->
          html.div([attribute.class("transaction-actions")], [
            html.button(
              [event.on_click(UserClickedApproveTransaction(transaction.id))],
              [html.text("Approve")],
            ),
            html.button(
              [event.on_click(UserClickedDeclineTransaction(transaction.id))],
              [html.text("Decline")],
            ),
          ])
        _ -> html.text("")
      },
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

fn currency_to_string(currency: Currency) -> String {
  case currency {
    USD -> "USD"
    GBP -> "GBP"
    EUR -> "EUR"
    NGN -> "NGN"
    KES -> "KES"
    ZAR -> "ZAR"
  }
}

fn currency_symbol(currency: Currency) -> String {
  case currency {
    USD -> "$"
    GBP -> "£"
    EUR -> "€"
    NGN -> "₦"
    KES -> "KSh"
    ZAR -> "R"
  }
}
