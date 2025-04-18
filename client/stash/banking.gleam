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
    accounts: Dict(Int, Account),
    transfers: Dict(Int, Transfer),
    statements: Dict(Int, Statement),
    organizations: Dict(Int, Organization),
    users: Dict(Int, BankUser),
    current_user: Option(Int),
    last_id: Int,
    nav_open: Bool,
    selected_account: Option(Int),
    budgets: Dict(Int, Budget),
  )
}

pub type Account {
  Account(
    id: Int,
    account_number: String,
    account_type: AccountType,
    balance: Float,
    currency: Currency,
    status: AccountStatus,
    holder_name: String,
    created_at: String,
    last_activity: String,
    interest_rate: Float,
    daily_limit: Float,
    monthly_limit: Float,
    alerts_enabled: Bool,
    minimum_balance: Float,
    overdraft_limit: Float,
    spending_controls: SpendingControls,
    transaction_history: List(Transaction),
    alert_settings: AlertSettings,
  )
}

pub type AccountType {
  Checking
  Savings
  Investment
  Business
}

pub type AccountStatus {
  Active
  Frozen
  Closed
}

pub type Currency {
  USD
  EUR
  GBP
  NGN
  KES
  ZAR
}

pub type Transfer {
  Transfer(
    id: Int,
    from_account: Int,
    to_account: Int,
    amount: Float,
    currency: Currency,
    status: TransferStatus,
    reference: String,
    date: String,
    notes: String,
    schedule: Option(TransferSchedule),
    recurrence: Option(TransferRecurrence),
  )
}

pub type TransferStatus {
  Pending
  Completed
  Failed
  Cancelled
}

pub type TransferSchedule {
  TransferSchedule(
    scheduled_date: String,
    execution_window: String,
    priority: TransferPriority,
  )
}

pub type TransferRecurrence {
  TransferRecurrence(
    frequency: RecurrenceFrequency,
    start_date: String,
    end_date: Option(String),
    max_occurrences: Option(Int),
  )
}

pub type TransferPriority {
  Normal
  High
  Low
}

pub type RecurrenceFrequency {
  Daily
  Weekly
  Monthly
  Quarterly
  Yearly
}

pub type Statement {
  Statement(
    id: Int,
    account_id: Int,
    period: String,
    transactions: List(Transaction),
    opening_balance: Float,
    closing_balance: Float,
    generated_at: String,
    summary: StatementSummary,
    format: StatementFormat,
  )
}

pub type StatementSummary {
  StatementSummary(
    total_credits: Float,
    total_debits: Float,
    transaction_count: Int,
    categories: Dict(TransactionCategory, Float),
  )
}

pub type StatementFormat {
  PDF
  CSV
  JSON
}

pub type Transaction {
  Transaction(
    id: Int,
    date: String,
    description: String,
    amount: Float,
    balance: Float,
    type_: TransactionType,
    category: TransactionCategory,
    reference: String,
    status: TransactionStatus,
    location: Option(String),
    merchant: Option(String),
  )
}

pub type TransactionType {
  Credit
  Debit
}

pub type TransactionCategory {
  TransferTxn
  PaymentTxn
  DepositTxn
  WithdrawalTxn
  FeeTxn
  InterestTxn
  OtherTxn
}

pub type TransactionStatus {
  TxnPending
  TxnCompleted
  TxnFailed
  TxnReversed
}

pub type SpendingControls {
  SpendingControls(
    merchant_categories: List(String),
    country_restrictions: List(String),
    max_transaction_amount: Float,
    allowed_days: List(Int),
    allowed_hours: List(Int),
    requires_approval: Bool,
  )
}

pub type AlertSettings {
  AlertSettings(
    low_balance_threshold: Float,
    large_transaction_threshold: Float,
    foreign_transaction_alerts: Bool,
    login_alerts: Bool,
    spending_limit_alerts: Bool,
  )
}

pub type Organization {
  Organization(
    id: Int,
    name: String,
    type_: OrgType,
    admin_users: List(BankUser),
    members: List(BankUser),
    accounts: List(Int),
    created_at: String,
    status: OrgStatus,
  )
}

pub type OrgType {
  BusinessOrg
  FamilyOrg
  InstitutionOrg
}

pub type OrgStatus {
  ActiveOrg
  SuspendedOrg
  ClosedOrg
}

pub type BankUser {
  BankUser(
    id: Int,
    email: String,
    name: String,
    role: UserRole,
    organization_id: Option(Int),
    last_login: String,
    magic_link_token: Option(String),
    magic_link_expiry: Option(String),
    status: BankUserStatus,
  )
}

pub type UserRole {
  AdminRole
  ManagerRole
  MemberRole
  RestrictedRole
}

pub type BankUserStatus {
  ActiveUser
  PendingUser
  SuspendedUser
}

pub type Budget {
  Budget(
    id: Int,
    name: String,
    period: BudgetingPeriod,
    start_date: String,
    end_date: String,
    categories: Dict(BudgetingCategory, BudgetAllocation),
    rules: List(BudgetRule),
    status: BudgetingStatus,
    owner_id: Int,
    shared_with: List(Int),
  )
}

pub type BudgetingPeriod {
  BudgetMonthly
  BudgetQuarterly
  BudgetYearly
  BudgetCustom(Int)
  // Number of days
}

pub type BudgetingCategory {
  BudgetHousing
  BudgetTransportation
  BudgetFood
  BudgetUtilities
  BudgetHealthcare
  BudgetInsurance
  BudgetSavings
  BudgetDebt
  BudgetEntertainment
  BudgetShopping
  BudgetEducation
  BudgetInvestments
  BudgetBusiness
  BudgetCustomCategory(String)
}

pub type BudgetAllocation {
  BudgetAllocation(
    planned_amount: Float,
    actual_amount: Float,
    currency: Currency,
    alerts_enabled: Bool,
    alert_threshold: Float,
    // Percentage of planned amount
    rollover_enabled: Bool,
    rollover_amount: Float,
    last_updated: String,
  )
}

pub type BudgetRule {
  SpendingLimit(BudgetingCategory, Float)
  AutoCategory(String, BudgetingCategory)
  // Merchant name pattern -> category
  RolloverLimit(Float)
  // Maximum amount that can roll over
  SharedAccess(Int, BudgetPermission)
  // User ID and their permission level
}

pub type BudgetPermission {
  ViewOnly
  Modify
  Admin
}

