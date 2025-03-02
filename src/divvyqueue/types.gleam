pub type ContractType {
  Standard
  SmartContract
  MultiParty
  Institutional
  DeFiLending
  DeFiStaking
  DeFiLiquidity
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
  Party(name: String, role: PartyRole, status: PartyStatus, trust_score: Float)
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
  Draft
  Pending
  Active
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
