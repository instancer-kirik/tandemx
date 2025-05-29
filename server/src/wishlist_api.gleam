import gleam/bytes_tree

import gleam/http.{Delete, Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{type Option}

import gleam/string
import mist

// TODO: Implement wishlist module
// import tandemx_server/wishlist.{type Product, type WishlistItem}
// import tandemx_server/wishlist_supabase

// Conceptual Supabase client import - you will need to implement or find this library
// import supabase
// import supabase/client exposing (Client)
// import supabase/query // For query building if your lib has it

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
    // Assuming specs will be decoded from JSONB into a suitable Gleam structure
    // For example, a List(#(String, String)) or a custom Specs type
    specs: List(#(String, String)),
  )
}

// ProductSpec type might not be needed if specs are directly in Product struct
// pub type ProductSpec {
//   ProductSpec(id: Int, product_id: String, spec_key: String, spec_value: String)
// }

pub type CartItem {
  CartItem(
    id: Int,
    product_id: String,
    user_id: String,
    quantity: Int,
    added_at: String,
  )
}

// TODO: Define your Supabase client initialization logic
// This might be done globally in dev_server.gleam and passed around,
// or initialized per request/module if simpler for your library design.
// fn init_supabase_client() -> supabase.Client {
//   supabase.create("YOUR_SUPABASE_URL", "YOUR_SUPABASE_KEY")
// }

pub fn handle_wishlist_request(
  req: Request(String),
  // supabase_client: supabase.Client, // Ideally pass client from dev_server. Changed from client.Client
) -> Response(mist.ResponseData) {
  // let supabase_client = init_supabase_client() // Or init here if not passed
  let path = req.path |> string.split("/") |> list.drop(2)

  case path, req.method {
    // GET /api/wishlist/products - List all products
    ["products"], Get -> get_all_products()

    // Pass supabase_client
    // GET /api/wishlist/products/:id - Get product by ID
    ["products", product_id], Get -> get_product(product_id)

    // Pass supabase_client
    // GET /api/wishlist/:user_id - Get user's wishlist
    [user_id], Get -> get_user_wishlist(user_id)

    // Pass supabase_client
    // POST /api/wishlist/:user_id/:product_id - Add product to wishlist
    [user_id, product_id], Post -> add_to_wishlist(user_id, product_id)

    // Pass supabase_client
    // DELETE /api/wishlist/:user_id/:product_id - Remove product from wishlist
    [user_id, product_id], Delete -> remove_from_wishlist(user_id, product_id)

    // Pass supabase_client
    // GET /api/wishlist/cart/:user_id - Get user's cart
    ["cart", user_id], Get -> get_user_cart(user_id)

    // Pass supabase_client
    // POST /api/wishlist/cart/:user_id/:product_id - Add product to cart
    ["cart", user_id, product_id], Post -> add_to_cart(user_id, product_id)

    // Pass supabase_client
    // DELETE /api/wishlist/cart/:user_id/:product_id - Remove product from cart
    ["cart", user_id, product_id], Delete ->
      remove_from_cart(user_id, product_id)

    // Pass supabase_client
    _, _ -> not_found()
  }
}

fn get_all_products(
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to fetch all products from 'products' table
  // let supabase_client = init_supabase_client()
  // use db_result <- supabase.from(supabase_client, "products")
  //   |> supabase.select("*") 
  //   |> supabase.execute()
  // case db_result {
  //   Ok(product_dynamics_list_dynamic) -> 
  //     // Assuming execute returns a single dynamic which could be a list
  //     case dynamic.dynamic_to_list(product_dynamics_list_dynamic) {
  //        Ok(product_dynamics) -> {
  //            let products_result = list.try_map(product_dynamics, decode.run(_, product_decoder()))
  //            case products_result {
  //               Ok(decoded_products) -> {
  //                  let products_json = list.map(decoded_products, product_to_json)
  //                  let body = json.to_string(json.array(products_json, fn(x) { x }))
  //                  response.new(200)
  //                  |> response.set_header("content-type", "application/json")
  //                  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
  //               }
  //               Error(decode_error) -> bad_request("Failed to decode products: " <> string.inspect(decode_error))
  //            }
  //        }
  //        Error(_) -> bad_request("Products data is not a list")
  //     }
  //   Error(db_error) -> internal_server_error("Database error fetching products: " <> string.inspect(db_error))
  // }
  // Placeholder response:
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string("[]")))
}