pub type BudgetingStatus {
  BudgetActive
  BudgetPaused
  BudgetArchived
}

pub type Msg {
  CreateAccount(AccountType, String, Currency)
  CloseAccount(Int)
  FreezeAccount(Int)
  UnfreezeAccount(Int)
  InitiateTransfer(Int, Int, Float, String)
  ScheduleTransfer(Int, Int, Float, String, TransferSchedule)
  SetupRecurringTransfer(Int, Int, Float, String, TransferRecurrence)
  CancelTransfer(Int)
  GenerateStatement(Int, String, StatementFormat)
  SelectAccount(Int)
  UpdateAccountLimits(Int, Float, Float)
  ToggleAccountAlerts(Int)
  SetMinimumBalance(Int, Float)
  SetOverdraftLimit(Int, Float)
  UpdateSpendingControls(Int, SpendingControls)
  UpdateAlertSettings(Int, AlertSettings)
  UpdateInterestRate(Int, Float)
  NavMsg(nav.Msg)
  // Auth messages
  RequestMagicLink(String)
  VerifyMagicLink(String)
  CreateOrganization(String, OrgType)
  InviteUser(Int, String, UserRole)
  AcceptInvite(String)
  // New budget messages
  CreateBudget(String, BudgetingPeriod, String, String)
  UpdateBudget(Int, Budget)
  DeleteBudget(Int)
  AddBudgetCategory(Int, BudgetingCategory, BudgetAllocation)
  UpdateBudgetAllocation(Int, BudgetingCategory, BudgetAllocation)
  AddBudgetRule(Int, BudgetRule)
  RemoveBudgetRule(Int, BudgetRule)
  ShareBudget(Int, Int, BudgetPermission)
  ArchiveBudget(Int)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let sample_accounts =
    [
      #(
        1,
        Account(
          id: 1,
          account_number: "1001-2024-001",
          account_type: Checking,
          balance: 5000.0,
          currency: USD,
          status: Active,
          holder_name: "John Doe",
          created_at: "2024-01-01",
          last_activity: "2024-03-20",
          interest_rate: 0.0,
          daily_limit: 0.0,
          monthly_limit: 0.0,
          alerts_enabled: False,
          minimum_balance: 0.0,
          overdraft_limit: 0.0,
          spending_controls: SpendingControls(
            merchant_categories: [],
            country_restrictions: [],
            max_transaction_amount: 0.0,
            allowed_days: [],
            allowed_hours: [],
            requires_approval: False,
          ),
          transaction_history: [],
          alert_settings: AlertSettings(
            low_balance_threshold: 0.0,
            large_transaction_threshold: 0.0,
            foreign_transaction_alerts: False,
            login_alerts: False,
            spending_limit_alerts: False,
          ),
        ),
      ),
      #(
        2,
        Account(
          id: 2,
          account_number: "1001-2024-002",
          account_type: Savings,
          balance: 15_000.0,
          currency: USD,
          status: Active,
          holder_name: "John Doe",
          created_at: "2024-01-01",
          last_activity: "2024-03-19",
          interest_rate: 0.0,
          daily_limit: 0.0,
          monthly_limit: 0.0,
          alerts_enabled: False,
          minimum_balance: 0.0,
          overdraft_limit: 0.0,
          spending_controls: SpendingControls(
            merchant_categories: [],
            country_restrictions: [],
            max_transaction_amount: 0.0,
            allowed_days: [],
            allowed_hours: [],
            requires_approval: False,
          ),
          transaction_history: [],
          alert_settings: AlertSettings(
            low_balance_threshold: 0.0,
            large_transaction_threshold: 0.0,
            foreign_transaction_alerts: False,
            login_alerts: False,
            spending_limit_alerts: False,
          ),
        ),
      ),
    ]
    |> dict.from_list()

  let sample_transfers =
    [
      #(
        1,
        Transfer(
          id: 1,
          from_account: 1,
          to_account: 2,
          amount: 1000.0,
          currency: USD,
          status: Completed,
          reference: "TRF-2024-001",
          date: "2024-03-20",
          notes: "Monthly savings transfer",
          schedule: None,
          recurrence: None,
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      accounts: sample_accounts,
      transfers: sample_transfers,
      statements: dict.new(),
      organizations: dict.new(),
      users: dict.new(),
      current_user: None,
      last_id: 2,
      nav_open: False,
      selected_account: None,
      budgets: dict.new(),
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    CreateAccount(type_, holder_name, currency) -> {
      let last_id = model.last_id + 1
      let account =
        Account(
          id: last_id,
          account_number: "1001-2024-" <> int.to_string(last_id),
          account_type: type_,
          balance: 0.0,
          currency: currency,
          status: Active,
          holder_name: holder_name,
          created_at: "2024-03-21",
          // TODO: Use actual date
          last_activity: "2024-03-21",
          interest_rate: 0.0,
          daily_limit: 0.0,
          monthly_limit: 0.0,
          alerts_enabled: False,
          minimum_balance: 0.0,
          overdraft_limit: 0.0,
          spending_controls: SpendingControls(
            merchant_categories: [],
            country_restrictions: [],
            max_transaction_amount: 0.0,
            allowed_days: [],
            allowed_hours: [],
            requires_approval: False,
          ),
          transaction_history: [],
          alert_settings: AlertSettings(
            low_balance_threshold: 0.0,
            large_transaction_threshold: 0.0,
            foreign_transaction_alerts: False,
            login_alerts: False,
            spending_limit_alerts: False,
          ),
        )
      let accounts = dict.insert(model.accounts, last_id, account)
      #(Model(..model, accounts: accounts, last_id: last_id), effect.none())
    }

    CloseAccount(id) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(model.accounts, id, Account(..account, status: Closed))
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    FreezeAccount(id) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(model.accounts, id, Account(..account, status: Frozen))
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    UnfreezeAccount(id) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(model.accounts, id, Account(..account, status: Active))
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    InitiateTransfer(from_id, to_id, amount, notes) -> {
      let last_id = model.last_id + 1
      let from_account = dict.get(model.accounts, from_id)
      let to_account = dict.get(model.accounts, to_id)

      case #(from_account, to_account) {
        #(Ok(from), Ok(to)) -> {
          let transfer =
            Transfer(
              id: last_id,
              from_account: from_id,
              to_account: to_id,
              amount: amount,
              currency: from.currency,
              status: Pending,
              reference: "TRF-2024-" <> int.to_string(last_id),
              date: "2024-03-21",
              notes: notes,
              schedule: None,
              recurrence: None,
            )
          let transfers = dict.insert(model.transfers, last_id, transfer)
          #(
            Model(..model, transfers: transfers, last_id: last_id),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }
    }

    ScheduleTransfer(from_id, to_id, amount, notes, schedule) -> {
      let last_id = model.last_id + 1
      let from_account = dict.get(model.accounts, from_id)
      let to_account = dict.get(model.accounts, to_id)

      case #(from_account, to_account) {
        #(Ok(from), Ok(to)) -> {
          let transfer =
            Transfer(
              id: last_id,
              from_account: from_id,
              to_account: to_id,
              amount: amount,
              currency: from.currency,
              status: Pending,
              reference: "TRF-2024-" <> int.to_string(last_id),
              date: "2024-03-21",
              notes: notes,
              schedule: Some(schedule),
              recurrence: None,
            )
          let transfers = dict.insert(model.transfers, last_id, transfer)
          #(
            Model(..model, transfers: transfers, last_id: last_id),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }
    }

    SetupRecurringTransfer(from_id, to_id, amount, notes, recurrence) -> {
      let last_id = model.last_id + 1
      let from_account = dict.get(model.accounts, from_id)
      let to_account = dict.get(model.accounts, to_id)

      case #(from_account, to_account) {
        #(Ok(from), Ok(to)) -> {
          let transfer =
            Transfer(
              id: last_id,
              from_account: from_id,
              to_account: to_id,
              amount: amount,
              currency: from.currency,
              status: Pending,
              reference: "TRF-2024-" <> int.to_string(last_id),
              date: "2024-03-21",
              notes: notes,
              schedule: None,
              recurrence: Some(recurrence),
            )
          let transfers = dict.insert(model.transfers, last_id, transfer)
          #(
            Model(..model, transfers: transfers, last_id: last_id),
            effect.none(),
          )
        }
        _ -> #(model, effect.none())
      }
    }

    CancelTransfer(id) -> {
      let transfers = case dict.get(model.transfers, id) {
        Ok(transfer) ->
          dict.insert(
            model.transfers,
            id,
            Transfer(..transfer, status: Cancelled),
          )
        Error(_) -> model.transfers
      }
      #(Model(..model, transfers: transfers), effect.none())
    }

    GenerateStatement(account_id, period, format) -> {
      let last_id = model.last_id + 1
      let account = dict.get(model.accounts, account_id)

      case account {
        Ok(acc) -> {
          let statement =
            Statement(
              id: last_id,
              account_id: account_id,
              period: period,
              transactions: [],
              opening_balance: acc.balance,
              closing_balance: acc.balance,
              generated_at: "2024-03-21",
              summary: StatementSummary(
                total_credits: 0.0,
                total_debits: 0.0,
                transaction_count: 0,
                categories: dict.new(),
              ),
              format: format,
            )
          let statements = dict.insert(model.statements, last_id, statement)
          #(
            Model(..model, statements: statements, last_id: last_id),
            effect.none(),
          )
        }
        Error(_) -> #(model, effect.none())
      }
    }

    SelectAccount(id) -> {
      #(Model(..model, selected_account: Some(id)), effect.none())
    }

    UpdateAccountLimits(id, daily, monthly) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, daily_limit: daily, monthly_limit: monthly),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    ToggleAccountAlerts(id) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, alerts_enabled: !account.alerts_enabled),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    SetMinimumBalance(id, amount) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, minimum_balance: amount),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    SetOverdraftLimit(id, amount) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, overdraft_limit: amount),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    UpdateSpendingControls(id, controls) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, spending_controls: controls),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    UpdateAlertSettings(id, settings) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, alert_settings: settings),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    UpdateInterestRate(id, rate) -> {
      let accounts = case dict.get(model.accounts, id) {
        Ok(account) ->
          dict.insert(
            model.accounts,
            id,
            Account(..account, interest_rate: rate),
          )
        Error(_) -> model.accounts
      }
      #(Model(..model, accounts: accounts), effect.none())
    }

    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> #(
          Model(..model, nav_open: !model.nav_open),
          effect.none(),
        )
      }
    }

    RequestMagicLink(email) -> {
      // TODO: Integrate with email service to send magic link
      let last_id = model.last_id + 1
      let user =
        BankUser(
          id: last_id,
          email: email,
          name: "",
          // Will be set when user completes profile
          role: MemberRole,
          organization_id: None,
          last_login: "2024-03-21",
          magic_link_token: Some("temp-token-" <> int.to_string(last_id)),
          magic_link_expiry: Some("2024-03-22"),
          status: PendingUser,
        )
      let users = dict.insert(model.users, last_id, user)
      #(Model(..model, users: users, last_id: last_id), effect.none())
    }

    VerifyMagicLink(token) -> {
      // Find user with matching token and verify
      let users =
        dict.values(model.users)
        |> list.filter(fn(user) {
          case user.magic_link_token {
            Some(t) -> t == token
            None -> False
          }
        })

      case list.first(users) {
        Ok(user) -> {
          let updated_user =
            BankUser(
              ..user,
              status: ActiveUser,
              magic_link_token: None,
              magic_link_expiry: None,
            )
          let users = dict.insert(model.users, user.id, updated_user)
          #(
            Model(..model, users: users, current_user: Some(user.id)),
            effect.none(),
          )
        }
        Error(_) -> #(model, effect.none())
      }
    }

    CreateOrganization(name, type_) -> {
      case model.current_user {
        Some(user_id) -> {
          let last_id = model.last_id + 1
          let org =
            Organization(
              id: last_id,
              name: name,
              type_: type_,
              admin_users: [],
              members: [],
              accounts: [],
              created_at: "2024-03-21",
              status: ActiveOrg,
            )
          let organizations = dict.insert(model.organizations, last_id, org)

          // Update user's organization
          let user =
            dict.get(model.users, user_id)
            |> result.unwrap(BankUser(
              id: 0,
              email: "",
              name: "",
              role: MemberRole,
              organization_id: None,
              last_login: "",
              magic_link_token: None,
              magic_link_expiry: None,
              status: PendingUser,
            ))
          let updated_user =
            BankUser(..user, organization_id: Some(last_id), role: AdminRole)
          let users = dict.insert(model.users, user_id, updated_user)

          #(
            Model(
              ..model,
              organizations: organizations,
              users: users,
              last_id: last_id,
            ),
            effect.none(),
          )
        }
        None -> #(model, effect.none())
      }
    }

    InviteUser(org_id, email, role) -> {
      // TODO: Integrate with email service to send invite
      let last_id = model.last_id + 1
      let user =
        BankUser(
          id: last_id,
          email: email,
          name: "",
          role: role,
          organization_id: Some(org_id),
          last_login: "2024-03-21",
          magic_link_token: Some("invite-" <> int.to_string(last_id)),
          magic_link_expiry: Some("2024-03-22"),
          status: PendingUser,
        )
      let users = dict.insert(model.users, last_id, user)
      #(Model(..model, users: users, last_id: last_id), effect.none())
    }

    AcceptInvite(token) -> {
      // Similar to VerifyMagicLink but for organization invites
      let users =
        dict.values(model.users)
        |> list.filter(fn(user) {
          case user.magic_link_token {
            Some(t) -> t == token
            None -> False
          }
        })

      case list.first(users) {
        Ok(user) -> {
          let updated_user =
            BankUser(
              ..user,
              status: ActiveUser,
              magic_link_token: None,
              magic_link_expiry: None,
            )
          let users = dict.insert(model.users, user.id, updated_user)
          #(
            Model(..model, users: users, current_user: Some(user.id)),
            effect.none(),
          )
        }
        Error(_) -> #(model, effect.none())
      }
    }

    CreateBudget(name, period, start_date, end_date) -> {
      let last_id = model.last_id + 1
      let budget =
        Budget(
          id: last_id,
          name: name,
          period: period,
          start_date: start_date,
          end_date: end_date,
          categories: dict.new(),
          rules: [],
          status: BudgetActive,
          owner_id: case model.current_user {
            Some(id) -> id
            None -> 0
          },
          shared_with: [],
        )
      let budgets = dict.insert(model.budgets, last_id, budget)
      #(Model(..model, budgets: budgets, last_id: last_id), effect.none())
    }

    UpdateBudget(id, budget) -> {
      let budgets = dict.insert(model.budgets, id, budget)
      #(Model(..model, budgets: budgets), effect.none())
    }

    DeleteBudget(id) -> {
      let budgets = dict.delete(model.budgets, id)
      #(Model(..model, budgets: budgets), effect.none())
    }

    AddBudgetCategory(budget_id, category, allocation) -> {
      let budgets = case dict.get(model.budgets, budget_id) {
        Ok(budget) -> {
          let categories = dict.insert(budget.categories, category, allocation)
          dict.insert(
            model.budgets,
            budget_id,
            Budget(..budget, categories: categories),
          )
        }
        Error(_) -> model.budgets
      }
      #(Model(..model, budgets: budgets), effect.none())
    }

    UpdateBudgetAllocation(budget_id, category, allocation) -> {
      let budgets = case dict.get(model.budgets, budget_id) {
        Ok(budget) -> {
          let categories = dict.insert(budget.categories, category, allocation)
          dict.insert(
            model.budgets,
            budget_id,
            Budget(..budget, categories: categories),
          )
        }
        Error(_) -> model.budgets
      }
      #(Model(..model, budgets: budgets), effect.none())
    }

    AddBudgetRule(budget_id, rule) -> {
      let budgets = case dict.get(model.budgets, budget_id) {
        Ok(budget) -> {
          let rules = [rule, ..budget.rules]
          dict.insert(model.budgets, budget_id, Budget(..budget, rules: rules))
        }
        Error(_) -> model.budgets
      }
      #(Model(..model, budgets: budgets), effect.none())
    }

    RemoveBudgetRule(budget_id, rule) -> {
      let budgets = case dict.get(model.budgets, budget_id) {
        Ok(budget) -> {
          let rules = list.filter(budget.rules, fn(r) { r != rule })
          dict.insert(model.budgets, budget_id, Budget(..budget, rules: rules))
        }
        Error(_) -> model.budgets
      }
      #(Model(..model, budgets: budgets), effect.none())
    }

    ShareBudget(budget_id, user_id, permission) -> {
      let budgets = case dict.get(model.budgets, budget_id) {
        Ok(budget) -> {
          let shared_with = [user_id, ..budget.shared_with]
          dict.insert(
            model.budgets,
            budget_id,
            Budget(..budget, shared_with: shared_with),
          )
        }
        Error(_) -> model.budgets
      }
      #(Model(..model, budgets: budgets), effect.none())
    }

    ArchiveBudget(id) -> {
      let budgets = case dict.get(model.budgets, id) {
        Ok(budget) ->
          dict.insert(
            model.budgets,
            id,
            Budget(..budget, status: BudgetArchived),
          )
        Error(_) -> model.budgets
      }
      #(Model(..model, budgets: budgets), effect.none())
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
      html.main([attribute.class("banking-app")], [
        view_header(),
        case model.current_user {
          Some(user_id) -> view_authenticated_content(model, user_id)
          None -> view_auth_form()
        },
      ]),
    ],
  )
}

