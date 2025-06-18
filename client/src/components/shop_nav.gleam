import access_content.{
  type FetchState, type SupabaseUser, Errored, Idle, Loaded, Loading,
}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute.{class, id, placeholder, type_}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- Types ---

pub type MegamenuIdentifier {
  PartsMegamenu
  ServiceMegamenu
  BikesMegamenu
  AccessoriesMegamenu
  CustomMegamenu
}

pub type Model {
  Model(
    user_state: FetchState(Option(SupabaseUser)),
    open_megamenu: Option(MegamenuIdentifier),
    cart_count: Int,
  )
}

pub type Msg {
  ToggleMegamenu(MegamenuIdentifier)
  CloseAllMegamenus
  ParentShouldNavigate(String)
  ParentShouldLogin
  ParentShouldLogout
  ViewCart
  SearchTriggered(String)
}

// --- Init ---

pub fn init(user_state: FetchState(Option(SupabaseUser))) -> Model {
  Model(user_state: user_state, open_megamenu: None, cart_count: 0)
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ToggleMegamenu(identifier) -> {
      let new_open_megamenu = case model.open_megamenu {
        Some(currently_open) if currently_open == identifier -> None
        _ -> Some(identifier)
      }
      #(Model(..model, open_megamenu: new_open_megamenu), effect.none())
    }
    CloseAllMegamenus -> {
      #(Model(..model, open_megamenu: None), effect.none())
    }
    ParentShouldNavigate(_path) -> {
      #(Model(..model, open_megamenu: None), effect.none())
    }
    ParentShouldLogin -> {
      #(model, effect.none())
    }
    ParentShouldLogout -> {
      #(model, effect.none())
    }
    ViewCart -> {
      #(Model(..model, open_megamenu: None), effect.none())
    }
    SearchTriggered(_query) -> {
      #(model, effect.none())
    }
  }
}

// --- View ---

fn nav_link_item(href_val: String, text_val: String) -> Element(Msg) {
  html.a([
    class("nav-link-item"),
    event.on_click(ParentShouldNavigate(href_val))
  ], [html.text(text_val)])
}

