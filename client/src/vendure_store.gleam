import gleam/io
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html

pub type Msg {
  NoOp
}

pub type Model {
  Model
}

@external(javascript, "./vendure_store_ffi.js", "main")
fn ffi_main() -> Bool

pub fn init(_: Nil) -> #(Model, effect.Effect(Msg)) {
  let model = Model
  let _ = ffi_main()
  #(model, effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn view(_model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.id("vendure-store-root"),
      attribute.class("vendure-store-container"),
    ],
    [],
  )
}