fn view_authenticated_content(model: Model, user_id: Int) -> Element(Msg) {
  let user =
    dict.get(model.users, user_id)
    |> result.unwrap(BankUser(
      id: 0,
      email: "",
      name: "",
      role: MemberRole,
      organization_id: None,
      last_login: "",
      magic_link_token: None,
      magic_link_expiry: None,
      status: PendingUser,
    ))

  html.div([], [
    view_accounts_summary(model),
    case user.organization_id {
      Some(org_id) -> view_organization(model, org_id)
      None -> view_create_org_form()
    },
    view_accounts(model),
    view_transfers(model),
    view_statements(model),
    view_budgets(model),
  ])
}

fn view_auth_form() -> Element(Msg) {
  html.div([attribute.class("auth-form")], [
    html.h2([], [html.text("Welcome to Virtual Banking")]),
    html.p([], [html.text("Enter your email to sign in or create an account")]),
    html.div([attribute.class("magic-link-form")], [
      html.input([
        attribute.type_("email"),
        attribute.name("email"),
        attribute.placeholder("Enter your email"),
        attribute.required(True),
      ]),
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(RequestMagicLink("user@example.com")),
        ],
        [html.text("Continue with Magic Link")],
      ),
    ]),
  ])
}

fn view_create_org_form() -> Element(Msg) {
  html.div([attribute.class("create-org-form")], [
    html.h3([], [html.text("Create an Organization")]),
    html.p([], [
      html.text(
        "Set up a business or family account to manage multiple users and accounts",
      ),
    ]),
    html.div([attribute.class("org-form")], [
      html.input([
        attribute.type_("text"),
        attribute.name("name"),
        attribute.placeholder("Organization Name"),
        attribute.required(True),
      ]),
      html.select([attribute.name("type"), attribute.required(True)], [
        html.option([attribute.value("business")], "Business"),
        html.option([attribute.value("family")], "Family"),
        html.option([attribute.value("institution")], "Institution"),
      ]),
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(CreateOrganization("New Organization", BusinessOrg)),
        ],
        [html.text("Create Organization")],
      ),
    ]),
  ])
}

