import gleam/dynamic
import gleam/float
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre
import lustre/attribute.{class, style}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import mist.{type WebsocketConnection, type WebsocketMessage, Text}

pub type FormEvent {
  FormEvent(target: FormTarget)
}

pub type FormTarget {
  FormTarget(value: String, checked: Bool)
}

pub type Msg {
  NoOp
  Navigate(String)
  SpacesUpdated(List(Space))
  SwipeStart(Int)
  SwipeMove(Int)
  SwipeEnd(Int)
  ApplyFilters(Filters)
  WebSocketMsg(String)
}

pub type Model {
  Model(
    route: String,
    spaces: List(Space),
    ui_state: UiState,
    ws: Option(WebsocketConnection),
  )
}

pub type UiState {
  UiState(
    current_space_id: Option(String),
    swipe_state: SwipeState,
    filters: Filters,
  )
}

pub type SwipeState {
  NotSwiping
  Swiping(Int, Int)
}

pub type Space {
  Space(
    id: String,
    name: String,
    space_type: SpaceType,
    square_footage: Int,
    pricing_terms: PricingTerms,
    acoustics_rating: Int,
    natural_light: Bool,
    photos: List(String),
  )
}

pub type SpaceType {
  Studio
  RehearsalRoom
  RecordingStudio
  LiveVenue
  Other
}

pub type PricingTerms {
  PricingTerms(hourly_rate: Float, minimum_hours: Int, deposit_required: Bool)
}

pub type Filters {
  Filters(
    space_type: Option(SpaceType),
    min_square_footage: Option(Int),
    max_square_footage: Option(Int),
    min_hourly_rate: Option(Float),
    max_hourly_rate: Option(Float),
    min_acoustics_rating: Option(Int),
    natural_light_required: Bool,
  )
}

@external(javascript, "./findry_ffi.js", "getWebSocketUrl")
fn get_websocket_url() -> String

@external(javascript, "./findry_ffi.js", "dispatch")
fn dispatch(msg: String) -> Nil

@external(javascript, "./findry_ffi.js", "getWindowWidth")
fn window_width() -> Float

@external(javascript, "./findry_ffi.js", "onChange")
fn on_change(handler: fn(FormEvent) -> Msg) -> attribute.Attribute(Msg)

@external(javascript, "./findry_ffi.js", "onInput")
fn on_input(handler: fn(FormEvent) -> Msg) -> attribute.Attribute(Msg)

fn format_space_type(space_type: SpaceType) -> String {
  case space_type {
    Studio -> "Studio"
    RehearsalRoom -> "Rehearsal Room"
    RecordingStudio -> "Recording Studio"
    LiveVenue -> "Live Venue"
    Other -> "Other"
  }
}

fn handle_swipe_right(model: Model) -> Model {
  let current_index = case model.ui_state.current_space_id {
    Some(id) ->
      list.index_map(model.spaces, fn(s, i) {
        case s.id == id {
          True -> Some(i)
          False -> None
        }
      })
      |> list.find(fn(x) { x != None })
      |> option.from_result
      |> option.flatten
    None -> Some(-1)
  }

  let spaces_length = list.length(model.spaces)

  case current_index {
    Some(idx) -> {
      let next_spaces = list.drop(model.spaces, idx + 1)
      case next_spaces {
        [next, ..] ->
          case next {
            Space(id: id, ..) ->
              Model(
                ..model,
                ui_state: UiState(..model.ui_state, current_space_id: Some(id)),
              )
          }
        [] -> model
      }
    }
    None -> model
  }
}

fn handle_swipe_left(model: Model) -> Model {
  let current_index = case model.ui_state.current_space_id {
    Some(id) ->
      list.index_map(model.spaces, fn(s, i) {
        case s.id == id {
          True -> Some(i)
          False -> None
        }
      })
      |> list.find(fn(x) { x != None })
      |> option.from_result
      |> option.flatten
    None -> None
  }

  case current_index {
    Some(idx) -> {
      case idx > 0 {
        True -> {
          let prev_spaces = list.take(model.spaces, idx)
          case list.last(prev_spaces) {
            Ok(space) ->
              case space {
                Space(id: id, ..) ->
                  Model(
                    ..model,
                    ui_state: UiState(
                      ..model.ui_state,
                      current_space_id: Some(id),
                    ),
                  )
              }
            Error(_) -> model
          }
        }
        False -> model
      }
    }
    None -> model
  }
}

