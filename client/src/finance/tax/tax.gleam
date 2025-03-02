import components/nav
import finance/tax/types.{
  type DocumentStatus, type FilingFrequency, type FilingStatus, type TaxCategory,
  type TaxDocument, type TaxFiling, type TaxRate, type TaxRegion,
  type TaxSettings, Annually, CorporateIncomeTax, CustomTax, Draft, Kenya, Late,
  Monthly, Nigeria, Other, Overdue, Paid, PayrollTax, Pending, Quarterly,
  Rejected, SouthAfrica, Submitted, TaxDocument, TaxFiling, TaxRate, TaxSettings,
  VAT, Verified, WithholdingTax,
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
    settings: TaxSettings,
    filings: List(TaxFiling),
    documents: List(TaxDocument),
    selected_tab: Tab,
  )
}

pub type Tab {
  Overview
  Filings
  Documents
  Settings
}

pub type Msg {
  NavMsg(nav.Msg)
  SelectTab(Tab)
  UpdateSettings(TaxSettings)
  AddFiling(TaxFiling)
  UpdateFiling(TaxFiling)
  RemoveFiling(String)
  AddDocument(TaxDocument)
  UpdateDocument(TaxDocument)
  RemoveDocument(String)
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
      settings: TaxSettings("", Nigeria, Monthly, [
        TaxRate(VAT, 7.5, "2024-01-01", Nigeria),
        TaxRate(CorporateIncomeTax, 30.0, "2024-01-01", Nigeria),
        TaxRate(PayrollTax, 10.0, "2024-01-01", Nigeria),
        TaxRate(WithholdingTax, 5.0, "2024-01-01", Nigeria),
      ]),
      filings: [],
      documents: [],
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

    UpdateSettings(settings) -> #(
      Model(..model, settings: settings),
      effect.none(),
    )

    AddFiling(filing) -> {
      let filings = [filing, ..model.filings]
      #(Model(..model, filings: filings), effect.none())
    }

    UpdateFiling(updated_filing) -> {
      let filings =
        list.map(model.filings, fn(filing) {
          case filing.id == updated_filing.id {
            True -> updated_filing
            False -> filing
          }
        })
      #(Model(..model, filings: filings), effect.none())
    }

    RemoveFiling(id) -> {
      let filings = list.filter(model.filings, fn(filing) { filing.id != id })
      #(Model(..model, filings: filings), effect.none())
    }

    AddDocument(document) -> {
      let documents = [document, ..model.documents]
      #(Model(..model, documents: documents), effect.none())
    }

    UpdateDocument(updated_document) -> {
      let documents =
        list.map(model.documents, fn(doc) {
          case doc.id == updated_document.id {
            True -> updated_document
            False -> doc
          }
        })
      #(Model(..model, documents: documents), effect.none())
    }

    RemoveDocument(id) -> {
      let documents = list.filter(model.documents, fn(doc) { doc.id != id })
      #(Model(..model, documents: documents), effect.none())
    }
  }
}

pub fn view(model: Model) -> Element(Msg) {
  let nav_element = element.map(nav.view(), NavMsg)
  let main_content =
    html.main([attribute.class("tax-app")], [
      html.header([attribute.class("app-header")], [
        html.h1([], [html.text("Tax Management")]),
        html.p([attribute.class("header-subtitle")], [
          html.text("Manage tax filings and compliance"),
        ]),
      ]),
      html.div([attribute.class("tabs")], [
        view_tab(Overview, "Overview", model),
        view_tab(Filings, "Filings", model),
        view_tab(Documents, "Documents", model),
        view_tab(Settings, "Settings", model),
      ]),
      html.div([attribute.class("main-content")], [
        case model.selected_tab {
          Overview -> view_overview(model)
          Filings -> view_filings(model)
          Documents -> view_documents(model)
          Settings -> view_settings(model)
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
      view_stat_card("Total Filings", int.to_string(list.length(model.filings))),
      view_stat_card(
        "Pending Filings",
        int.to_string(
          list.length(
            list.filter(model.filings, fn(filing) { filing.status == Draft }),
          ),
        ),
      ),
      view_stat_card(
        "Overdue Filings",
        int.to_string(
          list.length(
            list.filter(model.filings, fn(filing) { filing.status == Overdue }),
          ),
        ),
      ),
    ]),
    html.div([attribute.class("tax-rates")], [
      html.h2([], [html.text("Current Tax Rates")]),
      html.div(
        [attribute.class("rates-grid")],
        list.map(model.settings.tax_rates, view_tax_rate),
      ),
    ]),
  ])
}

fn view_tax_rate(rate: TaxRate) -> Element(Msg) {
  html.div([attribute.class("tax-rate-card")], [
    html.div([attribute.class("rate-header")], [
      html.h3([], [
        html.text(case rate.category {
          VAT -> "Value Added Tax"
          CorporateIncomeTax -> "Corporate Income Tax"
          PayrollTax -> "Payroll Tax"
          WithholdingTax -> "Withholding Tax"
          CustomTax(name) -> name
        }),
      ]),
      html.p([attribute.class("rate-value")], [
        html.text(float.to_string(rate.rate) <> "%"),
      ]),
    ]),
    html.div([attribute.class("rate-details")], [
      html.p([], [html.text("Effective: " <> rate.effective_date)]),
      html.p([], [
        html.text(
          "Region: "
          <> case rate.region {
            Nigeria -> "Nigeria"
            Kenya -> "Kenya"
            SouthAfrica -> "South Africa"
            Other(region) -> region
          },
        ),
      ]),
    ]),
  ])
}

fn view_filings(model: Model) -> Element(Msg) {
  html.div([attribute.class("filings-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Tax Filings")]),
      html.button([attribute.class("btn-primary")], [html.text("New Filing")]),
    ]),
    html.div(
      [attribute.class("filings-grid")],
      list.map(model.filings, view_filing),
    ),
  ])
}

