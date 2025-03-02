import components/nav
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
    contracts: Dict(Int, Contract),
    last_id: Int,
    nav_open: Bool,
    selected_contract: Option(Int),
    view_mode: ViewMode,
    templates: List(ContractTemplate),
    show_templates: Bool,
    marketplace_items: Dict(Int, MarketplaceItem),
    selected_item: Option(Int),
  )
}

pub type ViewMode {
  ViewList
  ViewDetail
  ViewTemplates
  ViewMarketplace
  ViewItemDetail
}

pub type ContractTemplate {
  ContractTemplate(
    id: String,
    title: String,
    description: String,
    category: String,
    default_amount: Float,
    default_terms: String,
    required_parties: List(RequiredParty),
  )
}

pub type RequiredParty {
  RequiredParty(role: String, description: String)
}

pub type Contract {
  Contract(
    id: Int,
    title: String,
    amount: Float,
    status: ContractStatus,
    parties: List(Party),
    terms: String,
    created_at: String,
    primary_persona_id: Int,
    related_works: List(Int),
    activity_log: List(ContractActivity),
    metadata: ContractMetadata,
  )
}

pub type ContractStatus {
  ContractDraft
  ContractPending
  ContractActive
  ContractCompleted
  ContractDisputed
}

pub type Party {
  Party(
    name: String,
    role: String,
    status: PartyStatus,
    persona_id: Option(Int),
    verification_level: Option(VerificationLevel),
    trust_score: Option(Int),
  )
}

pub type PartyStatus {
  PartyPending
  PartyAccepted
  PartyRejected
}

pub type VerificationLevel {
  Verified
  Institution
  Premium
}

pub type ContractActivity {
  ContractActivity(
    timestamp: String,
    action: String,
    persona_id: Int,
    details: String,
  )
}

pub type ContractMetadata {
  ContractMetadata(
    category: String,
    tags: List(String),
    associated_institutions: List(Int),
    risk_score: Int,
    performance_metrics: ContractMetrics,
  )
}

pub type ContractMetrics {
  ContractMetrics(
    completion_time: Option(Int),
    payment_reliability: Float,
    collaboration_score: Int,
    dispute_count: Int,
  )
}

pub type MarketplaceItem {
  MarketplaceItem(
    id: Int,
    title: String,
    description: String,
    category: String,
    item_type: ItemType,
    price_per_hour: Option(Float),
    price_per_day: Option(Float),
    price_per_month: Option(Float),
    price: Option(Float),
    sale_price: Option(Float),
    sale_ends_at: Option(String),
    inventory: Option(Inventory),
    availability: List(TimeSlot),
    features: List(Feature),
    location: Location,
    owner_persona_id: Int,
    media: List(Media),
    status: ItemStatus,
    shipping_options: List(ShippingOption),
    variants: List(ProductVariant),
    reviews: List(Review),
    tags: List(String),
  )
}

pub type ItemType {
  Product
  Service
}

pub type Inventory {
  Inventory(
    quantity: Int,
    sku: String,
    low_stock_threshold: Int,
    track_quantity: Bool,
    allow_backorder: Bool,
  )
}

pub type ShippingOption {
  ShippingOption(
    name: String,
    price: Float,
    estimated_days: Int,
    carrier: String,
    tracking_available: Bool,
  )
}

pub type ProductVariant {
  ProductVariant(
    id: Int,
    name: String,
    sku: String,
    price: Float,
    inventory: Inventory,
    attributes: Dict(String, String),
  )
}

pub type Review {
  Review(
    id: Int,
    author_persona_id: Int,
    rating: Int,
    comment: String,
    created_at: String,
    verified_purchase: Bool,
  )
}

pub type TimeSlot {
  TimeSlot(
    start_time: String,
    end_time: String,
    is_available: Bool,
    booking_id: Option(Int),
  )
}

pub type Feature {
  Feature(
    name: String,
    category: String,
    description: String,
    included: Bool,
    extra_cost: Option(Float),
  )
}

