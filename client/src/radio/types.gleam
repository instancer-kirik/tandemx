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
