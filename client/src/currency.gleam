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
    exchange_rates: Dict(String, Float),
    selected_base_currency: Currency,
    crypto_rates: Dict(String, Float),
    currency_preferences: CurrencyPreferences,
    transaction_history: Dict(Int, CurrencyTransaction),
    wallet_balances: Dict(String, Float),
    nav_open: Bool,
  )
}

pub type Currency {
  USD
  GBP
  EUR
  NGN
  KES
  ZAR
  BTC
  ETH
}

pub type CurrencyPreferences {
  CurrencyPreferences(
    default_currency: Currency,
    enabled_currencies: List(Currency),
    auto_convert: Bool,
    notification_threshold: Float,
  )
}

pub type CurrencyTransaction {
  CurrencyTransaction(
    id: Int,
    from_currency: Currency,
    to_currency: Currency,
    amount: Float,
    converted_amount: Float,
    rate: Float,
    date: String,
    status: TransactionStatus,
  )
}

pub type TransactionStatus {
  Completed
  Pending
  Failed
}

pub type Msg {
  SetBaseCurrency(Currency)
  ToggleCurrency(Currency, Bool)
  SetAutoConvert(Bool)
  SetNotificationThreshold(Float)
  AddWalletBalance(String, Float)
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
      #("BTC", 0.000037),
      #("ETH", 0.00054),
    ]
    |> dict.from_list()

  let sample_wallet_balances =
    [
      #("USD", 2500.0),
      #("EUR", 1800.0),
      #("GBP", 1200.0),
      #("BTC", 0.15),
      #("ETH", 2.5),
    ]
    |> dict.from_list()

  let sample_preferences =
    CurrencyPreferences(
      default_currency: USD,
      enabled_currencies: [USD, EUR, GBP, BTC, ETH],
      auto_convert: True,
      notification_threshold: 5.0,
    )

  let sample_transactions =
    [
      #(
        1,
        CurrencyTransaction(
          id: 1,
          from_currency: USD,
          to_currency: EUR,
          amount: 1000.0,
          converted_amount: 920.0,
          rate: 0.92,
          date: "2024-03-20",
          status: Completed,
        ),
      ),
      #(
        2,
        CurrencyTransaction(
          id: 2,
          from_currency: GBP,
          to_currency: USD,
          amount: 500.0,
          converted_amount: 632.91,
          rate: 1.27,
          date: "2024-03-19",
          status: Completed,
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      exchange_rates: sample_exchange_rates,
      selected_base_currency: USD,
      crypto_rates: dict.new(),
      currency_preferences: sample_preferences,
      transaction_history: sample_transactions,
      wallet_balances: sample_wallet_balances,
      nav_open: False,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SetBaseCurrency(currency) -> {
      let preferences =
        CurrencyPreferences(
          ..model.currency_preferences,
          default_currency: currency,
        )
      #(Model(..model, currency_preferences: preferences), effect.none())
    }

    ToggleCurrency(currency, enabled) -> {
      let enabled_currencies = case enabled {
        True -> [currency, ..model.currency_preferences.enabled_currencies]
        False ->
          list.filter(model.currency_preferences.enabled_currencies, fn(c) {
            c != currency
          })
      }
      let preferences =
        CurrencyPreferences(
          ..model.currency_preferences,
          enabled_currencies: enabled_currencies,
        )
      #(Model(..model, currency_preferences: preferences), effect.none())
    }

    SetAutoConvert(enabled) -> {
      let preferences =
        CurrencyPreferences(..model.currency_preferences, auto_convert: enabled)
      #(Model(..model, currency_preferences: preferences), effect.none())
    }

    SetNotificationThreshold(threshold) -> {
      let preferences =
        CurrencyPreferences(
          ..model.currency_preferences,
          notification_threshold: threshold,
        )
      #(Model(..model, currency_preferences: preferences), effect.none())
    }

    AddWalletBalance(currency, amount) -> {
      let new_balances = dict.insert(model.wallet_balances, currency, amount)
      #(Model(..model, wallet_balances: new_balances), effect.none())
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
      html.main([attribute.class("currency-app")], [
        view_header(),
        view_wallet(model),
        view_exchange_dashboard(model),
        view_preferences(model.currency_preferences),
        view_transaction_history(model.transaction_history),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Currency Management")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage currencies, exchange rates, and preferences"),
    ]),
  ])
}