pub type Location {
  Location(
    address: String,
    city: String,
    state: String,
    postal_code: String,
    country: String,
    coordinates: Option(#(Float, Float)),
    accessibility: List(String),
    parking: List(String),
    public_transport: List(String),
  )
}

pub type Media {
  Media(
    url: String,
    type_: String,
    title: String,
    description: String,
    is_featured: Bool,
  )
}

pub type ItemStatus {
  ItemAvailable
  ItemBooked
  ItemMaintenance
  ItemUnavailable
}

pub type Msg {
  UserClickedAcceptContract(Int)
  UserClickedRejectContract(Int)
  UserSelectedContract(Int)
  UserClickedBack
  UserClickedNewContract
  UserSelectedTemplate(String)
  UserSelectedItem(Int)
  UserClickedBookItem(Int)
  UserClickedAddToCart(Int)
  NavMsg(nav.Msg)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) {
  let templates = [
    ContractTemplate(
      id: "student-loan",
      title: "Student Loan Agreement",
      description: "Standard agreement for educational financing between a student, financial institution, and educational institution.",
      category: "Education",
      default_amount: 25_000.0,
      default_terms: "This Student Loan Agreement (\"Agreement\") is made between [LENDER] (\"Lender\") and [BORROWER] (\"Borrower\") for the purpose of financing education at [SCHOOL]. The loan amount of $[AMOUNT] will be disbursed according to the academic calendar and is subject to the following terms:\n\n1. Interest Rate: Fixed at 4.5% APR\n2. Repayment Term: 10 years\n3. Grace Period: 6 months post-graduation\n4. Monthly Payment: To be calculated based on final disbursement\n\nThe Borrower agrees to maintain satisfactory academic progress and promptly notify the Lender of any changes in enrollment status.",
      required_parties: [
        RequiredParty(
          role: "Borrower",
          description: "Student receiving the loan",
        ),
        RequiredParty(
          role: "Lender",
          description: "Financial institution providing the loan",
        ),
        RequiredParty(
          role: "School",
          description: "Educational institution receiving funds",
        ),
      ],
    ),
    ContractTemplate(
      id: "isa",
      title: "Income Share Agreement",
      description: "Agreement where student pays a percentage of future income in exchange for education funding.",
      category: "Education",
      default_amount: 15_000.0,
      default_terms: "This Income Share Agreement (\"ISA\") establishes the terms under which [SCHOOL] will provide education services to [STUDENT] in exchange for a percentage of future income. Key terms include:\n\n1. Training Value: $[AMOUNT]\n2. Income Share: 12% of gross monthly income\n3. Payment Cap: $[CAP_AMOUNT]\n4. Minimum Income Threshold: $40,000/year\n5. Maximum Payment Term: 48 months\n\nPayments begin only when the Student's income exceeds the minimum threshold. The ISA obligation will be satisfied upon reaching either the Payment Cap or Maximum Payment Term.",
      required_parties: [
        RequiredParty(
          role: "Student",
          description: "Individual receiving training",
        ),
        RequiredParty(
          role: "School",
          description: "Institution providing education",
        ),
        RequiredParty(
          role: "Investor",
          description: "Entity funding the agreement",
        ),
      ],
    ),
    ContractTemplate(
      id: "business-loan",
      title: "Business Loan Agreement",
      description: "Standard commercial loan agreement for business financing.",
      category: "Business",
      default_amount: 100_000.0,
      default_terms: "This Business Loan Agreement (\"Agreement\") is entered into between [LENDER] (\"Lender\") and [BORROWER] (\"Borrower\") for the purpose of business financing.\n\n1. Loan Amount: $[AMOUNT]\n2. Interest Rate: Prime Rate + 2%\n3. Term: 5 years\n4. Payment Schedule: Monthly payments of principal and interest\n5. Collateral: [SPECIFY]\n\nUse of Funds: [PURPOSE]\nFinancial Covenants: [COVENANTS]\nReporting Requirements: Monthly financial statements",
      required_parties: [
        RequiredParty(
          role: "Borrower",
          description: "Business receiving the loan",
        ),
        RequiredParty(
          role: "Lender",
          description: "Financial institution providing the loan",
        ),
        RequiredParty(
          role: "Guarantor",
          description: "Individual or entity guaranteeing the loan",
        ),
      ],
    ),
    ContractTemplate(
      id: "revenue-share",
      title: "Revenue Share Agreement",
      description: "Agreement for sharing revenue between business partners or investors.",
      category: "Business",
      default_amount: 50_000.0,
      default_terms: "This Revenue Share Agreement outlines the terms under which [INVESTOR] will provide capital to [BUSINESS] in exchange for a share of future revenue.\n\n1. Investment Amount: $[AMOUNT]\n2. Revenue Share: 5% of monthly gross revenue\n3. Total Return Cap: 2x investment amount\n4. Payment Frequency: Monthly\n5. Term: Until return cap is reached\n\nReporting Requirements:\n- Monthly revenue reports\n- Quarterly financial statements\n- Annual audited accounts",
      required_parties: [
        RequiredParty(
          role: "Business",
          description: "Entity receiving investment",
        ),
        RequiredParty(role: "Investor", description: "Party providing capital"),
      ],
    ),
    ContractTemplate(
      id: "equipment-finance",
      title: "Equipment Finance Agreement",
      description: "Financing agreement for business equipment and machinery.",
      category: "Business",
      default_amount: 75_000.0,
      default_terms: "This Equipment Finance Agreement (\"Agreement\") is made between [LENDER] and [BORROWER] for the financing of [EQUIPMENT].\n\n1. Equipment Cost: $[AMOUNT]\n2. Term: 36 months\n3. Interest Rate: 6.5% fixed\n4. Monthly Payment: $[PAYMENT]\n5. Security: First lien on equipment\n\nMaintenance Requirements:\n- Regular scheduled maintenance\n- Annual inspections\n- Insurance coverage",
      required_parties: [
        RequiredParty(
          role: "Borrower",
          description: "Business acquiring equipment",
        ),
        RequiredParty(role: "Lender", description: "Finance provider"),
        RequiredParty(role: "Vendor", description: "Equipment supplier"),
      ],
    ),
  ]

  let sample_contracts =
    [
      #(
        1,
        Contract(
          id: 1,
          title: "Student Loan Agreement - Alice Chen",
          amount: 25_000.0,
          status: ContractPending,
          parties: [
            Party(
              "Alice Chen",
              "Borrower",
              PartyAccepted,
              Some(1),
              Some(Verified),
              Some(85),
            ),
            Party(
              "First National Bank",
              "Lender",
              PartyPending,
              Some(3),
              Some(Institution),
              Some(90),
            ),
            Party(
              "Stanford University",
              "School",
              PartyAccepted,
              Some(2),
              Some(Premium),
              Some(95),
            ),
          ],
          terms: "This Student Loan Agreement (\"Agreement\") is made between First National Bank (\"Lender\") and Alice Chen (\"Borrower\") for the purpose of financing education at Stanford University. The loan amount of $25,000 will be disbursed according to the academic calendar and is subject to the following terms:\n\n1. Interest Rate: Fixed at 4.5% APR\n2. Repayment Term: 10 years\n3. Grace Period: 6 months post-graduation\n4. Monthly Payment: Approximately $259\n\nThe Borrower agrees to maintain satisfactory academic progress and promptly notify the Lender of any changes in enrollment status.",
          created_at: "2024-03-20",
          primary_persona_id: 1,
          related_works: [1, 2],
          activity_log: [
            ContractActivity(
              "2024-03-20",
              "Contract Created",
              1,
              "Initial contract draft created",
            ),
            ContractActivity(
              "2024-03-20",
              "Party Accepted",
              1,
              "Borrower accepted terms",
            ),
          ],
          metadata: ContractMetadata(
            category: "Education",
            tags: ["student loan", "education financing", "undergraduate"],
            associated_institutions: [2, 3],
            risk_score: 85,
            performance_metrics: ContractMetrics(
              completion_time: None,
              payment_reliability: 0.0,
              collaboration_score: 90,
              dispute_count: 0,
            ),
          ),
        ),
      ),
      #(
        2,
        Contract(
          id: 2,
          title: "Tech Academy ISA - Bob Smith",
          amount: 15_000.0,
          status: ContractActive,
          parties: [
            Party("Bob Smith", "Student", PartyAccepted, None, None, None),
            Party("Tech Academy", "School", PartyAccepted, None, None, None),
            Party("ISA Fund LLC", "Investor", PartyAccepted, None, None, None),
          ],
          terms: "This Income Share Agreement (\"ISA\") establishes the terms under which Tech Academy will provide education services to Bob Smith in exchange for a percentage of future income. Key terms include:\n\n1. Training Value: $15,000\n2. Income Share: 12% of gross monthly income\n3. Payment Cap: $22,500\n4. Minimum Income Threshold: $40,000/year\n5. Maximum Payment Term: 48 months\n\nPayments begin only when the Student's income exceeds the minimum threshold. The ISA obligation will be satisfied upon reaching either the Payment Cap or Maximum Payment Term.",
          created_at: "2024-03-15",
          primary_persona_id: 2,
          related_works: [],
          activity_log: [],
          metadata: ContractMetadata(
            category: "Education",
            tags: ["income share", "education financing", "postgraduate"],
            associated_institutions: [2],
            risk_score: 90,
            performance_metrics: ContractMetrics(
              completion_time: None,
              payment_reliability: 0.0,
              collaboration_score: 90,
              dispute_count: 0,
            ),
          ),
        ),
      ),
      #(
        3,
        Contract(
          id: 3,
          title: "Equipment Finance - XYZ Manufacturing",
          amount: 75_000.0,
          status: ContractActive,
          parties: [
            Party(
              "XYZ Manufacturing",
              "Borrower",
              PartyAccepted,
              None,
              None,
              None,
            ),
            Party(
              "Equipment Capital LLC",
              "Lender",
              PartyAccepted,
              None,
              None,
              None,
            ),
            Party(
              "Machine Tools Co.",
              "Vendor",
              PartyAccepted,
              None,
              None,
              None,
            ),
          ],
          terms: "This Equipment Finance Agreement (\"Agreement\") is made between Equipment Capital LLC and XYZ Manufacturing for the financing of CNC Machining Center.\n\n1. Equipment Cost: $75,000\n2. Term: 36 months\n3. Interest Rate: 6.5% fixed\n4. Monthly Payment: $2,300\n5. Security: First lien on equipment\n\nMaintenance Requirements:\n- Regular scheduled maintenance\n- Annual inspections\n- Insurance coverage required",
          created_at: "2024-03-10",
          primary_persona_id: 3,
          related_works: [],
          activity_log: [],
          metadata: ContractMetadata(
            category: "Business",
            tags: ["equipment finance", "machinery", "manufacturing"],
            associated_institutions: [3],
            risk_score: 80,
            performance_metrics: ContractMetrics(
              completion_time: None,
              payment_reliability: 0.0,
              collaboration_score: 85,
              dispute_count: 0,
            ),
          ),
        ),
      ),
    ]
    |> dict.from_list()

  let sample_marketplace_items =
    [
      #(
        1,
        MarketplaceItem(
          id: 1,
          title: "Downtown Art Studio",
          description: "Bright, spacious art studio with natural lighting and equipment",
          category: "Art Studio",
          item_type: Service,
          price_per_hour: Some(25.0),
          price_per_day: Some(150.0),
          price_per_month: Some(2000.0),
          price: None,
          sale_price: None,
          sale_ends_at: None,
          inventory: None,
          availability: [
            TimeSlot(
              start_time: "2024-03-25T09:00:00Z",
              end_time: "2024-03-25T17:00:00Z",
              is_available: True,
              booking_id: None,
            ),
          ],
          features: [
            Feature(
              name: "Easels",
              category: "Equipment",
              description: "Professional wooden easels",
              included: True,
              extra_cost: None,
            ),
            Feature(
              name: "Storage",
              category: "Space",
              description: "Secure storage lockers",
              included: False,
              extra_cost: Some(50.0),
            ),
          ],
          location: Location(
            address: "123 Art Street",
            city: "Portland",
            state: "OR",
            postal_code: "97201",
            country: "USA",
            coordinates: Some(#(45.523064, -122.676483)),
            accessibility: ["Elevator", "Wide doorways"],
            parking: ["Street parking", "Garage nearby"],
            public_transport: [
              "Bus stop 2 blocks away", "Light rail station 5 min walk",
            ],
          ),
          owner_persona_id: 2,
          media: [
            Media(
              url: "/images/studio1.jpg",
              type_: "image",
              title: "Main studio space",
              description: "Large windows provide natural lighting throughout the day",
              is_featured: True,
            ),
          ],
          status: ItemAvailable,
          shipping_options: [],
          variants: [],
          reviews: [],
          tags: ["art studio", "creative space", "natural light"],
        ),
      ),
      #(
        2,
        MarketplaceItem(
          id: 2,
          title: "Professional Art Supplies Kit",
          description: "Complete set of professional-grade art supplies including brushes, paints, and canvas",
          category: "Art Supplies",
          item_type: Product,
          price_per_hour: None,
          price_per_day: None,
          price_per_month: None,
          price: Some(199.99),
          sale_price: Some(159.99),
          sale_ends_at: Some("2024-04-01T00:00:00Z"),
          inventory: Some(Inventory(
            quantity: 50,
            sku: "ART-KIT-001",
            low_stock_threshold: 10,
            track_quantity: True,
            allow_backorder: False,
          )),
          availability: [],
          features: [
            Feature(
              name: "Professional Brushes",
              category: "Tools",
              description: "Set of 12 professional-grade brushes",
              included: True,
              extra_cost: None,
            ),
            Feature(
              name: "Acrylic Paints",
              category: "Materials",
              description: "24 colors of premium acrylic paint",
              included: True,
              extra_cost: None,
            ),
          ],
          location: Location(
            address: "456 Creator Ave",
            city: "Portland",
            state: "OR",
            postal_code: "97202",
            country: "USA",
            coordinates: Some(#(45.515, -122.658)),
            accessibility: [],
            parking: [],
            public_transport: [],
          ),
          owner_persona_id: 2,
          media: [
            Media(
              url: "/images/art-kit.jpg",
              type_: "image",
              title: "Art Supplies Kit",
              description: "Complete professional art supplies kit",
              is_featured: True,
            ),
          ],
          status: ItemAvailable,
          shipping_options: [
            ShippingOption(
              name: "Standard Shipping",
              price: 9.99,
              estimated_days: 5,
              carrier: "USPS",
              tracking_available: True,
            ),
            ShippingOption(
              name: "Express Shipping",
              price: 24.99,
              estimated_days: 2,
              carrier: "FedEx",
              tracking_available: True,
            ),
          ],
          variants: [
            ProductVariant(
              id: 1,
              name: "Starter Kit",
              sku: "ART-KIT-001-S",
              price: 159.99,
              inventory: Inventory(
                quantity: 30,
                sku: "ART-KIT-001-S",
                low_stock_threshold: 5,
                track_quantity: True,
                allow_backorder: False,
              ),
              attributes: dict.from_list([
                #("size", "Starter"),
                #("pieces", "24"),
              ]),
            ),
            ProductVariant(
              id: 2,
              name: "Professional Kit",
              sku: "ART-KIT-001-P",
              price: 199.99,
              inventory: Inventory(
                quantity: 20,
                sku: "ART-KIT-001-P",
                low_stock_threshold: 5,
                track_quantity: True,
                allow_backorder: False,
              ),
              attributes: dict.from_list([
                #("size", "Professional"),
                #("pieces", "36"),
              ]),
            ),
          ],
          reviews: [
            Review(
              id: 1,
              author_persona_id: 1,
              rating: 5,
              comment: "Excellent quality supplies, perfect for both beginners and professionals",
              created_at: "2024-03-20",
              verified_purchase: True,
            ),
          ],
          tags: ["art supplies", "professional", "starter kit"],
        ),
      ),
    ]
    |> dict.from_list()

  #(
    Model(
      contracts: sample_contracts,
      last_id: 3,
      nav_open: False,
      selected_contract: None,
      view_mode: ViewList,
      templates: templates,
      show_templates: False,
      marketplace_items: sample_marketplace_items,
      selected_item: None,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserClickedAcceptContract(id) -> {
      let contracts = case dict.get(model.contracts, id) {
        Ok(contract) ->
          dict.insert(
            model.contracts,
            id,
            Contract(..contract, status: ContractActive),
          )
        Error(_) -> model.contracts
      }
      #(Model(..model, contracts: contracts), effect.none())
    }

    UserClickedRejectContract(id) -> {
      let contracts = case dict.get(model.contracts, id) {
        Ok(contract) ->
          dict.insert(
            model.contracts,
            id,
            Contract(..contract, status: ContractDisputed),
          )
        Error(_) -> model.contracts
      }
      #(Model(..model, contracts: contracts), effect.none())
    }

    UserSelectedContract(id) -> {
      #(
        Model(..model, selected_contract: Some(id), view_mode: ViewDetail),
        effect.none(),
      )
    }

    UserClickedBack -> {
      #(
        Model(..model, selected_contract: None, view_mode: ViewList),
        effect.none(),
      )
    }

    UserClickedNewContract -> {
      #(Model(..model, view_mode: ViewTemplates), effect.none())
    }

    UserSelectedTemplate(_template_id) -> {
      // TODO: Implement template selection and contract creation
      #(Model(..model, view_mode: ViewList), effect.none())
    }

    UserSelectedItem(id) -> {
      #(
        Model(..model, selected_item: Some(id), view_mode: ViewItemDetail),
        effect.none(),
      )
    }

    UserClickedBookItem(id) -> {
      // TODO: Implement booking logic
      #(model, effect.none())
    }

    UserClickedAddToCart(id) -> {
      // TODO: Implement add to cart logic
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
  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [
      element.map(nav.view(), NavMsg),
      html.main([attribute.class("contracts-app")], case model.view_mode {
        ViewList -> [
          html.header([attribute.class("app-header")], [
            html.h1([], [html.text("Multiparty Contracts")]),
            html.p([attribute.class("header-subtitle")], [
              html.text("Manage loan agreements and income share contracts"),
            ]),
            html.div([attribute.class("header-actions")], [
              html.button(
                [
                  attribute.class("btn-primary"),
                  event.on_click(UserClickedNewContract),
                ],
                [html.text("New Contract")],
              ),
            ]),
          ]),
          view_summary_stats(model.contracts),
          view_contracts(model.contracts),
        ]
        ViewDetail ->
          case model.selected_contract {
            Some(id) ->
              case dict.get(model.contracts, id) {
                Ok(contract) -> [view_contract_detail(contract)]
                Error(_) -> [html.text("Contract not found")]
              }
            None -> [html.text("No contract selected")]
          }
        ViewTemplates -> [view_templates(model.templates)]
        ViewMarketplace -> [view_marketplace(model.marketplace_items)]
        ViewItemDetail -> [
          view_item_detail(model.selected_item, model.marketplace_items),
        ]
      }),
    ],
  )
}