fn view_organization(model: Model, org_id: Int) -> Element(Msg) {
  let org =
    dict.get(model.organizations, org_id)
    |> result.unwrap(Organization(
      id: 0,
      name: "",
      type_: BusinessOrg,
      admin_users: [],
      members: [],
      accounts: [],
      created_at: "",
      status: ActiveOrg,
    ))

  html.section([attribute.class("organization-section")], [
    html.div([attribute.class("org-header")], [
      html.h3([], [html.text(org.name)]),
      html.div([attribute.class("org-type")], [
        html.text(org_type_to_string(org.type_)),
      ]),
      html.div([attribute.class("org-status")], [
        html.text(org_status_to_string(org.status)),
      ]),
    ]),
    html.div([attribute.class("org-members")], [
      html.h4([], [html.text("Members")]),
      html.div(
        [attribute.class("members-grid")],
        list.map(org.members, view_member),
      ),
      case org.status {
        ActiveOrg ->
          html.div([attribute.class("invite-member")], [
            html.div([attribute.class("invite-form")], [
              html.input([
                attribute.type_("email"),
                attribute.name("email"),
                attribute.placeholder("Member Email"),
                attribute.required(True),
              ]),
              html.select([attribute.name("role"), attribute.required(True)], [
                html.option([attribute.value("manager")], "Manager"),
                html.option([attribute.value("member")], "Member"),
                html.option([attribute.value("restricted")], "Restricted"),
              ]),
              html.button(
                [
                  attribute.class("btn-primary"),
                  event.on_click(InviteUser(
                    org_id,
                    "member@example.com",
                    MemberRole,
                  )),
                ],
                [html.text("Invite Member")],
              ),
            ]),
          ])
        _ -> element.none()
      },
    ]),
  ])
}

