import gleam/int
import gleam/json
import gleam/list
import gleam/option

pub type CartItem {
  CartItem(
    variant_id: String,
    name: String,
    price: Float,
    quantity: Int,
    is_preorder: Bool,
    release_date: option.Option(String),
  )
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
  CartActor(state: CartState(items: new_items))
}

// Add preorder item to cart
pub fn add_preorder(
  actor: CartActor,
  variant_id: String,
  name: String,
  price: Float,
  quantity: Int,
  release_date: String,
) -> CartActor {
  let preorder_item =
    CartItem(
      variant_id: variant_id,
      name: name,
      price: price,
      quantity: quantity,
      is_preorder: True,
      release_date: option.Some(release_date),
    )
  add_item(actor, preorder_item)
}

// Remove item from cart
pub fn remove_item(actor: CartActor, variant_id: String) -> CartActor {
  let new_items =
    list.filter(actor.state.items, fn(i) { i.variant_id != variant_id })
  CartActor(state: CartState(items: new_items))
}

// Update item quantity
pub fn update_quantity(
  actor: CartActor,
  variant_id: String,
  new_quantity: Int,
) -> CartActor {
  let new_items =
    list.map(actor.state.items, fn(i) {
      case i.variant_id == variant_id {
        True -> CartItem(..i, quantity: new_quantity)
        False -> i
      }
    })
  CartActor(state: CartState(items: new_items))
}

// Calculate total price
pub fn total_price(actor: CartActor) -> Float {
  list.fold(actor.state.items, 0.0, fn(total, item) {
    total +. int.to_float(item.quantity) *. item.price
  })
}

// Get all preorder items
pub fn get_preorders(actor: CartActor) -> List(CartItem) {
  list.filter(actor.state.items, fn(item) { item.is_preorder })
}

// Convert cart state to JSON for Lemon Squeezy checkout
pub fn to_json(actor: CartActor) -> json.Json {
  let items_json =
    list.map(actor.state.items, fn(item) {
      let base_json = [
        #("variant_id", json.string(item.variant_id)),
        #("name", json.string(item.name)),
        #("price", json.float(item.price)),
        #("quantity", json.int(item.quantity)),
        #("is_preorder", json.bool(item.is_preorder)),
      ]

      case item.release_date {
        option.Some(date) ->
          json.object(
            list.append(base_json, [#("release_date", json.string(date))]),
          )
        option.None -> json.object(base_json)
      }
    })

  json.object([
    #("items", json.array(items_json, fn(j) { j })),
    #("total_price", json.float(total_price(actor))),
  ])
}
