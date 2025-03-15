import electric/db.{type Database, type DbError, type Subscription}
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string
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
    Text("init") -> {
      // Send initial state to the new client
      list.each(state.spaces, fn(space) {
        let assert Ok(_) =
          mist.send_text_frame(
            conn,
            serialize_electric_message(SpaceAdded(space)),
          )
      })
      list.each(state.artists, fn(artist) {
        let assert Ok(_) =
          mist.send_text_frame(
            conn,
            serialize_electric_message(ArtistAdded(artist)),
          )
      })
      list.each(state.matches, fn(match) {
        let assert Ok(_) =
          mist.send_text_frame(
            conn,
            serialize_electric_message(MatchCreated(match)),
          )
      })
      #(state, connections)
    }

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
fn parse_electric_message(text: String) -> ClientMessage {
  // Basic message parsing for now
  case string.split(text, ":") {
    ["space_added", space_id, name] -> {
      SpaceAdded(Space(
        id: space_id,
        name: name,
        space_type: Studio,
        // Default type
        square_footage: 0,
        equipment_list: [],
        availability_schedule: [],
        pricing_terms: PricingTerms(
          hourly_rate: 0.0,
          daily_rate: None,
          weekly_rate: None,
          monthly_rate: None,
          deposit_required: False,
          deposit_amount: None,
        ),
        acoustics_rating: 0,
        lighting_details: LightingDetails(
          natural_light: False,
          adjustable: False,
          color_temperature: None,
          special_features: [],
        ),
        access_hours: AccessHours(
          monday: [],
          tuesday: [],
          wednesday: [],
          thursday: [],
          friday: [],
          saturday: [],
          sunday: [],
          special_hours: [],
        ),
        location_data: LocationData(
          address: "",
          latitude: 0.0,
          longitude: 0.0,
          public_transport: [],
          parking_available: False,
          loading_zone: False,
          noise_restrictions: [],
        ),
        photos: [],
        virtual_tour_url: None,
      ))
    }
    ["space_deleted", space_id] -> SpaceDeleted(space_id)
    ["artist_added", artist_id, name] -> {
      ArtistAdded(Artist(
        id: artist_id,
        name: name,
        creative_discipline: [],
        space_requirements: SpaceRequirements(
          min_square_footage: 0,
          preferred_types: [],
          required_equipment: [],
          min_acoustics_rating: 0,
          natural_light_required: False,
          storage_needed: False,
          special_requirements: [],
        ),
        project_timeline: TimeSlot(start_time: "", end_time: ""),
        budget_range: BudgetRange(min: 0.0, max: 0.0),
        equipment_needs: [],
        preferred_hours: AccessHours(
          monday: [],
          tuesday: [],
          wednesday: [],
          thursday: [],
          friday: [],
          saturday: [],
          sunday: [],
          special_hours: [],
        ),
        portfolio_urls: [],
        group_size: 1,
        noise_level: 0,
      ))
    }
    ["artist_deleted", artist_id] -> ArtistDeleted(artist_id)
    ["swipe_right", artist_id, space_id] -> SwipeRight(artist_id, space_id)
    ["swipe_left", artist_id, space_id] -> SwipeLeft(artist_id, space_id)
    ["booking_request", artist_id, space_id, start_time, end_time] ->
      BookingRequested(
        artist_id,
        space_id,
        TimeSlot(start_time: start_time, end_time: end_time),
      )
    _ -> SpaceDeleted("invalid")
    // Default case for invalid messages
  }
}

fn serialize_electric_message(msg: ClientMessage) -> String {
  case msg {
    SpaceAdded(space) -> "space_added:" <> space.id <> ":" <> space.name
    SpaceDeleted(space_id) -> "space_deleted:" <> space_id
    SpaceUpdated(space) -> "space_updated:" <> space.id <> ":" <> space.name
    ArtistAdded(artist) -> "artist_added:" <> artist.id <> ":" <> artist.name
    ArtistDeleted(artist_id) -> "artist_deleted:" <> artist_id
    ArtistUpdated(artist) ->
      "artist_updated:" <> artist.id <> ":" <> artist.name
    SwipeRight(artist_id, space_id) ->
      "swipe_right:" <> artist_id <> ":" <> space_id
    SwipeLeft(artist_id, space_id) ->
      "swipe_left:" <> artist_id <> ":" <> space_id
    BookingRequested(artist_id, space_id, time_slot) ->
      "booking_request:"
      <> artist_id
      <> ":"
      <> space_id
      <> ":"
      <> time_slot.start_time
      <> ":"
      <> time_slot.end_time
    MatchCreated(match) ->
      "match_created:"
      <> match.id
      <> ":"
      <> match.artist.id
      <> ":"
      <> match.space.id
      <> ":"
      <> match.matched_at
      <> ":"
      <> int.to_string(float.round(match.compatibility_score *. 100.0))
    MatchDeleted(match_id) -> "match_deleted:" <> match_id
  }
}