pub fn init() -> #(Model, effect.Effect(Msg)) {
  let model =
    Model(
      route: "/",
      spaces: [],
      ui_state: UiState(
        current_space_id: None,
        swipe_state: NotSwiping,
        filters: Filters(
          space_type: None,
          min_square_footage: None,
          max_square_footage: None,
          min_hourly_rate: None,
          max_hourly_rate: None,
          min_acoustics_rating: None,
          natural_light_required: False,
        ),
      ),
      ws: None,
    )

  #(model, effect.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())

    Navigate(route) -> #(Model(..model, route: route), effect.none())

    SpacesUpdated(spaces) -> #(Model(..model, spaces: spaces), effect.none())

    SwipeStart(x) -> #(
      Model(
        ..model,
        ui_state: UiState(..model.ui_state, swipe_state: Swiping(x, x)),
      ),
      effect.none(),
    )

    SwipeMove(x) ->
      case model.ui_state.swipe_state {
        Swiping(start_x, _) -> #(
          Model(
            ..model,
            ui_state: UiState(
              ..model.ui_state,
              swipe_state: Swiping(start_x, x),
            ),
          ),
          effect.none(),
        )
        NotSwiping -> #(model, effect.none())
      }

    SwipeEnd(end_x) -> {
      let offset =
        int.to_float(
          end_x
          - case model.ui_state.swipe_state {
            Swiping(start_x, _) -> start_x
            NotSwiping -> end_x
          },
        )
      let threshold = window_width() *. 0.3
      let neg_threshold = float.subtract(0.0, threshold)

      let new_model = case model.ui_state.swipe_state {
        Swiping(start_x, _) -> {
          case offset >. threshold, offset <. neg_threshold {
            True, _ -> handle_swipe_right(model)
            _, True -> handle_swipe_left(model)
            _, _ ->
              Model(
                ..model,
                ui_state: UiState(..model.ui_state, swipe_state: NotSwiping),
              )
          }
        }
        NotSwiping -> model
      }
      #(new_model, effect.none())
    }

    ApplyFilters(filters) -> #(
      Model(..model, ui_state: UiState(..model.ui_state, filters: filters)),
      effect.none(),
    )

    WebSocketMsg(msg) -> {
      case string.starts_with(msg, "spaces:") {
        True -> {
          let spaces = parse_spaces(string.slice(msg, 7, string.length(msg)))
          #(Model(..model, spaces: spaces), effect.none())
        }
        False -> #(model, effect.none())
      }
    }
  }
}

fn view_space_card(space: Space, swipe_state: SwipeState) -> Element(Msg) {
  let transform = case swipe_state {
    Swiping(start_x, current_x) -> {
      let offset = current_x - start_x
      "translateX(" <> int.to_string(offset) <> "px)"
    }
    NotSwiping -> "translateX(0px)"
  }

  html.div([class("space-card"), style([#("transform", transform)])], [
    html.h2([], [html.text(space.name)]),
    html.p([], [html.text(format_space_type(space.space_type))]),
    html.div([class("space-photos")], case space.photos {
      [] -> [html.div([class("placeholder-photo")], [])]
      photos ->
        list.map(photos, fn(photo) {
          html.img([attribute.src(photo), attribute.alt(space.name)])
        })
    }),
    html.div([class("space-info")], [
      html.div([class("space-details")], [
        html.p([], [
          html.text(
            int.to_string(space.square_footage)
            <> " sq ft · $"
            <> float.to_string(space.pricing_terms.hourly_rate)
            <> "/hr",
          ),
        ]),
        html.p([], [
          html.text(
            "Acoustics: " <> int.to_string(space.acoustics_rating) <> "/10",
          ),
        ]),
      ]),
    ]),
  ])
}

fn view_spaces_page(model: Model) -> Element(Msg) {
  html.div([class("spaces-page")], [
    view_nav(model),
    html.div([class("content")], [
      view_card_stack(model),
      view_swipe_controls(),
      view_filters_panel(model.ui_state.filters),
    ]),
  ])
}

fn view_nav(model: Model) -> Element(Msg) {
  html.nav([], [
    html.a(
      [
        attribute.class("nav-link"),
        event.on("click", fn(_e) { Ok(Navigate("/")) }),
      ],
      [html.text("Spaces")],
    ),
  ])
}

fn view_card_stack(model: Model) -> Element(Msg) {
  let current_space = case model.ui_state.current_space_id {
    Some(id) ->
      list.find(model.spaces, fn(space) { space.id == id })
      |> result.map(fn(space) { Some(space) })
      |> option.from_result
      |> option.flatten
    None ->
      case model.spaces {
        [first, ..] -> Some(first)
        [] -> None
      }
  }

  case current_space {
    Some(space) -> view_space_card(space, model.ui_state.swipe_state)
    None -> view_empty_state()
  }
}

fn view_empty_state() -> Element(Msg) {
  html.div([class("empty-state")], [
    html.h2([], [html.text("No more spaces")]),
    html.p([], [html.text("Try adjusting your filters to see more spaces")]),
  ])
}

fn view_swipe_controls() -> Element(Msg) {
  html.div([class("swipe-controls")], [
    html.button(
      [class("swipe-left"), event.on("click", fn(_e) { Ok(SwipeStart(-1)) })],
      [html.text("👎")],
    ),
    html.button(
      [class("swipe-right"), event.on("click", fn(_e) { Ok(SwipeStart(1)) })],
      [html.text("👍")],
    ),
  ])
}

fn view_filters_panel(filters: Filters) -> Element(Msg) {
  html.div([class("filters-panel")], [
    html.h3([], [html.text("Filters")]),
    html.div([class("filter-group")], [
      html.label([], [html.text("Space Type")]),
      html.select(
        [
          on_change(fn(e) {
            ApplyFilters(
              Filters(..filters, space_type: parse_space_type(e.target.value)),
            )
          }),
        ],
        [
          html.option([attribute.value("")], "Any"),
          html.option([attribute.value("studio")], "Studio"),
          html.option([attribute.value("rehearsal")], "Rehearsal Room"),
          html.option([attribute.value("recording")], "Recording Studio"),
          html.option([attribute.value("live")], "Live Venue"),
          html.option([attribute.value("other")], "Other"),
        ],
      ),
    ]),
    html.div([class("filter-group")], [
      html.label([], [html.text("Square Footage")]),
      html.input([
        attribute.type_("number"),
        attribute.placeholder("Min"),
        on_input(fn(e) {
          ApplyFilters(
            Filters(
              ..filters,
              min_square_footage: parse_int_option(e.target.value),
            ),
          )
        }),
      ]),
      html.input([
        attribute.type_("number"),
        attribute.placeholder("Max"),
        on_input(fn(e) {
          ApplyFilters(
            Filters(
              ..filters,
              max_square_footage: parse_int_option(e.target.value),
            ),
          )
        }),
      ]),
    ]),
    html.div([class("filter-group")], [
      html.label([], [html.text("Budget Range ($/hr)")]),
      html.input([
        attribute.type_("number"),
        attribute.placeholder("Min"),
        on_input(fn(e) {
          ApplyFilters(
            Filters(
              ..filters,
              min_hourly_rate: parse_float_option(e.target.value),
            ),
          )
        }),
      ]),
      html.input([
        attribute.type_("number"),
        attribute.placeholder("Max"),
        on_input(fn(e) {
          ApplyFilters(
            Filters(
              ..filters,
              max_hourly_rate: parse_float_option(e.target.value),
            ),
          )
        }),
      ]),
    ]),
    html.div([class("filter-group")], [
      html.label([], [html.text("Acoustics Rating (min)")]),
      html.input([
        attribute.type_("number"),
        attribute.min("1"),
        attribute.max("10"),
        on_input(fn(e) {
          ApplyFilters(
            Filters(
              ..filters,
              min_acoustics_rating: parse_int_option(e.target.value),
            ),
          )
        }),
      ]),
    ]),
    html.div([class("filter-group")], [
      html.label([], [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(filters.natural_light_required),
          on_change(fn(e) {
            ApplyFilters(
              Filters(..filters, natural_light_required: e.target.checked),
            )
          }),
        ]),
        html.text("Natural Light Required"),
      ]),
    ]),
  ])
}

