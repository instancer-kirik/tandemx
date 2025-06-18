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

fn not_allowed() -> Response(ResponseData) {
  response.new(405)
    |> response.set_body(Text("Method not allowed"))
}

fn parse_product_json(body: String) -> Result(#(String, String, Float, String, Int), String) {
  let json_result = json.decode(body, dynamic.decoder())
  
  case json_result {
    Ok(json_value) -> {
      // First get name
      let name_result = dynamic.field(json_value, "name")
        |> result.then(dynamic.string)
      
      case name_result {
        Error(_) -> Error("Missing or invalid name field")
        Ok(name) -> {
          // Then description
          let description_result = dynamic.field(json_value, "description")
            |> result.then(dynamic.string)
          
          case description_result {
            Error(_) -> Error("Missing or invalid description field")
            Ok(description) -> {
              // Then price
              let price_result = dynamic.field(json_value, "price")
                |> result.then(dynamic.float)
              
              case price_result {
                Error(_) -> Error("Missing or invalid price field")
                Ok(price) -> {
                  // Then sku
                  let sku_result = dynamic.field(json_value, "sku")
                    |> result.then(dynamic.string)
                  
                  case sku_result {
                    Error(_) -> Error("Missing or invalid sku field")
                    Ok(sku) -> {
                      // Finally stock_quantity
                      let stock_result = dynamic.field(json_value, "stock_quantity")
                        |> result.then(dynamic.int)
                      
                      case stock_result {
                        Error(_) -> Error("Missing or invalid stock_quantity field")
                        Ok(stock_quantity) -> {
                          // Validation
                          case price <= 0.0 {
                            True -> Error("Price must be greater than zero")
                            False -> case stock_quantity < 0 {
                              True -> Error("Stock quantity cannot be negative")
                              False -> Ok(#(name, description, price, sku, stock_quantity))
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
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