fn view_summary_stats(contracts: Dict(Int, Contract)) -> Element(Msg) {
  let total_active =
    dict.values(contracts)
    |> list.filter(fn(contract) { contract.status == ContractActive })
    |> list.length()

  let total_pending =
    dict.values(contracts)
    |> list.filter(fn(contract) { contract.status == ContractPending })
    |> list.length()

  let total_amount =
    dict.values(contracts)
    |> list.fold(0.0, fn(acc, contract) { acc +. contract.amount })

  html.div([attribute.class("summary-stats")], [
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Active Contracts")]),
      html.span([attribute.class("stat-value")], [
        html.text(int.to_string(total_active)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [
        html.text("Pending Contracts"),
      ]),
      html.span([attribute.class("stat-value")], [
        html.text(int.to_string(total_pending)),
      ]),
    ]),
    html.div([attribute.class("stat-card")], [
      html.span([attribute.class("stat-label")], [html.text("Total Value")]),
      html.span([attribute.class("stat-value")], [
        html.text("$" <> float.to_string(total_amount)),
      ]),
    ]),
  ])
}

fn view_contracts(contracts: Dict(Int, Contract)) -> Element(Msg) {
  html.div(
    [attribute.class("contracts-grid")],
    dict.values(contracts)
      |> list.map(view_contract),
  )
}

