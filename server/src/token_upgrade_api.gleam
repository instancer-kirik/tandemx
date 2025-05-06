import gleam/bytes_tree
import gleam/dynamic
import gleam/http.{Delete, Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mist

pub type Token {
  Token(
    id: String,
    name: String,
    description: String,
    price: Float,
    image_url: String,
    badge: Option(String),
  )
}

pub type TruckUpgrade {
  TruckUpgrade(
    id: String,
    name: String,
    description: String,
    category: String,
    price: Float,
    sale_price: Option(Float),
    image_url: String,
    badge: Option(String),
    specs: List(#(String, String)),
  )
}

pub type UserBadge {
  UserBadge(
    id: Int,
    user_id: String,
    badge_id: String,
    badge_type: String,
    // "token" or "upgrade"
    acquired_at: String,
  )
}

pub type Address {
  Address(
    street: String,
    city: String,
    state: String,
    zip: String,
    country: String,
  )
}

pub type PurchaseDetails {
  PurchaseDetails(
    payment_method: String,
    // "paddle", "crypto", "bank"
    crypto_address: Option(String),
    // e.g., SOL, ETH, ETC address used if method is crypto
    crypto_tx_id: Option(String),
    // Transaction ID if method is crypto
    shipping_address: Option(Address),
    // Optional shipping address
    redemption_instructions: Option(String),
    // Optional instructions
  )
}

pub type CryptoOptions {
  CryptoOptions(sol_address: String, eth_address: String, etc_address: String)
}

pub type BankInfo {
  BankInfo(instructions: String)
  // Stub for now
}

pub type PaymentOptions {
  PaymentOptions(crypto: CryptoOptions, bank: BankInfo)
}

pub fn handle_token_upgrade_request(
  path_segments: List(String),
  method: http.Method,
  body: Option(dynamic.Dynamic),
) -> Response(mist.ResponseData) {
  case path_segments, method {
    // GET /api/payment-options - Get payment addresses/info
    ["payment-options"], Get -> get_payment_options()

    // GET /api/tokens - List all tokens
    ["tokens"], Get -> get_all_tokens()

    // GET /api/upgrades - List all truck upgrades
    ["upgrades"], Get -> get_all_upgrades()

    // GET /api/badges/:user_id - Get user's badges
    ["badges", user_id], Get -> get_user_badges(user_id)

    // POST /api/purchase/token/:user_id/:token_id - Purchase token
    ["purchase", "token", user_id, token_id], Post ->
      purchase_token(user_id, token_id, body)

    // POST /api/purchase/upgrade/:user_id/:upgrade_id - Purchase truck upgrade
    ["purchase", "upgrade", user_id, upgrade_id], Post ->
      purchase_upgrade(user_id, upgrade_id, body)

    _, _ -> not_found()
  }
}

fn get_all_tokens() -> Response(mist.ResponseData) {
  let tokens = get_mock_tokens()
  let tokens_json =
    list.map(tokens, fn(token) {
      json.object([
        #("id", json.string(token.id)),
        #("name", json.string(token.name)),
        #("description", json.string(token.description)),
        #("price", json.float(token.price)),
        #("image", json.string(token.image_url)),
        #("badge", case token.badge {
          Some(badge) -> json.string(badge)
          None -> json.null()
        }),
      ])
    })

  let body = json.to_string(json.array(tokens_json, fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn get_all_upgrades() -> Response(mist.ResponseData) {
  let upgrades = get_mock_upgrades()
  let upgrades_json =
    list.map(upgrades, fn(upgrade) {
      json.object([
        #("id", json.string(upgrade.id)),
        #("name", json.string(upgrade.name)),
        #("description", json.string(upgrade.description)),
        #("category", json.string(upgrade.category)),
        #("price", json.float(upgrade.price)),
        #("salePrice", case upgrade.sale_price {
          Some(price) -> json.float(price)
          None -> json.null()
        }),
        #("image", json.string(upgrade.image_url)),
        #("badge", case upgrade.badge {
          Some(badge) -> json.string(badge)
          None -> json.null()
        }),
        #(
          "specs",
          json.object(
            list.map(upgrade.specs, fn(spec) {
              let #(key, value) = spec
              #(key, json.string(value))
            }),
          ),
        ),
      ])
    })

  let body = json.to_string(json.array(upgrades_json, fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn get_user_badges(_user_id: String) -> Response(mist.ResponseData) {
  // Return empty list - will be managed on client side
  let body = json.to_string(json.array([], fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn get_payment_options() -> Response(mist.ResponseData) {
  let options =
    PaymentOptions(
      crypto: CryptoOptions(
        sol_address: "YOUR_SOLANA_ADDRESS_HERE",
        // Replace with actual address
        eth_address: "YOUR_ETHEREUM_ADDRESS_HERE",
        // Replace with actual address
        etc_address: "YOUR_ETHEREUM_CLASSIC_ADDRESS_HERE",
        // Replace with actual address
      ),
      bank: BankInfo(
        instructions: "Bank Transfer: Please contact support for details. (Stub)",
      ),
    )

  let options_json =
    json.object([
      #(
        "crypto",
        json.object([
          #("sol_address", json.string(options.crypto.sol_address)),
          #("eth_address", json.string(options.crypto.eth_address)),
          #("etc_address", json.string(options.crypto.etc_address)),
        ]),
      ),
      #(
        "bank",
        json.object([#("instructions", json.string(options.bank.instructions))]),
      ),
    ])

  let body = json.to_string(options_json)
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn purchase_token(
  user_id: String,
  token_id: String,
  body: Option(dynamic.Dynamic),
) -> Response(mist.ResponseData) {
  case body {
    Some(dynamic_body) -> {
      case decode_purchase_details(dynamic_body) {
        Ok(details) -> {
          io.println("Received token purchase request:")
          io.println("  Payment Method: " <> details.payment_method)
          let resp_json =
            json.object([
              #("success", json.bool(True)),
              #(
                "message",
                json.string(
                  "Token purchase request received (pending processing)",
                ),
              ),
            ])
          let body = json.to_string(resp_json)
          response.new(200)
          |> response.set_header("content-type", "application/json")
          |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
        }
        Error(error) -> {
          io.println(
            "Failed to decode purchase details: " <> string.inspect(error),
          )
          bad_request("Invalid purchase details in request body.")
        }
      }
    }
    None -> bad_request("Missing purchase details in request body.")
  }
}

fn purchase_upgrade(
  user_id: String,
  upgrade_id: String,
  body: Option(dynamic.Dynamic),
) -> Response(mist.ResponseData) {
  case body {
    Some(dynamic_body) -> {
      case decode_purchase_details(dynamic_body) {
        Ok(details) -> {
          io.println("Received upgrade purchase request:")
          io.println("  Payment Method: " <> details.payment_method)
          let resp_json =
            json.object([
              #("success", json.bool(True)),
              #(
                "message",
                json.string(
                  "Upgrade purchase request received (pending processing)",
                ),
              ),
            ])
          let body = json.to_string(resp_json)
          response.new(200)
          |> response.set_header("content-type", "application/json")
          |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
        }
        Error(error) -> {
          io.println(
            "Failed to decode purchase details: " <> string.inspect(error),
          )
          bad_request("Invalid purchase details in request body.")
        }
      }
    }
    None -> bad_request("Missing purchase details in request body.")
  }
}

fn bad_request(message: String) -> Response(mist.ResponseData) {
  let error_json = json.object([#("error", json.string(message))])
  let body = json.to_string(error_json)
  response.new(400)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn decode_address(
  decoder: dynamic.Dynamic,
) -> Result(Address, List(dynamic.DecodeError)) {
  dynamic.decode5(
    Address,
    dynamic.field("street", dynamic.string),
    dynamic.field("city", dynamic.string),
    dynamic.field("state", dynamic.string),
    dynamic.field("zip", dynamic.string),
    dynamic.field("country", dynamic.string),
  )(decoder)
}

fn decode_purchase_details(
  decoder: dynamic.Dynamic,
) -> Result(PurchaseDetails, List(dynamic.DecodeError)) {
  dynamic.decode5(
    PurchaseDetails,
    dynamic.field("payment_method", dynamic.string),
    dynamic.optional_field("crypto_address", dynamic.string),
    dynamic.optional_field("crypto_tx_id", dynamic.string),
    dynamic.optional_field("shipping_address", decode_address),
    dynamic.optional_field("redemption_instructions", dynamic.string),
  )(decoder)
}

fn not_found() -> Response(mist.ResponseData) {
  let error_json = json.object([#("error", json.string("Not found"))])
  let body = json.to_string(error_json)
  response.new(404)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

// Helper function to get mock token data
pub fn get_mock_tokens() -> List(Token) {
  [
    Token(
      id: "basic-token",
      name: "Basic Token",
      description: "Standard token for basic truck operations",
      price: 9.99,
      image_url: "/images/tokens/basic.svg",
      badge: Some("basic"),
    ),
    Token(
      id: "premium-token",
      name: "Premium Token",
      description: "Enhanced token with additional features",
      price: 19.99,
      image_url: "/images/tokens/premium.svg",
      badge: Some("premium"),
    ),
    Token(
      id: "elite-token",
      name: "Elite Token",
      description: "Top-tier token with all features unlocked",
      price: 29.99,
      image_url: "/images/tokens/elite.svg",
      badge: Some("elite"),
    ),
  ]
}

// Helper function to get mock upgrade data
pub fn get_mock_upgrades() -> List(TruckUpgrade) {
  [
    TruckUpgrade(
      id: "performance-engine",
      name: "Performance Engine",
      description: "High-performance engine upgrade for increased power",
      category: "engine",
      price: 499.99,
      sale_price: Some(449.99),
      image_url: "/images/upgrades/engine.svg",
      badge: Some("performance"),
      specs: [
        #("Power Increase", "25%"),
        #("Fuel Efficiency", "15%"),
        #("Installation Time", "4 hours"),
      ],
    ),
    TruckUpgrade(
      id: "luxury-cabin",
      name: "Luxury Cabin Package",
      description: "Premium interior upgrade with comfort features",
      category: "interior",
      price: 299.99,
      sale_price: None,
      image_url: "/images/upgrades/cabin.svg",
      badge: Some("luxury"),
      specs: [
        #("Seat Type", "Premium Leather"),
        #("Climate Control", "Dual Zone"),
        #("Sound System", "Premium Audio"),
      ],
    ),
    TruckUpgrade(
      id: "offroad-package",
      name: "Off-Road Package",
      description: "Complete off-road capability upgrade",
      category: "suspension",
      price: 799.99,
      sale_price: None,
      image_url: "/images/upgrades/offroad.svg",
      badge: Some("offroad"),
      specs: [
        #("Suspension", "Heavy Duty"),
        #("Ground Clearance", "+4 inches"),
        #("Tire Type", "All-Terrain"),
      ],
    ),
  ]
}

fn add_token_to_badges(
  _user_id: String,
  _token_id: String,
) -> Response(mist.ResponseData) {
  todo
  // ... existing code ...
}

fn add_upgrade_to_badges(
  _user_id: String,
  _upgrade_id: String,
) -> Response(mist.ResponseData) {
  todo
  // ... existing code ...
}