fn view_wallet(model: Model) -> Element(Msg) {
  html.section([attribute.class("wallet-section")], [
    html.h2([], [html.text("Your Wallet")]),
    html.div([attribute.class("wallet-grid")], [
      html.div([attribute.class("fiat-balances")], [
        html.h3([], [html.text("Fiat Balances")]),
        html.div(
          [attribute.class("balance-grid")],
          dict.filter(model.wallet_balances, fn(key, _) {
            key != "BTC" && key != "ETH"
          })
            |> dict.to_list
            |> list.map(fn(pair) {
              let #(currency, balance) = pair
              view_balance_card(
                currency,
                balance,
                dict.get(model.exchange_rates, currency)
                  |> result.unwrap(1.0),
                model.selected_base_currency,
              )
            }),
        ),
      ]),
      html.div([attribute.class("crypto-balances")], [
        html.h3([], [html.text("Crypto Balances")]),
        html.div([attribute.class("balance-grid")], [
          view_balance_card(
            "BTC",
            dict.get(model.wallet_balances, "BTC")
              |> result.unwrap(0.0),
            dict.get(model.exchange_rates, "BTC")
              |> result.unwrap(0.0),
            model.selected_base_currency,
          ),
          view_balance_card(
            "ETH",
            dict.get(model.wallet_balances, "ETH")
              |> result.unwrap(0.0),
            dict.get(model.exchange_rates, "ETH")
              |> result.unwrap(0.0),
            model.selected_base_currency,
          ),
        ]),
      ]),
    ]),
  ])
}

fn view_balance_card(
  currency: String,
  balance: Float,
  rate: Float,
  base_currency: Currency,
) -> Element(Msg) {
  let base_value = balance *. rate
  html.div([attribute.class("balance-card")], [
    html.div([attribute.class("balance-currency")], [html.text(currency)]),
    html.div([attribute.class("balance-amount")], [
      html.strong([], [html.text(float.to_string(balance) <> " " <> currency)]),
      html.div([attribute.class("converted-amount")], [
        html.text(
          "≈ "
          <> float.to_string(base_value)
          <> " "
          <> currency_to_string(base_currency),
        ),
      ]),
    ]),
  ])
}

fn view_exchange_dashboard(model: Model) -> Element(Msg) {
  html.section([attribute.class("exchange-dashboard")], [
    html.h2([], [html.text("Exchange Rates")]),
    html.div([attribute.class("rate-cards")], [
      html.div([attribute.class("fiat-rates")], [
        html.h3([], [html.text("Fiat Currencies")]),
        html.div(
          [attribute.class("rate-grid")],
          dict.filter(model.exchange_rates, fn(key, _) {
            key != "BTC" && key != "ETH"
          })
            |> dict.to_list
            |> list.map(fn(pair) {
              let #(currency, rate) = pair
              view_rate_card(currency, rate, model.selected_base_currency)
            }),
        ),
      ]),
      html.div([attribute.class("crypto-rates")], [
        html.h3([], [html.text("Cryptocurrencies")]),
        html.div([attribute.class("rate-grid")], [
          view_rate_card(
            "BTC",
            dict.get(model.exchange_rates, "BTC")
              |> result.unwrap(0.0),
            model.selected_base_currency,
          ),
          view_rate_card(
            "ETH",
            dict.get(model.exchange_rates, "ETH")
              |> result.unwrap(0.0),
            model.selected_base_currency,
          ),
        ]),
      ]),
    ]),
  ])
}

