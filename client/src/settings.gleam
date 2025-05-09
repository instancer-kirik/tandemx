// Removed FetchState, SupabaseUser, Idle
import gleam/dict.{type Dict}
import gleam/dynamic/decode

import gleam/list
import gleam/option
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type ColorTheme {
  Default
  Ocean
  Forest
  Sunset
  Custom(String)
}

pub type Theme {
  Light(ColorTheme)
  Dark(ColorTheme)
  System
}

pub type Model {
  Model(
    theme: Theme,
    preferences: Dict(String, String),
    custom_colors: Dict(String, String),
    ad_platforms: Dict(String, Bool),
    tax_settings: Dict(String, String),
    payroll_settings: Dict(String, String),
    // nav_model: nav.Model, // Removed
  )
}

pub type Msg {
  SetTheme(Theme)
  SetCustomColors(Dict(String, String))
  SavePreference(String, String)
  ToggleAdPlatform(String, Bool)
  UpdateTaxSettings(String, String)
  UpdatePayrollSettings(String, String)
  // NavMsg(nav.Msg) // Removed
}

pub fn init(_: Nil) -> #(Model, Effect(Msg)) {
  // let initial_nav_model = nav.init(Idle) // Removed
  #(
    Model(
      theme: System,
      preferences: dict.new(),
      custom_colors: dict.from_list([
        #("primary", "#2563eb"),
        #("success", "#16a34a"),
        #("warning", "#ca8a04"),
        #("danger", "#dc2626"),
      ]),
      ad_platforms: dict.from_list([
        #("facebook", False),
        #("instagram", False),
        #("tiktok", False),
        #("google", False),
        #("linkedin", False),
        #("x", False),
      ]),
      tax_settings: dict.from_list([
        #("vat_number", ""),
        #("tax_region", ""),
        #("filing_frequency", "monthly"),
      ]),
      payroll_settings: dict.from_list([
        #("pay_cycle", "monthly"),
        #("tax_withholding", "automatic"),
        #("payment_method", "bank_transfer"),
      ]),
      // nav_model: initial_nav_model, // Removed
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    SetTheme(theme) -> {
      #(Model(..model, theme: theme), effect.none())
    }
    SetCustomColors(colors) -> {
      #(Model(..model, custom_colors: colors), effect.none())
    }
    SavePreference(key, value) -> {
      let preferences = dict.insert(model.preferences, key, value)
      #(Model(..model, preferences: preferences), effect.none())
    }
    ToggleAdPlatform(platform, enabled) -> {
      let ad_platforms = dict.insert(model.ad_platforms, platform, enabled)
      #(Model(..model, ad_platforms: ad_platforms), effect.none())
    }
    UpdateTaxSettings(key, value) -> {
      let tax_settings = dict.insert(model.tax_settings, key, value)
      #(Model(..model, tax_settings: tax_settings), effect.none())
    }
    UpdatePayrollSettings(key, value) -> {
      let payroll_settings = dict.insert(model.payroll_settings, key, value)
      #(Model(..model, payroll_settings: payroll_settings), effect.none())
    }
    // NavMsg case removed
  }
}

fn view_theme_button(model: Model, theme: Theme, label: String) -> Element(Msg) {
  html.button(
    [
      attribute.class(case model.theme {
        current_theme if current_theme == theme -> "theme-btn selected"
        _ -> "theme-btn"
      }),
      event.on("click", decode.success(SetTheme(theme))),
    ],
    [html.text(label)],
  )
}