fn parse_int_option(value: String) -> Option(Int) {
  case int.parse(value) {
    Ok(n) -> Some(n)
    Error(_) -> None
  }
}

fn parse_float_option(value: String) -> Option(Float) {
  case float.parse(value) {
    Ok(n) -> Some(n)
    Error(_) -> None
  }
}

fn parse_space_type(value: String) -> Option(SpaceType) {
  case value {
    "studio" -> Some(Studio)
    "rehearsal" -> Some(RehearsalRoom)
    "recording" -> Some(RecordingStudio)
    "live" -> Some(LiveVenue)
    "other" -> Some(Other)
    _ -> None
  }
}

fn parse_spaces(json: String) -> List(Space) {
  case json.decode(json, dynamic.list(dynamic.dynamic)) {
    Ok(json_value) -> {
      let list_decoder = dynamic.list(space_decoder)
      case list_decoder(dynamic.from(json_value)) {
        Ok(spaces) -> spaces
        Error(err) -> {
          io.debug(err)
          []
        }
      }
    }
    Error(_) -> []
  }
}

fn space_decoder(
  dynamic: dynamic.Dynamic,
) -> Result(Space, List(dynamic.DecodeError)) {
  let space_type_decoder = fn(d: dynamic.Dynamic) {
    case dynamic.string(d) {
      Ok("studio") -> Ok(Studio)
      Ok("rehearsal") -> Ok(RehearsalRoom)
      Ok("recording") -> Ok(RecordingStudio)
      Ok("live") -> Ok(LiveVenue)
      Ok("other") -> Ok(Other)
      Ok(_) ->
        Error([
          dynamic.DecodeError(
            expected: "valid space type",
            found: "unknown space type",
            path: [],
          ),
        ])
      Error(e) -> Error(e)
    }
  }

  let decoder =
    dynamic.decode8(
      Space,
      dynamic.field("id", dynamic.string),
      dynamic.field("name", dynamic.string),
      dynamic.field("space_type", space_type_decoder),
      dynamic.field("square_footage", dynamic.int),
      dynamic.field(
        "pricing_terms",
        dynamic.decode3(
          PricingTerms,
          dynamic.field("hourly_rate", dynamic.float),
          dynamic.field("minimum_hours", dynamic.int),
          dynamic.field("deposit_required", dynamic.bool),
        ),
      ),
      dynamic.field("acoustics_rating", dynamic.int),
      dynamic.field("natural_light", dynamic.bool),
      dynamic.field("photos", dynamic.list(dynamic.string)),
    )

  decoder(dynamic)
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("findry-container")], [
    view_nav(model),
    view_spaces_page(model),
  ])
}
