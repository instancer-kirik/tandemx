import gleam/bytes_tree
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http.{Get, Post}

import gleam/http/response.{type Response}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}

import gleam/string
import mist

// TODO: Configure and import your Supabase client (from tandemx/supabase/supabase.gleam)
// import supabase
// import supabase/client exposing (Client) // Assuming Client type is defined in your module
// import supabase/query // If you build out query capabilities

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
  // TODO: Pass your custom Supabase client instance if initialized in dev_server.gleam
  // supabase_client: supabase.Client, 
) -> Response(mist.ResponseData) {
  case path_segments, method {
    // GET /api/payment-options - Get payment addresses/info
    ["payment-options"], Get -> get_payment_options()

    // supabase_client
    // GET /api/tokens - List all tokens
    ["tokens"], Get -> get_all_tokens()

    // GET /api/upgrades - List all truck upgrades
    ["upgrades"], Get -> get_all_upgrades()

    // GET /api/badges/:user_id - Get user's badges
    ["badges", user_id], Get -> get_user_badges(user_id)

    // POST /api/purchase/token/:user_id/:token_id - Purchase token
    ["purchase", "token", user_id, token_id], Post ->
      purchase_token(user_id, token_id, body)

    // supabase_client
    // POST /api/purchase/upgrade/:user_id/:upgrade_id - Purchase truck upgrade
    ["purchase", "upgrade", user_id, upgrade_id], Post ->
      purchase_upgrade(user_id, upgrade_id, body)

    // supabase_client
    _, _ -> not_found()
  }
}

