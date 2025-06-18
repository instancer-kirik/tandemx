import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre/attribute.{class, id, src, alt, href, type_, placeholder, value}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import access_content.{type FetchState, Idle, Loading, Loaded, Errored}

// --- Types ---

pub type Product {
  Product(
    id: Int,
    name: String,
    description: String,
    price: Float,
    sku: String,
    stock_quantity: Int,
    status: String,
    category: String,
    image_url: Option(String),
    brand: Option(String),
    specifications: Dict(String, String),
  )
}

pub type Category {
  Category(
    id: String,
    name: String,
    description: String,
    image_url: Option(String),
    parent_id: Option(String),
    product_count: Int,
  )
}

pub type CartItem {
  CartItem(
    product_id: Int,
    name: String,
    price: Float,
    quantity: Int,
    sku: String,
  )
}

pub type ViewMode {
  GridView
  ListView
}

pub type SortOption {
  PriceAsc
  PriceDesc
  NameAsc
  NameDesc
  Newest
  BestSelling
}

pub type FilterOptions {
  FilterOptions(
    category: Option(String),
    brand: Option(String),
    price_min: Option(Float),
    price_max: Option(Float),
    in_stock_only: Bool,
  )
}

pub type Model {
  Model(
    products: FetchState(List(Product)),
    categories: FetchState(List(Category)),
    cart: Dict(Int, CartItem),
    current_category: Option(String),
    search_query: String,
    view_mode: ViewMode,
    sort_option: SortOption,
    filters: FilterOptions,
    page: Int,
    page_size: Int,
    total_products: Int,
  )
}

pub type Msg {
  LoadProducts
  LoadCategories
  ProductsLoaded(List(Product))
  CategoriesLoaded(List(Category))
  LoadingFailed(String)
  CategorySelected(String)
  SearchQueryChanged(String)
  ViewModeChanged(ViewMode)
  SortOptionChanged(SortOption)
  FilterChanged(FilterOptions)
  AddToCart(Product)
  RemoveFromCart(Int)
  UpdateCartQuantity(Int, Int)
  PageChanged(Int)
  ProductClicked(Int)
}

