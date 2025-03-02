import chartspace
import lustre
import lustre/effect
import lustre/element

pub fn main() {
  let app =
    lustre.application(
      fn(_) { #(chartspace.init(), effect.none()) },
      chartspace.update,
      chartspace.render,
    )
  let assert Ok(_) = lustre.start(app, "#chartspace-container", Nil)
  Nil
}
