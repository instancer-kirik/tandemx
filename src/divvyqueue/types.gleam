pub type ContractType {
  Service
  Partnership
  Employment
  Other
}

pub type PartyRole {
  Lender
  Borrower
  Guarantor
  Validator
  Institution
  LiquidityProvider
  Staker
  Protocol
}

pub type PartyStatus {
  Pending
  Accepted
  Rejected
}

pub type VerificationStatus {
  VerificationUnverified
  VerificationPending
  VerificationVerified
  VerificationInstitution
}

pub type Party {
  Party(name: String, role: String, address: String, wallet_address: String)
}

pub type Contract {
  Contract(
    id: String,
    contract_type: ContractType,
    parties: List(Party),
    status: ContractStatus,
    verification: VerificationStatus,
    created_at: String,
    updated_at: String,
    metadata: ContractMetadata,
  )
}

pub type ContractStatus {
  Active
  Pending
  Completed
  Breached
  Terminated
}

pub type ContractMetadata {
  ContractMetadata(
    amount: Float,
    currency: String,
    apy: Option(Float),
    term_length: Option(Int),
    collateral: Option(Float),
    risk_level: Option(String),
    protocol_id: Option(String),
  )
}

pub type KeyDates {
  KeyDates(
    effective_date: String,
    expiration_date: String,
    next_review_date: String,
    termination_date: Option(String),
  )
}

pub type GoverningLaw {
  GoverningLaw(jurisdiction: String, dispute_resolution: String, venue: String)
}

pub type Responsibility {
  Responsibility(party: String, items: List(String))
}

pub type MarketConditions {
  MarketConditions(overview: String, trends: List(String), risks: List(String))
}

pub type CompetitiveAnalysis {
  CompetitiveAnalysis(strengths: List(String), opportunities: List(String))
}

pub type IndustryAnalysis {
  IndustryAnalysis(
    market_conditions: MarketConditions,
    competitive_analysis: CompetitiveAnalysis,
    regulatory_considerations: List(String),
  )
}

pub type MonetaryDividend {
  MonetaryDividend(
    type_: String,
    amount: Float,
    currency: String,
    schedule: String,
    distribution: Dict(String, Float),
  )
}

pub type CryptoDividend {
  CryptoDividend(
    type_: String,
    amount: Float,
    token: String,
    schedule: String,
    distribution: Dict(String, Float),
  )
}

pub type ResourceDividend {
  ResourceDividend(
    type_: String,
    name: String,
    provider: String,
    beneficiary: String,
    duration: String,
  )
}

pub type Dividends {
  Dividends(
    monetary: List(MonetaryDividend),
    crypto: List(CryptoDividend),
    resources: List(ResourceDividend),
  )
}

pub type Timeline {
  Timeline(milestones: List(Milestone))
}

pub type Milestone {
  Milestone(date: String, description: String)
}

pub type Agreement {
  Agreement(
    id: String,
    title: String,
    type_: String,
    status: String,
    key_dates: KeyDates,
    parties: List(Party),
    governing_law: GoverningLaw,
    responsibilities: List(Responsibility),
    industry_analysis: IndustryAnalysis,
    dividends: Dividends,
    last_updated: String,
    description: String,
    timeline: Timeline,
  )
}
