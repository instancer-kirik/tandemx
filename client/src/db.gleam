import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

pub type Meeting {
  Meeting(
    id: String,
    title: String,
    description: String,
    date: String,
    start_time: String,
    duration_minutes: Int,
    timezone: String,
  )
}

pub type Contact {
  Contact(
    id: String,
    full_name: String,
    email: String,
    phone: String,
    company: String,
    job_title: String,
    contact_type: String,
    notes: String,
  )
}

pub type CalendarEvent {
  CalendarEvent(
    id: String,
    title: String,
    description: String,
    start_timestamp: String,
    end_timestamp: String,
    calendar_system: String,
    category: String,
  )
}

pub type BlogPost {
  BlogPost(
    id: String,
    title: String,
    content: String,
    excerpt: Option(String),
    date: String,
    author: String,
    category: String,
    image: Option(String),
    published: Bool,
  )
}

pub type CalendarSystem {
  Gregorian
  MayanLongCount
  MayanTzolkin
  MayanHaab
  Chinese
  Islamic
  Hebrew
}

pub type CalendarVariant {
  GregorianJulian
  GregorianRevised
  GregorianAstronomical
  MayanClassic
  MayanGMT
  MayanSpinden
  ChineseAstronomical
  ChineseTraditional
  IslamicAstronomical
  IslamicCivil
  IslamicObserved
  HebrewAstronomical
  HebrewTraditional
}

pub type PlanetModel {
  PlanetModel(
    id: String,
    planet_name: String,
    description: String,
    scale_km: Float,
    rotation_period_hours: Option(Float),
    orbital_period_days: Option(Float),
    axial_tilt_degrees: Option(Float),
  )
}

pub type InterestSubmission {
  InterestSubmission(
    project: String,
    email: String,
    name: String,
    company: Option(String),
    message: String,
  )
}

pub type Campaign {
  Campaign(
    id: String,
    title: String,
    description: String,
    start_timestamp: String,
    end_timestamp: String,
    calendar_system: String,
    category: String,
  )
}

pub type Post {
  Post(
    id: String,
    title: String,
    content: String,
    excerpt: Option(String),
    image: Option(String),
    date: String,
    author: String,
    category: String,
    published: Bool,
  )
}

pub type Planet {
  Planet(
    id: String,
    planet_name: String,
    description: String,
    scale_km: Float,
    rotation_period_hours: Option(Float),
    orbital_period_days: Option(Float),
    axial_tilt_degrees: Option(Float),
  )
}

@external(javascript, "./db_ffi.js", "initDb")
pub fn init() -> Dynamic

@external(javascript, "./db_ffi.js", "createMeeting")
pub fn create_meeting(meeting: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "getMeeting")
pub fn get_meeting(id: String) -> Dynamic

@external(javascript, "./db_ffi.js", "listMeetings")
pub fn list_meetings() -> Dynamic

@external(javascript, "./db_ffi.js", "updateMeeting")
pub fn update_meeting(id: String, updates: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "deleteMeeting")
pub fn delete_meeting(id: String) -> Dynamic

@external(javascript, "./db_ffi.js", "createContact")
pub fn create_contact(contact: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "getContact")
pub fn get_contact(id: String) -> Dynamic

@external(javascript, "./db_ffi.js", "listContacts")
pub fn list_contacts() -> Dynamic

@external(javascript, "./db_ffi.js", "createCalendarEvent")
pub fn create_calendar_event(event: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "getCalendarEvent")
pub fn get_calendar_event(id: String) -> Dynamic

@external(javascript, "./db_ffi.js", "listCalendarEvents")
pub fn list_calendar_events(start_date: String, end_date: String) -> Dynamic

@external(javascript, "./db_ffi.js", "createBlogPost")
pub fn create_blog_post(post: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "getBlogPost")
pub fn get_blog_post(id: String) -> Dynamic

@external(javascript, "./db_ffi.js", "listBlogPosts")
pub fn list_blog_posts(options: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "updateBlogPost")
pub fn update_blog_post(id: String, updates: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "deleteBlogPost")
pub fn delete_blog_post(id: String) -> Dynamic

