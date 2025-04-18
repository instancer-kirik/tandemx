import gleam/float
import gleam/list
import gleam/string
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type PaymentMethod {
  CreditCard
  BankTransfer
  Crypto
}

pub type CardType {
  Visa
  Mastercard
  Amex
  Other
}

pub type PaymentState {
  SelectingMethod
  EnteringCardDetails
  EnteringBankDetails
  EnteringCryptoDetails
  ProcessingPayment
  PaymentComplete
  PaymentError(String)
}

pub type Model {
  Model(
    amount: Float,
    currency: String,
    selected_method: PaymentMethod,
    payment_state: PaymentState,
    card_number: String,
    card_expiry: String,
    card_cvc: String,
    card_type: CardType,
    bank_account: String,
    bank_routing: String,
    crypto_address: String,
    error_message: String,
  )
}

pub type Msg {
  SelectPaymentMethod(PaymentMethod)
  UpdateCardNumber(String)
  UpdateCardExpiry(String)
  UpdateCardCVC(String)
  UpdateBankAccount(String)
  UpdateBankRouting(String)
  UpdateCryptoAddress(String)
  SubmitPayment
  PaymentProcessed
  PaymentFailed(String)
  NavigateBack
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(
    Model(
      amount: 0.0,
      currency: "USD",
      selected_method: CreditCard,
      payment_state: SelectingMethod,
      card_number: "",
      card_expiry: "",
      card_cvc: "",
      card_type: Other,
      bank_account: "",
      bank_routing: "",
      crypto_address: "",
      error_message: "",
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SelectPaymentMethod(method) -> {
      let payment_state = case method {
        CreditCard -> EnteringCardDetails
        BankTransfer -> EnteringBankDetails
        Crypto -> EnteringCryptoDetails
      }
      #(
        Model(..model, selected_method: method, payment_state: payment_state),
        effect.none(),
      )
    }

    UpdateCardNumber(number) -> {
      let card_type = detect_card_type(number)
      #(
        Model(..model, card_number: number, card_type: card_type),
        effect.none(),
      )
    }

    UpdateCardExpiry(expiry) -> {
      #(Model(..model, card_expiry: expiry), effect.none())
    }

    UpdateCardCVC(cvc) -> {
      #(Model(..model, card_cvc: cvc), effect.none())
    }

    UpdateBankAccount(account) -> {
      #(Model(..model, bank_account: account), effect.none())
    }

    UpdateBankRouting(routing) -> {
      #(Model(..model, bank_routing: routing), effect.none())
    }

    UpdateCryptoAddress(address) -> {
      #(Model(..model, crypto_address: address), effect.none())
    }

    SubmitPayment -> {
      #(Model(..model, payment_state: ProcessingPayment), process_payment())
    }

    PaymentProcessed -> {
      #(Model(..model, payment_state: PaymentComplete), effect.none())
    }

    PaymentFailed(error) -> {
      #(
        Model(..model, payment_state: PaymentError(error), error_message: error),
        effect.none(),
      )
    }

    NavigateBack -> {
      #(Model(..model, payment_state: SelectingMethod), effect.none())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("payment-container")], [
    html.div([class("payment-header")], [
      html.h1([class("payment-title")], [html.text("Payment")]),
      html.div([class("payment-amount")], [
        html.text(model.currency <> " " <> float.to_string(model.amount)),
      ]),
    ]),
    case model.payment_state {
      SelectingMethod -> view_payment_methods()
      EnteringCardDetails -> view_card_form(model)
      EnteringBankDetails -> view_bank_form(model)
      EnteringCryptoDetails -> view_crypto_form(model)
      ProcessingPayment -> view_processing()
      PaymentComplete -> view_success()
      PaymentError(error) -> view_error(error)
    },
  ])
}

fn view_payment_methods() -> Element(Msg) {
  html.div([class("payment-methods")], [
    html.h2([class("section-title")], [html.text("Select Payment Method")]),
    html.div([class("payment-options")], [
      payment_method_button(CreditCard, "Credit Card", "💳"),
      payment_method_button(BankTransfer, "Bank Transfer", "🏦"),
      payment_method_button(Crypto, "Cryptocurrency", "₿"),
    ]),
  ])
}

fn payment_method_button(
  method: PaymentMethod,
  label: String,
  icon: String,
) -> Element(Msg) {
  html.button(
    [class("payment-method-btn"), event.on_click(SelectPaymentMethod(method))],
    [
      html.span([class("payment-method-icon")], [html.text(icon)]),
      html.span([class("payment-method-label")], [html.text(label)]),
    ],
  )
}