pub fn init() -> FindryState {
  let sample_space =
    Space(
      id: "space1",
      name: "Downtown Art Studio",
      space_type: Studio,
      square_footage: 1200,
      equipment_list: ["Easels", "Lighting", "Storage"],
      availability_schedule: [],
      pricing_terms: PricingTerms(
        hourly_rate: 45.0,
        daily_rate: Some(300.0),
        weekly_rate: Some(1200.0),
        monthly_rate: Some(4000.0),
        deposit_required: True,
        deposit_amount: Some(500.0),
      ),
      acoustics_rating: 4,
      lighting_details: LightingDetails(
        natural_light: True,
        adjustable: True,
        color_temperature: Some(5000),
        special_features: [
          "North-facing windows", "Dimmable LED track lighting",
        ],
      ),
      access_hours: AccessHours(
        monday: [TimeSlot(start_time: "09:00", end_time: "21:00")],
        tuesday: [TimeSlot(start_time: "09:00", end_time: "21:00")],
        wednesday: [TimeSlot(start_time: "09:00", end_time: "21:00")],
        thursday: [TimeSlot(start_time: "09:00", end_time: "21:00")],
        friday: [TimeSlot(start_time: "09:00", end_time: "21:00")],
        saturday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        sunday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        special_hours: [],
      ),
      location_data: LocationData(
        address: "123 Artist Way, Creative District",
        latitude: 40.7128,
        longitude: -74.006,
        public_transport: ["Subway: Line A, B", "Bus: 42, 43"],
        parking_available: True,
        loading_zone: True,
        noise_restrictions: ["No amplified music after 9pm"],
      ),
      photos: ["studio1.jpg", "studio2.jpg"],
      virtual_tour_url: Some("https://example.com/tour/downtown-studio"),
    )

  let sample_artist =
    Artist(
      id: "artist1",
      name: "Sarah Chen",
      creative_discipline: ["Painting", "Mixed Media"],
      space_requirements: SpaceRequirements(
        min_square_footage: 800,
        preferred_types: [Studio],
        required_equipment: ["Easels", "Storage"],
        min_acoustics_rating: 3,
        natural_light_required: True,
        storage_needed: True,
        special_requirements: ["Ventilation for oil paints"],
      ),
      project_timeline: TimeSlot(
        start_time: "2024-04-01",
        end_time: "2024-06-30",
      ),
      budget_range: BudgetRange(min: 0.0, max: 2000.0),
      equipment_needs: ["Easels", "Lighting"],
      preferred_hours: AccessHours(
        monday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        tuesday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        wednesday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        thursday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        friday: [TimeSlot(start_time: "10:00", end_time: "18:00")],
        saturday: [],
        sunday: [],
        special_hours: [],
      ),
      portfolio_urls: ["https://example.com/sarah-chen"],
      group_size: 1,
      noise_level: 1,
    )

  let sample_match =
    Match(
      id: "match1",
      artist: sample_artist,
      space: sample_space,
      compatibility_score: 0.92,
      matched_at: "2024-03-11T21:45:00Z",
    )

  FindryState(
    spaces: [sample_space],
    artists: [sample_artist],
    matches: [sample_match],
    db: None,
    subscriptions: [],
  )
}

fn handle_db_error(error: DbError) {
  let error_msg = case error {
    db.ConnectionError(msg) -> "Database Connection Error: " <> msg
    db.QueryError(msg) -> "Database Query Error: " <> msg
    db.ValidationError(msg) -> "Database Validation Error: " <> msg
    db.SubscriptionError(msg) -> "Database Subscription Error: " <> msg
    db.ParseError(msg) -> "Database Parse Error: " <> msg
    db.NetworkError(msg) -> "Database Network Error: " <> msg
  }
  io.println(error_msg)
}

pub fn start() -> Result(process.Subject(FindryActor), actor.StartError) {
  let state = init()

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