// --- Init ---

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(
    products: Idle,
    categories: Idle,
    cart: dict.new(),
    current_category: None,
    search_query: "",
    view_mode: GridView,
    sort_option: Newest,
    filters: FilterOptions(
      category: None,
      brand: None,
      price_min: None,
      price_max: None,
      in_stock_only: False,
    ),
    page: 1,
    page_size: 20,
    total_products: 0,
  )
  
  #(model, effect.batch([
    effect.from(fn(_) { LoadProducts }),
    effect.from(fn(_) { LoadCategories }),
  ]))
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    LoadProducts -> {
      #(Model(..model, products: Loading), load_products_effect(model))
    }
    
    LoadCategories -> {
      #(Model(..model, categories: Loading), load_categories_effect())
    }
    
    ProductsLoaded(products) -> {
      #(Model(..model, products: Loaded(products)), effect.none())
    }
    
    CategoriesLoaded(categories) -> {
      #(Model(..model, categories: Loaded(categories)), effect.none())
    }
    
    LoadingFailed(error) -> {
      #(Model(
        ..model, 
        products: Errored(error),
        categories: Errored(error)
      ), effect.none())
    }
    
    CategorySelected(category_id) -> {
      let new_filters = FilterOptions(..model.filters, category: Some(category_id))
      #(Model(
        ..model, 
        current_category: Some(category_id),
        filters: new_filters,
        page: 1
      ), load_products_effect(Model(..model, filters: new_filters)))
    }
    
    SearchQueryChanged(query) -> {
      #(Model(..model, search_query: query, page: 1), 
        load_products_effect(Model(..model, search_query: query)))
    }
    
    ViewModeChanged(mode) -> {
      #(Model(..model, view_mode: mode), effect.none())
    }
    
    SortOptionChanged(sort) -> {
      #(Model(..model, sort_option: sort, page: 1),
        load_products_effect(Model(..model, sort_option: sort)))
    }
    
    FilterChanged(filters) -> {
      #(Model(..model, filters: filters, page: 1),
        load_products_effect(Model(..model, filters: filters)))
    }
    
    AddToCart(product) -> {
      let existing_item = dict.get(model.cart, product.id)
      let new_quantity = case existing_item {
        Ok(item) -> item.quantity + 1
        Error(_) -> 1
      }
      
      let cart_item = CartItem(
        product_id: product.id,
        name: product.name,
        price: product.price,
        quantity: new_quantity,
        sku: product.sku,
      )
      
      let new_cart = dict.insert(model.cart, product.id, cart_item)
      #(Model(..model, cart: new_cart), effect.none())
    }
    
    RemoveFromCart(product_id) -> {
      let new_cart = dict.delete(model.cart, product_id)
      #(Model(..model, cart: new_cart), effect.none())
    }
    
    UpdateCartQuantity(product_id, quantity) -> {
      case dict.get(model.cart, product_id) {
        Ok(item) -> {
          let updated_item = CartItem(..item, quantity: quantity)
          let new_cart = case quantity <= 0 {
            True -> dict.delete(model.cart, product_id)
            False -> dict.insert(model.cart, product_id, updated_item)
          }
          #(Model(..model, cart: new_cart), effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }
    
    PageChanged(page) -> {
      #(Model(..model, page: page), load_products_effect(Model(..model, page: page)))
    }
    
    ProductClicked(_product_id) -> {
      #(model, effect.none())
    }
  }
}

// --- Effects ---

fn load_products_effect(model: Model) -> Effect(Msg) {
  // This would normally make an HTTP request to your API
  // For now, return mock data
  effect.from(fn(_) {
    ProductsLoaded([
      Product(
        id: 1,
        name: "K&N High-Flow Air Filter",
        description: "Premium replacement air filter for increased airflow and performance",
        price: 89.99,
        sku: "KN-HA-1010",
        stock_quantity: 15,
        status: "active",
        category: "engine-filters",
        image_url: Some("/images/products/kn-air-filter.jpg"),
        brand: Some("K&N"),
        specifications: dict.from_list([
          #("Fitment", "Universal 10\" Round"),
          #("Material", "Cotton Gauze"),
          #("Warranty", "Million Mile Limited"),
        ]),
      ),
      Product(
        id: 2,
        name: "NGK Iridium IX Spark Plugs",
        description: "Long-life iridium spark plugs for optimal ignition",
        price: 12.99,
        sku: "NGK-IX-7092",
        stock_quantity: 48,
        status: "active",
        category: "engine-ignition",
        image_url: Some("/images/products/ngk-spark-plugs.jpg"),
        brand: Some("NGK"),
        specifications: dict.from_list([
          #("Thread Size", "14mm"),
          #("Heat Range", "7"),
          #("Electrode", "Iridium"),
        ]),
      ),
      Product(
        id: 3,
        name: "DID Chain & Sprocket Kit",
        description: "Complete chain and sprocket kit for sport bikes",
        price: 189.99,
        sku: "DID-525-ZVMX",
        stock_quantity: 8,
        status: "active",
        category: "drivetrain-chains",
        image_url: Some("/images/products/did-chain-kit.jpg"),
        brand: Some("DID"),
        specifications: dict.from_list([
          #("Chain Size", "525"),
          #("Links", "118"),
          #("Material", "Steel"),
        ]),
      ),
    ])
  })
}

fn load_categories_effect() -> Effect(Msg) {
  effect.from(fn(_) {
    CategoriesLoaded([
      Category(
        id: "engine",
        name: "Engine Parts",
        description: "Filters, spark plugs, gaskets and more",
        image_url: Some("/images/categories/engine.jpg"),
        parent_id: None,
        product_count: 156,
      ),
      Category(
        id: "drivetrain",
        name: "Drivetrain",
        description: "Chains, sprockets, belts and clutch components",
        image_url: Some("/images/categories/drivetrain.jpg"),
        parent_id: None,
        product_count: 89,
      ),
      Category(
        id: "brakes",
        name: "Brakes",
        description: "Brake pads, rotors, lines and fluid",
        image_url: Some("/images/categories/brakes.jpg"),
        parent_id: None,
        product_count: 67,
      ),
    ])
  })
}

// --- View ---

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("shop-layout")], [
    view_hero_section(),
    html.div([class("shop-container")], [
      view_sidebar(model),
      view_main_content(model),
    ]),
  ])
}