fn get_all_tokens(
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Initialize your custom Supabase client if not passed as arg
  // let supabase_client = supabase.create("YOUR_SUPABASE_URL", "YOUR_SUPABASE_KEY_OR_SERVICE_ROLE")

  // TODO: Fetch tokens from Supabase 'tokens' table using your custom client
  // use result <- supabase.from(supabase_client, "tokens")
  //   |> supabase.select("*") 
  //   |> supabase.execute()
  // case result {
  //   Ok(data_dynamic) -> {
  //     // TODO: Decode the data_dynamic (dynamic.Dynamic) into List(Token)
  //     // This will require a new decoder: decode.list(decode_token_from_db_decoder())
  //     // For example, if data_dynamic is a list:
  //     // case dynamic.dynamic_to_list(data_dynamic) {
  //     //   Ok(list_of_dynamics) -> 
  //     //      let decode_result = list.try_map(list_of_dynamics, decode.run(_, decode_token_from_db_decoder()))
  //     //      case decode_result {
  //     //         Ok(tokens) -> // Proceed with tokens
  //     //         Error(decode_err) -> // Handle decode error
  //     //      }
  //     //   Error(_) -> // Handle error: data_dynamic was not a list
  //     // }
  //     let tokens = [] // Placeholder for decoded tokens
  //     let tokens_json =
  //       list.map(tokens, fn(token) {
  //         json.object([
  //           #("id", json.string(token.id)),
  //           #("name", json.string(token.name)),
  //           #("description", json.string(token.description)),
  //           #("price", json.float(token.price)),
  //           #("image", json.string(token.image_url)), // Ensure field name matches DB
  //           #("badge", case token.badge {
  //             Some(badge) -> json.string(badge)
  //             None -> json.null()
  //           }),
  //         ])
  //       })
  //     let body = json.to_string(json.array(tokens_json, fn(x) { x }))
  //     response.new(200)
  //     |> response.set_header("content-type", "application/json")
  //     |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
  //   }
  //   Error(error) -> {
  //     io.println("Error fetching tokens from Supabase: " <> string.inspect(error))
  //     // Return an appropriate error response
  //     response.new(500)
  //     |> response.set_body(mist.Bytes(bytes_tree.from_string("{\"error\":\"Failed to fetch tokens\"}")))
  //   }
  // }
  // Placeholder response until Supabase integration is complete
  let tokens = []
  // Was: get_mock_tokens()
  let tokens_json =
    list.map(tokens, fn(token: Token) {
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

fn get_all_upgrades(
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Initialize your custom Supabase client
  // TODO: Fetch upgrades from Supabase 'upgrades' table using your custom client
  // use result <- supabase.from(supabase_client, "upgrades") 
  //   |> supabase.select("*") 
  //   |> supabase.execute()
  // case result {
  //   Ok(data_dynamic) -> {
  //     // TODO: Decode data_dynamic into List(TruckUpgrade)
  //     // Similar decoding logic as in get_all_tokens
  //     let upgrades = [] // Placeholder for decoded upgrades
  //     let upgrades_json =
  //       list.map(upgrades, fn(upgrade) {
  //         json.object([
  //           #("id", json.string(upgrade.id)),
  //           #("name", json.string(upgrade.name)),
  //           #("description", json.string(upgrade.description)),
  //           #("category", json.string(upgrade.category)),
  //           #("price", json.float(upgrade.price)),
  //           #("salePrice", case upgrade.sale_price {
  //             Some(price) -> json.float(price)
  //             None -> json.null()
  //           }),
  //           #("image", json.string(upgrade.image_url)), // Ensure field name matches DB
  //           #("badge", case upgrade.badge {
  //             Some(badge) -> json.string(badge)
  //             None -> json.null()
  //           }),
  //           #(
  //             "specs", // Ensure this matches how you store/retrieve specs (e.g., JSONB)
  //             json.object(
  //               list.map(upgrade.specs, fn(spec) {
  //                 let #(key, value) = spec
  //                 #(key, json.string(value)) // If specs are List(#(String,String))
  //               }),
  //               // If specs are JSONB, you might parse it directly or map its fields
  //             ),
  //           ),
  //         ])
  //       })
  //     let body = json.to_string(json.array(upgrades_json, fn(x) { x }))
  //     response.new(200)
  //     |> response.set_header("content-type", "application/json")
  //     |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
  //   }
  //   Error(error) -> {
  //     io.println("Error fetching upgrades from Supabase: " <> string.inspect(error))
  //     response.new(500)
  //     |> response.set_body(mist.Bytes(bytes_tree.from_string("{\"error\":\"Failed to fetch upgrades\"}")))
  //   }
  // }
  // Placeholder response
  let upgrades = []
  // Was: get_mock_upgrades()
  let upgrades_json =
    list.map(upgrades, fn(upgrade: TruckUpgrade) {
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
  // TODO: Fetch user badges from Supabase 'user_badges' table if you implement this
  // For now, client-side might be handling this or it's not fully implemented.
  let body = json.to_string(json.array([], fn(x) { x }))
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn get_payment_options(
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Fetch payment options from Supabase 'payment_options_config' table using your custom client
  // use result <- supabase.from(supabase_client, "payment_options_config") 
  //             |> supabase.select("*") 
  //             |> supabase.eq("is_active", "true") // Assuming eq takes string for bool, adapt as needed
  //             |> supabase.maybe_single() // To get a single row
  //             |> supabase.execute()
  // case result {
  //   Ok(option_config_dynamic) -> // expect_single might make this Option(Dynamic) or Dynamic (if found)
  //      // case option_config_dynamic {
  //      //   Some(config_dynamic) -> 
  //      //      // TODO: Decode config_dynamic into a PaymentOptions like structure
  //      //      // let crypto_opts = CryptoOptions(...)
  //      //      // let bank_info = BankInfo(...)
  //      //      // let options = PaymentOptions(crypto: crypto_opts, bank: bank_info)
  //      //      // ... then serialize to JSON as before
  //      //   None -> // No active config found, return default or error
  //      // }
  //   Error(db_error) -> // DB error
  // }

  // Using hardcoded values as a fallback or if DB approach is not yet implemented
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
  _user_id: String,
  _token_id: String,
  body: Option(dynamic.Dynamic),
  // supabase_client: supabase.Client,
) -> Response(mist.ResponseData) {
  case body {
    Some(dynamic_body) -> {
      case decode_purchase_details(dynamic_body) {
        Ok(details) -> {
          io.println("Received token purchase request:")
          io.println("  Payment Method: " <> details.payment_method)

          // TODO: Insert into Supabase 'user_purchases' table using your custom client
          // let purchase_json_to_insert = purchase_details_to_json_for_insert(details, _user_id, _token_id, "token")
          // use insert_result <- supabase.from(supabase_client, "user_purchases")
          //                     |> supabase.insert(purchase_json_to_insert)
          //                     |> supabase.execute()
          // case insert_result {
          //   Ok(_) -> // Successfully inserted
          //   Error(db_error) -> // Handle DB insertion error
          // }

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
  _user_id: String,
  _upgrade_id: String,
  body: Option(dynamic.Dynamic),
  // supabase_client: supabase.Client,
) -> Response(mist.ResponseData) {
  case body {
    Some(dynamic_body) -> {
      case decode_purchase_details(dynamic_body) {
        Ok(details) -> {
          io.println("Received upgrade purchase request:")
          io.println("  Payment Method: " <> details.payment_method)

          // TODO: Insert into Supabase 'user_purchases' table using your custom client
          // let purchase_json_to_insert = purchase_details_to_json_for_insert(details, _user_id, _upgrade_id, "upgrade")
          // use insert_result <- supabase.from(supabase_client, "user_purchases")
          //                     |> supabase.insert(purchase_json_to_insert)
          //                     |> supabase.execute()
          // case insert_result {
          //   Ok(_) -> // Successfully inserted
          //   Error(db_error) -> // Handle DB insertion error
          // }

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

// This function defines a decoder for the Address type.
// It can be reused, for example, in other decoders for nested optional addresses.
pub fn address_field_decoder() -> decode.Decoder(Address) {
  {
    use street <- decode.field("street", decode.string)
    use city <- decode.field("city", decode.string)
    use state <- decode.field("state", decode.string)
    use zip <- decode.field("zip", decode.string)
    use country <- decode.field("country", decode.string)
    decode.success(Address(street, city, state, zip, country))
  }
}

// This function defines a decoder for the PurchaseDetails type.
pub fn purchase_details_field_decoder() -> decode.Decoder(PurchaseDetails) {
  {
    use payment_method <- decode.field("payment_method", decode.string)
    use crypto_address <- decode.field(
      "crypto_address",
      decode.optional(decode.string),
    )
    use crypto_tx_id <- decode.field(
      "crypto_tx_id",
      decode.optional(decode.string),
    )
    // For the nested optional address, we use the address_field_decoder
    use shipping_address <- decode.field(
      "shipping_address",
      decode.optional(address_field_decoder()),
      // address_field_decoder() returns Decoder(Address)
    )
    use redemption_instructions <- decode.field(
      "redemption_instructions",
      decode.optional(decode.string),
    )
    decode.success(PurchaseDetails(
      payment_method,
      crypto_address,
      crypto_tx_id,
      shipping_address,
      redemption_instructions,
    ))
  }
}

fn decode_purchase_details(
  data: dynamic.Dynamic,
) -> Result(PurchaseDetails, List(decode.DecodeError)) {
  decode.run(data, purchase_details_field_decoder())
}

fn not_found() -> Response(mist.ResponseData) {
  let error_json = json.object([#("error", json.string("Not found"))])
  let body = json.to_string(error_json)
  response.new(404)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}
// Helper function to get mock token data
// pub fn get_mock_tokens() -> List(Token) {
//   [
//     Token(
//       id: "basic-token",
//       name: "Basic Token",
//       description: "Standard token for basic truck operations",
//       price: 9.99,
//       image_url: "/images/tokens/basic.svg",
//       badge: Some("basic"),
//     ),
//     Token(
//       id: "premium-token",
//       name: "Premium Token",
//       description: "Enhanced token with additional features",
//       price: 19.99,
//       image_url: "/images/tokens/premium.svg",
//       badge: Some("premium"),
//     ),
//     Token(
//       id: "elite-token",
//       name: "Elite Token",
//       description: "Top-tier token with all features unlocked",
//       price: 29.99,
//       image_url: "/images/tokens/elite.svg",
//       badge: Some("elite"),
//     ),
//   ]
// }

// Helper function to get mock upgrade data
// pub fn get_mock_upgrades() -> List(TruckUpgrade) {
//   [
//     TruckUpgrade(
//       id: "performance-engine",
//       name: "Performance Engine",
//       description: "High-performance engine upgrade for increased power",
//       category: "engine",
//       price: 499.99,
//       sale_price: Some(449.99),
//       image_url: "/images/upgrades/engine.svg",
//       badge: Some("performance"),
//       specs: [
//         #("Power Increase", "25%"),
//         #("Fuel Efficiency", "15%"),
//         #("Installation Time", "4 hours"),
//       ],
//     ),
//     TruckUpgrade(
//       id: "luxury-cabin",
//       name: "Luxury Cabin Package",
//       description: "Premium interior upgrade with comfort features",
//       category: "interior",
//       price: 299.99,
//       sale_price: None,
//       image_url: "/images/upgrades/cabin.svg",
//       badge: Some("luxury"),
//       specs: [
//         #("Seat Type", "Premium Leather"),
//         #("Climate Control", "Dual Zone"),
//         #("Sound System", "Premium Audio"),
//       ],
//     ),
//     TruckUpgrade(
//       id: "offroad-package",
//       name: "Off-Road Package",
//       description: "Complete off-road capability upgrade",
//       category: "suspension",
//       price: 799.99,
//       sale_price: None,
//       image_url: "/images/upgrades/offroad.svg",
//       badge: Some("offroad"),
//       specs: [
//         #("Suspension", "Heavy Duty"),
//         #("Ground Clearance", "+4 inches"),
//         #("Tire Type", "All-Terrain"),
//       ],
//     ),
//   ]
// }

// TODO: Add decoders for Token and TruckUpgrade from Supabase data
// e.g., fn decode_token_from_db(data: dynamic.Dynamic) -> Result(Token, List(decode.DecodeError))
// fn decode_token_from_db_decoder() -> decode.Decoder(Token) {
//   {
//     use id <- decode.field("id", decode.string)
//     use name <- decode.field("name", decode.string)
//     use description <- decode.field("description", decode.string) // Ensure this field exists or use optional
//     use price <- decode.field("price", decode.float)
//     use image_url <- decode.field("image_url", decode.string)
//     use badge <- decode.field("badge", decode.optional(decode.string))
//     // created_at is in the DB but maybe not needed in Token struct for client
//     decode.success(Token(id, name, description, price, image_url, badge))
//   }
// }

// fn decode_upgrade_from_db_decoder() -> decode.Decoder(TruckUpgrade) {
//   {
//     use id <- decode.field("id", decode.string)
//     use name <- decode.field("name", decode.string)
//     use description <- decode.field("description", decode.string)
//     use category <- decode.field("category", decode.string)
//     use price <- decode.field("price", decode.float)
//     use sale_price <- decode.field("sale_price", decode.optional(decode.float))
//     use image_url <- decode.field("image_url", decode.string)
//     use badge <- decode.field("badge", decode.optional(decode.string))
//     // Specs will be JSONB. You'll need a strategy:
//     // 1. Decode the JSONB into a Dynamic, then further decode into List(#(String, String))
//     //    use specs_dynamic <- decode.field("specs", dynamic.dynamic)
//     //    let specs_result = decode_specs_from_dynamic(specs_dynamic)
//     //    // handle specs_result (Result(List(#(String,String)), DecodeError))
//     //    let specs = result.unwrap(specs_result, []) // example default
//     // 2. Or, if specs structure is simple and fixed, decode directly.
//     let specs = [] // Placeholder
//     decode.success(TruckUpgrade(id, name, description, category, price, sale_price, image_url, badge, specs))
//   }
// }

// TODO: Helper function to convert PurchaseDetails to a JSON for Supabase insert.
// This needs to create a json.Json value that your supabase.insert function expects.
// fn purchase_details_to_json_for_insert(
//   details: PurchaseDetails, 
//   user_id: String, 
//   item_id: String, 
//   item_type: String
// ) -> json.Json {
//   let shipping_address_json = case details.shipping_address {
//     Some(addr) -> json.object([
//       #("street", json.string(addr.street)),
//       #("city", json.string(addr.city)),
//       #("state", json.string(addr.state)),
//       #("zip", json.string(addr.zip)),
//       #("country", json.string(addr.country)),
//     ])
//     None -> json.null()
//   }
//   let purchase_details_data = json.object([
//     #("payment_method", json.string(details.payment_method)),
//     #("crypto_address", option.map(details.crypto_address, json.string) |> option.unwrap(json.null())),
//     #("crypto_tx_id", option.map(details.crypto_tx_id, json.string) |> option.unwrap(json.null())),
//     #("shipping_address", shipping_address_json),
//     #("redemption_instructions", option.map(details.redemption_instructions, json.string) |> option.unwrap(json.null())),
//   ])
//   // Supabase often expects a list of records for insert, even if it's a single record.
//   // Adjust if your supabase.insert takes a single json.Json record directly.
//   // json.array([json.object([
//   //   #("user_id", json.string(user_id)),
//   //   #("item_id", json.string(item_id)),
//   //   #("item_type", json.string(item_type)),
//   //   #("purchase_details", purchase_details_data), // Storing the nested JSON here
//   // ])], fn(x) { x })
//   // OR if supabase.insert takes a single object:
//   json.object([
//     #("user_id", json.string(user_id)),
//     #("item_id", json.string(item_id)),
//     #("item_type", json.string(item_type)),
//     #("purchase_details", purchase_details_data),
//   ])
// }
// fn add_token_to_badges(
//   _user_id: String,
//   _token_id: String,
// ... existing code ...
//   _user_id: String,
//   _upgrade_id: String,
// ) -> Response(mist.ResponseData) {
//   todo
//   // ... existing code ...
// }