fn view_party(party: Party) -> Element(Msg) {
  html.div([attribute.class("party-item")], [
    html.div([attribute.class("party-info")], [
      html.span([attribute.class("party-name")], [html.text(party.name)]),
      html.span([attribute.class("party-role")], [html.text(party.role)]),
    ]),
    html.span(
      [attribute.class("party-status " <> party_status_class(party.status))],
      [html.text(party_status_text(party.status))],
    ),
  ])
}

fn view_contract(contract: Contract) -> Element(Msg) {
  html.div([attribute.class("contract-card")], [
    html.div([attribute.class("contract-header")], [
      html.h3([attribute.class("contract-title")], [html.text(contract.title)]),
      html.div([attribute.class("contract-meta")], [
        html.span([attribute.class("contract-amount")], [
          html.text("$" <> float.to_string(contract.amount)),
        ]),
        html.span(
          [attribute.class("contract-status " <> status_class(contract.status))],
          [html.text(status_text(contract.status))],
        ),
      ]),
    ]),
    html.div([attribute.class("contract-parties")], [
      html.h4([], [html.text("Parties")]),
      html.div(
        [attribute.class("party-list")],
        list.map(contract.parties, view_party),
      ),
    ]),
    html.div([attribute.class("contract-footer")], [
      html.div([attribute.class("contract-date")], [
        html.text("Created: " <> contract.created_at),
      ]),
      html.div([attribute.class("contract-actions")], [
        html.button(
          [
            attribute.class("btn-secondary"),
            event.on_click(UserSelectedContract(contract.id)),
          ],
          [html.text("View Details")],
        ),
        case contract.status {
          ContractPending ->
            html.div([attribute.class("action-group")], [
              html.button(
                [
                  attribute.class("btn-success"),
                  event.on_click(UserClickedAcceptContract(contract.id)),
                ],
                [html.text("Accept")],
              ),
              html.button(
                [
                  attribute.class("btn-danger"),
                  event.on_click(UserClickedRejectContract(contract.id)),
                ],
                [html.text("Reject")],
              ),
            ])
          _ -> html.text("")
        },
      ]),
    ]),
  ])
}

