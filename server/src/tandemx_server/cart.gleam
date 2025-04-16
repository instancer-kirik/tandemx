import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type CartItem {
  CartItem(
    id: Int,
    title: String,
    price: Float,
    quantity: Int,
    image_url: Option(String),
  )
}

pub type CartState {
  CartState(items: String)
}

pub type CartMessage {
  AddItem(Int, String, Float)
  RemoveItem(Int)
  UpdateQuantity(Int, Int)
  SyncState(String)
}

pub fn calculate_total(items: Dict(Int, CartItem)) -> Float {
  dict.values(items)
  |> list.fold(0.0, fn(total, item) {
    total +. item.price *. int.to_float(item.quantity)
  })
}
