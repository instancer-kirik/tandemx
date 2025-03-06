import electric/db.{type Database, type DbError, type Subscription}
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage, Bytes, Text, websocket,
}

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

pub type Artist {
  Artist(
    id: String,
    name: String,
    creative_discipline: List(String),
    space_requirements: SpaceRequirements,
    project_timeline: TimeSlot,
    budget_range: BudgetRange,
    equipment_needs: List(String),
    preferred_hours: AccessHours,
    portfolio_urls: List(String),
    group_size: Int,
    noise_level: Int,
  )
}

pub type SpaceRequirements {
  SpaceRequirements(
    min_square_footage: Int,
    preferred_types: List(SpaceType),
    required_equipment: List(String),
    min_acoustics_rating: Int,
    natural_light_required: Bool,
    storage_needed: Bool,
    special_requirements: List(String),
  )
}

pub type BudgetRange {
  BudgetRange(min: Float, max: Float)
}

pub type Match {
  Match(
    id: String,
    space: Space,
    artist: Artist,
    compatibility_score: Float,
    matched_at: String,
  )
}

pub type FindryState {
  FindryState(
    spaces: List(Space),
    artists: List(Artist),
    matches: List(Match),
    db: Option(Database),
    subscriptions: List(Subscription),
  )
}

pub type FindryActor {
  FindryActor(state: FindryState, connections: List(WebsocketConnection))
}

pub type ClientMessage {
  SpaceAdded(Space)
  SpaceUpdated(Space)
  SpaceDeleted(String)
  ArtistAdded(Artist)
  ArtistUpdated(Artist)
  ArtistDeleted(String)
  MatchCreated(Match)
  MatchDeleted(String)
  SwipeRight(String, String)
  // artist_id, space_id
  SwipeLeft(String, String)
  // artist_id, space_id
  BookingRequested(String, String, TimeSlot)
  // artist_id, space_id, time_slot
}

pub fn handle_message(
  state: FindryState,
  conn: WebsocketConnection,
  msg: WebsocketMessage(String),
  connections: List(WebsocketConnection),
) -> #(FindryState, List(WebsocketConnection)) {
  case msg {
    Text(text) -> {
      let message = parse_electric_message(text)
      case message {
        SpaceAdded(space) -> {
          let new_state = FindryState(..state, spaces: [space, ..state.spaces])
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        SpaceUpdated(updated_space) -> {
          let new_state =
            FindryState(
              ..state,
              spaces: list.map(state.spaces, fn(s) {
                case s.id == updated_space.id {
                  True -> updated_space
                  False -> s
                }
              }),
            )
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        SpaceDeleted(space_id) -> {
          let new_state =
            FindryState(
              ..state,
              spaces: list.filter(state.spaces, fn(s) { s.id != space_id }),
            )
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        ArtistAdded(artist) -> {
          let new_state =
            FindryState(..state, artists: [artist, ..state.artists])
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        ArtistUpdated(updated_artist) -> {
          let new_state =
            FindryState(
              ..state,
              artists: list.map(state.artists, fn(a) {
                case a.id == updated_artist.id {
                  True -> updated_artist
                  False -> a
                }
              }),
            )
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        ArtistDeleted(artist_id) -> {
          let new_state =
            FindryState(
              ..state,
              artists: list.filter(state.artists, fn(a) { a.id != artist_id }),
            )
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        SwipeRight(artist_id, space_id) -> {
          // Create potential match if both parties have swiped right
          let new_state = create_match_if_mutual(state, artist_id, space_id)
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        SwipeLeft(artist_id, space_id) -> {
          // Record rejection to avoid showing again
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(state, connections)
        }

        MatchCreated(match) -> {
          let new_state =
            FindryState(..state, matches: [match, ..state.matches])
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        MatchDeleted(match_id) -> {
          let new_state =
            FindryState(
              ..state,
              matches: list.filter(state.matches, fn(m) { m.id != match_id }),
            )
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }

        BookingRequested(artist_id, space_id, time_slot) -> {
          // Handle booking request
          let new_state =
            handle_booking_request(state, artist_id, space_id, time_slot)
          broadcast_to_others(
            conn,
            serialize_electric_message(message),
            connections,
          )
          #(new_state, connections)
        }
      }
    }
    _ -> #(state, connections)
  }
}

fn broadcast_to_others(
  sender: WebsocketConnection,
  msg: String,
  connections: List(WebsocketConnection),
) {
  list.filter(connections, fn(conn) { conn != sender })
  |> list.each(fn(conn) {
    let assert Ok(_) = mist.send_text_frame(conn, msg)
  })
}

fn create_match_if_mutual(
  state: FindryState,
  artist_id: String,
  space_id: String,
) -> FindryState {
  // TODO: Implement mutual matching logic
  state
}

fn handle_booking_request(
  state: FindryState,
  artist_id: String,
  space_id: String,
  time_slot: TimeSlot,
) -> FindryState {
  // TODO: Implement booking request handling
  state
}

// Electric SQL integration
fn parse_electric_message(_text: String) -> ClientMessage {
  // TODO: Implement Electric SQL message parsing
  panic as "Not implemented"
}

fn serialize_electric_message(_msg: ClientMessage) -> String {
  // TODO: Implement Electric SQL message serialization
  panic as "Not implemented"
}

pub fn init() -> FindryState {
  FindryState(spaces: [], artists: [], matches: [], db: None, subscriptions: [])
}

fn handle_db_error(error: DbError) {
  case error {
    db.ConnectionError(msg) -> io.println("DB Connection Error: " <> msg)
    db.QueryError(msg) -> io.println("DB Query Error: " <> msg)
    db.ValidationError(msg) -> io.println("DB Validation Error: " <> msg)
    db.SubscriptionError(msg) -> io.println("DB Subscription Error: " <> msg)
    db.ParseError(msg) -> io.println("DB Parse Error: " <> msg)
    db.NetworkError(msg) -> io.println("DB Network Error: " <> msg)
  }
}

fn setup_subscriptions(state: FindryState, database: Database) -> FindryState {
  // TODO: Implement Electric SQL subscriptions
  state
}

pub fn start() -> Result(process.Subject(FindryActor), actor.StartError) {
  let state = init()

  // Try to connect to the database
  let state = case db.connect("electric://localhost:5133") {
    Ok(database) -> setup_subscriptions(state, database)
    Error(error) -> {
      handle_db_error(error)
      state
    }
  }

  actor.start_spec(
    actor.Spec(
      init: fn() {
        actor.Ready(
          state: FindryActor(state: state, connections: []),
          selector: process.new_selector(),
        )
      },
      init_timeout: 1000,
      loop: fn(_msg, state) { actor.continue(state) },
    ),
  )
}