fn view_megamenu_panel(
  identifier: MegamenuIdentifier,
  model: Model,
) -> Element(Msg) {
  let is_open = case model.open_megamenu {
    Some(open_id) -> open_id == identifier
    None -> False
  }

  let base_classes = "megamenu-panel"
  let open_class = case is_open {
    True -> " open"
    False -> ""
  }

  html.div(
    [class(base_classes <> open_class), id(megamenu_id_string(identifier))],
    case identifier {
      PartsMegamenu -> [
        view_megamenu_column("Engine", [
          nav_link_item("/shop/parts/engine/filters", "Air & Oil Filters"),
          nav_link_item("/shop/parts/engine/spark-plugs", "Spark Plugs"),
          nav_link_item("/shop/parts/engine/gaskets", "Gaskets & Seals"),
          nav_link_item("/shop/parts/engine/pistons", "Pistons & Rings"),
        ]),
        view_megamenu_column("Drivetrain", [
          nav_link_item("/shop/parts/drivetrain/chains", "Chains & Sprockets"),
          nav_link_item("/shop/parts/drivetrain/belts", "Drive Belts"),
          nav_link_item("/shop/parts/drivetrain/clutch", "Clutch Components"),
          nav_link_item("/shop/parts/drivetrain/transmission", "Transmission"),
        ]),
        view_megamenu_column("Brakes & Suspension", [
          nav_link_item("/shop/parts/brakes/pads", "Brake Pads"),
          nav_link_item("/shop/parts/brakes/rotors", "Brake Rotors"),
          nav_link_item("/shop/parts/suspension/shocks", "Shocks & Struts"),
          nav_link_item("/shop/parts/suspension/springs", "Springs"),
        ]),
        view_megamenu_column("Electrical", [
          nav_link_item("/shop/parts/electrical/batteries", "Batteries"),
          nav_link_item("/shop/parts/electrical/lighting", "Lighting"),
          nav_link_item("/shop/parts/electrical/ignition", "Ignition System"),
          nav_link_item("/shop/parts/electrical/wiring", "Wiring & Connectors"),
        ]),
      ]
      ServiceMegamenu -> [
        view_megamenu_column("Maintenance", [
          nav_link_item("/services/maintenance/oil-change", "Oil Change"),
          nav_link_item("/services/maintenance/tune-up", "Tune-Up Service"),
          nav_link_item("/services/maintenance/inspection", "Safety Inspection"),
          nav_link_item("/services/maintenance/winterization", "Winterization"),
        ]),
        view_megamenu_column("Repairs", [
          nav_link_item("/services/repairs/engine", "Engine Repair"),
          nav_link_item("/services/repairs/transmission", "Transmission Work"),
          nav_link_item("/services/repairs/electrical", "Electrical Diagnosis"),
          nav_link_item("/services/repairs/bodywork", "Body & Paint"),
        ]),
        view_megamenu_column("Custom Work", [
          nav_link_item("/services/custom/performance", "Performance Upgrades"),
          nav_link_item("/services/custom/fabrication", "Custom Fabrication"),
          nav_link_item("/services/custom/restoration", "Restoration"),
          nav_link_item("/services/custom/quote", "Get Custom Quote"),
        ]),
      ]
      BikesMegamenu -> [
        view_megamenu_column("New Motorcycles", [
          nav_link_item("/shop/bikes/new/sport", "Sport Bikes"),
          nav_link_item("/shop/bikes/new/cruiser", "Cruisers"),
          nav_link_item("/shop/bikes/new/touring", "Touring"),
          nav_link_item("/shop/bikes/new/adventure", "Adventure"),
        ]),
        view_megamenu_column("Used Motorcycles", [
          nav_link_item("/shop/bikes/used/sport", "Used Sport Bikes"),
          nav_link_item("/shop/bikes/used/cruiser", "Used Cruisers"),
          nav_link_item("/shop/bikes/used/vintage", "Vintage & Classic"),
          nav_link_item("/shop/bikes/used/project", "Project Bikes"),
        ]),
        view_megamenu_column("Services", [
          nav_link_item("/services/financing", "Financing"),
          nav_link_item("/services/trade-in", "Trade-In Value"),
          nav_link_item("/services/delivery", "Delivery Service"),
        ]),
      ]
      AccessoriesMegamenu -> [
        view_megamenu_column("Riding Gear", [
          nav_link_item("/shop/gear/helmets", "Helmets"),
          nav_link_item("/shop/gear/jackets", "Jackets & Vests"),
          nav_link_item("/shop/gear/gloves", "Gloves"),
          nav_link_item("/shop/gear/boots", "Boots"),
        ]),
        view_megamenu_column("Bike Accessories", [
          nav_link_item("/shop/accessories/luggage", "Luggage & Bags"),
          nav_link_item("/shop/accessories/windshields", "Windshields"),
          nav_link_item("/shop/accessories/mirrors", "Mirrors"),
          nav_link_item("/shop/accessories/grips", "Grips & Controls"),
        ]),
        view_megamenu_column("Maintenance", [
          nav_link_item("/shop/accessories/tools", "Tools & Equipment"),
          nav_link_item("/shop/accessories/chemicals", "Oils & Chemicals"),
          nav_link_item("/shop/accessories/covers", "Bike Covers"),
          nav_link_item("/shop/accessories/stands", "Stands & Lifts"),
        ]),
      ]
      CustomMegamenu -> [
        view_megamenu_column("Custom Builds", [
          nav_link_item("/custom/builds/cafe-racer", "Cafe Racer"),
          nav_link_item("/custom/builds/bobber", "Bobber"),
          nav_link_item("/custom/builds/chopper", "Chopper"),
          nav_link_item("/custom/builds/tracker", "Tracker"),
        ]),
        view_megamenu_column("Performance", [
          nav_link_item("/custom/performance/exhaust", "Exhaust Systems"),
          nav_link_item("/custom/performance/tuning", "ECU Tuning"),
          nav_link_item("/custom/performance/suspension", "Suspension Setup"),
          nav_link_item("/custom/performance/engine", "Engine Mods"),
        ]),
        view_megamenu_column("Get Started", [
          nav_link_item("/custom/consultation", "Free Consultation"),
          nav_link_item("/custom/quote", "Get Quote"),
          nav_link_item("/custom/gallery", "Our Work Gallery"),
          nav_link_item("/custom/process", "Build Process"),
        ]),
      ]
    },
  )
}

fn megamenu_id_string(identifier: MegamenuIdentifier) -> String {
  case identifier {
    PartsMegamenu -> "megamenu-parts"
    ServiceMegamenu -> "megamenu-service"
    BikesMegamenu -> "megamenu-bikes"
    AccessoriesMegamenu -> "megamenu-accessories"
    CustomMegamenu -> "megamenu-custom"
  }
}

fn view_megamenu_column(
  title: String,
  items: List(Element(Msg)),
) -> Element(Msg) {
  html.div([class("megamenu-column")], [
    html.h4([class("megamenu-column-title")], [html.text(title)]),
    html.ul([class("megamenu-column-list")], 
      list.map(items, fn(item) { html.li([class("megamenu-item")], [item]) })
    ),
  ])
}

