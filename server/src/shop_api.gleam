import gleam/dynamic
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/bytes_builder
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData, Bytes, Text}
import turso_db
import shop
import glibsql

pub fn register_routes(req: Request(Connection)) -> Response(ResponseData) {
  case request.path_segments(req) {
    ["api", "shop", "products"] -> {
      case req.method {
        Get -> get_products(req)
        Post -> create_product(req)
        _ -> not_allowed()
      }
    }
    ["api", "shop", "products", id] -> {
      case req.method {
        Get -> get_product_by_id(req, id)
        _ -> not_allowed()
      }
    }
    ["api", "shop", "orders"] -> {
      case req.method {
        Get -> get_orders(req)
        Post -> create_order(req)
        _ -> not_allowed()
      }
    }
    ["api", "shop", "orders", id] -> {
      case req.method {
        Get -> get_order_by_id(req, id)
        _ -> not_allowed()
      }
    }
    _ -> response.new(404)
      |> response.set_body(Text("Not found"))
  }
}

fn get_products(req: Request(Connection)) -> Response(ResponseData) {
  let page = case request.get_query(req, "page") {
    Ok(page_str) -> {
      case int.parse(page_str) {
        Ok(page) -> case page > 0 {
          True -> page
          False -> 1
        }
        Error(_) -> 1
      }
    }
    Error(_) -> 1
  }
  
  let page_size = case request.get_query(req, "limit") {
    Ok(limit_str) -> {
      case int.parse(limit_str) {
        Ok(limit) -> case limit > 0 && limit <= 100 {
          True -> limit
          False -> 20
        }
        Error(_) -> 20
      }
    }
    Error(_) -> 20
  }
  
  case turso_db.get_connection() {
    Ok(conn) -> {
      let result = shop.get_all_products(conn, page, page_size)
      let _ = turso_db.close_connection(conn)
      
      case result {
        Ok(products) -> {
          let products_json = list.map(
            products,
            fn(product) {
              json.object([
                #("id", json.int(product.id)),
                #("name", json.string(product.name)),
                #("description", json.string(product.description)),
                #("price", json.float(product.price)),
                #("sku", json.string(product.sku)),
                #("stock_quantity", json.int(product.stock_quantity)),
                #("status", json.string(product.status)),
                #("created_at", json.string(product.created_at)),
                #("updated_at", json.string(product.updated_at)),
              ])
            },
          )
          
          let response_json = json.object([
            #("data", json.array(products_json)),
            #("meta", json.object([
              #("page", json.int(page)),
              #("page_size", json.int(page_size)),
              #("total_count", json.int(list.length(products))),
            ])),
          ])
          
          response.new(200)
            |> response.set_header("content-type", "application/json")
            |> response.set_body(Text(json.to_string(response_json)))
        }
        Error(err) -> {
          let error_json = json.object([
            #("error", json.string(shop_error_to_string(err))),
          ])
          
          response.new(500)
            |> response.set_header("content-type", "application/json")
            |> response.set_body(Text(json.to_string(error_json)))
        }
      }
    }
    Error(_) -> {
      response.new(500)
        |> response.set_body(Text("Database connection error"))
    }
  }
}

fn create_product(req: Request(Connection)) -> Response(ResponseData) {
  case mist.read_body(req, 1024 * 1024) {
    Ok(req) -> {
      case parse_product_json(req.body) {
        Ok(#(name, description, price, sku, stock_quantity)) -> {
          case turso_db.get_connection() {
            Ok(conn) -> {
              let result = shop.create_product(conn, name, description, price, sku, stock_quantity)
              let _ = turso_db.close_connection(conn)
              
              case result {
                Ok(product) -> {
                  let product_json = json.object([
                    #("id", json.int(product.id)),
                    #("name", json.string(product.name)),
                    #("description", json.string(product.description)),
                    #("price", json.float(product.price)),
                    #("sku", json.string(product.sku)),
                    #("stock_quantity", json.int(product.stock_quantity)),
                    #("status", json.string(product.status)),
                    #("created_at", json.string(product.created_at)),
                    #("updated_at", json.string(product.updated_at)),
                  ])
                  
                  response.new(201)
                    |> response.set_header("content-type", "application/json")
                    |> response.set_body(Text(json.to_string(product_json)))
                }
                Error(err) -> {
                  let error_json = json.object([
                    #("error", json.string(shop_error_to_string(err))),
                  ])
                  
                  response.new(500)
                    |> response.set_header("content-type", "application/json")
                    |> response.set_body(Text(json.to_string(error_json)))
                }
              }
            }
            Error(_) -> {
              response.new(500)
                |> response.set_body(Text("Database connection error"))
            }
          }
        }
        Error(reason) -> {
          let error_json = json.object([
            #("error", json.string("Invalid request: " <> reason)),
          ])
          
          response.new(400)
            |> response.set_header("content-type", "application/json")
            |> response.set_body(Text(json.to_string(error_json)))
        }
      }
    }
    Error(_) -> {
      response.new(400)
        |> response.set_body(Text("Invalid request body"))
    }
  }
}