fn view_member(user: BankUser) -> Element(Msg) {
  html.div([attribute.class("member-card")], [
    html.div([attribute.class("member-info")], [
      html.div([attribute.class("member-name")], [html.text(user.name)]),
      html.div([attribute.class("member-email")], [html.text(user.email)]),
      html.div([attribute.class("member-role")], [
        html.text(user_role_to_string(user.role)),
      ]),
    ]),
    html.div([attribute.class("member-status")], [
      html.text(user_status_to_string(user.status)),
    ]),
  ])
}

fn org_type_from_string(type_: String) -> OrgType {
  case type_ {
    "business" -> BusinessOrg
    "family" -> FamilyOrg
    "institution" -> InstitutionOrg
    _ -> BusinessOrg
  }
}

fn org_type_to_string(type_: OrgType) -> String {
  case type_ {
    BusinessOrg -> "Business"
    FamilyOrg -> "Family"
    InstitutionOrg -> "Institution"
  }
}

fn org_status_to_string(status: OrgStatus) -> String {
  case status {
    ActiveOrg -> "Active"
    SuspendedOrg -> "Suspended"
    ClosedOrg -> "Closed"
  }
}

fn user_role_from_string(role: String) -> UserRole {
  case role {
    "admin" -> AdminRole
    "manager" -> ManagerRole
    "member" -> MemberRole
    "restricted" -> RestrictedRole
    _ -> MemberRole
  }
}

fn user_role_to_string(role: UserRole) -> String {
  case role {
    AdminRole -> "Admin"
    ManagerRole -> "Manager"
    MemberRole -> "Member"
    RestrictedRole -> "Restricted"
  }
}

fn user_status_to_string(status: BankUserStatus) -> String {
  case status {
    ActiveUser -> "Active"
    PendingUser -> "Pending"
    SuspendedUser -> "Suspended"
  }
}

fn view_header() -> Element(Msg) {
  html.header([attribute.class("app-header")], [
    html.h1([], [html.text("Virtual Banking")]),
    html.p([attribute.class("header-subtitle")], [
      html.text("Manage your accounts, transfers, and statements"),
    ]),
  ])
}

