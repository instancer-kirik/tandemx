import components/nav
import finance/ads/types.{
  type AdAccount, type AdAccountSettings, type AdPlatform, type AdSpendAlert,
  type AgeRange, type BudgetType, type Campaign, type CampaignForm,
  type CampaignObjective, type CampaignTargeting, type FormValidation,
  AccountActive, AccountPaused, AccountPendingReview, AccountSuspended,
  Awareness, CampaignActive, CampaignCompleted, CampaignDraft, CampaignPaused,
  CampaignRejected, Consideration, Conversion, Daily, Facebook, Google, Lifetime,
  LinkedIn, Other, TikTok, Twitter, new_campaign_form,
}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Tab {
  Overview
  Accounts
  Campaigns
  Analytics
  Settings
  NewCampaign
}

pub type Model {
  Model(
    selected_tab: Tab,
    accounts: List(AdAccount),
    campaigns: List(Campaign),
    alerts: List(AdSpendAlert),
    settings: AdAccountSettings,
    nav_open: Bool,
    campaign_form: CampaignForm,
    form_validation: FormValidation,
  )
}

pub type Msg {
  UserSelectedTab(Tab)
  UserToggledAccountStatus(String)
  UserToggledCampaignStatus(String)
  UserAddedAccount
  UserAddedCampaign
  UserUpdatedCampaignName(String)
  UserSelectedPlatform(AdPlatform)
  UserSelectedAccount(String)
  UserSelectedBudgetType(BudgetType)
  UserUpdatedBudgetAmount(String)
  UserUpdatedStartDate(String)
  UserUpdatedEndDate(String)
  UserSelectedObjective(CampaignObjective)
  UserUpdatedLocation(String)
  UserUpdatedAgeRange(Int, Int)
  UserUpdatedInterests(String)
  UserUpdatedLanguages(String)
  UserUpdatedExcludedLocations(String)
  UserSubmittedCampaignForm
  NavMsg(nav.Msg)
}