fn get_product_by_id(req: Request(Connection), id_str: String) -> Response(ResponseData) {
  case int.parse(id_str) {
    Ok(id) -> {
      case turso_db.get_connection() {
        Ok(conn) -> {
          let result = shop.get_product(conn, id)
          let _ = turso_db.close_connection(conn)
          
          case result {
            Ok(product) -> {
              let product_json = json.object([
                #("id", json.int(product.id)),
                #("name", json.string(product.name)),
                #("description", json.string(product.description)),
                #("price", json.float(product.price)),
                #("sku", json.string(product.sku)),
                #("stock_quantity", json.int(product.stock_quantity)),
                #("status", json.string(product.status)),
                #("created_at", json.string(product.created_at)),
                #("updated_at", json.string(product.updated_at)),
              ])
              
              response.new(200)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(Text(json.to_string(product_json)))
            }
            Error(shop.ProductNotFound(_)) -> {
              let error_json = json.object([
                #("error", json.string("Product not found")),
              ])
              
              response.new(404)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(Text(json.to_string(error_json)))
            }
            Error(err) -> {
              let error_json = json.object([
                #("error", json.string(shop_error_to_string(err))),
              ])
              
              response.new(500)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(Text(json.to_string(error_json)))
            }
          }
        }
        Error(_) -> {
          response.new(500)
            |> response.set_body(Text("Database connection error"))
        }
      }
    }
    Error(_) -> {
      response.new(400)
        |> response.set_body(Text("Invalid product ID"))
    }
  }
}

fn create_order(req: Request(Connection)) -> Response(ResponseData) {
  case mist.read_body(req, 1024 * 1024) {
    Ok(req) -> {
      case parse_order_json(req.body) {
        Ok(#(user_id, cart_items)) -> {
          case turso_db.get_connection() {
            Ok(conn) -> {
              let result = shop.create_order(conn, user_id, cart_items)
              let _ = turso_db.close_connection(conn)
              
              case result {
                Ok(#(order, items)) -> {
                  let order_json = json.object([
                    #("id", json.int(order.id)),
                    #("user_id", case order.user_id {
                      Some(id) -> json.int(id)
                      None -> json.null()
                    }),
                    #("status", json.string(order.status)),
                    #("total_amount", json.float(order.total_amount)),
                    #("created_at", json.string(order.created_at)),
                    #("updated_at", json.string(order.updated_at)),
                    #("items", json.array(list.map(
                      items,
                      fn(item) {
                        json.object([
                          #("id", json.int(item.id)),
                          #("product_id", json.int(item.product_id)),
                          #("quantity", json.int(item.quantity)),
                          #("price", json.float(item.price)),
                          #("product_name", case item.product_name {
                            Some(name) -> json.string(name)
                            None -> json.null()
                          }),
                          #("sku", case item.sku {
                            Some(sku) -> json.string(sku)
                            None -> json.null()
                          }),
                        ])
                      }
                    ))),
                  ])
                  
                  response.new(201)
                    |> response.set_header("content-type", "application/json")
                    |> response.set_body(Text(json.to_string(order_json)))
                }
                Error(err) -> {
                  let error_json = json.object([
                    #("error", json.string(shop_error_to_string(err))),
                  ])
                  
                  let status = case err {
                    shop.ProductNotFound(_) -> 404
                    shop.InsufficientStock(_, _, _) -> 400
                    shop.InvalidQuantity(_, _) -> 400
                    _ -> 500
                  }
                  
                  response.new(status)
                    |> response.set_header("content-type", "application/json")
                    |> response.set_body(Text(json.to_string(error_json)))
                }
              }
            }
            Error(_) -> {
              response.new(500)
                |> response.set_body(Text("Database connection error"))
            }
          }
        }
        Error(reason) -> {
          let error_json = json.object([
            #("error", json.string("Invalid request: " <> reason)),
          ])
          
          response.new(400)
            |> response.set_header("content-type", "application/json")
            |> response.set_body(Text(json.to_string(error_json)))
        }
      }
    }
    Error(_) -> {
      response.new(400)
        |> response.set_body(Text("Invalid request body"))
    }
  }
}