fn view_accounts_summary(model: Model) -> Element(Msg) {
  let total_balance =
    dict.values(model.accounts)
    |> list.filter(fn(acc) { acc.status == Active })
    |> list.fold(0.0, fn(acc, account) { acc +. account.balance })

  let active_accounts =
    dict.values(model.accounts)
    |> list.filter(fn(acc) { acc.status == Active })
    |> list.length

  html.section([attribute.class("summary-stats")], [
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Total Balance")]),
      html.span([attribute.class("stat-value")], [
        html.text("$" <> float.to_string(total_balance)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Active Accounts")]),
      html.span([attribute.class("stat-value")], [
        html.text(int.to_string(active_accounts)),
      ]),
    ]),
  ])
}

fn view_accounts(model: Model) -> Element(Msg) {
  html.section([attribute.class("accounts-section")], [
    html.h2([], [html.text("Your Accounts")]),
    html.div(
      [attribute.class("accounts-grid")],
      dict.values(model.accounts)
        |> list.map(view_account),
    ),
  ])
}

fn view_account(account: Account) -> Element(Msg) {
  html.div([attribute.class("account-card")], [
    html.div([attribute.class("account-header")], [
      html.div([attribute.class("account-title")], [
        html.h3([], [html.text(account_type_to_string(account.account_type))]),
        html.div([attribute.class("account-number")], [
          html.text(account.account_number),
        ]),
      ]),
      html.div([attribute.class("account-balance")], [
        html.text(
          currency_symbol(account.currency) <> float.to_string(account.balance),
        ),
      ]),
    ]),
    html.div([attribute.class("account-details")], [
      html.div([attribute.class("account-holder")], [
        html.text("Holder: " <> account.holder_name),
      ]),
      html.div([attribute.class("account-metrics")], [
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [
            html.text("Interest Rate"),
          ]),
          html.span([attribute.class("metric-value")], [
            html.text(float.to_string(account.interest_rate) <> "%"),
          ]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [
            html.text("Daily Limit"),
          ]),
          html.span([attribute.class("metric-value")], [
            html.text(
              currency_symbol(account.currency)
              <> float.to_string(account.daily_limit),
            ),
          ]),
        ]),
        html.div([attribute.class("metric")], [
          html.span([attribute.class("metric-label")], [
            html.text("Monthly Limit"),
          ]),
          html.span([attribute.class("metric-value")], [
            html.text(
              currency_symbol(account.currency)
              <> float.to_string(account.monthly_limit),
            ),
          ]),
        ]),
      ]),
      html.div([attribute.class("account-security")], [
        html.div([attribute.class("spending-controls")], [
          html.h4([], [html.text("Spending Controls")]),
          html.div([attribute.class("control-grid")], [
            html.div([attribute.class("control-item")], [
              html.span([attribute.class("control-label")], [
                html.text("Max Transaction"),
              ]),
              html.span([attribute.class("control-value")], [
                html.text(
                  currency_symbol(account.currency)
                  <> float.to_string(
                    account.spending_controls.max_transaction_amount,
                  ),
                ),
              ]),
            ]),
            html.div([attribute.class("control-item")], [
              html.span([attribute.class("control-label")], [
                html.text("Requires Approval"),
              ]),
              html.span([attribute.class("control-value")], [
                html.text(case account.spending_controls.requires_approval {
                  True -> "Yes"
                  False -> "No"
                }),
              ]),
            ]),
          ]),
        ]),
        html.div([attribute.class("alert-settings")], [
          html.h4([], [html.text("Alert Settings")]),
          html.div([attribute.class("alert-grid")], [
            html.div([attribute.class("alert-item")], [
              html.span([attribute.class("alert-label")], [
                html.text("Low Balance Alert"),
              ]),
              html.span([attribute.class("alert-value")], [
                html.text(
                  currency_symbol(account.currency)
                  <> float.to_string(
                    account.alert_settings.low_balance_threshold,
                  ),
                ),
              ]),
            ]),
            html.div([attribute.class("alert-item")], [
              html.span([attribute.class("alert-label")], [
                html.text("Large Transaction Alert"),
              ]),
              html.span([attribute.class("alert-value")], [
                html.text(
                  currency_symbol(account.currency)
                  <> float.to_string(
                    account.alert_settings.large_transaction_threshold,
                  ),
                ),
              ]),
            ]),
          ]),
        ]),
      ]),
      html.div(
        [attribute.class("account-status " <> status_class(account.status))],
        [html.text(status_text(account.status))],
      ),
    ]),
    html.div([attribute.class("account-actions")], case account.status {
      Active -> [
        html.button(
          [
            attribute.class("btn-danger"),
            event.on_click(FreezeAccount(account.id)),
          ],
          [html.text("Freeze")],
        ),
        html.button(
          [
            attribute.class("btn-primary"),
            event.on_click(SelectAccount(account.id)),
          ],
          [html.text("View Details")],
        ),
      ]
      Frozen -> [
        html.button(
          [
            attribute.class("btn-primary"),
            event.on_click(UnfreezeAccount(account.id)),
          ],
          [html.text("Unfreeze")],
        ),
      ]
      Closed -> []
    }),
  ])
}

fn view_transfers(model: Model) -> Element(Msg) {
  html.section([attribute.class("transfers-section")], [
    html.h2([], [html.text("Recent Transfers")]),
    html.div(
      [attribute.class("transfers-list")],
      dict.values(model.transfers)
        |> list.map(fn(transfer) { view_transfer(model, transfer) }),
    ),
  ])
}

fn view_transfer(model: Model, transfer: Transfer) -> Element(Msg) {
  let from_account =
    dict.get(model.accounts, transfer.from_account)
    |> result.unwrap(Account(
      id: 0,
      account_number: "",
      account_type: Checking,
      balance: 0.0,
      currency: USD,
      status: Active,
      holder_name: "",
      created_at: "",
      last_activity: "",
      interest_rate: 0.0,
      daily_limit: 0.0,
      monthly_limit: 0.0,
      alerts_enabled: False,
      minimum_balance: 0.0,
      overdraft_limit: 0.0,
      spending_controls: SpendingControls(
        merchant_categories: [],
        country_restrictions: [],
        max_transaction_amount: 0.0,
        allowed_days: [],
        allowed_hours: [],
        requires_approval: False,
      ),
      transaction_history: [],
      alert_settings: AlertSettings(
        low_balance_threshold: 0.0,
        large_transaction_threshold: 0.0,
        foreign_transaction_alerts: False,
        login_alerts: False,
        spending_limit_alerts: False,
      ),
    ))
  let to_account =
    dict.get(model.accounts, transfer.to_account)
    |> result.unwrap(Account(
      id: 0,
      account_number: "",
      account_type: Checking,
      balance: 0.0,
      currency: USD,
      status: Active,
      holder_name: "",
      created_at: "",
      last_activity: "",
      interest_rate: 0.0,
      daily_limit: 0.0,
      monthly_limit: 0.0,
      alerts_enabled: False,
      minimum_balance: 0.0,
      overdraft_limit: 0.0,
      spending_controls: SpendingControls(
        merchant_categories: [],
        country_restrictions: [],
        max_transaction_amount: 0.0,
        allowed_days: [],
        allowed_hours: [],
        requires_approval: False,
      ),
      transaction_history: [],
      alert_settings: AlertSettings(
        low_balance_threshold: 0.0,
        large_transaction_threshold: 0.0,
        foreign_transaction_alerts: False,
        login_alerts: False,
        spending_limit_alerts: False,
      ),
    ))

  html.div([attribute.class("transfer-item")], [
    html.div([attribute.class("transfer-details")], [
      html.div([attribute.class("transfer-accounts")], [
        html.text(
          from_account.account_number <> " → " <> to_account.account_number,
        ),
      ]),
      html.div([attribute.class("transfer-amount")], [
        html.text(
          currency_symbol(transfer.currency) <> float.to_string(transfer.amount),
        ),
      ]),
    ]),
    html.div([attribute.class("transfer-meta")], [
      html.div([attribute.class("transfer-reference")], [
        html.text(transfer.reference),
      ]),
      html.div([attribute.class("transfer-date")], [html.text(transfer.date)]),
      case transfer.schedule {
        Some(schedule) ->
          html.div([attribute.class("transfer-schedule")], [
            html.div([attribute.class("schedule-date")], [
              html.text("Scheduled: " <> schedule.scheduled_date),
            ]),
            html.div([attribute.class("schedule-window")], [
              html.text("Window: " <> schedule.execution_window),
            ]),
            html.div([attribute.class("schedule-priority")], [
              html.text("Priority: " <> priority_to_string(schedule.priority)),
            ]),
          ])
        None -> element.none()
      },
      case transfer.recurrence {
        Some(recurrence) ->
          html.div([attribute.class("transfer-recurrence")], [
            html.div([attribute.class("recurrence-frequency")], [
              html.text(
                "Recurring: " <> frequency_to_string(recurrence.frequency),
              ),
            ]),
            html.div([attribute.class("recurrence-dates")], [
              html.text("Start: " <> recurrence.start_date),
              case recurrence.end_date {
                Some(end_date) -> html.text(" | End: " <> end_date)
                None -> element.none()
              },
            ]),
            case recurrence.max_occurrences {
              Some(max) ->
                html.div([attribute.class("recurrence-max")], [
                  html.text("Max occurrences: " <> int.to_string(max)),
                ])
              None -> element.none()
            },
          ])
        None -> element.none()
      },
      html.div(
        [
          attribute.class(
            "transfer-status " <> transfer_status_class(transfer.status),
          ),
        ],
        [html.text(transfer_status_text(transfer.status))],
      ),
    ]),
    html.div([attribute.class("transfer-actions")], case transfer.status {
      Pending -> [
        html.button(
          [
            attribute.class("btn-danger"),
            event.on_click(CancelTransfer(transfer.id)),
          ],
          [html.text("Cancel")],
        ),
      ]
      _ -> []
    }),
  ])
}