pub fn init() -> Model {
  let sample_accounts = [
    types.AdAccount(
      id: "acc_001",
      name: "Facebook Business",
      platform: Facebook,
      status: AccountActive,
      currency: "USD",
      balance: 5000.0,
      spend_limit: 10_000.0,
      virtual_card: None,
      verification_status: types.Verified,
    ),
    types.AdAccount(
      id: "acc_002",
      name: "Google Ads",
      platform: Google,
      status: AccountActive,
      currency: "USD",
      balance: 7500.0,
      spend_limit: 15_000.0,
      virtual_card: None,
      verification_status: types.Verified,
    ),
    types.AdAccount(
      id: "acc_003",
      name: "LinkedIn Ads",
      platform: LinkedIn,
      status: AccountPaused,
      currency: "USD",
      balance: 3000.0,
      spend_limit: 5000.0,
      virtual_card: None,
      verification_status: types.InProgress,
    ),
  ]

  let sample_campaigns = [
    types.Campaign(
      id: "camp_001",
      name: "Spring Product Launch",
      platform: Facebook,
      status: CampaignActive,
      budget_type: Daily,
      budget_amount: 100.0,
      spend: 450.0,
      start_date: "2024-03-01",
      end_date: Some("2024-03-31"),
      performance: types.CampaignPerformance(
        impressions: 50_000,
        clicks: 2500,
        conversions: 100,
        spend: 450.0,
        ctr: 0.05,
        cpc: 0.18,
        roas: 2.5,
      ),
    ),
    types.Campaign(
      id: "camp_002",
      name: "Lead Generation Q1",
      platform: Google,
      status: CampaignActive,
      budget_type: Lifetime,
      budget_amount: 5000.0,
      spend: 2100.0,
      start_date: "2024-01-01",
      end_date: Some("2024-03-31"),
      performance: types.CampaignPerformance(
        impressions: 75_000,
        clicks: 3800,
        conversions: 250,
        spend: 2100.0,
        ctr: 0.0507,
        cpc: 0.55,
        roas: 3.2,
      ),
    ),
  ]

  let sample_alerts = [
    types.AdSpendAlert(
      account_id: "acc_001",
      alert_type: types.DailySpendLimit,
      threshold: 1000.0,
      current_spend: 450.0,
      triggered_at: "2024-03-15",
    ),
    types.AdSpendAlert(
      account_id: "acc_002",
      alert_type: types.BudgetDepletion,
      threshold: 5000.0,
      current_spend: 4200.0,
      triggered_at: "2024-03-14",
    ),
  ]

  Model(
    selected_tab: Overview,
    accounts: sample_accounts,
    campaigns: sample_campaigns,
    alerts: sample_alerts,
    settings: types.AdAccountSettings(
      default_currency: "USD",
      auto_reload: True,
      reload_threshold: 100.0,
      reload_amount: 500.0,
      spend_alerts: [100.0, 500.0, 1000.0],
      notification_email: "admin@tandemx.com",
    ),
    nav_open: False,
    campaign_form: new_campaign_form(),
    form_validation: types.FormValidation(
      name_error: None,
      platform_error: None,
      account_error: None,
      budget_error: None,
      date_error: None,
    ),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserSelectedTab(tab) -> #(Model(..model, selected_tab: tab), effect.none())
    UserToggledAccountStatus(account_id) -> {
      let updated_accounts =
        list.map(model.accounts, fn(account) {
          case account.id == account_id {
            True -> {
              case account.status {
                AccountActive ->
                  types.AdAccount(..account, status: AccountPaused)
                AccountPaused ->
                  types.AdAccount(..account, status: AccountActive)
                _ -> account
              }
            }
            False -> account
          }
        })
      #(Model(..model, accounts: updated_accounts), effect.none())
    }
    UserToggledCampaignStatus(campaign_id) -> {
      let updated_campaigns =
        list.map(model.campaigns, fn(campaign) {
          case campaign.id == campaign_id {
            True -> {
              case campaign.status {
                CampaignActive ->
                  types.Campaign(..campaign, status: CampaignPaused)
                CampaignPaused ->
                  types.Campaign(..campaign, status: CampaignActive)
                _ -> campaign
              }
            }
            False -> campaign
          }
        })
      #(Model(..model, campaigns: updated_campaigns), effect.none())
    }
    UserAddedAccount -> #(model, effect.none())
    UserAddedCampaign -> #(
      Model(..model, selected_tab: NewCampaign),
      effect.none(),
    )
    UserUpdatedCampaignName(name) -> {
      let form = model.campaign_form
      #(
        Model(..model, campaign_form: types.CampaignForm(..form, name: name)),
        effect.none(),
      )
    }
    UserSelectedPlatform(platform) -> {
      let form = model.campaign_form
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(..form, platform: Some(platform)),
        ),
        effect.none(),
      )
    }
    UserSelectedAccount(account_id) -> {
      let form = model.campaign_form
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            account_id: Some(account_id),
          ),
        ),
        effect.none(),
      )
    }
    UserSelectedBudgetType(budget_type) -> {
      let form = model.campaign_form
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            budget_type: Some(budget_type),
          ),
        ),
        effect.none(),
      )
    }
    UserUpdatedBudgetAmount(amount) -> {
      let form = model.campaign_form
      case float.parse(amount) {
        Ok(value) -> #(
          Model(
            ..model,
            campaign_form: types.CampaignForm(
              ..form,
              budget_amount: Some(value),
            ),
          ),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
    }
    UserUpdatedStartDate(date) -> {
      let form = model.campaign_form
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(..form, start_date: Some(date)),
        ),
        effect.none(),
      )
    }
    UserUpdatedEndDate(date) -> {
      let form = model.campaign_form
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(..form, end_date: Some(date)),
        ),
        effect.none(),
      )
    }
    UserSelectedObjective(objective) -> {
      let form = model.campaign_form
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(..form, objective: Some(objective)),
        ),
        effect.none(),
      )
    }
    UserUpdatedLocation(location) -> {
      let form = model.campaign_form
      let targeting = form.targeting
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            targeting: types.CampaignTargeting(..targeting, locations: [
              location,
              ..targeting.locations
            ]),
          ),
        ),
        effect.none(),
      )
    }
    UserUpdatedAgeRange(min, max) -> {
      let form = model.campaign_form
      let targeting = form.targeting
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            targeting: types.CampaignTargeting(
              ..targeting,
              age_range: types.AgeRange(min: min, max: max),
            ),
          ),
        ),
        effect.none(),
      )
    }
    UserUpdatedInterests(interest) -> {
      let form = model.campaign_form
      let targeting = form.targeting
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            targeting: types.CampaignTargeting(..targeting, interests: [
              interest,
              ..targeting.interests
            ]),
          ),
        ),
        effect.none(),
      )
    }
    UserUpdatedLanguages(language) -> {
      let form = model.campaign_form
      let targeting = form.targeting
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            targeting: types.CampaignTargeting(..targeting, languages: [
              language,
              ..targeting.languages
            ]),
          ),
        ),
        effect.none(),
      )
    }
    UserUpdatedExcludedLocations(location) -> {
      let form = model.campaign_form
      let targeting = form.targeting
      #(
        Model(
          ..model,
          campaign_form: types.CampaignForm(
            ..form,
            targeting: types.CampaignTargeting(..targeting, excluded_locations: [
              location,
              ..targeting.excluded_locations
            ]),
          ),
        ),
        effect.none(),
      )
    }
    UserSubmittedCampaignForm -> {
      // TODO: Validate form and create campaign
      #(model, effect.none())
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

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    element.map(nav.view(), NavMsg),
    html.div([attribute.class("ads-app")], [
      html.header([attribute.class("app-header")], [
        html.div([attribute.class("header-content")], [
          html.h1([], [html.text("Ad Platform Management")]),
          html.p([attribute.class("header-subtitle")], [
            html.text("Manage your ad accounts, campaigns, and budgets"),
          ]),
        ]),
        html.div([attribute.class("header-actions")], [
          html.button(
            [attribute.class("btn-primary"), event.on_click(UserAddedAccount)],
            [html.text("New Ad Account")],
          ),
        ]),
      ]),
      view_tabs(model.selected_tab),
      html.div([attribute.class("main-content")], [
        case model.selected_tab {
          Overview -> view_overview(model)
          Accounts -> view_accounts(model.accounts)
          Campaigns -> view_campaigns(model.campaigns)
          Analytics -> view_analytics(model)
          Settings -> view_settings(model.settings)
          NewCampaign -> view_campaign_form(model)
        },
      ]),
    ]),
  ])
}