fn view_hero_section() -> Element(Msg) {
  html.section([class("shop-hero")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [html.text("Performance Parts & Accessories")]),
      html.p([class("hero-subtitle")], [
        html.text("Quality motorcycle parts for every ride. From daily commuting to track days.")
      ]),
      html.div([class("hero-search")], [
        html.input([
          type_("search"),
          placeholder("Search parts by name, brand, or part number..."),
          class("hero-search-input"),
          event.on_input(SearchQueryChanged)
        ]),
        html.button([class("hero-search-btn")], [html.text("🔍")])
      ])
    ])
  ])
}

fn view_sidebar(model: Model) -> Element(Msg) {
  html.aside([class("shop-sidebar")], [
    view_category_filter(model),
    view_price_filter(model),
    view_brand_filter(model),
    view_stock_filter(model),
  ])
}

fn view_category_filter(model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.h3([class("filter-title")], [html.text("Categories")]),
    html.div([class("filter-content")], [
      case model.categories {
        Loaded(categories) -> html.ul([class("category-list")], 
          list.map(categories, view_category_item)
        )
        Loading -> html.div([class("loading")], [html.text("Loading categories...")])
        Errored(error) -> html.div([class("error")], [html.text("Error: " <> error)])
        Idle -> html.text("")
      }
    ])
  ])
}

fn view_category_item(category: Category) -> Element(Msg) {
  html.li([class("category-item")], [
    html.button([
      class("category-btn"),
      event.on_click(CategorySelected(category.id))
    ], [
      html.span([class("category-name")], [html.text(category.name)]),
      html.span([class("category-count")], [html.text("(" <> int.to_string(category.product_count) <> ")")]),
    ])
  ])
}

fn view_price_filter(model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.h3([class("filter-title")], [html.text("Price Range")]),
    html.div([class("price-range")], [
      html.input([
        type_("number"),
        placeholder("Min"),
        class("price-input"),
        value(case model.filters.price_min {
          Some(min) -> float.to_string(min)
          None -> ""
        })
      ]),
      html.span([class("price-separator")], [html.text("-")]),
      html.input([
        type_("number"),
        placeholder("Max"),
        class("price-input"),
        value(case model.filters.price_max {
          Some(max) -> float.to_string(max)
          None -> ""
        })
      ])
    ])
  ])
}

fn view_brand_filter(_model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.h3([class("filter-title")], [html.text("Brand")]),
    html.div([class("brand-list")], [
      html.label([class("brand-checkbox")], [
        html.input([type_("checkbox")]),
        html.span([], [html.text("K&N (23)")]),
      ]),
      html.label([class("brand-checkbox")], [
        html.input([type_("checkbox")]),
        html.span([], [html.text("NGK (18)")]),
      ]),
      html.label([class("brand-checkbox")], [
        html.input([type_("checkbox")]),
        html.span([], [html.text("DID (15)")]),
      ]),
    ])
  ])
}

fn view_stock_filter(model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.label([class("stock-checkbox")], [
      html.input([
        type_("checkbox"),
        attribute.checked(model.filters.in_stock_only)
      ]),
      html.span([], [html.text("In Stock Only")]),
    ])
  ])
}

fn view_main_content(model: Model) -> Element(Msg) {
  html.main([class("shop-main")], [
    view_toolbar(model),
    view_products(model),
    view_pagination(model),
  ])
}

fn view_toolbar(model: Model) -> Element(Msg) {
  html.div([class("shop-toolbar")], [
    html.div([class("toolbar-left")], [
      html.span([class("results-count")], [
        html.text("Showing " <> int.to_string(get_product_count(model)) <> " products")
      ])
    ]),
    html.div([class("toolbar-right")], [
      view_sort_dropdown(model),
      view_mode_toggle(model),
    ])
  ])
}

fn view_sort_dropdown(model: Model) -> Element(Msg) {
  html.select([
    class("sort-select"),
    event.on_input(fn(value) {
      case value {
        "price-asc" -> SortOptionChanged(PriceAsc)
        "price-desc" -> SortOptionChanged(PriceDesc)
        "name-asc" -> SortOptionChanged(NameAsc)
        "name-desc" -> SortOptionChanged(NameDesc)
        "newest" -> SortOptionChanged(Newest)
        "best-selling" -> SortOptionChanged(BestSelling)
        _ -> SortOptionChanged(Newest)
      }
    })
  ], [
    html.option([value("newest")], [html.text("Newest First")]),
    html.option([value("best-selling")], [html.text("Best Selling")]),
    html.option([value("price-asc")], [html.text("Price: Low to High")]),
    html.option([value("price-desc")], [html.text("Price: High to Low")]),
    html.option([value("name-asc")], [html.text("Name: A to Z")]),
    html.option([value("name-desc")], [html.text("Name: Z to A")]),
  ])
}