fn view_statements(model: Model) -> Element(Msg) {
  html.section([attribute.class("statements-section")], [
    html.h2([], [html.text("Account Statements")]),
    html.div(
      [attribute.class("statements-list")],
      dict.values(model.statements)
        |> list.map(fn(statement) { view_statement(model, statement) }),
    ),
  ])
}

fn view_statement(model: Model, statement: Statement) -> Element(Msg) {
  let account =
    dict.get(model.accounts, statement.account_id)
    |> result.unwrap(Account(
      id: 0,
      account_number: "",
      account_type: Checking,
      balance: 0.0,
      currency: USD,
      status: Active,
      holder_name: "",
      created_at: "",
      last_activity: "",
      interest_rate: 0.0,
      daily_limit: 0.0,
      monthly_limit: 0.0,
      alerts_enabled: False,
      minimum_balance: 0.0,
      overdraft_limit: 0.0,
      spending_controls: SpendingControls(
        merchant_categories: [],
        country_restrictions: [],
        max_transaction_amount: 0.0,
        allowed_days: [],
        allowed_hours: [],
        requires_approval: False,
      ),
      transaction_history: [],
      alert_settings: AlertSettings(
        low_balance_threshold: 0.0,
        large_transaction_threshold: 0.0,
        foreign_transaction_alerts: False,
        login_alerts: False,
        spending_limit_alerts: False,
      ),
    ))

  html.div([attribute.class("statement-item")], [
    html.div([attribute.class("statement-header")], [
      html.div([attribute.class("statement-account")], [
        html.text(account.account_number),
      ]),
      html.div([attribute.class("statement-period")], [
        html.text("Period: " <> statement.period),
      ]),
    ]),
    html.div([attribute.class("statement-summary")], [
      html.div([attribute.class("balance-summary")], [
        html.div([attribute.class("opening-balance")], [
          html.text("Opening: " <> float.to_string(statement.opening_balance)),
        ]),
        html.div([attribute.class("closing-balance")], [
          html.text("Closing: " <> float.to_string(statement.closing_balance)),
        ]),
      ]),
      html.div([attribute.class("transaction-summary")], [
        html.div([attribute.class("total-credits")], [
          html.text(
            "Credits: " <> float.to_string(statement.summary.total_credits),
          ),
        ]),
        html.div([attribute.class("total-debits")], [
          html.text(
            "Debits: " <> float.to_string(statement.summary.total_debits),
          ),
        ]),
        html.div([attribute.class("transaction-count")], [
          html.text(
            "Transactions: "
            <> int.to_string(statement.summary.transaction_count),
          ),
        ]),
      ]),
      html.div([attribute.class("category-summary")], [
        html.h4([], [html.text("Transaction Categories")]),
        html.div(
          [attribute.class("category-grid")],
          dict.to_list(statement.summary.categories)
            |> list.map(fn(pair) {
              let #(category, amount) = pair
              html.div([attribute.class("category-item")], [
                html.span([attribute.class("category-name")], [
                  html.text(category_to_string(category)),
                ]),
                html.span([attribute.class("category-amount")], [
                  html.text(float.to_string(amount)),
                ]),
              ])
            }),
        ),
      ]),
    ]),
    html.div([attribute.class("statement-format")], [
      html.text("Format: " <> format_to_string(statement.format)),
    ]),
    html.div([attribute.class("statement-actions")], [
      html.button([attribute.class("btn-primary")], [
        html.text("Download " <> format_to_string(statement.format)),
      ]),
    ]),
  ])
}

fn view_budgets(model: Model) -> Element(Msg) {
  html.section([attribute.class("budgets-section")], [
    html.h2([], [html.text("Budgets")]),
    html.div(
      [attribute.class("budgets-grid")],
      dict.values(model.budgets)
        |> list.map(view_budget),
    ),
  ])
}

fn view_budget(budget: Budget) -> Element(Msg) {
  html.div([attribute.class("budget-card")], [
    html.div([attribute.class("budget-header")], [
      html.div([attribute.class("budget-title")], [
        html.h3([], [html.text(budget.name)]),
        html.div([attribute.class("budget-period")], [
          html.text(budget_period_to_string(budget.period)),
        ]),
      ]),
      html.div([attribute.class("budget-dates")], [
        html.text(budget.start_date <> " - " <> budget.end_date),
      ]),
    ]),
    html.div([attribute.class("budget-categories")], [
      html.h4([], [html.text("Categories")]),
      html.div(
        [attribute.class("categories-grid")],
        dict.to_list(budget.categories)
          |> list.map(fn(pair) {
            let #(category, allocation) = pair
            view_budget_category(category, allocation)
          }),
      ),
    ]),
    html.div([attribute.class("budget-rules")], [
      html.h4([], [html.text("Rules")]),
      html.div(
        [attribute.class("rules-list")],
        list.map(budget.rules, view_budget_rule),
      ),
    ]),
    html.div(
      [
        attribute.class(
          "budget-status "
          <> case budget.status {
            BudgetActive -> "status-active"
            BudgetPaused -> "status-paused"
            BudgetArchived -> "status-archived"
          },
        ),
      ],
      [
        html.text(case budget.status {
          BudgetActive -> "Active"
          BudgetPaused -> "Paused"
          BudgetArchived -> "Archived"
        }),
      ],
    ),
    html.div([attribute.class("budget-actions")], case budget.status {
      BudgetActive -> [
        html.button(
          [
            attribute.class("btn-primary"),
            event.on_click(ArchiveBudget(budget.id)),
          ],
          [html.text("Archive")],
        ),
      ]
      _ -> []
    }),
  ])
}

