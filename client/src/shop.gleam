import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

import lustre/attribute.{class, src, alt, type_, placeholder, value}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

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
    products: List(Product),
    categories: List(Category),
    cart: List(CartItem),
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
  let initial_filters = FilterOptions(
    category: None,
    brand: None,
    price_min: None,
    price_max: None,
    in_stock_only: False,
  )
  
  let model = Model(
    products: [],
    categories: [],
    cart: [],
    current_category: None,
    search_query: "",
    view_mode: GridView,
    sort_option: Newest,
    filters: initial_filters,
    page: 1,
    page_size: 12,
    total_products: 0,
  )
  
  #(model, effect.batch([
    effect.from(fn(dispatch) { dispatch(LoadProducts) }),
    effect.from(fn(dispatch) { dispatch(LoadCategories) }),
  ]))
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    LoadProducts -> #(model, load_products_effect(model))
    
    LoadCategories -> #(model, load_categories_effect())
    
    ProductsLoaded(products) -> {
      let sorted_products = sort_products(products, model.sort_option)
      #(
        Model(..model, products: sorted_products, total_products: list.length(products)),
        effect.none(),
      )
    }
    
    CategoriesLoaded(categories) -> #(
      Model(..model, categories: categories),
      effect.none(),
    )
    
    LoadingFailed(error) -> {
      // Handle error - could show a toast or error message
      #(model, effect.none())
    }
    
    CategorySelected(category_id) -> {
      let new_model = Model(
        ..model,
        current_category: Some(category_id),
        page: 1, // Reset to first page when changing category
      )
      #(new_model, load_products_effect(new_model))
    }
    
    SearchQueryChanged(query) -> {
      let new_model = Model(
        ..model,
        search_query: query,
        page: 1, // Reset to first page when searching
      )
      #(new_model, load_products_effect(new_model))
    }
    
    ViewModeChanged(mode) -> #(
      Model(..model, view_mode: mode),
      effect.none(),
    )
    
    SortOptionChanged(option) -> {
      let sorted_products = sort_products(model.products, option)
      #(
        Model(..model, sort_option: option, products: sorted_products),
        effect.none(),
      )
    }
    
    FilterChanged(filters) -> {
      let new_model = Model(
        ..model,
        filters: filters,
        page: 1, // Reset to first page when changing filters
      )
      #(new_model, load_products_effect(new_model))
    }
    
    AddToCart(product) -> {
      let existing_item = list.find(model.cart, fn(item) {
        item.product_id == product.id
      })
      
      let new_cart = case existing_item {
        Ok(item) -> {
          // Update quantity of existing item
          list.map(model.cart, fn(cart_item) {
            case cart_item.product_id == product.id {
              True -> CartItem(..cart_item, quantity: cart_item.quantity + 1)
              False -> cart_item
            }
          })
        }
        Error(_) -> {
          // Add new item to cart
          let new_item = CartItem(
            product_id: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
            sku: product.sku,
          )
          [new_item, ..model.cart]
        }
      }
      
      #(Model(..model, cart: new_cart), effect.none())
    }
    
    RemoveFromCart(product_id) -> {
      let new_cart = list.filter(model.cart, fn(item) {
        item.product_id != product_id
      })
      #(Model(..model, cart: new_cart), effect.none())
    }
    
    UpdateCartQuantity(product_id, quantity) -> {
      let new_cart = case quantity <= 0 {
        True -> list.filter(model.cart, fn(item) { item.product_id != product_id })
        False -> {
          list.map(model.cart, fn(item) {
            case item.product_id == product_id {
              True -> CartItem(..item, quantity: quantity)
              False -> item
            }
          })
        }
      }
      #(Model(..model, cart: new_cart), effect.none())
    }
    
    PageChanged(page) -> {
      let new_model = Model(..model, page: page)
      #(new_model, load_products_effect(new_model))
    }
    
    ProductClicked(product_id) -> {
      // Navigate to product detail page or show modal
      #(model, effect.none())
    }
  }
}

// --- Effects ---

fn load_products_effect(_model: Model) -> Effect(Msg) {
  // This would normally make an HTTP request to your API
  // For now, return mock data
  effect.from(fn(dispatch) {
    dispatch(ProductsLoaded([
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
    ]))
  })
}