fn view_mode_toggle(model: Model) -> Element(Msg) {
  html.div([class("view-mode-toggle")], [
    html.button([
      class(case model.view_mode {
        GridView -> "mode-btn active"
        _ -> "mode-btn"
      }),
      event.on_click(ViewModeChanged(GridView))
    ], [html.text("⊞")]),
    html.button([
      class(case model.view_mode {
        ListView -> "mode-btn active"
        _ -> "mode-btn"
      }),
      event.on_click(ViewModeChanged(ListView))
    ], [html.text("☰")]),
  ])
}

fn view_products(model: Model) -> Element(Msg) {
  case model.products {
    Loaded(products) -> {
      let container_class = case model.view_mode {
        GridView -> "products-grid"
        ListView -> "products-list"
      }
      
      html.div([class(container_class)], 
        list.map(products, fn(product) { view_product_card(product, model) })
      )
    }
    Loading -> html.div([class("loading-products")], [
      html.div([class("loading-spinner")], []),
      html.p([], [html.text("Loading products...")])
    ])
    Errored(error) -> html.div([class("error-products")], [
      html.p([], [html.text("Failed to load products: " <> error)])
    ])
    Idle -> html.text("")
  }
}

fn view_product_card(product: Product, model: Model) -> Element(Msg) {
  let card_class = case model.view_mode {
    GridView -> "product-card grid-card"
    ListView -> "product-card list-card"
  }
  
  html.div([class(card_class)], [
    html.div([class("product-image")], [
      case product.image_url {
        Some(url) -> html.img([
          src(url),
          alt(product.name),
          class("product-img")
        ])
        None -> html.div([class("product-img-placeholder")], [
          html.text("📷")
        ])
      }
    ]),
    html.div([class("product-info")], [
      html.h3([class("product-name")], [html.text(product.name)]),
      html.p([class("product-description")], [html.text(product.description)]),
      html.div([class("product-meta")], [
        html.span([class("product-sku")], [html.text("SKU: " <> product.sku)]),
        case product.brand {
          Some(brand) -> html.span([class("product-brand")], [html.text(brand)])
          None -> html.text("")
        }
      ]),
      html.div([class("product-stock")], [
        case product.stock_quantity > 0 {
          True -> html.span([class("in-stock")], [
            html.text("✓ " <> int.to_string(product.stock_quantity) <> " in stock")
          ])
          False -> html.span([class("out-of-stock")], [
            html.text("✗ Out of stock")
          ])
        }
      ])
    ]),
    html.div([class("product-actions")], [
      html.div([class("product-price")], [
        html.span([class("price")], [html.text("$" <> float.to_string(product.price))])
      ]),
      html.button([
        class(case product.stock_quantity > 0 {
          True -> "add-to-cart-btn"
          False -> "add-to-cart-btn disabled"
        }),
        event.on_click(AddToCart(product))
      ], [
        html.text(case dict.has_key(model.cart, product.id) {
          True -> "Added ✓"
          False -> "Add to Cart"
        })
      ])
    ])
  ])
}

fn view_pagination(model: Model) -> Element(Msg) {
  let total_pages = case model.total_products > 0 {
    True -> { model.total_products + model.page_size - 1 } / model.page_size
    False -> 1
  }
  
  html.div([class("pagination")], [
    html.button([
      class(case model.page > 1 {
        True -> "page-btn"
        False -> "page-btn disabled"
      }),
      event.on_click(PageChanged(model.page - 1))
    ], [html.text("Previous")]),
    
    html.span([class("page-info")], [
      html.text("Page " <> int.to_string(model.page) <> " of " <> int.to_string(total_pages))
    ]),
    
    html.button([
      class(case model.page < total_pages {
        True -> "page-btn"
        False -> "page-btn disabled"
      }),
      event.on_click(PageChanged(model.page + 1))
    ], [html.text("Next")])
  ])
}

// --- Helper Functions ---

fn get_product_count(model: Model) -> Int {
  case model.products {
    Loaded(products) -> list.length(products)
    _ -> 0
  }
}