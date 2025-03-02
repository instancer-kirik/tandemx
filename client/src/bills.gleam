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
    bills: Dict(Int, Bill),
    vendors: Dict(Int, Vendor),
    payment_methods: Dict(Int, PaymentMethod),
    scheduled_payments: Dict(Int, ScheduledPayment),
    last_id: Int,
    nav_open: Bool,
  )
}

pub type Bill {
  Bill(
    id: Int,
    vendor_id: Int,
    amount: Float,
    due_date: String,
    status: BillStatus,
    category: BillCategory,
    reference_number: String,
    payment_method_id: Option(Int),
  )
}

pub type BillStatus {
  BillUnpaid
  BillScheduled
  BillPaid
  BillOverdue
}

pub type BillCategory {
  Utility(UtilityType)
  Telecom(TelecomType)
  InsuranceType(InsuranceKind)
  RealProperty
  Other(String)
}

pub type UtilityType {
  Electricity
  Water
  Gas
}

pub type TelecomType {
  Internet
  Mobile
  Cable
}

pub type InsuranceKind {
  HealthInsurance
  PropertyInsurance
  VehicleInsurance
  BusinessInsurance
}

pub type Vendor {
  Vendor(
    id: Int,
    name: String,
    category: BillCategory,
    payment_methods: List(PaymentMethod),
    auto_pay_enabled: Bool,
    verification_status: VerificationStatus,
  )
}

pub type VerificationStatus {
  VendorVerified
  VendorPending
  VendorUnverified
}

pub type PaymentMethod {
  PaymentMethod(
    id: Int,
    card_id: Option(Int),
    wallet_currency: Option(String),
    name: String,
    is_default: Bool,
  )
}

pub type ScheduledPayment {
  ScheduledPayment(
    id: Int,
    bill_id: Int,
    payment_date: String,
    amount: Float,
    status: ScheduleStatus,
  )
}

pub type ScheduleStatus {
  PaymentPending
  PaymentProcessing
  PaymentCompleted
  PaymentFailed
}

pub type Msg {
  AddBill(Bill)
  UpdateBill(Int, Bill)
  DeleteBill(Int)
  AddVendor(Vendor)
  UpdateVendor(Int, Vendor)
  DeleteVendor(Int)
  SchedulePayment(Int, String)
  CancelScheduledPayment(Int)
  SetDefaultPaymentMethod(Int)
  EnableAutoPay(Int)
  DisableAutoPay(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_vendors =
    [
      #(
        1,
        Vendor(
          id: 1,
          name: "PHCN",
          category: Utility(Electricity),
          payment_methods: [],
          auto_pay_enabled: False,
          verification_status: VendorVerified,
        ),
      ),
      #(
        2,
        Vendor(
          id: 2,
          name: "MTN",
          category: Telecom(Mobile),
          payment_methods: [],
          auto_pay_enabled: False,
          verification_status: VendorVerified,
        ),
      ),
    ]
    |> dict.from_list()

  let sample_bills =
    [
      #(
        1,
        Bill(
          id: 1,
          vendor_id: 1,
          amount: 150.0,
          due_date: "2024-04-15",
          status: BillUnpaid,
          category: Utility(Electricity),
          reference_number: "PHCN-2024-001",
          payment_method_id: None,
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      bills: sample_bills,
      vendors: sample_vendors,
      payment_methods: dict.new(),
      scheduled_payments: dict.new(),
      last_id: 1,
      nav_open: False,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    AddBill(bill) -> {
      let last_id = model.last_id + 1
      let bills = dict.insert(model.bills, last_id, Bill(..bill, id: last_id))
      #(Model(..model, bills: bills, last_id: last_id), effect.none())
    }

    UpdateBill(id, bill) -> {
      let bills = dict.insert(model.bills, id, bill)
      #(Model(..model, bills: bills), effect.none())
    }

    DeleteBill(id) -> {
      let bills = dict.delete(model.bills, id)
      #(Model(..model, bills: bills), effect.none())
    }

    AddVendor(vendor) -> {
      let last_id = model.last_id + 1
      let vendors =
        dict.insert(model.vendors, last_id, Vendor(..vendor, id: last_id))
      #(Model(..model, vendors: vendors, last_id: last_id), effect.none())
    }

    UpdateVendor(id, vendor) -> {
      let vendors = dict.insert(model.vendors, id, vendor)
      #(Model(..model, vendors: vendors), effect.none())
    }

    DeleteVendor(id) -> {
      let vendors = dict.delete(model.vendors, id)
      #(Model(..model, vendors: vendors), effect.none())
    }

    SchedulePayment(bill_id, date) -> {
      let last_id = model.last_id + 1
      let bill =
        dict.get(model.bills, bill_id)
        |> result.unwrap(Bill(0, 0, 0.0, "", BillUnpaid, Other(""), "", None))
      let scheduled_payment =
        ScheduledPayment(
          id: last_id,
          bill_id: bill_id,
          payment_date: date,
          amount: bill.amount,
          status: PaymentPending,
        )
      let scheduled_payments =
        dict.insert(model.scheduled_payments, last_id, scheduled_payment)
      let bills =
        dict.insert(model.bills, bill_id, Bill(..bill, status: BillScheduled))
      #(
        Model(
          ..model,
          scheduled_payments: scheduled_payments,
          bills: bills,
          last_id: last_id,
        ),
        effect.none(),
      )
    }

    CancelScheduledPayment(id) -> {
      let scheduled_payments = dict.delete(model.scheduled_payments, id)
      #(Model(..model, scheduled_payments: scheduled_payments), effect.none())
    }

    SetDefaultPaymentMethod(id) -> {
      let payment_methods =
        dict.map_values(model.payment_methods, fn(_, method) {
          PaymentMethod(..method, is_default: method.id == id)
        })
      #(Model(..model, payment_methods: payment_methods), effect.none())
    }

    EnableAutoPay(vendor_id) -> {
      let vendors = case dict.get(model.vendors, vendor_id) {
        Ok(vendor) ->
          dict.insert(
            model.vendors,
            vendor_id,
            Vendor(..vendor, auto_pay_enabled: True),
          )
        Error(_) -> model.vendors
      }
      #(Model(..model, vendors: vendors), effect.none())
    }

    DisableAutoPay(vendor_id) -> {
      let vendors = case dict.get(model.vendors, vendor_id) {
        Ok(vendor) ->
          dict.insert(
            model.vendors,
            vendor_id,
            Vendor(..vendor, auto_pay_enabled: False),
          )
        Error(_) -> model.vendors
      }
      #(Model(..model, vendors: vendors), effect.none())
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
      html.main([attribute.class("bills-app")], [
        view_header(),
        view_summary_stats(model),
        view_bills(model),
        view_vendors(model),
        view_scheduled_payments(model),
      ]),
    ],
  )
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Bill Payments")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage bills, vendors, and scheduled payments"),
    ]),
  ])
}

