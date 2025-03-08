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

pub type Route {
  Landing
  Spaces
  Artists
  Matches
  Sponsor
  Credit
  Support
  Market
  Contact
}

pub type Msg {
  NavigateTo(Route)
  SpaceAdded(Space)
  SpaceUpdated(Space)
  SpaceDeleted(String)
  SwipeRight(String)
  SwipeLeft(String)
  ShowSpaceDetails(Space)
  CloseModal
  ApplyFilters(Filters)
  WebSocketMessage(Json)
  ConnectToSpaces
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
    route: Route,
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
      route: Landing,
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

  #(model, effect.none())
}

@external(javascript, "./findry_ffi.js", "getWebSocketUrl")
fn get_websocket_url() -> String

@external(javascript, "./findry_ffi.js", "dispatch")
fn dispatch(msg: Msg) -> Nil

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NavigateTo(route) -> {
      case route {
        Spaces -> {
          case model.ws {
            Some(_) -> #(Model(..model, route: route), effect.none())
            None -> {
              let ws =
                websocket.connect(
                  get_websocket_url(),
                  fn(msg) { dispatch(WebSocketMessage(msg)) },
                  fn() { io.println("WebSocket closed") },
                )
              #(Model(..model, route: route, ws: Some(ws)), effect.none())
            }
          }
        }
        _ -> #(Model(..model, route: route), effect.none())
      }
    }

    ConnectToSpaces -> {
      let ws =
        websocket.connect(
          get_websocket_url(),
          fn(msg) { dispatch(WebSocketMessage(msg)) },
          fn() { io.println("WebSocket closed") },
        )
      #(Model(..model, ws: Some(ws)), effect.none())
    }

    SpaceAdded(space) -> {
      #(Model(..model, spaces: [space, ..model.spaces]), effect.none())
    }

    SpaceUpdated(updated_space) -> {
      let updated_spaces =
        list.map(model.spaces, fn(s) {
          case s.id == updated_space.id {
            True -> updated_space
            False -> s
          }
        })
      #(Model(..model, spaces: updated_spaces), effect.none())
    }

    SpaceDeleted(space_id) -> {
      let filtered_spaces =
        list.filter(model.spaces, fn(s) { s.id != space_id })
      #(Model(..model, spaces: filtered_spaces), effect.none())
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
          #(show_next_space(model), effect.none())
        }
        None -> #(model, effect.none())
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
          #(show_next_space(model), effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    ShowSpaceDetails(space) -> {
      #(Model(..model, selected_space: Some(space)), effect.none())
    }

    CloseModal -> {
      #(Model(..model, selected_space: None), effect.none())
    }

    ApplyFilters(filters) -> {
      #(Model(..model, filters: filters), effect.none())
    }

    WebSocketMessage(msg) -> {
      #(handle_ws_message(model, msg), effect.none())
    }
  }
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
    case model.route {
      Landing -> view_landing_page()
      Spaces -> view_spaces_page(model)
      Artists -> view_artists_page()
      Matches -> view_matches_page()
      Sponsor -> view_sponsor_page()
      Credit -> view_credit_page()
      Support -> view_support_page()
      Market -> view_market_page()
      Contact -> view_contact_page()
    },
  ])
}