fn view_contract_detail(contract: Contract) -> Element(Msg) {
  html.div([attribute.class("contract-detail")], [
    html.div([attribute.class("detail-header")], [
      html.button(
        [attribute.class("btn-back"), event.on_click(UserClickedBack)],
        [html.text("← Back to Contracts")],
      ),
      html.h2([], [html.text(contract.title)]),
      html.div([attribute.class("contract-meta")], [
        html.span([attribute.class("contract-amount")], [
          html.text("$" <> float.to_string(contract.amount)),
        ]),
        html.span(
          [attribute.class("contract-status " <> status_class(contract.status))],
          [html.text(status_text(contract.status))],
        ),
      ]),
    ]),
    html.div([attribute.class("detail-content")], [
      // Risk and Performance Section
      html.div([attribute.class("detail-section metrics-overview")], [
        html.h3([], [html.text("Contract Overview")]),
        html.div([attribute.class("metrics-grid")], [
          html.div([attribute.class("metric-card")], [
            html.span([attribute.class("metric-label")], [
              html.text("Risk Score"),
            ]),
            html.div([attribute.class("metric-value risk-score")], [
              html.text(int.to_string(contract.metadata.risk_score)),
            ]),
          ]),
          html.div([attribute.class("metric-card")], [
            html.span([attribute.class("metric-label")], [
              html.text("Collaboration Score"),
            ]),
            html.div([attribute.class("metric-value")], [
              html.text(int.to_string(
                contract.metadata.performance_metrics.collaboration_score,
              )),
            ]),
          ]),
          html.div([attribute.class("metric-card")], [
            html.span([attribute.class("metric-label")], [
              html.text("Payment Reliability"),
            ]),
            html.div([attribute.class("metric-value")], [
              html.text(
                float.to_string(
                  contract.metadata.performance_metrics.payment_reliability
                  *. 100.0,
                )
                <> "%",
              ),
            ]),
          ]),
        ]),
        html.div([attribute.class("tags-container")], [
          html.span([attribute.class("tag-label")], [html.text("Categories:")]),
          ..list.map(contract.metadata.tags, fn(tag) {
            html.span([attribute.class("contract-tag")], [html.text(tag)])
          })
        ]),
      ]),
      // Parties Section with Enhanced Persona Info
      html.div([attribute.class("detail-section")], [
        html.h3([], [html.text("Parties")]),
        html.div(
          [attribute.class("party-grid")],
          list.map(contract.parties, view_party_detail_enhanced),
        ),
      ]),
      // Related Works Section
      html.div([attribute.class("detail-section")], [
        html.h3([], [html.text("Related Works")]),
        case list.length(contract.related_works) {
          0 ->
            html.div([attribute.class("no-works")], [
              html.text("No related works found"),
            ])
          _ ->
            html.div(
              [attribute.class("related-works-grid")],
              list.map(contract.related_works, fn(work_id) {
                html.div([attribute.class("related-work-card")], [
                  html.span([attribute.class("work-id")], [
                    html.text("Work #" <> int.to_string(work_id)),
                  ]),
                  // TODO: Add more work details when available
                ])
              }),
            )
        },
      ]),
      // Terms Section
      html.div([attribute.class("detail-section")], [
        html.h3([], [html.text("Terms")]),
        html.div([attribute.class("terms-content")], [
          html.pre([], [html.text(contract.terms)]),
        ]),
      ]),
      // Documents Section with Enhanced UI
      html.div([attribute.class("detail-section")], [
        html.h3([], [html.text("Documents & Attachments")]),
        html.div([attribute.class("document-section")], [
          html.div([attribute.class("document-upload")], [
            html.div([attribute.class("upload-placeholder")], [
              html.i([attribute.class("upload-icon")], []),
              html.div([attribute.class("upload-text")], [
                html.strong([], [html.text("Upload Documents")]),
                html.p([], [
                  html.text("Drag and drop files here or click to upload"),
                ]),
              ]),
            ]),
          ]),
          html.div([attribute.class("document-categories")], [
            html.div([attribute.class("document-category")], [
              html.h4([], [html.text("Contract Documents")]),
              html.div([attribute.class("document-list")], [
                view_document("contract_draft.pdf", "Mar 20, 2024"),
                view_document("terms_signed.pdf", "Mar 21, 2024"),
              ]),
            ]),
            html.div([attribute.class("document-category")], [
              html.h4([], [html.text("Supporting Documents")]),
              html.div([attribute.class("document-list")], [
                view_document("financial_statement.pdf", "Mar 19, 2024"),
              ]),
            ]),
          ]),
        ]),
      ]),
      // Activity Timeline
      html.div([attribute.class("detail-section")], [
        html.h3([], [html.text("Activity Timeline")]),
        html.div(
          [attribute.class("activity-timeline")],
          list.map(contract.activity_log, fn(activity) {
            html.div([attribute.class("activity-item")], [
              html.div([attribute.class("activity-content")], [
                html.span([attribute.class("activity-action")], [
                  html.text(activity.action),
                ]),
                html.p([attribute.class("activity-details")], [
                  html.text(activity.details),
                ]),
              ]),
              html.span([attribute.class("activity-date")], [
                html.text(activity.timestamp),
              ]),
            ])
          }),
        ),
      ]),
      // Findry Integration Section
      html.div([attribute.class("detail-section findry-integration")], [
        html.h3([], [html.text("Artist/Offerer Profiles")]),
        html.div([attribute.class("findry-profiles")], [
          html.div([attribute.class("findry-connection")], [
            html.p([attribute.class("findry-info")], [
              html.text(
                "Connect with verified artists and service providers from Findry",
              ),
            ]),
            html.button([attribute.class("btn-secondary")], [
              html.text("Link Findry Profile"),
            ]),
          ]),
          html.div([attribute.class("suggested-profiles")], [
            html.h4([], [html.text("Suggested Matches")]),
            html.div([attribute.class("profile-grid")], [
              // Placeholder for Findry profile matches
              html.div([attribute.class("profile-card")], [
                html.div([attribute.class("profile-header")], [
                  html.h5([], [html.text("Creative Studio X")]),
                  html.span([attribute.class("profile-type")], [
                    html.text("Digital Art Studio"),
                  ]),
                ]),
                html.div([attribute.class("profile-stats")], [
                  html.span([], [html.text("Rating: 4.8/5")]),
                  html.span([], [html.text("Projects: 124")]),
                ]),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]),
  ])
}

fn view_party_detail_enhanced(party: Party) -> Element(Msg) {
  html.div([attribute.class("party-detail-card")], [
    html.div([attribute.class("party-header")], [
      html.h4([attribute.class("party-name")], [html.text(party.name)]),
      html.span([attribute.class("party-role")], [html.text(party.role)]),
    ]),
    case party.persona_id {
      Some(id) ->
        html.div([attribute.class("persona-details")], [
          html.div([attribute.class("verification-section")], [
            case party.verification_level {
              Some(level) ->
                html.span(
                  [
                    attribute.class(
                      "verification-badge " <> verification_level_class(level),
                    ),
                  ],
                  [html.text(verification_level_text(level))],
                )
              None -> html.text("")
            },
          ]),
          case party.trust_score {
            Some(score) ->
              html.div([attribute.class("trust-score")], [
                html.span([attribute.class("score-label")], [
                  html.text("Trust Score: "),
                ]),
                html.span([attribute.class("score-value")], [
                  html.text(int.to_string(score)),
                ]),
              ])
            None -> html.text("")
          },
        ])
      None ->
        html.div([attribute.class("no-persona")], [
          html.button([attribute.class("btn-link")], [
            html.text("Link to Persona"),
          ]),
        ])
    },
    html.div([attribute.class("party-status-section")], [
      html.span(
        [attribute.class("party-status " <> party_status_class(party.status))],
        [html.text(party_status_text(party.status))],
      ),
    ]),
  ])
}

fn view_document(name: String, date: String) -> Element(Msg) {
  html.div([attribute.class("document-item")], [
    html.div([attribute.class("document-info")], [
      html.span([attribute.class("document-name")], [html.text(name)]),
      html.span([attribute.class("document-date")], [
        html.text("Uploaded: " <> date),
      ]),
    ]),
    html.div([attribute.class("document-actions")], [
      html.button([attribute.class("btn-icon")], [html.text("View")]),
      html.button([attribute.class("btn-icon")], [html.text("Download")]),
    ]),
  ])
}

fn verification_level_class(level: VerificationLevel) -> String {
  case level {
    Verified -> "level-verified"
    Institution -> "level-institution"
    Premium -> "level-premium"
  }
}

fn verification_level_text(level: VerificationLevel) -> String {
  case level {
    Verified -> "Verified"
    Institution -> "Institution"
    Premium -> "Premium"
  }
}

fn status_class(status: ContractStatus) -> String {
  case status {
    ContractDraft -> "status-draft"
    ContractPending -> "status-pending"
    ContractActive -> "status-active"
    ContractCompleted -> "status-completed"
    ContractDisputed -> "status-disputed"
  }
}

fn status_text(status: ContractStatus) -> String {
  case status {
    ContractDraft -> "Draft"
    ContractPending -> "Pending"
    ContractActive -> "Active"
    ContractCompleted -> "Completed"
    ContractDisputed -> "Disputed"
  }
}

fn party_status_class(status: PartyStatus) -> String {
  case status {
    PartyPending -> "status-pending"
    PartyAccepted -> "status-accepted"
    PartyRejected -> "status-rejected"
  }
}

fn party_status_text(status: PartyStatus) -> String {
  case status {
    PartyPending -> "Pending"
    PartyAccepted -> "Accepted"
    PartyRejected -> "Rejected"
  }
}

fn view_templates(templates: List(ContractTemplate)) -> Element(Msg) {
  html.div([attribute.class("templates-view")], [
    html.div([attribute.class("templates-header")], [
      html.button(
        [attribute.class("btn-back"), event.on_click(UserClickedBack)],
        [html.text("← Back to Contracts")],
      ),
      html.h2([], [html.text("Contract Templates")]),
      html.p([attribute.class("header-subtitle")], [
        html.text("Select a template to create a new contract"),
      ]),
    ]),
    html.div(
      [attribute.class("templates-grid")],
      list.map(templates, view_template),
    ),
  ])
}

fn view_template(template: ContractTemplate) -> Element(Msg) {
  html.div([attribute.class("template-card")], [
    html.div([attribute.class("template-header")], [
      html.span([attribute.class("template-category")], [
        html.text(template.category),
      ]),
      html.h3([attribute.class("template-title")], [html.text(template.title)]),
      html.p([attribute.class("template-description")], [
        html.text(template.description),
      ]),
    ]),
    html.div([attribute.class("template-details")], [
      html.div([attribute.class("template-parties")], [
        html.h4([], [html.text("Required Parties")]),
        html.ul(
          [],
          list.map(template.required_parties, fn(party) {
            html.li([], [
              html.strong([], [html.text(party.role <> ": ")]),
              html.text(party.description),
            ])
          }),
        ),
      ]),
    ]),
    html.div([attribute.class("template-actions")], [
      html.button(
        [
          attribute.class("btn-primary"),
          event.on_click(UserSelectedTemplate(template.id)),
        ],
        [html.text("Use Template")],
      ),
    ]),
  ])
}

fn view_marketplace(items: Dict(Int, MarketplaceItem)) -> Element(Msg) {
  html.div([attribute.class("marketplace-view")], [
    html.div([attribute.class("marketplace-header")], [
      html.button(
        [attribute.class("btn-back"), event.on_click(UserClickedBack)],
        [html.text("← Back to Contracts")],
      ),
      html.h2([], [html.text("Marketplace Items")]),
      html.p([attribute.class("header-subtitle")], [
        html.text("Manage marketplace items"),
      ]),
    ]),
    html.div(
      [attribute.class("marketplace-grid")],
      dict.values(items)
        |> list.map(view_marketplace_item),
    ),
  ])
}

fn view_marketplace_item(item: MarketplaceItem) -> Element(Msg) {
  html.div([attribute.class("marketplace-item")], [
    html.div([attribute.class("item-header")], [
      html.h3([attribute.class("item-title")], [html.text(item.title)]),
      html.div([attribute.class("item-meta")], [
        case item.item_type {
          Product -> {
            html.div([attribute.class("product-pricing")], [
              case item.sale_price {
                Some(sale_price) -> {
                  html.div([attribute.class("price-container")], [
                    html.span([attribute.class("original-price")], [
                      html.text(
                        "$" <> float.to_string(option.unwrap(item.price, 0.0)),
                      ),
                    ]),
                    html.span([attribute.class("sale-price")], [
                      html.text("$" <> float.to_string(sale_price)),
                    ]),
                  ])
                }
                None -> {
                  html.span([attribute.class("item-price")], [
                    html.text(
                      "$" <> float.to_string(option.unwrap(item.price, 0.0)),
                    ),
                  ])
                }
              },
            ])
          }
          Service -> {
            html.div([attribute.class("service-pricing")], [
              case item.price_per_hour {
                Some(hourly) -> {
                  html.span([attribute.class("price-rate")], [
                    html.text("$" <> float.to_string(hourly) <> "/hour"),
                  ])
                }
                None -> html.text("")
              },
              case item.price_per_day {
                Some(daily) -> {
                  html.span([attribute.class("price-rate")], [
                    html.text(" · $" <> float.to_string(daily) <> "/day"),
                  ])
                }
                None -> html.text("")
              },
            ])
          }
        },
        html.span([attribute.class("item-status")], [
          html.text(item_status_text(item.status)),
        ]),
      ]),
    ]),
    html.div([attribute.class("item-details")], [
      html.p([], [html.text(item.description)]),
      case item.item_type {
        Product -> {
          html.div([attribute.class("product-details")], [
            case item.inventory {
              Some(inv) -> {
                html.div([attribute.class("inventory-status")], [
                  html.span([attribute.class("stock-level")], [
                    html.text(case inv.quantity {
                      0 -> "Out of stock"
                      qty -> {
                        case qty <= inv.low_stock_threshold {
                          True -> "Low stock"
                          False -> "In stock"
                        }
                      }
                    }),
                  ]),
                  html.span([attribute.class("sku")], [
                    html.text("SKU: " <> inv.sku),
                  ]),
                ])
              }
              None -> html.text("")
            },
            case list.length(item.variants) {
              0 -> html.text("")
              _ -> {
                html.div([attribute.class("variants-preview")], [
                  html.span([attribute.class("variants-label")], [
                    html.text(
                      int.to_string(list.length(item.variants))
                      <> " variants available",
                    ),
                  ]),
                ])
              }
            },
            case list.length(item.reviews) {
              0 -> html.text("")
              n -> {
                html.div([attribute.class("reviews-preview")], [
                  html.span([attribute.class("review-count")], [
                    html.text(int.to_string(n) <> " reviews"),
                  ]),
                ])
              }
            },
          ])
        }
        Service -> {
          html.div([attribute.class("service-details")], [
            html.div([attribute.class("availability-preview")], [
              html.span([attribute.class("availability-label")], [
                html.text("Next available: "),
              ]),
              case
                list.find(item.availability, fn(slot) { slot.is_available })
              {
                Ok(slot) -> {
                  html.span([attribute.class("next-slot")], [
                    html.text(slot.start_time),
                  ])
                }
                Error(_) -> {
                  html.span([attribute.class("no-slots")], [
                    html.text("No available slots"),
                  ])
                }
              },
            ]),
          ])
        }
      },
      html.div([attribute.class("item-features")], [
        html.h4([], [html.text("Features")]),
        html.ul(
          [],
          list.map(item.features, fn(feature) {
            html.li([], [
              html.strong([], [html.text(feature.name <> ": ")]),
              html.text(feature.description),
            ])
          }),
        ),
      ]),
    ]),
    html.div([attribute.class("item-actions")], [
      html.button(
        [
          attribute.class("btn-secondary"),
          event.on_click(UserSelectedItem(item.id)),
        ],
        [html.text("View Details")],
      ),
      case item.item_type {
        Product -> {
          html.button(
            [
              attribute.class("btn-primary"),
              event.on_click(UserClickedAddToCart(item.id)),
            ],
            [html.text("Add to Cart")],
          )
        }
        Service -> {
          html.button(
            [
              attribute.class("btn-primary"),
              event.on_click(UserClickedBookItem(item.id)),
            ],
            [html.text("Book Now")],
          )
        }
      },
    ]),
  ])
}

fn view_item_detail(
  maybe_item_id: Option(Int),
  items: Dict(Int, MarketplaceItem),
) -> Element(Msg) {
  case maybe_item_id {
    None -> html.text("Item not found")
    Some(id) ->
      case dict.get(items, id) {
        Ok(item) ->
          html.div([attribute.class("item-detail")], [
            html.div([attribute.class("detail-header")], [
              html.button(
                [attribute.class("btn-back"), event.on_click(UserClickedBack)],
                [html.text("← Back to Marketplace")],
              ),
              html.h2([], [html.text(item.title)]),
            ]),
            html.div([attribute.class("detail-content")], [
              html.div([attribute.class("detail-section")], [
                html.h3([], [html.text("Item Details")]),
                html.div([attribute.class("item-details")], [
                  html.p([], [html.text(item.description)]),
                  html.div([attribute.class("item-features")], [
                    html.h4([], [html.text("Features")]),
                    html.ul(
                      [],
                      list.map(item.features, fn(feature) {
                        html.li([], [
                          html.strong([], [html.text(feature.name <> ": ")]),
                          html.text(feature.description),
                        ])
                      }),
                    ),
                  ]),
                ]),
              ]),
              html.div([attribute.class("detail-section")], [
                html.h3([], [html.text("Availability")]),
                html.div([attribute.class("availability-grid")], [
                  html.div([attribute.class("availability-item")], [
                    html.span([attribute.class("availability-label")], [
                      html.text("Available"),
                    ]),
                    html.span([attribute.class("availability-value")], [
                      html.text(item_status_text(item.status)),
                    ]),
                  ]),
                  html.div([attribute.class("availability-item")], [
                    html.span([attribute.class("availability-label")], [
                      html.text("Location"),
                    ]),
                    html.span([attribute.class("availability-value")], [
                      html.text(
                        item.location.address
                        <> ", "
                        <> item.location.city
                        <> ", "
                        <> item.location.state,
                      ),
                    ]),
                  ]),
                ]),
              ]),
              html.div([attribute.class("detail-section")], [
                html.h3([], [html.text("Documents & Attachments")]),
                html.div([attribute.class("document-section")], [
                  html.div([attribute.class("document-upload")], [
                    html.div([attribute.class("upload-placeholder")], [
                      html.i([attribute.class("upload-icon")], []),
                      html.div([attribute.class("upload-text")], [
                        html.strong([], [html.text("Upload Documents")]),
                        html.p([], [
                          html.text(
                            "Drag and drop files here or click to upload",
                          ),
                        ]),
                      ]),
                    ]),
                  ]),
                ]),
              ]),
            ]),
          ])
        Error(_) -> html.text("Item not found")
      }
  }
}

fn item_status_text(status: ItemStatus) -> String {
  case status {
    ItemAvailable -> "Available"
    ItemBooked -> "Booked"
    ItemMaintenance -> "Maintenance"
    ItemUnavailable -> "Unavailable"
  }
}