@external(javascript, "./db_ffi.js", "getCalendarEpochs")
pub fn get_calendar_epochs(calendar_system: String) -> Dynamic

@external(javascript, "./db_ffi.js", "convertCalendarDate")
pub fn convert_calendar_date(params: Dynamic) -> Dynamic

@external(javascript, "./db_ffi.js", "getCalendarSpecialDays")
pub fn get_calendar_special_days(calendar_system: String) -> Dynamic

@external(javascript, "./db_ffi.js", "getPlanetModels")
pub fn get_planet_models() -> Dynamic

@external(javascript, "./db_ffi.js", "getPlanetModel")
pub fn get_planet_model(name: String) -> Dynamic

@external(javascript, "./db_ffi.js", "createInterestSubmission")
pub fn create_interest_submission(submission: Dynamic) -> Dynamic

// Helper functions to convert between Gleam types and JavaScript objects
pub fn meeting_to_json(meeting: Meeting) -> Dynamic {
  json.object([
    #("id", json.string(meeting.id)),
    #("title", json.string(meeting.title)),
    #("description", json.string(meeting.description)),
    #("date", json.string(meeting.date)),
    #("start_time", json.string(meeting.start_time)),
    #("duration_minutes", json.int(meeting.duration_minutes)),
    #("timezone", json.string(meeting.timezone)),
  ])
  |> json.to_string
  |> dynamic.from
}

fn meeting_decoder() -> decode.Decoder(Meeting) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.string)
    use date <- decode.field("date", decode.string)
    use start_time <- decode.field("start_time", decode.string)
    use duration_minutes <- decode.field("duration_minutes", decode.int)
    use timezone <- decode.field("timezone", decode.string)
    decode.success(Meeting(
      id,
      title,
      description,
      date,
      start_time,
      duration_minutes,
      timezone,
    ))
  }
}

pub fn json_to_meeting(data: Dynamic) -> Result(Meeting, String) {
  decode.run(data, meeting_decoder())
  |> result.map_error(fn(_errors) { "Failed to decode meeting data" })
}

pub fn contact_to_json(contact: Contact) -> Dynamic {
  json.object([
    #("id", json.string(contact.id)),
    #("full_name", json.string(contact.full_name)),
    #("email", json.string(contact.email)),
    #("phone", json.string(contact.phone)),
    #("company", json.string(contact.company)),
    #("job_title", json.string(contact.job_title)),
    #("contact_type", json.string(contact.contact_type)),
    #("notes", json.string(contact.notes)),
  ])
  |> json.to_string
  |> dynamic.from
}

fn contact_decoder() -> decode.Decoder(Contact) {
  {
    use id <- decode.field("id", decode.string)
    use full_name <- decode.field("full_name", decode.string)
    use email <- decode.field("email", decode.string)
    use phone <- decode.field("phone", decode.string)
    use company <- decode.field("company", decode.string)
    use job_title <- decode.field("job_title", decode.string)
    use contact_type <- decode.field("contact_type", decode.string)
    use notes <- decode.field("notes", decode.string)
    decode.success(Contact(
      id,
      full_name,
      email,
      phone,
      company,
      job_title,
      contact_type,
      notes,
    ))
  }
}

pub fn json_to_contact(data: Dynamic) -> Result(Contact, String) {
  decode.run(data, contact_decoder())
  |> result.map_error(fn(_errors) { "Failed to decode contact data" })
}

pub fn calendar_event_to_json(event: CalendarEvent) -> Dynamic {
  json.object([
    #("id", json.string(event.id)),
    #("title", json.string(event.title)),
    #("description", json.string(event.description)),
    #("start_timestamp", json.string(event.start_timestamp)),
    #("end_timestamp", json.string(event.end_timestamp)),
    #("calendar_system", json.string(event.calendar_system)),
    #("category", json.string(event.category)),
  ])
  |> json.to_string
  |> dynamic.from
}

