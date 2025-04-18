import gleam/option.{type Option, None}

pub type AdPlatform {
  Facebook
  Google
  TikTok
  LinkedIn
  Twitter
  Other(String)
}

pub type AdAccount {
  AdAccount(
    id: String,
    name: String,
    platform: AdPlatform,
    status: AccountStatus,
    currency: String,
    balance: Float,
    spend_limit: Float,
    virtual_card: Option(String),
    verification_status: VerificationStatus,
  )
}

pub type AccountStatus {
  AccountActive
  AccountPaused
  AccountSuspended
  AccountPendingReview
}

pub type VerificationStatus {
  Unverified
  InProgress
  Verified
  Failed
}

pub type Campaign {
  Campaign(
    id: String,
    name: String,
    platform: AdPlatform,
    status: CampaignStatus,
    budget_type: BudgetType,
    budget_amount: Float,
    spend: Float,
    start_date: String,
    end_date: Option(String),
    performance: CampaignPerformance,
  )
}

pub type CampaignStatus {
  CampaignDraft
  CampaignActive
  CampaignPaused
  CampaignCompleted
  CampaignRejected
}

pub type BudgetType {
  Daily
  Lifetime
}

pub type CampaignPerformance {
  CampaignPerformance(
    impressions: Int,
    clicks: Int,
    conversions: Int,
    spend: Float,
    ctr: Float,
    cpc: Float,
    roas: Float,
  )
}

pub type AdSpendAlert {
  AdSpendAlert(
    account_id: String,
    alert_type: AlertType,
    threshold: Float,
    current_spend: Float,
    triggered_at: String,
  )
}

pub type AlertType {
  DailySpendLimit
  BudgetDepletion
  UnusualActivity
  PaymentRequired
}

pub type AdAccountSettings {
  AdAccountSettings(
    default_currency: String,
    auto_reload: Bool,
    reload_threshold: Float,
    reload_amount: Float,
    spend_alerts: List(Float),
    notification_email: String,
  )
}

pub type CampaignForm {
  CampaignForm(
    name: String,
    platform: Option(AdPlatform),
    account_id: Option(String),
    budget_type: Option(BudgetType),
    budget_amount: Option(Float),
    start_date: Option(String),
    end_date: Option(String),
    objective: Option(CampaignObjective),
    targeting: CampaignTargeting,
  )
}

pub type CampaignObjective {
  Awareness
  Consideration
  Conversion
}

pub type CampaignTargeting {
  CampaignTargeting(
    locations: List(String),
    age_range: AgeRange,
    interests: List(String),
    languages: List(String),
    excluded_locations: List(String),
  )
}

pub type AgeRange {
  AgeRange(min: Int, max: Int)
}

pub type FormValidation {
  FormValidation(
    name_error: Option(String),
    platform_error: Option(String),
    account_error: Option(String),
    budget_error: Option(String),
    date_error: Option(String),
  )
}

pub fn new_campaign_form() -> CampaignForm {
  CampaignForm(
    name: "",
    platform: None,
    account_id: None,
    budget_type: None,
    budget_amount: None,
    start_date: None,
    end_date: None,
    objective: None,
    targeting: CampaignTargeting(
      locations: [],
      age_range: AgeRange(min: 18, max: 65),
      interests: [],
      languages: [],
      excluded_locations: [],
    ),
  )
}