fn view_summary_stats(model: Model) -> Element(Msg) {
  let total_unpaid =
    dict.values(model.bills)
    |> list.filter(fn(bill) { bill.status == BillUnpaid })
    |> list.fold(0.0, fn(acc, bill) { acc +. bill.amount })

  let total_scheduled =
    dict.values(model.scheduled_payments)
    |> list.filter(fn(payment) { payment.status == PaymentPending })
    |> list.fold(0.0, fn(acc, payment) { acc +. payment.amount })

  html.section([attribute.class("summary-stats")], [
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Unpaid Bills")]),
      html.span([attribute.class("stat-value")], [
        html.text("$" <> float.to_string(total_unpaid)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [
        html.text("Scheduled Payments"),
      ]),
      html.span([attribute.class("stat-value")], [
        html.text("$" <> float.to_string(total_scheduled)),
      ]),
    ]),
  ])
}

fn view_bills(model: Model) -> Element(Msg) {
  html.section([attribute.class("bills-section")], [
    html.h2([], [html.text("Your Bills")]),
    html.div(
      [attribute.class("bills-grid")],
      dict.values(model.bills)
        |> list.map(fn(bill) { view_bill(model, bill) }),
    ),
  ])
}

fn view_bill(model: Model, bill: Bill) -> Element(Msg) {
  let vendor =
    dict.get(model.vendors, bill.vendor_id)
    |> result.unwrap(Vendor(
      0,
      "Unknown",
      Other(""),
      [],
      False,
      VendorUnverified,
    ))

  html.div([attribute.class("bill-card")], [
    html.div([attribute.class("bill-header")], [
      html.div([attribute.class("bill-title")], [
        html.h3([], [html.text(vendor.name)]),
        html.div([attribute.class("bill-category")], [
          html.text(category_to_string(bill.category)),
        ]),
      ]),
      html.div([attribute.class("bill-amount")], [
        html.text("$" <> float.to_string(bill.amount)),
      ]),
    ]),
    html.div([attribute.class("bill-details")], [
      html.div([attribute.class("bill-due-date")], [
        html.text("Due: " <> bill.due_date),
      ]),
      html.div([attribute.class("bill-reference")], [
        html.text("Ref: " <> bill.reference_number),
      ]),
      html.div(
        [
          attribute.class(
            "bill-status "
            <> case bill.status {
              BillUnpaid -> "status-unpaid"
              BillScheduled -> "status-scheduled"
              BillPaid -> "status-paid"
              BillOverdue -> "status-overdue"
            },
          ),
        ],
        [
          html.text(case bill.status {
            BillUnpaid -> "Unpaid"
            BillScheduled -> "Scheduled"
            BillPaid -> "Paid"
            BillOverdue -> "Overdue"
          }),
        ],
      ),
    ]),
    html.div([attribute.class("bill-actions")], case bill.status {
      BillUnpaid | BillOverdue -> [
        html.button(
          [
            attribute.class("btn-primary"),
            event.on_click(SchedulePayment(bill.id, "")),
          ],
          [html.text("Schedule Payment")],
        ),
      ]
      BillScheduled -> [
        html.button(
          [
            attribute.class("btn-danger"),
            event.on_click(CancelScheduledPayment(bill.id)),
          ],
          [html.text("Cancel Payment")],
        ),
      ]
      _ -> []
    }),
  ])
}