fn get_product(
  _product_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to fetch a single product by ID
  // let supabase_client = init_supabase_client()
  // use db_result <- supabase.from(supabase_client, "products")
  //   |> supabase.select("*")
  //   |> supabase.eq("id", product_id) // Assuming eq takes String, adjust if it takes Dynamic
  //   |> supabase.maybe_single() 
  //   |> supabase.execute()
  // case db_result {
  //   Ok(product_dynamic) -> // maybe_single might make this Option(Dynamic) or Dynamic (if found)
  //     // If product_dynamic is Option(Dynamic), unwrap it first
  //     // case product_dynamic {
  //     //   Some(actual_dynamic) -> 
  //     //     case decode.run(actual_dynamic, product_decoder()) {
  //     //       Ok(product) -> { ... }
  //     //       Error(decode_error) -> ...
  //     //     }
  //     //   None -> not_found()
  //     // }
  //     // If product_dynamic is Dynamic and can represent null/not found implicitly by execute:
  //     case decode.run(product_dynamic, product_decoder()) { // This assumes execute returns Dynamic that might be decodable to Product or not
  //       Ok(product) -> {
  //         let body = json.to_string(product_to_json(product))
  //         response.new(200)
  //         |> response.set_header("content-type", "application/json")
  //         |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
  //       }
  //       Error(decode_error) -> { // This could be due to not found OR actual decode error
  //          // You'd need a way for your supabase.execute() to distinguish "not found" from "decode error"
  //          // or handle it here by checking the error type if execute returns a more specific error.
  //          // For now, assuming a decode error means it wasn't a valid product (could be not found).
  //          io.println("Decode error for product: " <> string.inspect(decode_error))
  //          not_found() // Or bad_request if it's a clear decode error on existing data
  //       }
  //     }
  //   Error(db_error) -> internal_server_error("Database error fetching product: " <> string.inspect(db_error))
  // }
  // Placeholder response:
  not_found()
}

fn get_user_wishlist(
  _user_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to fetch wishlist items for a user_id
  // Join with 'products' table to get product details or fetch product details separately.
  // Example: Fetching product_ids first, then fetching full product details.
  // let supabase_client = init_supabase_client()
  // use wishlist_items_result <- supabase.from(supabase_client, "user_wishlist_items")
  //   |> supabase.select("product_id") // Or select all fields of user_wishlist_items if needed
  //   |> supabase.eq("user_id", user_id)
  //   |> supabase.execute()
  // case wishlist_items_result {
  //    Ok(wishlist_dynamics_list_dynamic) -> {
  //        // Assuming this is a list of {product_id: "..."} objects
  //        // case dynamic.dynamic_to_list(wishlist_dynamics_list_dynamic) {
  //        //    Ok(wishlist_dynamics) -> {
  //        //        // Extract product_ids. This requires a decoder for the simple {product_id: ...} structure
  //        //        // Then, fetch full product details for these product_ids (e.g., using an 'in' filter)
  //        //        // This part needs careful implementation for efficiency and error handling
  //        //        // For now, just returning empty
  //        //    }
  //        //    Error(_) -> bad_request("Wishlist data is not a list")
  //        // }
  //    }
  //    Error(db_err) -> internal_server_error("Failed to fetch wishlist: " <> string.inspect(db_err))
  // }
  // Placeholder response:
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string("[]")))
}

fn add_to_wishlist(
  _user_id: String,
  _product_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to insert into 'user_wishlist_items' table
  // let supabase_client = init_supabase_client()
  // let item_to_insert_json = json.object([
  //   #("user_id", json.string(user_id)),
  //   #("product_id", json.string(product_id)),
  //   // added_at can be defaulted by DB
  // ])
  // use insert_result <- supabase.from(supabase_client, "user_wishlist_items")
  //   |> supabase.insert(item_to_insert_json) // Assuming insert takes json.Json
  //   |> supabase.execute()
  // case insert_result {
  //   Ok(_) -> success_response("Item added to wishlist")
  //   Error(db_error) -> 
  //     // Handle potential unique constraint violation (item already in wishlist)
  //     // and other db errors. SupabaseError type in your client should help differentiate.
  //     io.println("Failed to add to wishlist: " <> string.inspect(db_error))
  //     internal_server_error("Failed to add item to wishlist")
  // }
  // Placeholder response:
  success_response("Item added to wishlist (mocked)")
}

fn remove_from_wishlist(
  _user_id: String,
  _product_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to delete from 'user_wishlist_items' table
  // let supabase_client = init_supabase_client()
  // use delete_result <- supabase.from(supabase_client, "user_wishlist_items")
  //   |> supabase.delete()
  //   |> supabase.eq("user_id", user_id)
  //   |> supabase.eq("product_id", product_id)
  //   |> supabase.execute()
  // case delete_result {
  //   Ok(_) -> success_response("Item removed from wishlist")
  //   Error(db_error) -> 
  //     io.println("Failed to remove from wishlist: " <> string.inspect(db_error))
  //     internal_server_error("Failed to remove item from wishlist")
  // }
  // Placeholder response:
  success_response("Item removed from wishlist (mocked)")
}

fn get_user_cart(
  _user_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call similar to get_user_wishlist but for 'user_cart_items'
  // Remember to fetch quantity as well.
  // Placeholder response:
  response.new(200)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string("[]")))
}

