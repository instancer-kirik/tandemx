import components/nav
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect
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
    nav_open: Bool,
    preferences: Dict(String, String),
    custom_colors: Dict(String, String),
    ad_platforms: Dict(String, Bool),
    tax_settings: Dict(String, String),
    payroll_settings: Dict(String, String),
  )
}

pub type Msg {
  SetTheme(Theme)
  SetCustomColors(Dict(String, String))
  SavePreference(String, String)
  ToggleAdPlatform(String, Bool)
  UpdateTaxSettings(String, String)
  UpdatePayrollSettings(String, String)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub fn init(_) {
  #(
    Model(
      theme: System,
      nav_open: False,
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
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
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

fn get_theme_colors(theme: ColorTheme) -> Dict(String, String) {
  case theme {
    Default ->
      dict.from_list([
        #("primary", "#2563eb"),
        #("success", "#16a34a"),
        #("warning", "#ca8a04"),
        #("danger", "#dc2626"),
      ])
    Ocean ->
      dict.from_list([
        #("primary", "#0ea5e9"),
        #("success", "#0d9488"),
        #("warning", "#0369a1"),
        #("danger", "#0c4a6e"),
      ])
    Forest ->
      dict.from_list([
        #("primary", "#059669"),
        #("success", "#16a34a"),
        #("warning", "#65a30d"),
        #("danger", "#b91c1c"),
      ])
    Sunset ->
      dict.from_list([
        #("primary", "#f59e0b"),
        #("success", "#d97706"),
        #("warning", "#dc2626"),
        #("danger", "#7c2d12"),
      ])
    Custom(color) ->
      dict.from_list([
        #("primary", color),
        #("success", "#16a34a"),
        #("warning", "#ca8a04"),
        #("danger", "#dc2626"),
      ])
  }
}

fn view_theme_button(model: Model, theme: Theme, label: String) -> Element(Msg) {
  html.button(
    [
      attribute.class(case model.theme {
        current_theme if current_theme == theme -> "theme-btn selected"
        _ -> "theme-btn"
      }),
      event.on("click", fn(_) { Ok(SetTheme(theme)) }),
    ],
    [html.text(label)],
  )
}

pub fn view(model: Model) -> Element(Msg) {
  let nav_element = element.map(nav.view(), NavMsg)
  let main_content =
    html.main([attribute.class("settings-app")], [
      html.header([attribute.class("app-header")], [
        html.h1([], [html.text("Settings")]),
        html.p([attribute.class("header-subtitle")], [
          html.text("Customize your experience"),
        ]),
      ]),
      html.div([attribute.class("settings-grid")], [
        // Theme settings
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Theme Mode")]),
          html.div([attribute.class("theme-options")], [
            view_theme_button(model, Light(Default), "Light"),
            view_theme_button(model, Dark(Default), "Dark"),
            view_theme_button(model, System, "System"),
          ]),
        ]),
        // Color Theme settings
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
                  attribute.style([
                    #(
                      "background-color",
                      option.unwrap(
                        option.from_result(dict.get(
                          model.custom_colors,
                          "primary",
                        )),
                        "#2563eb",
                      ),
                    ),
                  ]),
                ],
                [],
              ),
              html.div(
                [
                  attribute.class("color-swatch success"),
                  attribute.style([
                    #(
                      "background-color",
                      option.unwrap(
                        option.from_result(dict.get(
                          model.custom_colors,
                          "success",
                        )),
                        "#16a34a",
                      ),
                    ),
                  ]),
                ],
                [],
              ),
              html.div(
                [
                  attribute.class("color-swatch warning"),
                  attribute.style([
                    #(
                      "background-color",
                      option.unwrap(
                        option.from_result(dict.get(
                          model.custom_colors,
                          "warning",
                        )),
                        "#ca8a04",
                      ),
                    ),
                  ]),
                ],
                [],
              ),
              html.div(
                [
                  attribute.class("color-swatch danger"),
                  attribute.style([
                    #(
                      "background-color",
                      option.unwrap(
                        option.from_result(dict.get(
                          model.custom_colors,
                          "danger",
                        )),
                        "#dc2626",
                      ),
                    ),
                  ]),
                ],
                [],
              ),
            ]),
          ]),
        ]),
        // Ad Platform Integration settings
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Ad Platform Integration")]),
          html.p([attribute.class("section-description")], [
            html.text("Connect your virtual cards to advertising platforms"),
          ]),
          html.div([attribute.class("ad-platforms-grid")], [
            view_ad_platform_toggle("facebook", "Facebook Ads", model),
            view_ad_platform_toggle("instagram", "Instagram Ads", model),
            view_ad_platform_toggle("tiktok", "TikTok Ads", model),
            view_ad_platform_toggle("google", "Google Ads", model),
            view_ad_platform_toggle("linkedin", "LinkedIn Ads", model),
            view_ad_platform_toggle("x", "X Ads", model),
          ]),
        ]),
        // Tax Management settings
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Tax Management")]),
          html.div([attribute.class("tax-settings")], [
            view_tax_input(
              "vat_number",
              "VAT Number",
              "Enter your VAT registration number",
              model,
            ),
            view_tax_select(
              "tax_region",
              "Tax Region",
              [
                #("ng", "Nigeria"),
                #("ke", "Kenya"),
                #("za", "South Africa"),
                #("other", "Other"),
              ],
              model,
            ),
            view_tax_select(
              "filing_frequency",
              "Filing Frequency",
              [
                #("monthly", "Monthly"),
                #("quarterly", "Quarterly"),
                #("annually", "Annually"),
              ],
              model,
            ),
          ]),
        ]),
        // Payroll settings
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Payroll Settings")]),
          html.div([attribute.class("payroll-settings")], [
            view_payroll_select(
              "pay_cycle",
              "Pay Cycle",
              [
                #("weekly", "Weekly"),
                #("biweekly", "Bi-weekly"),
                #("monthly", "Monthly"),
              ],
              model,
            ),
            view_payroll_select(
              "tax_withholding",
              "Tax Withholding",
              [
                #("automatic", "Automatic"),
                #("manual", "Manual"),
                #("none", "None"),
              ],
              model,
            ),
            view_payroll_select(
              "payment_method",
              "Payment Method",
              [
                #("bank_transfer", "Bank Transfer"),
                #("mobile_money", "Mobile Money"),
                #("cash", "Cash"),
              ],
              model,
            ),
          ]),
        ]),
        // Notification settings
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Notifications")]),
          html.div([attribute.class("notification-options")], [
            view_notification_toggle(
              "email_notifications",
              "Email Notifications",
              "Receive updates and alerts via email",
              option.unwrap(
                option.from_result(dict.get(
                  model.preferences,
                  "email_notifications",
                )),
                "false",
              ),
            ),
            view_notification_toggle(
              "push_notifications",
              "Push Notifications",
              "Get instant updates in your browser",
              option.unwrap(
                option.from_result(dict.get(
                  model.preferences,
                  "push_notifications",
                )),
                "false",
              ),
            ),
          ]),
        ]),
        // Display settings
        html.section([attribute.class("settings-section")], [
          html.h2([], [html.text("Display")]),
          html.div([attribute.class("display-options")], [
            view_display_option(
              "compact_view",
              "Compact View",
              "Show more content with less spacing",
              option.unwrap(
                option.from_result(dict.get(model.preferences, "compact_view")),
                "false",
              ),
            ),
            view_display_option(
              "show_metrics",
              "Show Metrics",
              "Display performance metrics and statistics",
              option.unwrap(
                option.from_result(dict.get(model.preferences, "show_metrics")),
                "true",
              ),
            ),
          ]),
        ]),
      ]),
    ])

  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
      attribute.data("theme", case model.theme {
        Light(_) -> "light"
        Dark(_) -> "dark"
        System -> "system"
      }),
      attribute.data("color-theme", case model.theme {
        Light(color_theme) | Dark(color_theme) ->
          case color_theme {
            Default -> "default"
            Ocean -> "ocean"
            Forest -> "forest"
            Sunset -> "sunset"
            Custom(_) -> "custom"
          }
        System -> "default"
      }),
    ],
    [nav_element, main_content],
  )
}