fn load_categories_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    dispatch(CategoriesLoaded([
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
    ]))
  })
}

// --- View ---

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("shop-container")], [
    view_hero_section(),
    html.div([class("shop-content")], [
      view_sidebar(model),
      view_main_content(model),
    ]),
  ])
}

fn view_hero_section() -> Element(Msg) {
  html.section([class("shop-hero")], [
    html.div([class("hero-content")], [
      html.h1([class("hero-title")], [html.text("TandemX Moto Parts & Accessories")]),
      html.p([class("hero-subtitle")], [
        html.text("Premium motorcycle parts, gear, and custom solutions for riders who demand the best")
      ]),
      html.div([class("hero-search")], [
        html.input([
          type_("search"),
          placeholder("Search parts, accessories, or part numbers..."),
          class("hero-search-input"),
          event.on_input(SearchQueryChanged),
        ]),
        html.button([class("hero-search-btn")], [html.text("Search")]),
      ]),
    ]),
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
    html.div([class("category-list")], 
      list.map(model.categories, view_category_item)
    ),
  ])
}

fn view_category_item(category: Category) -> Element(Msg) {
  html.button([
    class("category-item"),
    event.on_click(CategorySelected(category.id)),
  ], [
    html.span([class("category-name")], [html.text(category.name)]),
    html.span([class("category-count")], [html.text("(" <> int.to_string(category.product_count) <> ")")]),
  ])
}

fn view_price_filter(model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.h3([class("filter-title")], [html.text("Price Range")]),
    html.div([class("price-inputs")], [
      html.input([
        type_("number"),
        placeholder("Min"),
        class("price-input"),
        value(case model.filters.price_min {
          Some(min) -> float.to_string(min)
          None -> ""
        }),
      ]),
      html.span([class("price-separator")], [html.text(" - ")]),
      html.input([
        type_("number"),
        placeholder("Max"),
        class("price-input"),
        value(case model.filters.price_max {
          Some(max) -> float.to_string(max)
          None -> ""
        }),
      ]),
    ]),
  ])
}

fn view_brand_filter(model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.h3([class("filter-title")], [html.text("Brand")]),
    html.div([class("brand-list")], [
      html.label([class("brand-item")], [
        html.input([type_("checkbox")]),
        html.text("K&N"),
      ]),
      html.label([class("brand-item")], [
        html.input([type_("checkbox")]),
        html.text("NGK"),
      ]),
      html.label([class("brand-item")], [
        html.input([type_("checkbox")]),
        html.text("DID"),
      ]),
    ]),
  ])
}

fn view_stock_filter(model: Model) -> Element(Msg) {
  html.div([class("filter-section")], [
    html.label([class("stock-filter")], [
      html.input([
        type_("checkbox"),
        attribute.checked(model.filters.in_stock_only),
      ]),
      html.text("In Stock Only"),
    ]),
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
        html.text(int.to_string(model.total_products) <> " products found")
      ]),
    ]),
    html.div([class("toolbar-right")], [
      view_sort_dropdown(model),
      view_mode_toggle(model),
    ]),
  ])
}

fn view_sort_dropdown(_model: Model) -> Element(Msg) {
  html.select([
    class("sort-select"),
    event.on_input(fn(value) {
      case value {
        "newest" -> SortOptionChanged(Newest)
        "best-selling" -> SortOptionChanged(BestSelling)
        "price-asc" -> SortOptionChanged(PriceAsc)
        "price-desc" -> SortOptionChanged(PriceDesc)
        "name-asc" -> SortOptionChanged(NameAsc)
        "name-desc" -> SortOptionChanged(NameDesc)
        _ -> SortOptionChanged(Newest)
      }
    })
  ], [
    html.option([value("newest")], "Newest First"),
    html.option([value("best-selling")], "Best Selling"),
    html.option([value("price-asc")], "Price: Low to High"),
    html.option([value("price-desc")], "Price: High to Low"),
    html.option([value("name-asc")], "Name: A to Z"),
    html.option([value("name-desc")], "Name: Z to A"),
  ])
}

