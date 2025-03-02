pub type TaxRegion {
  Nigeria
  Kenya
  SouthAfrica
  Other(String)
}

pub type FilingFrequency {
  Monthly
  Quarterly
  Annually
}

pub type TaxCategory {
  VAT
  CorporateIncomeTax
  PayrollTax
  WithholdingTax
  CustomTax(String)
}

pub type TaxRate {
  TaxRate(
    category: TaxCategory,
    rate: Float,
    effective_date: String,
    region: TaxRegion,
  )
}

pub type TaxFiling {
  TaxFiling(
    id: String,
    category: TaxCategory,
    period_start: String,
    period_end: String,
    due_date: String,
    amount: Float,
    status: FilingStatus,
  )
}

pub type FilingStatus {
  Draft
  Submitted
  Paid
  Late
  Overdue
}

pub type TaxDocument {
  TaxDocument(
    id: String,
    name: String,
    category: TaxCategory,
    date: String,
    file_url: String,
    status: DocumentStatus,
  )
}

pub type DocumentStatus {
  Pending
  Verified
  Rejected
}

pub type TaxSettings {
  TaxSettings(
    vat_number: String,
    tax_region: TaxRegion,
    filing_frequency: FilingFrequency,
    tax_rates: List(TaxRate),
  )
}