fn view_tabs(selected: Tab) -> Element(Msg) {
  html.div([attribute.class("tabs")], [
    html.button(
      [
        attribute.class(case selected == Overview {
          True -> "tab active"
          False -> "tab"
        }),
        event.on_click(UserSelectedTab(Overview)),
      ],
      [html.text("Overview")],
    ),
    html.button(
      [
        attribute.class(case selected == Accounts {
          True -> "tab active"
          False -> "tab"
        }),
        event.on_click(UserSelectedTab(Accounts)),
      ],
      [html.text("Ad Accounts")],
    ),
    html.button(
      [
        attribute.class(case selected == Campaigns {
          True -> "tab active"
          False -> "tab"
        }),
        event.on_click(UserSelectedTab(Campaigns)),
      ],
      [html.text("Campaigns")],
    ),
    html.button(
      [
        attribute.class(case selected == Analytics {
          True -> "tab active"
          False -> "tab"
        }),
        event.on_click(UserSelectedTab(Analytics)),
      ],
      [html.text("Analytics")],
    ),
    html.button(
      [
        attribute.class(case selected == Settings {
          True -> "tab active"
          False -> "tab"
        }),
        event.on_click(UserSelectedTab(Settings)),
      ],
      [html.text("Settings")],
    ),
    html.button(
      [
        attribute.class(case selected == NewCampaign {
          True -> "tab active"
          False -> "tab"
        }),
        event.on_click(UserSelectedTab(NewCampaign)),
      ],
      [html.text("New Campaign")],
    ),
  ])
}

fn view_overview(model: Model) -> Element(Msg) {
  html.div([attribute.class("overview-section")], [
    html.div([attribute.class("summary-stats")], [
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          html.text(int.to_string(list.length(model.accounts))),
        ]),
        html.span([attribute.class("stat-label")], [html.text("Ad Accounts")]),
      ]),
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          html.text(int.to_string(list.length(model.campaigns))),
        ]),
        html.span([attribute.class("stat-label")], [
          html.text("Active Campaigns"),
        ]),
      ]),
      html.div([attribute.class("stat-card")], [
        html.span([attribute.class("stat-value")], [
          html.text(int.to_string(list.length(model.alerts))),
        ]),
        html.span([attribute.class("stat-label")], [html.text("Alerts")]),
      ]),
    ]),
    html.div([attribute.class("platform-overview")], [
      html.h2([], [html.text("Platform Overview")]),
      html.div([attribute.class("platform-grid")], [
        view_platform_card(Facebook),
        view_platform_card(Google),
        view_platform_card(TikTok),
        view_platform_card(LinkedIn),
        view_platform_card(Twitter),
      ]),
    ]),
  ])
}

