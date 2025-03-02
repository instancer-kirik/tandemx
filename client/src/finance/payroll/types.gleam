import gleam/option.{type Option}

pub type PayCycle {
  Weekly
  Biweekly
  Monthly
}

pub type TaxWithholding {
  Automatic
  Manual
  None
}

pub type PaymentMethod {
  BankTransfer
  MobileMoney
  Cash
}

pub type Employee {
  Employee(
    id: String,
    name: String,
    role: String,
    salary: Float,
    pay_cycle: PayCycle,
    tax_withholding: TaxWithholding,
    payment_method: PaymentMethod,
    bank_details: Option(BankDetails),
    mobile_money_details: Option(MobileMoneyDetails),
  )
}

pub type BankDetails {
  BankDetails(
    bank_name: String,
    account_number: String,
    account_name: String,
    branch_code: String,
  )
}

pub type MobileMoneyDetails {
  MobileMoneyDetails(
    provider: String,
    phone_number: String,
    account_name: String,
  )
}

pub type PayrollPeriod {
  PayrollPeriod(
    start_date: String,
    end_date: String,
    pay_date: String,
    status: PayrollPeriodStatus,
  )
}

pub type PayrollPeriodStatus {
  PeriodDraft
  PeriodProcessing
  PeriodCompleted
  PeriodFailed
}

pub type PayrollEntry {
  PayrollEntry(
    employee: Employee,
    base_salary: Float,
    deductions: List(Deduction),
    allowances: List(Allowance),
    net_pay: Float,
    status: PayrollEntryStatus,
  )
}

pub type Deduction {
  Deduction(name: String, amount: Float, deduction_type: DeductionType)
}

pub type DeductionType {
  TaxDeduction
  InsuranceDeduction
  PensionDeduction
  LoanDeduction
  CustomDeduction(String)
}

pub type Allowance {
  Allowance(name: String, amount: Float, allowance_type: AllowanceType)
}

pub type AllowanceType {
  HousingAllowance
  TransportAllowance
  MealAllowance
  MedicalAllowance
  CustomAllowance(String)
}

pub type PayrollEntryStatus {
  EntryPending
  EntryProcessing
  EntryCompleted
  EntryFailed
}