fn view_mode_toggle(model: Model) -> Element(Msg) {
  html.div([class("view-mode-toggle")], [
    html.button([
      class(case model.view_mode {
        GridView -> "mode-btn active"
        _ -> "mode-btn"
      }),
      event.on_click(ViewModeChanged(GridView)),
    ], [html.text("⊞")]),
    html.button([
      class(case model.view_mode {
        ListView -> "mode-btn active"
        _ -> "mode-btn"
      }),
      event.on_click(ViewModeChanged(ListView)),
    ], [html.text("☰")]),
  ])
}

fn view_products(model: Model) -> Element(Msg) {
  let grid_class = case model.view_mode {
    GridView -> "products-grid"
    ListView -> "products-list"
  }
  
  html.div([class("products-container")], [
    html.div([class(grid_class)], 
      list.map(model.products, fn(product) {
        view_product_card(product, model.view_mode)
      })
    ),
  ])
}

fn view_product_card(product: Product, view_mode: ViewMode) -> Element(Msg) {
  let card_class = case view_mode {
    GridView -> "product-card grid"
    ListView -> "product-card list"
  }
  
  html.div([class(card_class)], [
    html.div([class("product-image-container")], [
      html.img([
        src(case product.image_url {
          Some(url) -> url
          None -> "/images/placeholder-product.jpg"
        }),
        alt(product.name),
        class("product-image"),
      ]),
      case product.stock_quantity <= 0 {
        True -> html.div([class("out-of-stock-badge")], [html.text("Out of Stock")])
        False -> html.div([], [])
      },
    ]),
    html.div([class("product-info")], [
      html.h3([class("product-name")], [html.text(product.name)]),
      html.p([class("product-description")], [html.text(product.description)]),
      html.div([class("product-meta")], [
        html.span([class("product-sku")], [html.text("SKU: " <> product.sku)]),
        case product.brand {
          Some(brand) -> html.span([class("product-brand")], [html.text(brand)])
          None -> html.span([], [])
        },
      ]),
      html.div([class("product-footer")], [
        html.div([class("product-price")], [
          html.span([class("price")], [html.text("$" <> float.to_string(product.price))]),
        ]),
        html.div([class("product-actions")], [
          html.button([
            class(case product.stock_quantity <= 0 {
              True -> "add-to-cart-btn disabled"
              False -> "add-to-cart-btn"
            }),
            attribute.disabled(product.stock_quantity <= 0),
            event.on_click(AddToCart(product)),
          ], [html.text("Add to Cart")]),
        ]),
      ]),
    ]),
  ])
}

fn view_pagination(model: Model) -> Element(Msg) {
  let total_pages = case model.total_products == 0 {
    True -> 1
    False -> {
      let pages = model.total_products / model.page_size
      case model.total_products % model.page_size {
        0 -> pages
        _ -> pages + 1
      }
    }
  }
  
  html.div([class("pagination")], [
    html.button([
      class("page-btn prev"),
      attribute.disabled(model.page <= 1),
      event.on_click(PageChanged(model.page - 1)),
    ], [html.text("Previous")]),
    html.span([class("page-info")], [
      html.text("Page " <> int.to_string(model.page) <> " of " <> int.to_string(total_pages))
    ]),
    html.button([
      class("page-btn next"),
      attribute.disabled(model.page >= total_pages),
      event.on_click(PageChanged(model.page + 1)),
    ], [html.text("Next")]),
  ])
}

// --- Helper Functions ---

fn get_product_count(products: List(Product)) -> Int {
  list.length(products)
}

fn sort_products(products: List(Product), sort_option: SortOption) -> List(Product) {
  case sort_option {
    PriceAsc -> list.sort(products, fn(a, b) { float.compare(a.price, b.price) })
    PriceDesc -> list.sort(products, fn(a, b) { float.compare(b.price, a.price) })
    NameAsc -> list.sort(products, fn(a, b) { string.compare(a.name, b.name) })
    NameDesc -> list.sort(products, fn(a, b) { string.compare(b.name, a.name) })
    Newest -> list.sort(products, fn(a, b) { int.compare(b.id, a.id) }) // Assuming higher ID = newer
    BestSelling -> products // Would need sales data to implement properly
  }
}