fn view_platform_card(platform: AdPlatform) -> Element(Msg) {
  html.div([attribute.class("platform-card")], [
    html.div([attribute.class("platform-header")], [
      html.h3([], [
        html.text(case platform {
          Facebook -> "Facebook Ads"
          Google -> "Google Ads"
          TikTok -> "TikTok Ads"
          LinkedIn -> "LinkedIn Ads"
          Twitter -> "Twitter Ads"
          Other(name) -> name
        }),
      ]),
    ]),
    html.div([attribute.class("platform-content")], [
      html.div([attribute.class("platform-metrics")], [
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("Accounts")]),
          html.span([attribute.class("metric-value")], [html.text("0")]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("Campaigns")]),
          html.span([attribute.class("metric-value")], [html.text("0")]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("Spend")]),
          html.span([attribute.class("metric-value")], [html.text("$0.00")]),
        ]),
      ]),
    ]),
  ])
}

fn view_accounts(accounts: List(AdAccount)) -> Element(Msg) {
  html.div([attribute.class("accounts-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Ad Accounts")]),
      html.button(
        [attribute.class("btn-primary"), event.on_click(UserAddedAccount)],
        [html.text("New Account")],
      ),
    ]),
    html.div([attribute.class("accounts-grid")], [
      case list.length(accounts) {
        0 ->
          html.div([attribute.class("empty-state")], [
            html.p([], [
              html.text(
                "No ad accounts yet. Click 'New Account' to add your first account.",
              ),
            ]),
          ])
        _ ->
          html.div(
            [],
            list.map(accounts, fn(account) { view_account_card(account) }),
          )
      },
    ]),
  ])
}

fn view_account_card(account: AdAccount) -> Element(Msg) {
  html.div([attribute.class("account-card")], [
    html.div([attribute.class("account-header")], [
      html.h3([], [html.text(account.name)]),
      html.span(
        [
          attribute.class(case account.status {
            AccountActive -> "status-badge active"
            AccountPaused -> "status-badge paused"
            AccountSuspended -> "status-badge suspended"
            AccountPendingReview -> "status-badge pending"
          }),
        ],
        [
          html.text(case account.status {
            AccountActive -> "Active"
            AccountPaused -> "Paused"
            AccountSuspended -> "Suspended"
            AccountPendingReview -> "Pending Review"
          }),
        ],
      ),
    ]),
    html.div([attribute.class("account-content")], [
      html.div([attribute.class("account-metrics")], [
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("Balance")]),
          html.span([attribute.class("metric-value")], [
            html.text(
              account.currency <> " " <> float.to_string(account.balance),
            ),
          ]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [
            html.text("Spend Limit"),
          ]),
          html.span([attribute.class("metric-value")], [
            html.text(
              account.currency <> " " <> float.to_string(account.spend_limit),
            ),
          ]),
        ]),
      ]),
    ]),
    html.div([attribute.class("account-actions")], [
      html.button(
        [
          attribute.class("btn-secondary"),
          event.on_click(UserToggledAccountStatus(account.id)),
        ],
        [
          html.text(case account.status {
            AccountActive -> "Pause"
            AccountPaused -> "Activate"
            _ -> "Manage"
          }),
        ],
      ),
    ]),
  ])
}

fn view_campaigns(campaigns: List(Campaign)) -> Element(Msg) {
  html.div([attribute.class("campaigns-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Campaigns")]),
      html.button(
        [attribute.class("btn-primary"), event.on_click(UserAddedCampaign)],
        [html.text("New Campaign")],
      ),
    ]),
    html.div([attribute.class("campaigns-grid")], [
      case list.length(campaigns) {
        0 ->
          html.div([attribute.class("empty-state")], [
            html.p([], [
              html.text(
                "No campaigns yet. Click 'New Campaign' to create your first campaign.",
              ),
            ]),
          ])
        _ ->
          html.div(
            [],
            list.map(campaigns, fn(campaign) { view_campaign_card(campaign) }),
          )
      },
    ]),
  ])
}

