import lustre
import lustre/element.{type Element}

@external(javascript, "/src/bizpay_background.js", "initBackground")
fn background_component() -> Element(msg)

pub fn view() -> Element(msg) {
  background_component()
}
