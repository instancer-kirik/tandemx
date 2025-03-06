import findry/websocket.{type WebSocket}
import gleam/float
import gleam/int
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type SpaceType {
  Studio
  Gallery
  PracticeRoom
  Workshop
  Treehouse
  Other(String)
}

pub type Space {
  Space(
    id: String,
    name: String,
    space_type: SpaceType,
    square_footage: Int,
    equipment_list: List(String),
    availability_schedule: List(TimeSlot),
    pricing_terms: PricingTerms,
    acoustics_rating: Int,
    lighting_details: LightingDetails,
    access_hours: AccessHours,
    location_data: LocationData,
    photos: List(String),
    virtual_tour_url: Option(String),
  )
}

pub type TimeSlot {
  TimeSlot(start_time: String, end_time: String)
}

pub type PricingTerms {
  PricingTerms(
    hourly_rate: Float,
    daily_rate: Option(Float),
    weekly_rate: Option(Float),
    monthly_rate: Option(Float),
    deposit_required: Bool,
    deposit_amount: Option(Float),
  )
}

pub type LightingDetails {
  LightingDetails(
    natural_light: Bool,
    adjustable: Bool,
    color_temperature: Option(Int),
    special_features: List(String),
  )
}

pub type AccessHours {
  AccessHours(
    monday: List(TimeSlot),
    tuesday: List(TimeSlot),
    wednesday: List(TimeSlot),
    thursday: List(TimeSlot),
    friday: List(TimeSlot),
    saturday: List(TimeSlot),
    sunday: List(TimeSlot),
    special_hours: List(#(String, List(TimeSlot))),
  )
}

pub type LocationData {
  LocationData(
    address: String,
    latitude: Float,
    longitude: Float,
    public_transport: List(String),
    parking_available: Bool,
    loading_zone: Bool,
    noise_restrictions: List(String),
  )
}

pub type Msg {
  SpaceAdded(Space)
  SpaceUpdated(Space)
  SpaceDeleted(String)
  SwipeRight(String)
  SwipeLeft(String)
  ShowSpaceDetails(Space)
  CloseModal
  ApplyFilters(Filters)
  WebSocketMessage(Json)
}

pub type Filters {
  Filters(
    space_type: Option(SpaceType),
    min_square_footage: Option(Int),
    max_square_footage: Option(Int),
    min_budget: Option(Float),
    max_budget: Option(Float),
    min_acoustics: Option(Int),
    natural_light_required: Bool,
  )
}

pub type Model {
  Model(
    spaces: List(Space),
    current_space_index: Int,
    selected_space: Option(Space),
    filters: Filters,
    ws: Option(WebSocket),
  )
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      spaces: [],
      current_space_index: 0,
      selected_space: None,
      filters: Filters(
        space_type: None,
        min_square_footage: None,
        max_square_footage: None,
        min_budget: None,
        max_budget: None,
        min_acoustics: None,
        natural_light_required: False,
      ),
      ws: None,
    )

  let ws =
    websocket.connect(
      get_websocket_url(),
      fn(msg) { dispatch(WebSocketMessage(msg)) },
      fn() { io.println("WebSocket closed") },
    )

  #(Model(..model, ws: Some(ws)), effect.none())
}

@external(javascript, "./findry_ffi.js", "getWebSocketUrl")
fn get_websocket_url() -> String

@external(javascript, "./findry_ffi.js", "dispatch")
fn dispatch(msg: Msg) -> Nil

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let new_model = case msg {
    SpaceAdded(space) -> {
      Model(..model, spaces: [space, ..model.spaces])
    }

    SpaceUpdated(updated_space) -> {
      let updated_spaces =
        list.map(model.spaces, fn(s) {
          case s.id == updated_space.id {
            True -> updated_space
            False -> s
          }
        })
      Model(..model, spaces: updated_spaces)
    }

    SpaceDeleted(space_id) -> {
      let filtered_spaces =
        list.filter(model.spaces, fn(s) { s.id != space_id })
      Model(..model, spaces: filtered_spaces)
    }

    SwipeRight(space_id) -> {
      case model.ws {
        Some(ws) -> {
          websocket.send(
            ws,
            json.object([
              #("type", json.string("SwipeRight")),
              #("spaceId", json.string(space_id)),
            ]),
          )
          show_next_space(model)
        }
        None -> model
      }
    }

    SwipeLeft(space_id) -> {
      case model.ws {
        Some(ws) -> {
          websocket.send(
            ws,
            json.object([
              #("type", json.string("SwipeLeft")),
              #("spaceId", json.string(space_id)),
            ]),
          )
          show_next_space(model)
        }
        None -> model
      }
    }

    ShowSpaceDetails(space) -> {
      Model(..model, selected_space: Some(space))
    }

    CloseModal -> {
      Model(..model, selected_space: None)
    }

    ApplyFilters(filters) -> {
      Model(..model, filters: filters)
    }

    WebSocketMessage(msg) -> {
      handle_ws_message(model, msg)
    }
  }
  #(new_model, effect.none())
}

fn show_next_space(model: Model) -> Model {
  Model(..model, current_space_index: model.current_space_index + 1)
}

fn handle_ws_message(model: Model, msg: Json) -> Model {
  // TODO: Implement WebSocket message handling
  model
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("findry-app")], [
    view_nav(),
    html.main([class("findry-main")], [
      view_card_stack(model),
      view_swipe_controls(),
      view_filters_panel(model.filters),
    ]),
    case model.selected_space {
      Some(space) -> view_space_details(space)
      None -> html.text("")
    },
  ])
}

