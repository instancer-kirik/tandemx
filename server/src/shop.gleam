import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/list
import gleam/string
import gleam/int
import gleam/io
import turso_db.{type DbError, type DbPool}
import glibsql

// Product types
pub type Product {
  Product(
    id: Int,
    name: String,
    description: String,
    price: Float,
    sku: String,
    stock_quantity: Int,
    status: String,
    created_at: String,
    updated_at: String,
  )
}

// Order types
pub type Order {
  Order(
    id: Int,
    user_id: Option(Int),
    status: String,
    total_amount: Float,
    created_at: String,
    updated_at: String,
  )
}

pub type OrderItem {
  OrderItem(
    id: Int,
    order_id: Int,
    product_id: Int,
    quantity: Int,
    price: Float,
    created_at: String,
    product_name: Option(String),
    sku: Option(String),
  )
}

pub type CartItem {
  CartItem(
    product_id: Int,
    quantity: Int,
    unit_price: Float,
    name: String,
    sku: String,
  )
}

pub type ShopError {
  DatabaseError(DbError)
  ProductNotFound(Int)
  InsufficientStock(Int, Int, Int)  // product_id, requested, available
  InvalidQuantity(Int, Int)  // product_id, quantity
  OrderNotFound(Int)
  OrderAlreadyCompleted(Int)
}

// Product operations
pub fn create_product(
  conn: DbPool,
  name: String,
  description: String,
  price: Float,
  sku: String,
  stock_quantity: Int,
) -> Result(Product, ShopError) {
  case turso_db.create_product(conn, name, description, price, sku, stock_quantity) {
    Ok(row) -> {
      decode_product(row)
      |> result.map_error(fn(err) { DatabaseError(err) })
    }
    Error(err) -> Error(DatabaseError(err))
  }
}

pub fn get_product(
  conn: DbPool,
  id: Int,
) -> Result(Product, ShopError) {
  case turso_db.get_product(conn, id) {
    Ok(Some(row)) -> {
      decode_product(row)
      |> result.map_error(fn(err) { DatabaseError(err) })
    }
    Ok(None) -> Error(ProductNotFound(id))
    Error(err) -> Error(DatabaseError(err))
  }
}

pub fn get_all_products(
  conn: DbPool,
  page: Int,
  page_size: Int,
) -> Result(List(Product), ShopError) {
  let limit = page_size
  let offset = { page - 1 } * page_size

  case turso_db.get_all_products(conn, limit, offset) {
    Ok(rows) -> {
      rows
      |> list.try_map(decode_product)
      |> result.map_error(fn(err) { DatabaseError(err) })
    }
    Error(err) -> Error(DatabaseError(err))
  }
}

// Helper functions
pub fn decode_product(row: glibsql.Row) -> Result(Product, DbError) {
  case turso_db.extract_int(row, "id") {
    Ok(id) -> {
      case turso_db.extract_string(row, "name") {
        Ok(name) -> {
          case turso_db.extract_string(row, "description") {
            Ok(description) -> {
              case turso_db.extract_float(row, "price") {
                Ok(price) -> {
                  case turso_db.extract_string(row, "sku") {
                    Ok(sku) -> {
                      case turso_db.extract_int(row, "stock_quantity") {
                        Ok(stock_quantity) -> {
                          case turso_db.extract_string(row, "status") {
                            Ok(status) -> {
                              case turso_db.extract_string(row, "created_at") {
                                Ok(created_at) -> {
                                  case turso_db.extract_string(row, "updated_at") {
                                    Ok(updated_at) -> {
                                      Ok(Product(
                                        id: id,
                                        name: name,
                                        description: description,
                                        price: price,
                                        sku: sku,
                                        stock_quantity: stock_quantity,
                                        status: status,
                                        created_at: created_at,
                                        updated_at: updated_at,
                                      ))
                                    }
                                    Error(err) -> Error(err)
                                  }
                                }
                                Error(err) -> Error(err)
                              }
                            }
                            Error(err) -> Error(err)
                          }
                        }
                        Error(err) -> Error(err)
                      }
                    }
                    Error(err) -> Error(err)
                  }
                }
                Error(err) -> Error(err)
              }
            }
            Error(err) -> Error(err)
          }
        }
        Error(err) -> Error(err)
      }
    }
    Error(err) -> Error(err)
  }
}