// import gleam/erlang/process
// import gleam/otp/actor
// import tandemx_server/cart.{
//   type CartMessage, type CartState, AddItem, RemoveItem, SyncState,
//   UpdateQuantity,
// }

// pub fn start() -> Result(process.Subject(CartMessage), Nil) {
//   actor.start(CartState("[]"), handle_message)
// }

// fn handle_message(
//   msg: CartMessage,
//   state: CartState,
// ) -> actor.Next(CartMessage, CartState) {
//   case msg {
//     AddItem(id, title, price) -> {
//       let new_state = CartState(state.items)
//       actor.continue(new_state)
//     }
//     RemoveItem(id) -> {
//       let new_state = CartState(state.items)
//       actor.continue(new_state)
//     }
//     UpdateQuantity(id, qty) -> {
//       let new_state = CartState(state.items)
//       actor.continue(new_state)
//     }
//     SyncState(items) -> {
//       let new_state = CartState(items)
//       actor.continue(new_state)
//     }
//   }
// }