fn get_order_by_id(req: Request(Connection), id_str: String) -> Response(ResponseData) {
  case int.parse(id_str) {
    Ok(id) -> {
      case turso_db.get_connection() {
        Ok(conn) -> {
          let result = shop.get_order(conn, id)
          let _ = turso_db.close_connection(conn)
          
          case result {
            Ok(#(order, items)) -> {
              let order_json = json.object([
                #("id", json.int(order.id)),
                #("user_id", case order.user_id {
                  Some(id) -> json.int(id)
                  None -> json.null()
                }),
                #("status", json.string(order.status)),
                #("total_amount", json.float(order.total_amount)),
                #("created_at", json.string(order.created_at)),
                #("updated_at", json.string(order.updated_at)),
                #("items", json.array(list.map(
                  items,
                  fn(item) {
                    json.object([
                      #("id", json.int(item.id)),
                      #("product_id", json.int(item.product_id)),
                      #("quantity", json.int(item.quantity)),
                      #("price", json.float(item.price)),
                      #("product_name", case item.product_name {
                        Some(name) -> json.string(name)
                        None -> json.null()
                      }),
                      #("sku", case item.sku {
                        Some(sku) -> json.string(sku)
                        None -> json.null()
                      }),
                    ])
                  }
                ))),
              ])
              
              response.new(200)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(Text(json.to_string(order_json)))
            }
            Error(shop.OrderNotFound(_)) -> {
              let error_json = json.object([
                #("error", json.string("Order not found")),
              ])
              
              response.new(404)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(Text(json.to_string(error_json)))
            }
            Error(err) -> {
              let error_json = json.object([
                #("error", json.string(shop_error_to_string(err))),
              ])
              
              response.new(500)
                |> response.set_header("content-type", "application/json")
                |> response.set_body(Text(json.to_string(error_json)))
            }
          }
        }
        Error(_) -> {
          response.new(500)
            |> response.set_body(Text("Database connection error"))
        }
      }
    }
    Error(_) -> {
      response.new(400)
        |> response.set_body(Text("Invalid order ID"))
    }
  }
}

fn get_orders(req: Request(Connection)) -> Response(ResponseData) {
  // This is a placeholder - implement order listing with filtering/pagination
  response.new(501)
    |> response.set_body(Text("Not implemented"))
}

// Helper functions

fn not_allowed() -> Response(ResponseData) {
  response.new(405)
    |> response.set_body(Text("Method not allowed"))
}