fn view_notification_toggle(
  key: String,
  title: String,
  description: String,
  value: String,
) -> Element(Msg) {
  html.div([attribute.class("notification-toggle")], [
    html.div([attribute.class("toggle-info")], [
      html.h3([], [html.text(title)]),
      html.p([], [html.text(description)]),
    ]),
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(value == "true"),
      event.on_check(fn(checked) {
        SavePreference(key, case checked {
          True -> "true"
          False -> "false"
        })
      }),
    ]),
  ])
}

fn view_display_option(
  key: String,
  title: String,
  description: String,
  value: String,
) -> Element(Msg) {
  html.div([attribute.class("display-option")], [
    html.div([attribute.class("option-info")], [
      html.h3([], [html.text(title)]),
      html.p([], [html.text(description)]),
    ]),
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(value == "true"),
      event.on_check(fn(checked) {
        SavePreference(key, case checked {
          True -> "true"
          False -> "false"
        })
      }),
    ]),
  ])
}

fn view_ad_platform_toggle(
  platform: String,
  label: String,
  model: Model,
) -> Element(Msg) {
  let enabled =
    option.unwrap(
      option.from_result(dict.get(model.ad_platforms, platform)),
      False,
    )
  html.div([attribute.class("ad-platform-toggle")], [
    html.div([attribute.class("platform-info")], [
      html.h3([], [html.text(label)]),
      html.p([], [
        html.text(case enabled {
          True -> "Connected"
          False -> "Not connected"
        }),
      ]),
    ]),
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(enabled),
      event.on_check(fn(checked) { ToggleAdPlatform(platform, checked) }),
    ]),
  ])
}

