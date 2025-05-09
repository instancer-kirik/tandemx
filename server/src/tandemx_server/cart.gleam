import gleam/dict.{type Dict}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}

pub type CartItem {
  CartItem(id: String, name: String, quantity: Int, price: Float)
}

pub type CartState {
  CartState(items: List(CartItem))
}

pub type CartActor {
  CartActor(state: CartState)
}

pub fn init() -> CartActor {
  CartActor(state: CartState(items: []))
}

// Add item to cart
pub fn add_item(actor: CartActor, item: CartItem) -> CartActor {
  let new_items = list.append(actor.state.items, [item])
  CartActor(state: CartState(..actor.state, items: new_items))
}

// Remove item from cart
pub fn remove_item(actor: CartActor, item_id: String) -> CartActor {
  let new_items = list.filter(actor.state.items, fn(i) { i.id != item_id })
  CartActor(state: CartState(..actor.state, items: new_items))
}

// Update item quantity
pub fn update_quantity(
  actor: CartActor,
  item_id: String,
  new_quantity: Int,
) -> CartActor {
  let new_items =
    list.map(actor.state.items, fn(i) {
      case i.id == item_id {
        True -> CartItem(..i, quantity: new_quantity)
        False -> i
      }
    })
  CartActor(state: CartState(..actor.state, items: new_items))
}

// Calculate total price
pub fn total_price(actor: CartActor) -> Float {
  list.fold(actor.state.items, 0.0, fn(total, item) {
    total +. int.to_float(item.quantity) *. item.price
  })
}

// Convert cart state to JSON
pub fn to_json(actor: CartActor) -> json.Json {
  let items_json =
    list.map(actor.state.items, fn(item) {
      json.object([
        #("id", json.string(item.id)),
        #("name", json.string(item.name)),
        #("quantity", json.int(item.quantity)),
        #("price", json.float(item.price)),
      ])
    })
  json.object([
    #("items", json.array(items_json, fn(j) { j })),
    #("totalPrice", json.float(total_price(actor))),
  ])
}
