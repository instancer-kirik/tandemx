import form_handler/form_analyzer
import gleam/dynamic.{type Dynamic}
import lustre
import lustre/effect

@external(javascript, "./form_handler/form_analyzer_ffi.js", "make_app_global")
pub fn make_app_global(app: Dynamic) -> Nil

@external(javascript, "./form_handler/form_analyzer_ffi.js", "cleanup_app")
pub fn cleanup_app() -> Nil

pub fn main() {
  let app =
    lustre.application(
      fn(_) { #(form_analyzer.init(), effect.none()) },
      form_analyzer.update,
      form_analyzer.render,
    )

  // Start the app and handle the result properly
  case lustre.start(app, "[data-lustre-app='form-analyzer']", Nil) {
    Ok(instance) -> {
      make_app_global(dynamic.from(instance))
      dynamic.from(#(instance, cleanup_app))
    }
    Error(error) -> {
      // Return a tuple with null values to match expected type
      dynamic.from(#(Nil, fn() { Nil }))
    }
  }
}