fn view_nav() -> Element(Msg) {
  html.nav([attribute.class("findry-nav")], [
    // Left section with logo
    html.a([attribute.class("logo"), event.on_click(NavigateTo(Landing))], [
      html.text("Findry"),
    ]),
    // Center section with main navigation
    html.div([attribute.class("nav-links")], [
      html.a([attribute.class("nav-link"), event.on_click(NavigateTo(Spaces))], [
        html.text("Spaces"),
      ]),
      html.a(
        [attribute.class("nav-link"), event.on_click(NavigateTo(Artists))],
        [html.text("Artists")],
      ),
      html.a(
        [attribute.class("nav-link"), event.on_click(NavigateTo(Matches))],
        [html.text("Matches")],
      ),
    ]),
    // Right section with user menu and additional buttons
    html.div([attribute.class("nav-right")], [
      html.div([attribute.class("action-buttons")], [
        html.a(
          [
            attribute.class("action-btn sponsor"),
            event.on_click(NavigateTo(Sponsor)),
          ],
          [html.text("🤝 Sponsor")],
        ),
        html.a(
          [
            attribute.class("action-btn credit"),
            event.on_click(NavigateTo(Credit)),
          ],
          [html.text("💳 Reverse Credit")],
        ),
        html.a(
          [
            attribute.class("action-btn support"),
            event.on_click(NavigateTo(Support)),
          ],
          [html.text("💬 Support")],
        ),
        html.a(
          [
            attribute.class("action-btn market"),
            event.on_click(NavigateTo(Market)),
          ],
          [html.text("📊 Market")],
        ),
        html.a(
          [
            attribute.class("action-btn contact"),
            event.on_click(NavigateTo(Contact)),
          ],
          [html.text("📧 Contact")],
        ),
        html.a(
          [
            attribute.class("action-btn source"),
            attribute.href("https://github.com/yourusername/findry"),
            attribute.target("_blank"),
            attribute.rel("noopener noreferrer"),
          ],
          [html.text("📝 Source")],
        ),
      ]),
      html.div([attribute.class("user-menu")], [
        html.button([attribute.class("profile-btn")], [html.text("Profile")]),
      ]),
    ]),
  ])
}

fn view_landing_page() -> Element(Msg) {
  html.div([attribute.class("landing-page")], [
    html.div([attribute.class("hero-section")], [
      html.h1([attribute.class("hero-title")], [
        html.text("Find Your Perfect Creative Space"),
      ]),
      html.p([attribute.class("hero-subtitle")], [
        html.text(
          "Connect with studios, galleries, practice rooms, and workshops tailored to your artistic vision",
        ),
      ]),
      html.div([attribute.class("cta-buttons")], [
        html.button(
          [
            attribute.class("cta-btn primary"),
            event.on_click(NavigateTo(Spaces)),
          ],
          [html.text("Find Spaces")],
        ),
        html.button(
          [
            attribute.class("cta-btn secondary"),
            event.on_click(NavigateTo(Artists)),
          ],
          [html.text("I'm a Space Owner")],
        ),
      ]),
    ]),
    html.div([attribute.class("features-section")], [
      view_feature_card(
        "🎨",
        "Creative Spaces",
        "Discover unique spaces perfect for your artistic needs",
      ),
      view_feature_card(
        "🤝",
        "Direct Connections",
        "Connect directly with space owners and artists",
      ),
      view_feature_card(
        "📅",
        "Easy Booking",
        "Simple scheduling and booking process",
      ),
      view_feature_card(
        "💡",
        "Smart Matching",
        "Find spaces that match your specific requirements",
      ),
    ]),
    html.div([attribute.class("social-proof-section")], [
      html.h2([attribute.class("section-title")], [
        html.text("Trusted by Artists"),
      ]),
      html.div([attribute.class("testimonials")], [
        view_testimonial(
          "Sarah M.",
          "Visual Artist",
          "Found my dream studio space in just a few days!",
        ),
        view_testimonial(
          "James K.",
          "Musician",
          "The practice room search was incredibly easy.",
        ),
        view_testimonial(
          "Emily R.",
          "Photographer",
          "Perfect for finding unique shooting locations.",
        ),
      ]),
    ]),
  ])
}

fn view_feature_card(
  emoji: String,
  title: String,
  description: String,
) -> Element(Msg) {
  html.div([attribute.class("feature-card")], [
    html.div([attribute.class("feature-emoji")], [html.text(emoji)]),
    html.h3([attribute.class("feature-title")], [html.text(title)]),
    html.p([attribute.class("feature-description")], [html.text(description)]),
  ])
}

fn view_testimonial(name: String, role: String, quote: String) -> Element(Msg) {
  html.div([class("testimonial-card")], [
    html.p([class("testimonial-quote")], [html.text(quote)]),
    html.div([class("testimonial-author")], [
      html.p([class("author-name")], [html.text(name)]),
      html.p([class("author-role")], [html.text(role)]),
    ]),
  ])
}

fn view_spaces_page(model: Model) -> Element(Msg) {
  html.main([class("findry-main")], [
    view_card_stack(model),
    view_swipe_controls(),
    view_filters_panel(model.filters),
    case model.selected_space {
      Some(space) -> view_space_details(space)
      None -> html.text("")
    },
  ])
}