fn view_campaign_card(campaign: Campaign) -> Element(Msg) {
  html.div([attribute.class("campaign-card")], [
    html.div([attribute.class("campaign-header")], [
      html.h3([], [html.text(campaign.name)]),
      html.span(
        [
          attribute.class(case campaign.status {
            CampaignActive -> "status-badge active"
            CampaignPaused -> "status-badge paused"
            CampaignDraft -> "status-badge draft"
            CampaignCompleted -> "status-badge completed"
            CampaignRejected -> "status-badge rejected"
          }),
        ],
        [
          html.text(case campaign.status {
            CampaignActive -> "Active"
            CampaignPaused -> "Paused"
            CampaignDraft -> "Draft"
            CampaignCompleted -> "Completed"
            CampaignRejected -> "Rejected"
          }),
        ],
      ),
    ]),
    html.div([attribute.class("campaign-content")], [
      html.div([attribute.class("campaign-metrics")], [
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("Budget")]),
          html.span([attribute.class("metric-value")], [
            html.text("$" <> float.to_string(campaign.budget_amount)),
          ]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("Spend")]),
          html.span([attribute.class("metric-value")], [
            html.text("$" <> float.to_string(campaign.spend)),
          ]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [html.text("ROAS")]),
          html.span([attribute.class("metric-value")], [
            html.text(float.to_string(campaign.performance.roas) <> "x"),
          ]),
        ]),
      ]),
    ]),
    html.div([attribute.class("campaign-actions")], [
      html.button(
        [
          attribute.class("btn-secondary"),
          event.on_click(UserToggledCampaignStatus(campaign.id)),
        ],
        [
          html.text(case campaign.status {
            CampaignActive -> "Pause"
            CampaignPaused -> "Activate"
            _ -> "Manage"
          }),
        ],
      ),
    ]),
  ])
}

fn view_analytics(model: Model) -> Element(Msg) {
  html.div([attribute.class("analytics-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Analytics")]),
    ]),
    html.div([attribute.class("analytics-content")], [
      html.p([], [html.text("Analytics dashboard coming soon...")]),
    ]),
  ])
}

fn view_settings(settings: AdAccountSettings) -> Element(Msg) {
  html.div([attribute.class("settings-section")], [
    html.div([attribute.class("section-header")], [
      html.h2([], [html.text("Ad Platform Settings")]),
    ]),
    html.div([attribute.class("settings-content")], [
      html.div([attribute.class("settings-group")], [
        html.h3([], [html.text("Default Settings")]),
        html.div([attribute.class("setting-item")], [
          html.label([], [html.text("Default Currency")]),
          html.select([attribute.value(settings.default_currency)], [
            html.option([attribute.value("USD")], "USD"),
            html.option([attribute.value("EUR")], "EUR"),
            html.option([attribute.value("GBP")], "GBP"),
          ]),
        ]),
      ]),
      html.div([attribute.class("settings-group")], [
        html.h3([], [html.text("Auto-Reload Settings")]),
        html.div([attribute.class("setting-item")], [
          html.label([], [html.text("Enable Auto-Reload")]),
          html.input([
            attribute.type_("checkbox"),
            attribute.checked(settings.auto_reload),
          ]),
        ]),
        html.div([attribute.class("setting-item")], [
          html.label([], [html.text("Reload Threshold")]),
          html.input([
            attribute.type_("number"),
            attribute.value(float.to_string(settings.reload_threshold)),
          ]),
        ]),
        html.div([attribute.class("setting-item")], [
          html.label([], [html.text("Reload Amount")]),
          html.input([
            attribute.type_("number"),
            attribute.value(float.to_string(settings.reload_amount)),
          ]),
        ]),
      ]),
      html.div([attribute.class("settings-group")], [
        html.h3([], [html.text("Notifications")]),
        html.div([attribute.class("setting-item")], [
          html.label([], [html.text("Notification Email")]),
          html.input([
            attribute.type_("email"),
            attribute.value(settings.notification_email),
          ]),
        ]),
      ]),
    ]),
  ])
}