fn view_budget_category(
  category: BudgetingCategory,
  allocation: BudgetAllocation,
) -> Element(Msg) {
  html.div([attribute.class("category-item")], [
    html.div([attribute.class("category-header")], [
      html.div([attribute.class("category-name")], [
        html.text(budget_category_to_string(category)),
      ]),
      html.div([attribute.class("category-amounts")], [
        html.div([attribute.class("planned-amount")], [
          html.text(
            currency_symbol(allocation.currency)
            <> float.to_string(allocation.planned_amount),
          ),
        ]),
        html.div([attribute.class("actual-amount")], [
          html.text(
            currency_symbol(allocation.currency)
            <> float.to_string(allocation.actual_amount),
          ),
        ]),
      ]),
    ]),
    html.div([attribute.class("category-progress")], [
      html.div(
        [
          attribute.class("progress-bar"),
          attribute.style([
            #(
              "width",
              float.to_string(
                allocation.actual_amount /. allocation.planned_amount *. 100.0,
              )
                <> "%",
            ),
          ]),
        ],
        [],
      ),
    ]),
    case allocation.alerts_enabled {
      True ->
        html.div([attribute.class("category-alert")], [
          html.text(
            "Alert at "
            <> float.to_string(allocation.alert_threshold)
            <> "% of budget",
          ),
        ])
      False -> element.none()
    },
  ])
}

fn view_budget_rule(rule: BudgetRule) -> Element(Msg) {
  html.div([attribute.class("rule-item")], [
    html.div([attribute.class("rule-content")], case rule {
      SpendingLimit(category, amount) -> [
        html.text(
          "Spending limit of "
          <> float.to_string(amount)
          <> " for "
          <> budget_category_to_string(category),
        ),
      ]
      AutoCategory(pattern, category) -> [
        html.text(
          "Auto-categorize \""
          <> pattern
          <> "\" as "
          <> budget_category_to_string(category),
        ),
      ]
      RolloverLimit(amount) -> [
        html.text("Maximum rollover amount: " <> float.to_string(amount)),
      ]
      SharedAccess(user_id, permission) -> [
        html.text(
          "Shared with user "
          <> int.to_string(user_id)
          <> " ("
          <> budget_permission_to_string(permission)
          <> ")",
        ),
      ]
    }),
  ])
}

fn budget_period_to_string(period: BudgetingPeriod) -> String {
  case period {
    BudgetMonthly -> "Monthly"
    BudgetQuarterly -> "Quarterly"
    BudgetYearly -> "Yearly"
    BudgetCustom(days) -> int.to_string(days) <> " days"
  }
}

fn budget_category_to_string(category: BudgetingCategory) -> String {
  case category {
    BudgetHousing -> "Housing"
    BudgetTransportation -> "Transportation"
    BudgetFood -> "Food"
    BudgetUtilities -> "Utilities"
    BudgetHealthcare -> "Healthcare"
    BudgetInsurance -> "Insurance"
    BudgetSavings -> "Savings"
    BudgetDebt -> "Debt"
    BudgetEntertainment -> "Entertainment"
    BudgetShopping -> "Shopping"
    BudgetEducation -> "Education"
    BudgetInvestments -> "Investments"
    BudgetBusiness -> "Business"
    BudgetCustomCategory(name) -> name
  }
}

fn budget_permission_to_string(permission: BudgetPermission) -> String {
  case permission {
    ViewOnly -> "View Only"
    Modify -> "Modify"
    Admin -> "Admin"
  }
}

fn account_type_to_string(type_: AccountType) -> String {
  case type_ {
    Checking -> "Checking Account"
    Savings -> "Savings Account"
    Investment -> "Investment Account"
    Business -> "Business Account"
  }
}

fn status_class(status: AccountStatus) -> String {
  case status {
    Active -> "status-active"
    Frozen -> "status-frozen"
    Closed -> "status-closed"
  }
}

fn status_text(status: AccountStatus) -> String {
  case status {
    Active -> "Active"
    Frozen -> "Frozen"
    Closed -> "Closed"
  }
}

fn transfer_status_class(status: TransferStatus) -> String {
  case status {
    Pending -> "status-pending"
    Completed -> "status-completed"
    Failed -> "status-failed"
    Cancelled -> "status-cancelled"
  }
}

fn transfer_status_text(status: TransferStatus) -> String {
  case status {
    Pending -> "Pending"
    Completed -> "Completed"
    Failed -> "Failed"
    Cancelled -> "Cancelled"
  }
}

fn currency_symbol(currency: Currency) -> String {
  case currency {
    USD -> "$"
    EUR -> "€"
    GBP -> "£"
    NGN -> "₦"
    KES -> "KSh"
    ZAR -> "R"
  }
}

fn priority_to_string(priority: TransferPriority) -> String {
  case priority {
    Normal -> "Normal"
    High -> "High"
    Low -> "Low"
  }
}

fn frequency_to_string(frequency: RecurrenceFrequency) -> String {
  case frequency {
    Daily -> "Daily"
    Weekly -> "Weekly"
    Monthly -> "Monthly"
    Quarterly -> "Quarterly"
    Yearly -> "Yearly"
  }
}

fn format_to_string(format: StatementFormat) -> String {
  case format {
    PDF -> "PDF"
    CSV -> "CSV"
    JSON -> "JSON"
  }
}

fn category_to_string(category: TransactionCategory) -> String {
  case category {
    TransferTxn -> "Transfer"
    PaymentTxn -> "Payment"
    DepositTxn -> "Deposit"
    WithdrawalTxn -> "Withdrawal"
    FeeTxn -> "Fee"
    InterestTxn -> "Interest"
    OtherTxn -> "Other"
  }
}
