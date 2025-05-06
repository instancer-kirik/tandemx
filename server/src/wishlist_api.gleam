import gleam/bytes_tree
import gleam/dynamic
import gleam/http.{Delete, Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mist

pub type WishlistItem {
  WishlistItem(id: Int, product_id: String, user_id: String, added_at: String)
}

pub type Product {
  Product(
    id: String,
    name: String,
    description: String,
    category: String,
    price: Float,
    sale_price: Option(Float),
    image_url: String,
    badge: Option(String),
  )
}

pub type ProductSpec {
  ProductSpec(id: Int, product_id: String, spec_key: String, spec_value: String)
}

pub type CartItem {
  CartItem(
    id: Int,
    product_id: String,
    user_id: String,
    quantity: Int,
    added_at: String,
  )
}

pub fn handle_wishlist_request(
  req: Request(String),
) -> Response(mist.ResponseData) {
  let path = req.path |> string.split("/") |> list.drop(2)

  case path, req.method {
    // GET /api/wishlist/products - List all products
    ["products"], Get -> get_all_products()

    // GET /api/wishlist/products/:id - Get product by ID
    ["products", product_id], Get -> get_product(product_id)

    // GET /api/wishlist/:user_id - Get user's wishlist
    [user_id], Get -> get_user_wishlist(user_id)

    // POST /api/wishlist/:user_id/:product_id - Add product to wishlist
    [user_id, product_id], Post -> add_to_wishlist(user_id, product_id)

    // DELETE /api/wishlist/:user_id/:product_id - Remove product from wishlist
    [user_id, product_id], Delete -> remove_from_wishlist(user_id, product_id)

    // GET /api/wishlist/cart/:user_id - Get user's cart
    ["cart", user_id], Get -> get_user_cart(user_id)

    // POST /api/wishlist/cart/:user_id/:product_id - Add product to cart
    ["cart", user_id, product_id], Post -> add_to_cart(user_id, product_id)

    // DELETE /api/wishlist/cart/:user_id/:product_id - Remove product from cart
    ["cart", user_id, product_id], Delete ->
      remove_from_cart(user_id, product_id)

    _, _ -> not_found()
  }
}

fn get_all_products() -> Response(mist.ResponseData) {
  // Return mock products
  let products = get_mock_products()

  let products_json =
    list.map(products, fn(product) {
      json.object([
        #("id", json.string(product.id)),
        #("name", json.string(product.name)),
        #("description", json.string(product.description)),
        #("category", json.string(product.category)),
        #("price", json.float(product.price)),
        #("salePrice", case product.sale_price {
          Some(price) -> json.float(price)
          None -> json.null()
        }),
        #("image", json.string(product.image_url)),
        #("badge", case product.badge {
          Some(badge) -> json.string(badge)
          None -> json.null()
        }),
        #("specs", json.object(get_mock_specs(product.id))),
      ])
    })

  let body = json.to_string(json.array(products_json, fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn get_product(product_id: String) -> Response(mist.ResponseData) {
  // Find product in mock data
  let products = get_mock_products()
  let product = list.find(products, fn(p) { p.id == product_id })

  case product {
    Ok(product) -> {
      let product_json =
        json.object([
          #("id", json.string(product.id)),
          #("name", json.string(product.name)),
          #("description", json.string(product.description)),
          #("category", json.string(product.category)),
          #("price", json.float(product.price)),
          #("salePrice", case product.sale_price {
            Some(price) -> json.float(price)
            None -> json.null()
          }),
          #("image", json.string(product.image_url)),
          #("badge", case product.badge {
            Some(badge) -> json.string(badge)
            None -> json.null()
          }),
          #("specs", json.object(get_mock_specs(product.id))),
        ])
      let body = json.to_string(product_json)
      response.new(200)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
    }
    Error(_) -> {
      let error_json =
        json.object([#("error", json.string("Product not found"))])
      let body = json.to_string(error_json)
      response.new(404)
      |> response.set_header("content-type", "application/json")
      |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
    }
  }
}