fn view_nav() -> Element(Msg) {
  html.nav([class("findry-nav")], [
    html.div([class("logo")], [html.text("Findry")]),
    html.div([class("nav-links")], [
      html.a([class("nav-link"), attribute.href("/findry/spaces")], [
        html.text("Spaces"),
      ]),
      html.a([class("nav-link"), attribute.href("/findry/artists")], [
        html.text("Artists"),
      ]),
      html.a([class("nav-link"), attribute.href("/findry/matches")], [
        html.text("Matches"),
      ]),
    ]),
    html.div([class("user-menu")], [
      html.button([class("profile-btn")], [html.text("Profile")]),
    ]),
  ])
}

fn view_card_stack(model: Model) -> Element(Msg) {
  html.div([class("card-stack")], case
    list.at(model.spaces, model.current_space_index)
  {
    Ok(space) -> [view_space_card(space)]
    Error(_) -> [
      html.div([class("no-spaces")], [html.text("No more spaces available")]),
    ]
  })
}

fn view_space_card(space: Space) -> Element(Msg) {
  html.div(
    [class("space-card"), event.on("click", fn(_) { ShowSpaceDetails(space) })],
    [
      html.div([class("card-photos")], case list.first(space.photos) {
        Ok(photo) -> [
          html.img([attribute.src(photo), attribute.alt(space.name)], []),
        ]
        Error(_) -> []
      }),
      html.div([class("card-info")], [
        html.h3([class("space-name")], [html.text(space.name)]),
        html.p([class("space-type")], [
          html.text(format_space_type(space.space_type)),
        ]),
        html.p([class("space-price")], [
          html.text(format_price(space.pricing_terms)),
        ]),
        view_feature_tags(space),
      ]),
    ],
  )
}

fn view_swipe_controls() -> Element(Msg) {
  html.div([class("swipe-controls")], [
    html.button(
      [class("swipe-btn pass"), event.on("click", fn(_) { SwipeLeft("") })],
      [html.text("✕")],
    ),
    html.button(
      [class("swipe-btn like"), event.on("click", fn(_) { SwipeRight("") })],
      [html.text("♥")],
    ),
  ])
}

fn view_filters_panel(filters: Filters) -> Element(Msg) {
  // TODO: Implement filters panel view
  html.div([], [])
}

fn view_space_details(space: Space) -> Element(Msg) {
  html.div([class("space-details modal")], [
    html.div([class("modal-content")], [
      html.button(
        [class("close-modal"), event.on("click", fn(_) { CloseModal })],
        [html.text("×")],
      ),
      html.div([class("space-gallery")], view_gallery(space.photos)),
      html.div([class("space-info")], [
        html.h2([class("space-name")], [html.text(space.name)]),
        html.p([class("space-type")], [
          html.text(format_space_type(space.space_type)),
        ]),
        view_space_details_grid(space),
        view_equipment_list(space.equipment_list),
        view_availability(space.availability_schedule),
        html.button([class("book-space")], [html.text("Book Space")]),
      ]),
    ]),
  ])
}

fn view_gallery(photos: List(String)) -> List(Element(Msg)) {
  list.map(photos, fn(photo) { html.img([attribute.src(photo)], []) })
}

fn view_space_details_grid(space: Space) -> Element(Msg) {
  html.div([class("space-details-grid")], [
    view_detail_item(
      "Square Footage",
      int.to_string(space.square_footage) <> " sq ft",
    ),
    view_detail_item(
      "Acoustics",
      int.to_string(space.acoustics_rating) <> "/10",
    ),
    view_detail_item("Lighting", case space.lighting_details.natural_light {
      True -> "Natural"
      False -> "Artificial"
    }),
    view_detail_item("Rate", format_price(space.pricing_terms)),
  ])
}

fn view_detail_item(label: String, value: String) -> Element(Msg) {
  html.div([class("detail-item")], [
    html.span([class("label")], [html.text(label)]),
    html.span([class("value")], [html.text(value)]),
  ])
}

fn view_equipment_list(equipment: List(String)) -> Element(Msg) {
  html.div([class("equipment-list")], [
    html.h3([], [html.text("Equipment & Amenities")]),
    html.ul(
      [],
      list.map(equipment, fn(item) { html.li([], [html.text(item)]) }),
    ),
  ])
}

fn view_availability(slots: List(TimeSlot)) -> Element(Msg) {
  html.div([class("availability")], [
    html.h3([], [html.text("Availability")]),
    html.div([class("calendar")], []),
    // TODO: Implement calendar view
  ])
}

fn view_feature_tags(space: Space) -> Element(Msg) {
  html.div(
    [class("space-features")],
    list.filter_map(
      [
        case space.acoustics_rating > 7 {
          True -> Some(view_feature_tag("🎵 Great Acoustics"))
          False -> None
        },
        case space.lighting_details.natural_light {
          True -> Some(view_feature_tag("☀️ Natural Light"))
          False -> None
        },
        case list.length(space.equipment_list) > 0 {
          True -> Some(view_feature_tag("🛠️ Equipped"))
          False -> None
        },
        case space.location_data.parking_available {
          True -> Some(view_feature_tag("🅿️ Parking"))
          False -> None
        },
      ],
      fn(x) { x },
    ),
  )
}

fn view_feature_tag(text: String) -> Element(Msg) {
  html.span([class("feature-tag")], [html.text(text)])
}

fn format_space_type(type_: SpaceType) -> String {
  case type_ {
    Studio -> "Studio"
    Gallery -> "Gallery"
    PracticeRoom -> "Practice Room"
    Workshop -> "Workshop"
    Treehouse -> "Treehouse"
    Other(name) -> name
  }
}

fn format_price(pricing: PricingTerms) -> String {
  "$" <> float.to_string(pricing.hourly_rate) <> "/hour"
}