fn view_tax_input(
  key: String,
  label: String,
  placeholder: String,
  model: Model,
) -> Element(Msg) {
  let value =
    option.unwrap(option.from_result(dict.get(model.tax_settings, key)), "")
  html.div([attribute.class("tax-input")], [
    html.label([], [html.text(label)]),
    html.input([
      attribute.type_("text"),
      attribute.value(value),
      attribute.placeholder(placeholder),
      event.on_input(fn(new_value) { UpdateTaxSettings(key, new_value) }),
    ]),
  ])
}

fn view_tax_select(
  key: String,
  label: String,
  options: List(#(String, String)),
  model: Model,
) -> Element(Msg) {
  let value =
    option.unwrap(option.from_result(dict.get(model.tax_settings, key)), "")
  html.div([attribute.class("tax-select")], [
    html.label([], [html.text(label)]),
    html.select(
      [event.on_input(fn(new_value) { UpdateTaxSettings(key, new_value) })],
      list.map(options, fn(opt: #(String, String)) {
        let #(value, label) = opt
        html.option(
          [attribute.value(value), attribute.selected(value == value)],
          label,
        )
      }),
    ),
  ])
}

fn view_payroll_select(
  key: String,
  label: String,
  options: List(#(String, String)),
  model: Model,
) -> Element(Msg) {
  let value =
    option.unwrap(option.from_result(dict.get(model.payroll_settings, key)), "")
  html.div([attribute.class("payroll-select")], [
    html.label([], [html.text(label)]),
    html.select(
      [event.on_input(fn(new_value) { UpdatePayrollSettings(key, new_value) })],
      list.map(options, fn(opt: #(String, String)) {
        let #(value, label) = opt
        html.option(
          [attribute.value(value), attribute.selected(value == value)],
          label,
        )
      }),
    ),
  ])
}