fn view_rate_card(
  currency: String,
  rate: Float,
  base_currency: Currency,
) -> Element(Msg) {
  html.div([attribute.class("rate-card")], [
    html.div([attribute.class("currency-code")], [html.text(currency)]),
    html.div([attribute.class("exchange-rate")], [
      html.text("1 " <> currency_to_string(base_currency) <> " = "),
      html.strong([], [html.text(float.to_string(rate) <> " " <> currency)]),
    ]),
  ])
}

fn view_preferences(preferences: CurrencyPreferences) -> Element(Msg) {
  html.section([attribute.class("currency-preferences")], [
    html.h2([], [html.text("Preferences")]),
    html.div([attribute.class("preferences-grid")], [
      html.div([attribute.class("preference-group")], [
        html.label([], [html.text("Default Currency")]),
        html.select(
          [
            event.on_input(fn(value) {
              SetBaseCurrency(string_to_currency(value))
            }),
          ],
          [USD, EUR, GBP, NGN, KES, ZAR, BTC, ETH]
            |> list.map(fn(currency) {
              html.option(
                [
                  attribute.value(currency_to_string(currency)),
                  attribute.selected(currency == preferences.default_currency),
                ],
                currency_to_string(currency),
              )
            }),
        ),
      ]),
      html.div([attribute.class("preference-group")], [
        html.label([], [html.text("Auto-Convert")]),
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(preferences.auto_convert),
          event.on_check(SetAutoConvert),
        ]),
      ]),
      html.div([attribute.class("preference-group")], [
        html.label([], [html.text("Rate Change Notification Threshold (%)")]),
        html.input([
          attribute.type_("number"),
          attribute.value(float.to_string(preferences.notification_threshold)),
          event.on_input(fn(value) {
            SetNotificationThreshold(
              float.parse(value)
              |> result.unwrap(5.0),
            )
          }),
        ]),
      ]),
    ]),
  ])
}

fn view_transaction_history(
  transactions: Dict(Int, CurrencyTransaction),
) -> Element(Msg) {
  html.section([attribute.class("transaction-history")], [
    html.h2([], [html.text("Recent Conversions")]),
    html.div(
      [attribute.class("transaction-list")],
      dict.values(transactions)
        |> list.map(view_transaction),
    ),
  ])
}

fn view_transaction(transaction: CurrencyTransaction) -> Element(Msg) {
  html.div([attribute.class("transaction-item")], [
    html.div([attribute.class("transaction-details")], [
      html.div([attribute.class("conversion-amount")], [
        html.text(
          float.to_string(transaction.amount)
          <> " "
          <> currency_to_string(transaction.from_currency)
          <> " → "
          <> float.to_string(transaction.converted_amount)
          <> " "
          <> currency_to_string(transaction.to_currency),
        ),
      ]),
      html.div([attribute.class("conversion-rate")], [
        html.text("Rate: " <> float.to_string(transaction.rate)),
      ]),
    ]),
    html.div([attribute.class("transaction-meta")], [
      html.div([attribute.class("transaction-date")], [
        html.text(transaction.date),
      ]),
      html.div(
        [
          attribute.class(
            "transaction-status "
            <> case transaction.status {
              Completed -> "status-completed"
              Pending -> "status-pending"
              Failed -> "status-failed"
            },
          ),
        ],
        [
          html.text(case transaction.status {
            Completed -> "Completed"
            Pending -> "Pending"
            Failed -> "Failed"
          }),
        ],
      ),
    ]),
  ])
}

fn currency_to_string(currency: Currency) -> String {
  case currency {
    USD -> "USD"
    GBP -> "GBP"
    EUR -> "EUR"
    NGN -> "NGN"
    KES -> "KES"
    ZAR -> "ZAR"
    BTC -> "BTC"
    ETH -> "ETH"
  }
}

fn string_to_currency(str: String) -> Currency {
  case str {
    "USD" -> USD
    "GBP" -> GBP
    "EUR" -> EUR
    "NGN" -> NGN
    "KES" -> KES
    "ZAR" -> ZAR
    "BTC" -> BTC
    "ETH" -> ETH
    _ -> USD
  }
}