fn view_card_stack(model: Model) -> Element(Msg) {
  case model.spaces {
    [] ->
      html.div([attribute.class("empty-state")], [
        html.text("No spaces available"),
      ])
    spaces -> {
      let current_space =
        list.first(list.drop(spaces, model.current_space_index))
      case current_space {
        Ok(space) -> view_space_card(space)
        Error(_) ->
          html.div([attribute.class("empty-state")], [
            html.text("No more spaces"),
          ])
      }
    }
  }
}

fn view_space_card(space: Space) -> Element(Msg) {
  html.div(
    [attribute.class("space-card"), event.on_click(ShowSpaceDetails(space))],
    [
      html.div([attribute.class("space-photo")], case list.first(space.photos) {
        Ok(photo) -> [html.img([attribute.src(photo)])]
        Error(_) -> []
      }),
      html.div([attribute.class("space-info")], [
        html.h2([], [html.text(space.name)]),
        html.p([], [html.text(format_space_type(space.space_type))]),
      ]),
      view_swipe_controls(),
    ],
  )
}

fn view_swipe_controls() -> Element(Msg) {
  html.div([attribute.class("swipe-controls")], [
    html.button([attribute.class("swipe-left"), event.on_click(SwipeLeft(""))], [
      html.text("←"),
    ]),
    html.button(
      [attribute.class("swipe-right"), event.on_click(SwipeRight(""))],
      [html.text("→")],
    ),
  ])
}

fn view_filters_panel(filters: Filters) -> Element(Msg) {
  // TODO: Implement filters panel view
  html.div([], [])
}

fn view_space_details(space: Space) -> Element(Msg) {
  html.div([attribute.class("modal")], [
    html.div([attribute.class("modal-content")], [
      html.div([attribute.class("modal-header")], [
        html.h2([], [html.text(space.name)]),
        html.button(
          [attribute.class("close-modal"), event.on_click(CloseModal)],
          [html.text("×")],
        ),
      ]),
      html.div(
        [attribute.class("gallery")],
        list.map(space.photos, fn(photo) { html.img([attribute.src(photo)]) }),
      ),
      html.div([attribute.class("space-details")], [
        html.p([], [html.text(format_space_type(space.space_type))]),
        html.p([], [html.text(space.location_data.address)]),
      ]),
    ]),
  ])
}

fn format_space_type(space_type: SpaceType) -> String {
  case space_type {
    Studio -> "Studio"
    Gallery -> "Gallery"
    PracticeRoom -> "Practice Room"
    Workshop -> "Workshop"
    Treehouse -> "Treehouse"
    Other(name) -> name
  }
}

fn format_location(location: LocationData) -> String {
  // Only use the address field since city and state don't exist
  location.address
}

fn view_gallery(photos: List(String)) -> List(Element(Msg)) {
  list.map(photos, fn(photo) { html.img([attribute.src(photo)]) })
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
  let features = []
  let features = case space.acoustics_rating > 7 {
    True -> [view_feature_tag("🎵 Great Acoustics"), ..features]
    False -> features
  }
  let features = case space.lighting_details.natural_light {
    True -> [view_feature_tag("☀️ Natural Light"), ..features]
    False -> features
  }
  let features = case list.length(space.equipment_list) > 0 {
    True -> [view_feature_tag("🛠️ Equipped"), ..features]
    False -> features
  }
  let features = case space.location_data.parking_available {
    True -> [view_feature_tag("🅿️ Parking"), ..features]
    False -> features
  }

  html.div([class("space-features")], features)
}

fn view_feature_tag(text: String) -> Element(Msg) {
  html.span([class("feature-tag")], [html.text(text)])
}

fn format_price(pricing: PricingTerms) -> String {
  "$" <> float.to_string(pricing.hourly_rate) <> "/hour"
}

// Placeholder views for other pages
fn view_artists_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Artists page coming soon")])
}

fn view_matches_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Matches page coming soon")])
}

fn view_sponsor_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Sponsor page coming soon")])
}

fn view_credit_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Credit page coming soon")])
}

fn view_support_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Support page coming soon")])
}

fn view_market_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Market page coming soon")])
}

fn view_contact_page() -> Element(Msg) {
  html.div([class("coming-soon")], [html.text("Contact page coming soon")])
}