fn view_search_bar() -> Element(Msg) {
  html.div([class("search-container")], [
    html.input([
      type_("search"),
      placeholder("Search parts, bikes, accessories..."),
      class("search-input"),
      id("shop-search")
    ]),
    html.button([
      class("search-btn"),
      event.on_click(SearchTriggered(""))
    ], [
      html.i([class("search-icon")], [html.text("🔍")])
    ])
  ])
}

fn view_cart_icon(model: Model) -> Element(Msg) {
  html.button([
    class("cart-btn"),
    event.on_click(ViewCart)
  ], [
    html.i([class("cart-icon")], [html.text("🛒")]),
    case model.cart_count > 0 {
      True -> html.span([class("cart-badge")], [html.text(int.to_string(model.cart_count))])
      False -> html.text("")
    }
  ])
}

pub fn view(model: Model) -> Element(Msg) {
  html.nav([class("shop-navbar")], [
    // Top bar with contact info and user actions
    html.div([class("navbar-top")], [
      html.div([class("nav-content")], [
        html.div([class("contact-info")], [
          html.span([class("phone")], [html.text("📞 (555) 123-BIKE")]),
          html.span([class("hours")], [html.text("🕒 Mon-Sat 8AM-6PM")]),
        ]),
        html.div([class("user-actions")], [
          case model.user_state {
            Loaded(Some(user)) -> html.div([class("user-menu")], [
              html.span([class("welcome")], [html.text("Welcome, " <> case user.email {
                Some(email) -> email
                None -> "User"
              })]),
              html.button([
                class("nav-btn logout"),
                event.on_click(ParentShouldLogout)
              ], [html.text("Logout")])
            ])
            Loaded(None) | Idle | Errored(_) -> html.button([
              class("nav-btn login"),
              event.on_click(ParentShouldLogin)
            ], [html.text("Login")])
            Loading -> html.span([class("nav-loading")], [html.text("...")])
          }
        ])
      ])
    ]),
    
    // Main navigation
    html.div([class("navbar-main")], [
      html.div([class("nav-content")], [
        // Logo
        html.a([
          class("shop-logo"),
          event.on_click(ParentShouldNavigate("/"))
        ], [
          html.div([class("logo-content")], [
            html.i([class("bike-icon")], [html.text("🏍️")]),
            html.div([class("logo-text")], [
              html.div([class("shop-name")], [html.text("TandemX Moto")]),
              html.div([class("shop-tagline")], [html.text("Performance & Custom")]),
            ])
          ])
        ]),
        
        // Search bar
        view_search_bar(),
        
        // Main navigation links with megamenus
        html.div([class("nav-links")], [
          html.div([class("nav-item has-megamenu")], [
            html.a([
              class("nav-link"),
              event.on_click(ToggleMegamenu(PartsMegamenu))
            ], [
              html.text("Parts"),
              html.i([class("dropdown-arrow")], [html.text("▼")])
            ]),
            view_megamenu_panel(PartsMegamenu, model),
          ]),
          
          html.div([class("nav-item has-megamenu")], [
            html.a([
              class("nav-link"),
              event.on_click(ToggleMegamenu(ServiceMegamenu))
            ], [
              html.text("Service"),
              html.i([class("dropdown-arrow")], [html.text("▼")])
            ]),
            view_megamenu_panel(ServiceMegamenu, model),
          ]),
          
          html.div([class("nav-item has-megamenu")], [
            html.a([
              class("nav-link"),
              event.on_click(ToggleMegamenu(BikesMegamenu))
            ], [
              html.text("Motorcycles"),
              html.i([class("dropdown-arrow")], [html.text("▼")])
            ]),
            view_megamenu_panel(BikesMegamenu, model),
          ]),
          
          html.div([class("nav-item has-megamenu")], [
            html.a([
              class("nav-link"),
              event.on_click(ToggleMegamenu(AccessoriesMegamenu))
            ], [
              html.text("Accessories"),
              html.i([class("dropdown-arrow")], [html.text("▼")])
            ]),
            view_megamenu_panel(AccessoriesMegamenu, model),
          ]),
          
          html.div([class("nav-item has-megamenu")], [
            html.a([
              class("nav-link"),
              event.on_click(ToggleMegamenu(CustomMegamenu))
            ], [
              html.text("Custom"),
              html.i([class("dropdown-arrow")], [html.text("▼")])
            ]),
            view_megamenu_panel(CustomMegamenu, model),
          ]),
        ]),
        
        // Cart and quick actions
        html.div([class("nav-actions")], [
          view_cart_icon(model),
          html.a([
            class("quick-quote-btn"),
            event.on_click(ParentShouldNavigate("/quote"))
          ], [html.text("Get Quote")])
        ])
      ])
    ])
  ])
}