fn view_campaign_form(model: Model) -> Element(Msg) {
  html.div([attribute.class("campaign-form")], [
    html.div([attribute.class("form-section")], [
      html.h3([], [html.text("Campaign Details")]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Campaign Name")]),
        html.input([
          attribute.type_("text"),
          attribute.value(model.campaign_form.name),
          event.on_input(UserUpdatedCampaignName),
        ]),
        case model.form_validation.name_error {
          Some(error) ->
            html.div([attribute.class("error-message")], [html.text(error)])
          None -> html.text("")
        },
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Platform")]),
        html.select(
          [
            event.on_input(fn(value) {
              case value {
                "facebook" -> UserSelectedPlatform(Facebook)
                "google" -> UserSelectedPlatform(Google)
                "tiktok" -> UserSelectedPlatform(TikTok)
                "linkedin" -> UserSelectedPlatform(LinkedIn)
                "twitter" -> UserSelectedPlatform(Twitter)
                _ -> UserSelectedPlatform(Other(value))
              }
            }),
          ],
          [
            html.option([attribute.value("")], "Select Platform"),
            html.option([attribute.value("facebook")], "Facebook Ads"),
            html.option([attribute.value("google")], "Google Ads"),
            html.option([attribute.value("tiktok")], "TikTok Ads"),
            html.option([attribute.value("linkedin")], "LinkedIn Ads"),
            html.option([attribute.value("twitter")], "Twitter Ads"),
          ],
        ),
      ]),
    ]),
    html.div([attribute.class("form-section")], [
      html.h3([], [html.text("Budget & Schedule")]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Budget Type")]),
        html.select(
          [
            event.on_input(fn(value) {
              case value {
                "daily" -> UserSelectedBudgetType(Daily)
                "lifetime" -> UserSelectedBudgetType(Lifetime)
                _ -> UserSelectedBudgetType(Daily)
              }
            }),
          ],
          [
            html.option([attribute.value("")], "Select Budget Type"),
            html.option([attribute.value("daily")], "Daily Budget"),
            html.option([attribute.value("lifetime")], "Lifetime Budget"),
          ],
        ),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Budget Amount")]),
        html.input([
          attribute.type_("number"),
          attribute.min("1"),
          attribute.step("0.01"),
          event.on_input(UserUpdatedBudgetAmount),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Start Date")]),
        html.input([
          attribute.type_("date"),
          event.on_input(UserUpdatedStartDate),
        ]),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("End Date (Optional)")]),
        html.input([attribute.type_("date"), event.on_input(UserUpdatedEndDate)]),
      ]),
    ]),
    html.div([attribute.class("form-section")], [
      html.h3([], [html.text("Campaign Objective")]),
      html.div([attribute.class("objective-options")], [
        html.button(
          [
            attribute.class(case model.campaign_form.objective {
              Some(Awareness) -> "objective-btn selected"
              _ -> "objective-btn"
            }),
            event.on_click(UserSelectedObjective(Awareness)),
          ],
          [html.text("Brand Awareness")],
        ),
        html.button(
          [
            attribute.class(case model.campaign_form.objective {
              Some(Consideration) -> "objective-btn selected"
              _ -> "objective-btn"
            }),
            event.on_click(UserSelectedObjective(Consideration)),
          ],
          [html.text("Consideration")],
        ),
        html.button(
          [
            attribute.class(case model.campaign_form.objective {
              Some(Conversion) -> "objective-btn selected"
              _ -> "objective-btn"
            }),
            event.on_click(UserSelectedObjective(Conversion)),
          ],
          [html.text("Conversion")],
        ),
      ]),
    ]),
    html.div([attribute.class("form-section")], [
      html.h3([], [html.text("Targeting")]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Locations")]),
        html.input([
          attribute.type_("text"),
          attribute.placeholder("Enter location"),
          event.on_input(UserUpdatedLocation),
        ]),
        html.div(
          [attribute.class("tags-list")],
          list.map(model.campaign_form.targeting.locations, fn(location) {
            html.span([attribute.class("tag")], [html.text(location)])
          }),
        ),
      ]),
      html.div([attribute.class("form-group")], [
        html.label([], [html.text("Age Range")]),
        html.div([attribute.class("age-range")], [
          html.input([
            attribute.type_("number"),
            attribute.min("13"),
            attribute.max("65"),
            attribute.value(int.to_string(
              model.campaign_form.targeting.age_range.min,
            )),
            event.on_input(fn(value) {
              case int.parse(value) {
                Ok(min) ->
                  UserUpdatedAgeRange(
                    min,
                    model.campaign_form.targeting.age_range.max,
                  )
                Error(_) -> UserUpdatedAgeRange(18, 65)
              }
            }),
          ]),
          html.span([], [html.text(" to ")]),
          html.input([
            attribute.type_("number"),
            attribute.min("13"),
            attribute.max("65"),
            attribute.value(int.to_string(
              model.campaign_form.targeting.age_range.max,
            )),
            event.on_input(fn(value) {
              case int.parse(value) {
                Ok(max) ->
                  UserUpdatedAgeRange(
                    model.campaign_form.targeting.age_range.min,
                    max,
                  )
                Error(_) -> UserUpdatedAgeRange(18, 65)
              }
            }),
          ]),
        ]),
      ]),
    ]),
    html.div([attribute.class("form-actions")], [
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(UserSubmittedCampaignForm),
        ],
        [html.text("Create Campaign")],
      ),
    ]),
  ])
}

pub fn main(_: Nil) -> Nil {
  let app = lustre.application(fn(_) { #(init(), effect.none()) }, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