fn calendar_event_field_decoder() -> decode.Decoder(CalendarEvent) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.string)
    use start_timestamp <- decode.field("start_timestamp", decode.string)
    use end_timestamp <- decode.field("end_timestamp", decode.string)
    use calendar_system <- decode.field("calendar_system", decode.string)
    use category <- decode.field("category", decode.string)
    decode.success(CalendarEvent(
      id,
      title,
      description,
      start_timestamp,
      end_timestamp,
      calendar_system,
      category,
    ))
  }
}

pub fn json_to_calendar_event(data: Dynamic) -> Result(CalendarEvent, String) {
  decode.run(data, calendar_event_field_decoder())
  |> result.map_error(fn(_errors) { "Failed to decode calendar event data" })
}

pub fn blog_post_to_json(post: BlogPost) -> Dynamic {
  json.object([
    #("id", json.string(post.id)),
    #("title", json.string(post.title)),
    #("content", json.string(post.content)),
    #("excerpt", case post.excerpt {
      Some(e) -> json.string(e)
      None -> json.null()
    }),
    #("date", json.string(post.date)),
    #("author", json.string(post.author)),
    #("category", json.string(post.category)),
    #("image", case post.image {
      Some(i) -> json.string(i)
      None -> json.null()
    }),
    #("published", json.bool(post.published)),
  ])
  |> json.to_string
  |> dynamic.from
}

fn blog_post_decoder() -> decode.Decoder(BlogPost) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use content <- decode.field("content", decode.string)
    use excerpt <- decode.field("excerpt", decode.optional(decode.string))
    use image <- decode.field("image", decode.optional(decode.string))
    use date <- decode.field("date", decode.string)
    use author <- decode.field("author", decode.string)
    use category <- decode.field("category", decode.string)
    use published <- decode.field("published", decode.bool)
    decode.success(BlogPost(
      id,
      title,
      content,
      excerpt,
      date,
      author,
      category,
      image,
      published,
    ))
  }
}

pub fn json_to_blog_post(data: Dynamic) -> Result(BlogPost, String) {
  decode.run(data, blog_post_decoder())
  |> result.map_error(fn(_errors) { "Failed to decode blog post data" })
}

pub fn interest_submission_to_json(submission: InterestSubmission) -> Dynamic {
  json.object([
    #("project", json.string(submission.project)),
    #("email", json.string(submission.email)),
    #("name", json.string(submission.name)),
    #("company", case submission.company {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("message", json.string(submission.message)),
  ])
  |> json.to_string
  |> dynamic.from
}

fn planet_model_decoder() -> decode.Decoder(PlanetModel) {
  {
    use id <- decode.field("id", decode.string)
    use planet_name <- decode.field("planet_name", decode.string)
    use description <- decode.field("description", decode.string)
    use scale_km <- decode.field("scale_km", decode.float)
    use rotation_period_hours <- decode.field(
      "rotation_period_hours",
      decode.optional(decode.float),
    )
    use orbital_period_days <- decode.field(
      "orbital_period_days",
      decode.optional(decode.float),
    )
    use axial_tilt_degrees <- decode.field(
      "axial_tilt_degrees",
      decode.optional(decode.float),
    )
    decode.success(PlanetModel(
      id,
      planet_name,
      description,
      scale_km,
      rotation_period_hours,
      orbital_period_days,
      axial_tilt_degrees,
    ))
  }
}

pub fn json_to_planet_model(data: Dynamic) -> Result(PlanetModel, String) {
  decode.run(data, planet_model_decoder())
  |> result.map_error(fn(_errors) { "Failed to decode planet model data" })
}

// Helper functions for calendar conversion
pub fn calendar_system_to_string(system: CalendarSystem) -> String {
  case system {
    Gregorian -> "gregorian"
    MayanLongCount -> "mayan_long_count"
    MayanTzolkin -> "mayan_tzolkin"
    MayanHaab -> "mayan_haab"
    Chinese -> "chinese"
    Islamic -> "islamic"
    Hebrew -> "hebrew"
  }
}