fn view_filing(filing: TaxFiling) -> Element(Msg) {
  html.div([attribute.class("filing-card")], [
    html.div([attribute.class("filing-header")], [
      html.h3([], [
        html.text(case filing.category {
          VAT -> "VAT Filing"
          CorporateIncomeTax -> "Corporate Tax Filing"
          PayrollTax -> "Payroll Tax Filing"
          WithholdingTax -> "Withholding Tax Filing"
          CustomTax(name) -> name <> " Filing"
        }),
      ]),
      html.p([attribute.class("filing-status")], [
        html.text(case filing.status {
          Draft -> "Draft"
          Submitted -> "Submitted"
          Paid -> "Paid"
          Late -> "Late"
          Overdue -> "Overdue"
        }),
      ]),
    ]),
    html.div([attribute.class("filing-details")], [
      html.p([], [
        html.text(
          "Period: " <> filing.period_start <> " - " <> filing.period_end,
        ),
      ]),
      html.p([], [html.text("Due: " <> filing.due_date)]),
      html.p([], [html.text("Amount: $" <> float.to_string(filing.amount))]),
    ]),
    html.div([attribute.class("filing-actions")], [
      html.button(
        [attribute.class("btn-secondary"), event.on_click(UpdateFiling(filing))],
        [html.text("Edit")],
      ),
      html.button(
        [attribute.class("btn-danger"), event.on_click(RemoveFiling(filing.id))],
        [html.text("Remove")],
      ),
    ]),
  ])
}

fn view_documents(model: Model) -> Element(Msg) {
  html.div([attribute.class("documents-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Tax Documents")]),
      html.button([attribute.class("btn-primary")], [
        html.text("Upload Document"),
      ]),
    ]),
    html.div(
      [attribute.class("documents-grid")],
      list.map(model.documents, view_document),
    ),
  ])
}

fn view_document(document: TaxDocument) -> Element(Msg) {
  html.div([attribute.class("document-card")], [
    html.div([attribute.class("document-header")], [
      html.h3([], [html.text(document.name)]),
      html.p([attribute.class("document-status")], [
        html.text(case document.status {
          Pending -> "Pending"
          Verified -> "Verified"
          Rejected -> "Rejected"
        }),
      ]),
    ]),
    html.div([attribute.class("document-details")], [
      html.p([], [
        html.text(case document.category {
          VAT -> "VAT Document"
          CorporateIncomeTax -> "Corporate Tax Document"
          PayrollTax -> "Payroll Tax Document"
          WithholdingTax -> "Withholding Tax Document"
          CustomTax(name) -> name <> " Document"
        }),
      ]),
      html.p([], [html.text("Date: " <> document.date)]),
    ]),
    html.div([attribute.class("document-actions")], [
      html.a(
        [attribute.href(document.file_url), attribute.class("btn-secondary")],
        [html.text("View")],
      ),
      html.button(
        [
          attribute.class("btn-danger"),
          event.on_click(RemoveDocument(document.id)),
        ],
        [html.text("Remove")],
      ),
    ]),
  ])
}

fn view_settings(model: Model) -> Element(Msg) {
  html.div([attribute.class("settings-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Tax Settings")]),
    ]),
    html.div([attribute.class("settings-form")], [
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("VAT Number")]),
        html.input([
          attribute.type_("text"),
          attribute.value(model.settings.vat_number),
          event.on_input(fn(value) {
            UpdateSettings(TaxSettings(
              value,
              model.settings.tax_region,
              model.settings.filing_frequency,
              model.settings.tax_rates,
            ))
          }),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Tax Region")]),
        html.select(
          [
            event.on_input(fn(value) {
              UpdateSettings(TaxSettings(
                model.settings.vat_number,
                case value {
                  "ng" -> Nigeria
                  "ke" -> Kenya
                  "za" -> SouthAfrica
                  other -> Other(other)
                },
                model.settings.filing_frequency,
                model.settings.tax_rates,
              ))
            }),
          ],
          [
            html.option([attribute.value("ng")], "Nigeria"),
            html.option([attribute.value("ke")], "Kenya"),
            html.option([attribute.value("za")], "South Africa"),
            html.option([attribute.value("other")], "Other"),
          ],
        ),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Filing Frequency")]),
        html.select(
          [
            event.on_input(fn(value) {
              UpdateSettings(TaxSettings(
                model.settings.vat_number,
                model.settings.tax_region,
                case value {
                  "monthly" -> Monthly
                  "quarterly" -> Quarterly
                  "annually" -> Annually
                  _ -> Monthly
                },
                model.settings.tax_rates,
              ))
            }),
          ],
          [
            html.option([attribute.value("monthly")], "Monthly"),
            html.option([attribute.value("quarterly")], "Quarterly"),
            html.option([attribute.value("annually")], "Annually"),
          ],
        ),
      ]),
    ]),
  ])
}

fn view_stat_card(label: String, value: String) -> Element(Msg) {
  html.div([attribute.class("stat-card")], [
    html.div([attribute.class("stat-value")], [html.text(value)]),
    html.div([attribute.class("stat-label")], [html.text(label)]),
  ])
}
