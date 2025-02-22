import chartspace
import lustre
import lustre/element

pub fn main() {
  let init = fn(_) { chartspace.init() }
  let app = lustre.simple(init, chartspace.update, chartspace.render)
  let assert Ok(_) = lustre.start(app, onto: "#chartspace-container", with: Nil)
  Ok(Nil)
}