pub fn view(
  model: Model,
  // user_state: FetchState(Option(SupabaseUser)), // Removed if only for nav
) -> Element(Msg) {
  // let current_nav_model_for_view = nav.Model(..model.nav_model, user_state: user_state) // Removed
  // let nav_element = element.map(nav.view(current_nav_model_for_view), NavMsg) // Removed

  let main_content =
    html.main([attribute.class("settings-app")], [
      html.header([attribute.class("app-header")], [
        html.h1([], [html.text("Settings")]),
        html.p([attribute.class("header-subtitle")], [
          html.text("Customize your experience"),
        ]),
      ]),
      html.div([attribute.class("settings-grid")], [
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Theme Mode")]),
          html.div([attribute.class("theme-options")], [
            view_theme_button(model, Light(Default), "Light"),
            view_theme_button(model, Dark(Default), "Dark"),
            view_theme_button(model, System, "System"),
          ]),
        ]),
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Color Theme")]),
          html.div([attribute.class("theme-options")], [
            view_theme_button(model, Light(Default), "Default"),
            view_theme_button(model, Light(Ocean), "Ocean"),
            view_theme_button(model, Light(Forest), "Forest"),
            view_theme_button(model, Light(Sunset), "Sunset"),
          ]),
          html.div([attribute.class("color-preview")], [
            html.div([attribute.class("color-grid")], [
              html.div(
                [
                  attribute.class("color-swatch primary"),
                  attribute.style(
                    "background-color",
                    option.unwrap(
                      option.from_result(dict.get(
                        model.custom_colors,
                        "primary",
                      )),
                      "#2563eb",
                    ),
                  ),
                ],
                [],
              ),
              html.div(
                [
                  attribute.class("color-swatch success"),
                  attribute.style(
                    "background-color",
                    option.unwrap(
                      option.from_result(dict.get(
                        model.custom_colors,
                        "success",
                      )),
                      "#16a34a",
                    ),
                  ),
                ],
                [],
              ),
              html.div(
                [
                  attribute.class("color-swatch warning"),
                  attribute.style(
                    "background-color",
                    option.unwrap(
                      option.from_result(dict.get(
                        model.custom_colors,
                        "warning",
                      )),
                      "#ca8a04",
                    ),
                  ),
                ],
                [],
              ),
              html.div(
                [
                  attribute.class("color-swatch danger"),
                  attribute.style(
                    "background-color",
                    option.unwrap(
                      option.from_result(dict.get(model.custom_colors, "danger")),
                      "#dc2626",
                    ),
                  ),
                ],
                [],
              ),
            ]),
          ]),
        ]),
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Ad Platforms")]),
          html.div(
            [attribute.class("ad-platform-options")],
            list.map(dict.to_list(model.ad_platforms), fn(item) {
              let #(platform, enabled) = item
              html.div([attribute.class("ad-platform-toggle")], [
                html.label([], [html.text(platform)]),
                html.input([
                  attribute.type_("checkbox"),
                  attribute.checked(enabled),
                  event.on(
                    "change",
                    decode.success(ToggleAdPlatform(platform, !enabled)),
                  ),
                ]),
              ])
            }),
          ),
        ]),
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Tax Settings")]),
          html.form([attribute.class("settings-form")], [
            html.div([attribute.class("form-group")], [
              html.label([], [html.text("VAT Number")]),
              html.input([
                attribute.type_("text"),
                attribute.value(option.unwrap(
                  option.from_result(dict.get(model.tax_settings, "vat_number")),
                  "",
                )),
                event.on(
                  "input",
                  decode.map(decode.string, fn(val) {
                    UpdateTaxSettings("vat_number", val)
                  }),
                ),
              ]),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([], [html.text("Tax Region")]),
              html.input([
                attribute.type_("text"),
                attribute.value(option.unwrap(
                  option.from_result(dict.get(model.tax_settings, "tax_region")),
                  "",
                )),
                event.on(
                  "input",
                  decode.map(decode.string, fn(val) {
                    UpdateTaxSettings("tax_region", val)
                  }),
                ),
              ]),
            ]),
          ]),
        ]),
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Payroll Settings")]),
          html.form([attribute.class("settings-form")], [
            html.div([attribute.class("form-group")], [
              html.label([], [html.text("Pay Cycle")]),
              html.select(
                [
                  event.on(
                    "change",
                    decode.map(decode.string, fn(val) {
                      UpdatePayrollSettings("pay_cycle", val)
                    }),
                  ),
                ],
                [
                  html.option([attribute.value("monthly")], "Monthly"),
                  html.option([attribute.value("bi-weekly")], "Bi-Weekly"),
                ],
              ),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([], [html.text("Tax Withholding")]),
              html.select(
                [
                  event.on(
                    "change",
                    decode.map(decode.string, fn(val) {
                      UpdatePayrollSettings("tax_withholding", val)
                    }),
                  ),
                ],
                [
                  html.option([attribute.value("automatic")], "Automatic"),
                  html.option([attribute.value("manual")], "Manual"),
                ],
              ),
            ]),
            html.div([attribute.class("form-group")], [
              html.label([], [html.text("Payment Method")]),
              html.select(
                [
                  event.on(
                    "change",
                    decode.map(decode.string, fn(val) {
                      UpdatePayrollSettings("payment_method", val)
                    }),
                  ),
                ],
                [
                  html.option(
                    [attribute.value("bank_transfer")],
                    "Bank Transfer",
                  ),
                  html.option([attribute.value("cash")], "Cash"),
                  html.option([attribute.value("check")], "Check"),
                  html.option([attribute.value("paypal")], "PayPal"),
                  html.option([attribute.value("stripe")], "Stripe"),
                  html.option([attribute.value("venmo")], "Venmo"),
                ],
              ),
            ]),
          ]),
        ]),
      ]),
    ])

  // The main_content is now the root element returned by this view.
  // The app-container div with theme data attributes is handled by app.gleam if needed,
  // or could be added around main_content if settings page needs its own theme container.
  // For now, returning main_content directly, assuming app.gleam wraps pages.
  main_content
}
