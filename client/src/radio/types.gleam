pub type Channel {
  Channel(
    id: String,
    name: String,
    // "Main", "Talk", "Night Vibes"
    description: String,
    theme: ChannelTheme,
    playlist: Playlist,
    schedule: Option(Schedule),
    is_active: Bool,
  )
}

pub type ChannelTheme {
  Music(genre: String, mood: String)
  Talk(host: String, format: String)
  Character(name: String, personality: String)
  Ambient(setting: String)
  // "truck cab", "forest", "city"
}

pub type Playlist {
  Playlist(
    tracks: List(Track),
    bumpers: List(Bumper),
    current_index: Int,
    shuffle: Bool,
    repeat: Bool,
  )
}

pub type Track {
  Track(
    id: String,
    title: String,
    artist: Option(String),
    duration: Int,
    file_url: String,
    // CDN URL
    metadata: TrackMetadata,
  )
}

pub type Bumper {
  Bumper(
    id: String,
    content: String,
    // "You're listening to...", lore quotes
    voice: String,
    // "host", "character_name"
    file_url: String,
    trigger: BumperTrigger,
  )
}

pub type BumperTrigger {
  EveryNTracks(Int)
  TimeInterval(Int)
  // minutes
  Manual
}

pub type TrackMetadata {
  TrackMetadata(
    genre: Option(String),
    year: Option(Int),
    album: Option(String),
    tags: List(String),
    uploaded_by: Option(String),
    upload_date: Option(String),
  )
}

pub type Schedule {
  Schedule(
    timezone: String,
    slots: List(ScheduleSlot),
  )
}

pub type ScheduleSlot {
  ScheduleSlot(
    day_of_week: Int, // 0-6, Sunday = 0
    start_time: String, // "14:30"
    end_time: String, // "16:00"
    content_type: ScheduleContent,
  )
}

pub type ScheduleContent {
  PlaylistLoop(playlist_id: String)
  LiveShow(host: String, description: String)
  SpecialProgram(name: String, playlist_id: String)
}

pub type PlayerState {
  PlayerState(
    current_channel: Option(Channel),
    current_track: Option(Track),
    is_playing: Bool,
    position: Int, // seconds
    volume: Float, // 0.0 - 1.0
    next_tracks: List(Track),
    last_bumper_time: Option(Int),
  )
}

pub type RadioEvent {
  ChannelChanged(Channel)
  TrackStarted(Track)
  TrackEnded(Track)
  BumperPlayed(Bumper)
  PlaybackStateChanged(Bool)
  PositionUpdated(Int)
  VolumeChanged(Float)
}