pub fn calendar_variant_to_string(variant: CalendarVariant) -> String {
  case variant {
    GregorianJulian -> "gregorian_julian"
    GregorianRevised -> "gregorian_revised"
    GregorianAstronomical -> "gregorian_astronomical"
    MayanClassic -> "mayan_classic"
    MayanGMT -> "mayan_goodman_martinez_thompson"
    MayanSpinden -> "mayan_spinden"
    ChineseAstronomical -> "chinese_astronomical"
    ChineseTraditional -> "chinese_traditional"
    IslamicAstronomical -> "islamic_astronomical"
    IslamicCivil -> "islamic_civil"
    IslamicObserved -> "islamic_observed"
    HebrewAstronomical -> "hebrew_astronomical"
    HebrewTraditional -> "hebrew_traditional"
  }
}

// Calendar conversion helper - directly take a pre-built params object
pub fn convert_calendar_date_with_json(params_json: String) -> Dynamic {
  dynamic.from(params_json)
  |> convert_calendar_date
}

// Helper function to construct a simple conversion params object
pub fn calendar_conversion_params(
  source_calendar: String,
  source_variant: String,
  source_components_json: String,
  target_calendar: String,
  target_variant: String,
) -> String {
  "{\n"
  <> "  \"sourceCalendar\": \""
  <> source_calendar
  <> "\",\n"
  <> "  \"sourceVariant\": \""
  <> source_variant
  <> "\",\n"
  <> "  \"sourceComponents\": "
  <> source_components_json
  <> ",\n"
  <> "  \"targetCalendar\": \""
  <> target_calendar
  <> "\",\n"
  <> "  \"targetVariant\": \""
  <> target_variant
  <> "\"\n"
  <> "}"
}

// Campaign Decoder
fn campaign_decoder() -> decode.Decoder(Campaign) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use description <- decode.field("description", decode.string)
    use start_timestamp <- decode.field("start_timestamp", decode.string)
    use end_timestamp <- decode.field("end_timestamp", decode.string)
    use calendar_system <- decode.field("calendar_system", decode.string)
    use category <- decode.field("category", decode.string)
    decode.success(Campaign(
      id,
      title,
      description,
      start_timestamp,
      end_timestamp,
      calendar_system,
      category,
    ))
  }
}

pub fn decode_campaign(
  data: dynamic.Dynamic,
) -> Result(Campaign, List(decode.DecodeError)) {
  decode.run(data, campaign_decoder())
}

// Post Decoder
fn post_decoder() -> decode.Decoder(Post) {
  {
    use id <- decode.field("id", decode.string)
    use title <- decode.field("title", decode.string)
    use content <- decode.field("content", decode.string)
    use excerpt <- decode.field("excerpt", decode.optional(decode.string))
    // Optional field
    use image <- decode.field("image", decode.optional(decode.string))
    // Optional field
    use date <- decode.field("date", decode.string)
    use author <- decode.field("author", decode.string)
    use category <- decode.field("category", decode.string)
    use published <- decode.field("published", decode.bool)
    decode.success(Post(
      id,
      title,
      content,
      excerpt,
      image,
      date,
      author,
      category,
      published,
    ))
  }
}

pub fn decode_post(
  data: dynamic.Dynamic,
) -> Result(Post, List(decode.DecodeError)) {
  decode.run(data, post_decoder())
}

// Planet Decoder
fn planet_decoder() -> decode.Decoder(Planet) {
  {
    use id <- decode.field("id", decode.string)
    use planet_name <- decode.field("planet_name", decode.string)
    use description <- decode.field("description", decode.string)
    use scale_km <- decode.field("scale_km", decode.float)
    use rotation_period_hours <- decode.field(
      "rotation_period_hours",
      decode.optional(decode.float),
    )
    use orbital_period_days <- decode.field(
      "orbital_period_days",
      decode.optional(decode.float),
    )
    use axial_tilt_degrees <- decode.field(
      "axial_tilt_degrees",
      decode.optional(decode.float),
    )
    decode.success(Planet(
      id,
      planet_name,
      description,
      scale_km,
      rotation_period_hours,
      orbital_period_days,
      axial_tilt_degrees,
    ))
  }
}

pub fn decode_planet(
  data: dynamic.Dynamic,
) -> Result(Planet, List(decode.DecodeError)) {
  decode.run(data, planet_decoder())
}
