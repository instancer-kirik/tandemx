import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

@external(javascript, "websocket.js", "send")
pub fn send_to_server(msg: String) -> effect.Effect(Nil)

pub type CartItem {
  CartItem(
    id: Int,
    title: String,
    price: Float,
    quantity: Int,
    image_url: Option(String),
  )
}

pub type Model {
  Model(items: Dict(Int, CartItem), total: Float, synced: Bool)
}

pub type CartMsg {
  Add(Int, String, Float)
  Remove(Int)
  Update(Int, Int)
  Sync(String)
}

pub type Msg {
  AddToCart(Int, String, Float)
  RemoveFromCart(Int)
  UpdateQuantity(Int, Int)
  CartStateUpdated(String)
}

// Serialize cart message to string for WebSocket
fn serialize_cart_msg(msg: CartMsg) -> String {
  case msg {
    Add(id, title, price) ->
      string.concat([
        "add:",
        int.to_string(id),
        ":",
        title,
        ":",
        float.to_string(price),
      ])
    Remove(id) -> string.concat(["remove:", int.to_string(id)])
    Update(id, qty) ->
      string.concat(["update:", int.to_string(id), ":", int.to_string(qty)])
    Sync(state) -> string.concat(["sync:", state])
  }
}

// Parse cart state from server message
fn parse_cart_state(msg: String) -> Option(Dict(Int, CartItem)) {
  case string.split(msg, "|") {
    ["state", items_str] -> {
      // Parse items from string format
      // Format: "id:title:price:qty,id:title:price:qty,..."
      let items =
        string.split(items_str, ",")
        |> list.map(fn(item_str) {
          case string.split(item_str, ":") {
            [id_str, title, price_str, qty_str] -> {
              case
                int.parse(id_str),
                float.parse(price_str),
                int.parse(qty_str)
              {
                Ok(id), Ok(price), Ok(qty) ->
                  Ok(#(id, CartItem(id, title, price, qty, None)))
                _, _, _ -> Error("Invalid number format")
              }
            }
            _ -> Error("Invalid format")
          }
        })
        |> list.filter(fn(result) {
          case result {
            Ok(_) -> True
            Error(_) -> False
          }
        })
        |> list.map(fn(result) {
          case result {
            Ok(cart_items) -> cart_items
            Error(_) -> panic as "This should never happen due to filter"
          }
        })
        |> dict.from_list()
      Some(items)
    }
    _ -> None
  }
}

pub fn init() -> #(Model, effect.Effect(Msg)) {
  #(Model(items: dict.new(), total: 0.0, synced: False), effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    AddToCart(id, title, price) -> {
      let item = case dict.get(model.items, id) {
        Ok(existing) -> CartItem(..existing, quantity: existing.quantity + 1)
        Error(_) -> CartItem(id, title, price, 1, None)
      }
      let items = dict.insert(model.items, id, item)
      let total = calculate_total(items)

      // Send update to server
      let msg = serialize_cart_msg(Add(id, title, price))
      let effect =
        effect.map(send_to_server(msg), fn(_) { CartStateUpdated(msg) })

      #(Model(items: items, total: total, synced: False), effect)
    }

    RemoveFromCart(id) -> {
      let items = dict.delete(model.items, id)
      let total = calculate_total(items)

      // Send update to server
      let msg = serialize_cart_msg(Remove(id))
      let effect =
        effect.map(send_to_server(msg), fn(_) { CartStateUpdated(msg) })

      #(Model(items: items, total: total, synced: False), effect)
    }

    UpdateQuantity(id, qty) -> {
      let items = case dict.get(model.items, id) {
        Ok(item) ->
          dict.insert(model.items, id, CartItem(..item, quantity: qty))
        Error(_) -> model.items
      }
      let total = calculate_total(items)

      // Send update to server
      let msg = serialize_cart_msg(Update(id, qty))
      let effect =
        effect.map(send_to_server(msg), fn(_) { CartStateUpdated(msg) })

      #(Model(items: items, total: total, synced: False), effect)
    }

    CartStateUpdated(state_msg) -> {
      case parse_cart_state(state_msg) {
        Some(items) -> {
          let total = calculate_total(items)
          #(Model(items: items, total: total, synced: True), effect.none())
        }
        None -> #(model, effect.none())
      }
    }
  }
}

fn calculate_total(items: Dict(Int, CartItem)) -> Float {
  dict.values(items)
  |> list.fold(0.0, fn(total, item) {
    total +. item.price *. int.to_float(item.quantity)
  })
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("shopping-cart")], [
    html.div([attribute.class("cart-header")], [
      html.h2([], [html.text("Shopping Cart")]),
      html.span(
        [
          attribute.class(
            "sync-status "
            <> case model.synced {
              True -> "synced"
              False -> "unsynced"
            },
          ),
        ],
        [
          html.text(case model.synced {
            True -> "Synced"
            False -> "Not synced"
          }),
        ],
      ),
    ]),
    html.div(
      [attribute.class("cart-items")],
      dict.values(model.items)
        |> list.map(view_cart_item),
    ),
    html.div([attribute.class("cart-total")], [
      html.span([], [html.text("Total: $" <> float.to_string(model.total))]),
    ]),
  ])
}

fn view_cart_item(item: CartItem) -> Element(Msg) {
  html.div([attribute.class("cart-item")], [
    case item.image_url {
      Some(url) ->
        html.img([
          attribute.src(url),
          attribute.alt(item.title),
          attribute.class("item-image"),
        ])
      None -> html.text("")
    },
    html.div([attribute.class("item-details")], [
      html.h3([], [html.text(item.title)]),
      html.span([], [html.text("$" <> float.to_string(item.price))]),
    ]),
    html.div([attribute.class("item-quantity")], [
      html.button(
        [
          attribute.class("qty-btn"),
          event.on_click(UpdateQuantity(item.id, item.quantity - 1)),
        ],
        [html.text("-")],
      ),
      html.span([], [html.text(int.to_string(item.quantity))]),
      html.button(
        [
          attribute.class("qty-btn"),
          event.on_click(UpdateQuantity(item.id, item.quantity + 1)),
        ],
        [html.text("+")],
      ),
    ]),
    html.button(
      [attribute.class("remove-btn"), event.on_click(RemoveFromCart(item.id))],
      [html.text("Remove")],
    ),
  ])
}