fn view_card_form(model: Model) -> Element(Msg) {
  html.form([class("payment-form card-form")], [
    html.div([class("form-header")], [
      html.h2([], [html.text("Enter Card Details")]),
      html.button([class("back-button"), event.on_click(NavigateBack)], [
        html.text("← Back"),
      ]),
    ]),
    html.div([class("form-group")], [
      html.label([class("form-label")], [html.text("Card Number")]),
      html.input([
        class("form-input"),
        attribute.type_("text"),
        attribute.placeholder("1234 5678 9012 3456"),
        attribute.value(model.card_number),
        event.on_input(UpdateCardNumber),
      ]),
    ]),
    html.div([class("form-row")], [
      html.div([class("form-group")], [
        html.label([class("form-label")], [html.text("Expiry")]),
        html.input([
          class("form-input"),
          attribute.type_("text"),
          attribute.placeholder("MM/YY"),
          attribute.value(model.card_expiry),
          event.on_input(UpdateCardExpiry),
        ]),
      ]),
      html.div([class("form-group")], [
        html.label([class("form-label")], [html.text("CVC")]),
        html.input([
          class("form-input"),
          attribute.type_("text"),
          attribute.placeholder("123"),
          attribute.value(model.card_cvc),
          event.on_input(UpdateCardCVC),
        ]),
      ]),
    ]),
    html.button([class("submit-button"), event.on_click(SubmitPayment)], [
      html.text("Pay Now"),
    ]),
  ])
}

fn view_bank_form(model: Model) -> Element(Msg) {
  html.form([class("payment-form bank-form")], [
    html.div([class("form-header")], [
      html.h2([], [html.text("Enter Bank Details")]),
      html.button([class("back-button"), event.on_click(NavigateBack)], [
        html.text("← Back"),
      ]),
    ]),
    html.div([class("form-group")], [
      html.label([class("form-label")], [html.text("Account Number")]),
      html.input([
        class("form-input"),
        attribute.type_("text"),
        attribute.placeholder("Enter account number"),
        attribute.value(model.bank_account),
        event.on_input(UpdateBankAccount),
      ]),
    ]),
    html.div([class("form-group")], [
      html.label([class("form-label")], [html.text("Routing Number")]),
      html.input([
        class("form-input"),
        attribute.type_("text"),
        attribute.placeholder("Enter routing number"),
        attribute.value(model.bank_routing),
        event.on_input(UpdateBankRouting),
      ]),
    ]),
    html.button([class("submit-button"), event.on_click(SubmitPayment)], [
      html.text("Pay Now"),
    ]),
  ])
}

fn view_crypto_form(model: Model) -> Element(Msg) {
  html.form([class("payment-form crypto-form")], [
    html.div([class("form-header")], [
      html.h2([], [html.text("Enter Crypto Details")]),
      html.button([class("back-button"), event.on_click(NavigateBack)], [
        html.text("← Back"),
      ]),
    ]),
    html.div([class("form-group")], [
      html.label([class("form-label")], [html.text("Wallet Address")]),
      html.input([
        class("form-input"),
        attribute.type_("text"),
        attribute.placeholder("Enter wallet address"),
        attribute.value(model.crypto_address),
        event.on_input(UpdateCryptoAddress),
      ]),
    ]),
    html.button([class("submit-button"), event.on_click(SubmitPayment)], [
      html.text("Pay Now"),
    ]),
  ])
}

fn view_processing() -> Element(Msg) {
  html.div([class("payment-status processing")], [
    html.div([class("spinner")], []),
    html.p([], [html.text("Processing your payment...")]),
  ])
}

fn view_success() -> Element(Msg) {
  html.div([class("payment-status success")], [
    html.div([class("success-icon")], [html.text("✓")]),
    html.h2([], [html.text("Payment Successful!")]),
    html.p([], [html.text("Thank you for your payment.")]),
  ])
}

fn view_error(error: String) -> Element(Msg) {
  html.div([class("payment-status error")], [
    html.div([class("error-icon")], [html.text("!")]),
    html.h2([], [html.text("Payment Failed")]),
    html.p([], [html.text(error)]),
    html.button([class("retry-button"), event.on_click(NavigateBack)], [
      html.text("Try Again"),
    ]),
  ])
}

fn detect_card_type(number: String) -> CardType {
  // Simple card type detection based on first digit
  case string.first(number) {
    Ok("4") -> Visa
    Ok("5") -> Mastercard
    Ok("3") -> Amex
    _ -> Other
  }
}

fn process_payment() -> Effect(Msg) {
  // TODO: Implement actual payment processing
  // For now, just simulate a successful payment after a delay
  use dispatch <- effect.from
  dispatch(PaymentProcessed)
}