fn view_vendors(model: Model) -> Element(Msg) {
  html.section([attribute.class("vendors-section")], [
    html.h2([], [html.text("Vendors")]),
    html.div(
      [attribute.class("vendors-grid")],
      dict.values(model.vendors)
        |> list.map(view_vendor),
    ),
  ])
}

fn view_vendor(vendor: Vendor) -> Element(Msg) {
  html.div([attribute.class("vendor-card")], [
    html.div([attribute.class("vendor-header")], [
      html.h3([], [html.text(vendor.name)]),
      html.div([attribute.class("vendor-category")], [
        html.text(category_to_string(vendor.category)),
      ]),
    ]),
    html.div([attribute.class("vendor-status")], [
      html.div(
        [
          attribute.class(
            "verification-status "
            <> case vendor.verification_status {
              VendorVerified -> "status-verified"
              VendorPending -> "status-pending"
              VendorUnverified -> "status-unverified"
            },
          ),
        ],
        [
          html.text(case vendor.verification_status {
            VendorVerified -> "Verified"
            VendorPending -> "Pending"
            VendorUnverified -> "Unverified"
          }),
        ],
      ),
    ]),
    html.div([attribute.class("vendor-actions")], [
      html.button(
        [
          attribute.class(case vendor.auto_pay_enabled {
            True -> "btn-danger"
            False -> "btn-primary"
          }),
          event.on_click(case vendor.auto_pay_enabled {
            True -> DisableAutoPay(vendor.id)
            False -> EnableAutoPay(vendor.id)
          }),
        ],
        [
          html.text(case vendor.auto_pay_enabled {
            True -> "Disable Auto-Pay"
            False -> "Enable Auto-Pay"
          }),
        ],
      ),
    ]),
  ])
}

fn view_scheduled_payments(model: Model) -> Element(Msg) {
  html.section([attribute.class("scheduled-payments-section")], [
    html.h2([], [html.text("Scheduled Payments")]),
    html.div(
      [attribute.class("scheduled-payments-grid")],
      dict.values(model.scheduled_payments)
        |> list.map(fn(payment) { view_scheduled_payment(model, payment) }),
    ),
  ])
}

fn view_scheduled_payment(
  model: Model,
  payment: ScheduledPayment,
) -> Element(Msg) {
  let bill =
    dict.get(model.bills, payment.bill_id)
    |> result.unwrap(Bill(0, 0, 0.0, "", BillUnpaid, Other(""), "", None))

  let vendor =
    dict.get(model.vendors, bill.vendor_id)
    |> result.unwrap(Vendor(
      0,
      "Unknown",
      Other(""),
      [],
      False,
      VendorUnverified,
    ))

  html.div([attribute.class("scheduled-payment-card")], [
    html.div([attribute.class("payment-header")], [
      html.h3([], [html.text(vendor.name)]),
      html.div([attribute.class("payment-amount")], [
        html.text("$" <> float.to_string(payment.amount)),
      ]),
    ]),
    html.div([attribute.class("payment-details")], [
      html.div([attribute.class("payment-date")], [
        html.text("Scheduled for: " <> payment.payment_date),
      ]),
      html.div(
        [
          attribute.class(
            "payment-status "
            <> case payment.status {
              PaymentPending -> "status-pending"
              PaymentProcessing -> "status-processing"
              PaymentCompleted -> "status-completed"
              PaymentFailed -> "status-failed"
            },
          ),
        ],
        [
          html.text(case payment.status {
            PaymentPending -> "Pending"
            PaymentProcessing -> "Processing"
            PaymentCompleted -> "Completed"
            PaymentFailed -> "Failed"
          }),
        ],
      ),
    ]),
    html.div([attribute.class("payment-actions")], case payment.status {
      PaymentPending -> [
        html.button(
          [
            attribute.class("btn-danger"),
            event.on_click(CancelScheduledPayment(payment.id)),
          ],
          [html.text("Cancel")],
        ),
      ]
      _ -> []
    }),
  ])
}

fn category_to_string(category: BillCategory) -> String {
  case category {
    Utility(type_) ->
      "Utility - "
      <> case type_ {
        Electricity -> "Electricity"
        Water -> "Water"
        Gas -> "Gas"
      }
    Telecom(type_) ->
      "Telecom - "
      <> case type_ {
        Internet -> "Internet"
        Mobile -> "Mobile"
        Cable -> "Cable"
      }
    InsuranceType(type_) ->
      "Insurance - "
      <> case type_ {
        HealthInsurance -> "Health"
        PropertyInsurance -> "Property"
        VehicleInsurance -> "Vehicle"
        BusinessInsurance -> "Business"
      }
    RealProperty -> "Property"
    Other(name) -> name
  }
}