fn get_user_wishlist(user_id: String) -> Response(mist.ResponseData) {
  // Return empty list - will be managed on client side
  let body = json.to_string(json.array([], fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn add_to_wishlist(
  _user_id: String,
  _product_id: String,
) -> Response(mist.ResponseData) {
  // Mock success response
  let resp_json =
    json.object([
      #("success", json.bool(True)),
      #("message", json.string("Item added to wishlist")),
    ])
  let body = json.to_string(resp_json)
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn remove_from_wishlist(
  user_id: String,
  product_id: String,
) -> Response(mist.ResponseData) {
  // Mock success response
  let resp_json =
    json.object([
      #("success", json.bool(True)),
      #("message", json.string("Item removed from wishlist")),
    ])
  let body = json.to_string(resp_json)
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn get_user_cart(_user_id: String) -> Response(mist.ResponseData) {
  // Return empty list - will be managed on client side
  let body = json.to_string(json.array([], fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn add_to_cart(
  _user_id: String,
  _product_id: String,
) -> Response(mist.ResponseData) {
  // Mock success response
  let resp_json =
    json.object([
      #("success", json.bool(True)),
      #("message", json.string("Item added to cart")),
    ])
  let body = json.to_string(resp_json)
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn remove_from_cart(
  _user_id: String,
  _product_id: String,
) -> Response(mist.ResponseData) {
  // Mock success response
  let resp_json =
    json.object([
      #("success", json.bool(True)),
      #("message", json.string("Item removed from cart")),
    ])
  let body = json.to_string(resp_json)
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn not_found() -> Response(mist.ResponseData) {
  let error_json = json.object([#("error", json.string("Not found"))])
  let body = json.to_string(error_json)
  response.new(404)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

// Helper function to get mock product data
pub fn get_mock_products() -> List(Product) {
  [
    Product(
      id: "servo-motor-sg90",
      name: "SG90 Micro Servo Motor",
      description: "Compact servo motor ideal for small robotics projects and prototypes.",
      category: "robot-parts",
      price: 4.99,
      sale_price: None,
      image_url: "/images/wishlist/servo-motor.svg",
      badge: Some("best-seller"),
    ),
    Product(
      id: "dc-motor-n20",
      name: "N20 DC Gear Motor",
      description: "Mini DC geared motor with high torque output for small robots.",
      category: "robot-parts",
      price: 6.99,
      sale_price: None,
      image_url: "/images/wishlist/placeholder.svg",
      badge: None,
    ),
    Product(
      id: "arduino-nano",
      name: "Arduino Nano Board",
      description: "Compact microcontroller board for robotics and IoT projects.",
      category: "controllers",
      price: 12.99,
      sale_price: None,
      image_url: "/images/wishlist/arduino-nano.svg",
      badge: None,
    ),
    Product(
      id: "raspberry-pi-4",
      name: "Raspberry Pi 4 (4GB)",
      description: "Powerful single-board computer for advanced robotics and AI projects.",
      category: "controllers",
      price: 59.99,
      sale_price: None,
      image_url: "/images/wishlist/placeholder.svg",
      badge: Some("featured"),
    ),
    Product(
      id: "ultrasonic-sensor",
      name: "HC-SR04 Ultrasonic Sensor",
      description: "Distance measurement sensor for obstacle detection and navigation.",
      category: "sensors",
      price: 3.99,
      sale_price: Some(2.99),
      image_url: "/images/wishlist/placeholder.svg",
      badge: Some("sale"),
    ),
    Product(
      id: "infrared-sensor",
      name: "IR Line Tracking Sensor",
      description: "Infrared line following sensor module for line-following robots.",
      category: "sensors",
      price: 2.99,
      sale_price: None,
      image_url: "/images/wishlist/placeholder.svg",
      badge: None,
    ),
  ]
}

// Helper function to get mock product specs
pub fn get_mock_specs(product_id: String) -> List(#(String, json.Json)) {
  case product_id {
    "servo-motor-sg90" -> [
      #("Weight", json.string("9g")),
      #("Torque", json.string("1.8kg/cm")),
      #("Speed", json.string("0.1s/60°")),
      #("Voltage", json.string("4.8-6V")),
    ]
    "dc-motor-n20" -> [
      #("RPM", json.string("200")),
      #("Voltage", json.string("6V")),
      #("Shaft Diameter", json.string("3mm")),
      #("Weight", json.string("15g")),
    ]
    "arduino-nano" -> [
      #("Microcontroller", json.string("ATmega328P")),
      #("Clock Speed", json.string("16MHz")),
      #("Digital I/O", json.string("14 pins")),
      #("Analog Inputs", json.string("8 pins")),
    ]
    "raspberry-pi-4" -> [
      #("CPU", json.string("Quad-core Cortex-A72")),
      #("RAM", json.string("4GB")),
      #("Connectivity", json.string("WiFi, Bluetooth 5.0")),
      #("Ports", json.string("USB 3.0, HDMI, Ethernet")),
    ]
    _ -> []
  }
}