fn add_to_cart(
  _user_id: String,
  _product_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to insert into 'user_cart_items' table.
  // Handle logic for incrementing quantity if item already in cart (upsert or select then insert/update).
  // Example for insert (without upsert logic):
  // let supabase_client = init_supabase_client()
  // let item_to_insert_json = json.object([
  //   #("user_id", json.string(user_id)),
  //   #("product_id", json.string(product_id)),
  //   #("quantity", json.int(1)), // Default quantity
  // ])
  // use insert_result <- supabase.from(supabase_client, "user_cart_items")
  //   |> supabase.insert(item_to_insert_json)
  //   |> supabase.execute()
  // case insert_result {
  //   Ok(_) -> success_response("Item added to cart")
  //   Error(db_error) -> 
  //      io.println("Failed to add to cart: " <> string.inspect(db_error))
  //      internal_server_error("Failed to add item to cart")
  // }
  // Placeholder response:
  success_response("Item added to cart (mocked)")
}

fn remove_from_cart(
  _user_id: String,
  _product_id: String,
  // supabase_client: supabase.Client
) -> Response(mist.ResponseData) {
  // TODO: Implement Supabase call to delete from 'user_cart_items' table.
  // Or decrement quantity, and delete if quantity becomes 0.
  // Example for direct delete:
  // let supabase_client = init_supabase_client()
  // use delete_result <- supabase.from(supabase_client, "user_cart_items")
  //   |> supabase.delete()
  //   |> supabase.eq("user_id", user_id)
  //   |> supabase.eq("product_id", product_id)
  //   |> supabase.execute()
  // case delete_result {
  //   Ok(_) -> success_response("Item removed from cart")
  //   Error(db_error) -> 
  //     io.println("Failed to remove from cart: " <> string.inspect(db_error))
  //     internal_server_error("Failed to remove from cart")
  // }
  // Placeholder response:
  success_response("Item removed from cart (mocked)")
}

fn not_found() -> Response(mist.ResponseData) {
  response_builder(404, json.object([#("error", json.string("Not found"))]))
}

fn success_response(message: String) -> Response(mist.ResponseData) {
  response_builder(
    200,
    json.object([
      #("success", json.bool(True)),
      #("message", json.string(message)),
    ]),
  )
}

fn response_builder(
  status: Int,
  body_json: json.Json,
) -> Response(mist.ResponseData) {
  let body = json.to_string(body_json)
  response.new(status)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}
// --- Decoders and Encoders --- 

// TODO: Implement a decoder for the Product type using gleam/dynamic/decode
// fn product_decoder() -> decode.Decoder(Product) {
//   {
//     use id <- decode.field("id", decode.string)
//     use name <- decode.field("name", decode.string)
//     use description <- decode.field("description", decode.string)
//     use category <- decode.field("category", decode.string)
//     use price <- decode.field("price", decode.float)
//     use sale_price <- decode.field("sale_price", decode.optional(decode.float))
//     use image_url <- decode.field("image_url", decode.string)
//     use badge <- decode.field("badge", decode.optional(decode.string))
//     // Decoding specs from JSONB:
//     // This assumes specs is stored as a JSON object like {"key1":"val1", "key2":"val2"}
//     // and you want to convert it to List(#(String, String))
//     use specs_dynamic <- decode.field("specs", dynamic.dynamic) // Get the raw JSONB as Dynamic
//     let specs_result = // Placeholder for actual decoding logic
//       case specs_dynamic {
//         dynamic.Object(map) -> {
//           use entries <- result.try(dict.to_list(map))
//           list.try_map(entries, fn(item) {
//             let #(key, value_dynamic) = item
//             case value_dynamic {
//               dynamic.String(s) -> Ok(#(key, s))
//               // Add other expected types or error for unexpected types
//               _ -> Error(decode.DecodeError(expected: "String for spec value", found: string.inspect(value_dynamic), path: [key]))
//             }
//           })
//         }
//         _ -> Error(decode.DecodeError(expected: "Object for specs", found: string.inspect(specs_dynamic), path: ["specs"]))
//       }
//     let specs = result.unwrap(specs_result, []) // Default to empty list on decode error for specs
//     decode.success(Product(id, name, description, category, price, sale_price, image_url, badge, specs))
//   }
// }

// TODO: Implement a function to convert Product to json.Json for responses
// fn product_to_json(product: Product) -> json.Json {
//   json.object([
//     #("id", json.string(product.id)),
//     #("name", json.string(product.name)),
//     #("description", json.string(product.description)),
//     #("category", json.string(product.category)),
//     #("price", json.float(product.price)),
//     #("salePrice", case product.sale_price {
//       Some(price) -> json.float(price)
//       None -> json.null()
//     }),
//     #("image", json.string(product.image_url)),
//     #("badge", case product.badge {
//       Some(badge) -> json.string(badge)
//       None -> json.null()
//     }),
//     #(
//       "specs",
//       json.object(
//         list.map(product.specs, fn(spec) {
//           let #(key, value) = spec
//           #(key, json.string(value))
//         }),
//       ),
//     ),
//     // Assumes specs is List(#(String,String))
//   ])
// }

// TODO: Implement decoders for WishlistItem and CartItem if needed for processing DB results
// directly into these types for internal logic, though often you might just use product details.

// Removed mock data functions: get_mock_products() and get_mock_specs()