fn parse_product_json(body: String) -> Result(#(String, String, Float, String, Int), String) {
  let json_result = json.decode(body, dynamic.decoder())
  
  case json_result {
    Ok(json_value) -> {
      use name <- result.try(dynamic.field(json_value, "name")
        |> result.then(dynamic.string)
        |> result.map_error(fn(_) { "Missing or invalid name field" }))
      
      use description <- result.try(dynamic.field(json_value, "description")
        |> result.then(dynamic.string)
        |> result.map_error(fn(_) { "Missing or invalid description field" }))
      
      use price <- result.try(dynamic.field(json_value, "price")
        |> result.then(dynamic.float)
        |> result.map_error(fn(_) { "Missing or invalid price field" }))
      
      use sku <- result.try(dynamic.field(json_value, "sku")
        |> result.then(dynamic.string)
        |> result.map_error(fn(_) { "Missing or invalid sku field" }))
      
      use stock_quantity <- result.try(dynamic.field(json_value, "stock_quantity")
        |> result.then(dynamic.int)
        |> result.map_error(fn(_) { "Missing or invalid stock_quantity field" }))
      
      // Validation
      case price <= 0.0 {
        True -> Error("Price must be greater than zero")
        False -> case stock_quantity < 0 {
          True -> Error("Stock quantity cannot be negative")
          False -> Ok(#(name, description, price, sku, stock_quantity))
        }
      }
    }
    Error(_) -> Error("Invalid JSON format")
  }
}

fn parse_order_json(body: String) -> Result(#(Option(Int), List(shop.CartItem)), String) {
  let json_result = json.decode(body, dynamic.decoder())
  
  case json_result {
    Ok(json_value) -> {
      // User ID is optional
      let user_id = dynamic.field(json_value, "user_id")
        |> result.then(dynamic.int)
        |> result.map(Some)
        |> result.unwrap(None)
      
      use items_json <- result.try(dynamic.field(json_value, "items")
        |> result.then(dynamic.list)
        |> result.map_error(fn(_) { "Missing or invalid items field" }))
      
      use cart_items <- result.try(items_json
        |> list.try_map(fn(item_json) {
          use product_id <- result.try(dynamic.field(item_json, "product_id")
            |> result.then(dynamic.int)
            |> result.map_error(fn(_) { "Missing or invalid product_id in item" }))
          
          use quantity <- result.try(dynamic.field(item_json, "quantity")
            |> result.then(dynamic.int)
            |> result.map_error(fn(_) { "Missing or invalid quantity in item" }))
          
          use unit_price <- result.try(dynamic.field(item_json, "unit_price")
            |> result.then(dynamic.float)
            |> result.map_error(fn(_) { "Missing or invalid unit_price in item" }))
          
          use name <- result.try(dynamic.field(item_json, "name")
            |> result.then(dynamic.string)
            |> result.map_error(fn(_) { "Missing or invalid name in item" }))
          
          use sku <- result.try(dynamic.field(item_json, "sku")
            |> result.then(dynamic.string)
            |> result.map_error(fn(_) { "Missing or invalid sku in item" }))
          
          // Validation
          case quantity <= 0 {
            True -> Error("Quantity must be greater than zero")
            False -> case unit_price <= 0.0 {
              True -> Error("Unit price must be greater than zero")
              False -> Ok(shop.CartItem(
                product_id: product_id,
                quantity: quantity,
                unit_price: unit_price,
                name: name,
                sku: sku,
              ))
            }
          }
        })
        |> result.map_error(fn(err) { "Invalid item: " <> err }))
      
      // Ensure we have at least one item
      case list.is_empty(cart_items) {
        True -> Error("Order must contain at least one item")
        False -> Ok(#(user_id, cart_items))
      }
    }
    Error(_) -> Error("Invalid JSON format")
  }
}

fn shop_error_to_string(err: shop.ShopError) -> String {
  case err {
    shop.DatabaseError(db_err) -> "Database error: " <> db_error_to_string(db_err)
    shop.ProductNotFound(id) -> "Product not found: " <> int.to_string(id)
    shop.InsufficientStock(id, requested, available) -> 
      "Insufficient stock for product " <> int.to_string(id) <> 
      ": requested " <> int.to_string(requested) <> 
      ", available " <> int.to_string(available)
    shop.InvalidQuantity(id, quantity) -> 
      "Invalid quantity for product " <> int.to_string(id) <> 
      ": " <> int.to_string(quantity)
    shop.OrderNotFound(id) -> "Order not found: " <> int.to_string(id)
    shop.OrderAlreadyCompleted(id) -> "Order already completed: " <> int.to_string(id)
  }
}

fn db_error_to_string(err: turso_db.DbError) -> String {
  case err {
    turso_db.ConnectionError(msg) -> "Connection error: " <> msg
    turso_db.QueryError(msg) -> "Query error: " <> msg
    turso_db.TransactionError(msg) -> "Transaction error: " <> msg
    turso_db.NoResultError -> "No result found"
    turso_db.ParseError(msg) -> "Parse error: " <> msg
  }
}