import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute
import lustre/event
import radio/types.{
  type Channel, type Track, type PlayerState,
  type ChannelTheme,
  PlayerState, Music, Talk, Character, Ambient,
}

pub type Model {
  Model(
    channels: List(Channel),
    player_state: PlayerState,
    selected_channel_id: Option(String),
    loading: Bool,
    error: Option(String),
    admin_mode: Bool,
  )
}

pub type Msg {
  // Channel management
  LoadChannels
  ChannelsLoaded(List(Channel))
  SelectChannel(String)
  ChannelSelected(Channel)
  
  // Playback control
  PlayPause
  NextTrack
  PrevTrack
  Seek(Int)
  SetVolume(Float)
  
  // Player events
  TrackEnded
  AudioReady
  AudioError(String)
  PositionUpdate(Int)
  
  // Playlist management
  ShuffleToggle
  RepeatToggle
  
  // Admin functions
  ToggleAdminMode
  AddTrack(Track)
  RemoveTrack(String)
  ReorderTracks(List(Track))
  
  // Error handling
  Error(String)
  ClearError
  
  NoOp
}

pub fn init() -> #(Model, Effect(Msg)) {
  let initial_player_state = PlayerState(
    current_channel: None,
    current_track: None,
    is_playing: False,
    position: 0,
    volume: 0.8,
    next_tracks: [],
    last_bumper_time: None,
  )
  
  let model = Model(
    channels: [],
    player_state: initial_player_state,
    selected_channel_id: None,
    loading: True,
    error: None,
    admin_mode: False,
  )
  
  #(model, load_channels_effect())
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    LoadChannels -> #(
      Model(..model, loading: True, error: None),
      load_channels_effect(),
    )
    
    ChannelsLoaded(channels) -> #(
      Model(..model, channels: channels, loading: False),
      effect.none(),
    )
    
    SelectChannel(channel_id) -> {
      case find_channel(model.channels, channel_id) {
        Some(channel) -> #(
          Model(..model, selected_channel_id: Some(channel_id)),
          select_channel_effect(channel),
        )
        None -> #(
          Model(..model, error: Some("Channel not found")),
          effect.none(),
        )
      }
    }
    
    ChannelSelected(channel) -> {
      let updated_player = PlayerState(
        ..model.player_state,
        current_channel: Some(channel),
        current_track: get_current_track(channel),
        next_tracks: get_next_tracks(channel),
      )
      #(
        Model(..model, player_state: updated_player),
        effect.none(),
      )
    }
    
    PlayPause -> {
      let new_playing = !model.player_state.is_playing
      let updated_player = PlayerState(
        ..model.player_state,
        is_playing: new_playing,
      )
      #(
        Model(..model, player_state: updated_player),
        case new_playing {
          True -> play_audio_effect()
          False -> pause_audio_effect()
        },
      )
    }
    
    NextTrack -> {
      case model.player_state.current_channel {
        Some(channel) -> {
          let next_track = get_next_track(channel)
          let updated_player = PlayerState(
            ..model.player_state,
            current_track: next_track,
            position: 0,
            next_tracks: get_next_tracks_after(channel, next_track),
          )
          #(
            Model(..model, player_state: updated_player),
            case next_track {
              Some(track) -> play_track_effect(track)
              None -> effect.none()
            },
          )
        }
        None -> #(model, effect.none())
      }
    }
    
    PrevTrack -> {
      case model.player_state.current_channel {
        Some(channel) -> {
          let prev_track = get_prev_track(channel)
          let updated_player = PlayerState(
            ..model.player_state,
            current_track: prev_track,
            position: 0,
          )
          #(
            Model(..model, player_state: updated_player),
            case prev_track {
              Some(track) -> play_track_effect(track)
              None -> effect.none()
            },
          )
        }
        None -> #(model, effect.none())
      }
    }
    
    Seek(position) -> {
      let updated_player = PlayerState(
        ..model.player_state,
        position: position,
      )
      #(
        Model(..model, player_state: updated_player),
        seek_audio_effect(position),
      )
    }
    
    SetVolume(volume) -> {
      let clamped_volume = case volume <. 0.0, volume >. 1.0 {
        True, _ -> 0.0
        _, True -> 1.0
        False, False -> volume
      }
      let updated_player = PlayerState(
        ..model.player_state,
        volume: clamped_volume,
      )
      #(
        Model(..model, player_state: updated_player),
        set_volume_effect(clamped_volume),
      )
    }
    
    TrackEnded -> {
      // Auto-advance to next track
      update(model, NextTrack)
    }
    
    PositionUpdate(position) -> {
      let updated_player = PlayerState(
        ..model.player_state,
        position: position,
      )
      #(
        Model(..model, player_state: updated_player),
        check_bumper_trigger_effect(model.player_state.current_channel, position),
      )
    }
    
    ToggleAdminMode -> #(
      Model(..model, admin_mode: !model.admin_mode),
      effect.none(),
    )
    
    Error(message) -> #(
      Model(..model, error: Some(message), loading: False),
      effect.none(),
    )
    
    ClearError -> #(
      Model(..model, error: None),
      effect.none(),
    )
    
    _ -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("pockets-radio")], [
    case model.loading {
      True -> loading_view()
      False -> radio_interface(model)
    },
    case model.error {
      Some(error) -> error_banner(error)
      None -> html.div([], [])
    },
  ])
}

fn radio_interface(model: Model) -> Element(Msg) {
  html.div([attribute.class("radio-container")], [
    channel_selector(model.channels, model.selected_channel_id),
    player_view(model.player_state),
    case model.admin_mode {
      True -> admin_panel(model)
      False -> html.div([], [])
    },
  ])
}

fn channel_selector(channels: List(Channel), selected_id: Option(String)) -> Element(Msg) {
  html.div([attribute.class("channel-selector")], [
    html.div([attribute.class("radio-header")], [
      html.h3([], [html.text("📻 Pockets Radio")]),
      html.button([
        attribute.class("admin-toggle-btn"),
        event.on_click(ToggleAdminMode),
      ], [html.text("🎚️ Admin")]),
    ]),
    html.div([attribute.class("channel-grid")], 
      list.map(channels, fn(channel) {
        let is_selected = case selected_id {
          Some(id) -> id == channel.id
          None -> False
        }
        
        html.button([
          attribute.class(case is_selected {
            True -> "channel-button selected"
            False -> "channel-button"
          }),
          event.on_click(SelectChannel(channel.id)),
        ], [
          html.div([attribute.class("channel-name")], [html.text(channel.name)]),
          html.div([attribute.class("channel-theme")], [html.text(theme_to_emoji(channel.theme))]),
          html.div([attribute.class("channel-desc")], [html.text(channel.description)]),
        ])
      })
    ),
  ])
}

fn player_view(player_state: PlayerState) -> Element(Msg) {
  html.div([attribute.class("player")], [
    current_track_display(player_state.current_track),
    playback_controls(player_state.is_playing),
    progress_bar(player_state.position, get_track_duration(player_state.current_track)),
    volume_control(player_state.volume),
    next_tracks_preview(player_state.next_tracks),
  ])
}

fn current_track_display(track: Option(Track)) -> Element(Msg) {
  case track {
    Some(t) -> html.div([attribute.class("now-playing")], [
      html.div([attribute.class("track-title")], [html.text(t.title)]),
      html.div([attribute.class("track-artist")], [
        html.text(case t.artist {
          Some(artist) -> artist
          None -> "Unknown Artist"
        })
      ]),
    ])
    None -> html.div([attribute.class("now-playing empty")], [
      html.text("Select a channel to start listening")
    ])
  }
}

fn playback_controls(is_playing: Bool) -> Element(Msg) {
  html.div([attribute.class("playback-controls")], [
    html.button([
      attribute.class("control-btn"),
      event.on_click(PrevTrack),
    ], [html.text("⏮️")]),
    
    html.button([
      attribute.class("play-pause-btn"),
      event.on_click(PlayPause),
    ], [html.text(case is_playing {
      True -> "⏸️"
      False -> "▶️"
    })]),
    
    html.button([
      attribute.class("control-btn"),
      event.on_click(NextTrack),
    ], [html.text("⏭️")]),
  ])
}

fn progress_bar(position: Int, duration: Int) -> Element(Msg) {
  let progress_percent = case duration {
    0 -> 0.0
    d -> int_to_float(position) /. int_to_float(d) *. 100.0
  }
  
  html.div([attribute.class("progress-container")], [
    html.div([
      attribute.class("progress-bar"),
      event.on_click(Seek(0)), // TODO: Calculate actual position from click
    ], [
      html.div([
        attribute.class("progress-fill"),
        attribute.style("width", float_to_string(progress_percent) <> "%"),
      ], []),
    ]),
    html.div([attribute.class("time-display")], [
      html.text(format_time(position) <> " / " <> format_time(duration)),
    ]),
  ])
}

fn volume_control(volume: Float) -> Element(Msg) {
  html.div([attribute.class("volume-control")], [
    html.text("🔊"),
    html.input([
      attribute.type_("range"),
      attribute.min("0"),
      attribute.max("100"),
      attribute.value(float_to_string(volume *. 100.0)),
      event.on_input(fn(value) {
        float.parse(value)
        |> result.map(fn(v) { SetVolume(v /. 100.0) })
        |> result.unwrap(NoOp)
      }),
    ]),
  ])
}

fn next_tracks_preview(tracks: List(Track)) -> Element(Msg) {
  html.div([attribute.class("next-tracks")], [
    html.h4([], [html.text("Up Next:")]),
    html.div([attribute.class("track-list")], 
      list.take(tracks, 3)
      |> list.map(fn(track) {
        html.div([attribute.class("track-preview")], [
          html.text(track.title <> case track.artist {
            Some(artist) -> " - " <> artist
            None -> ""
          })
        ])
      })
    ),
  ])
}

fn admin_panel(_model: Model) -> Element(Msg) {
  html.div([attribute.class("admin-panel")], [
    html.h3([], [html.text("🎚️ Admin Controls")]),
    html.button([
      attribute.class("admin-btn"),
      event.on_click(ToggleAdminMode),
    ], [html.text("Close Admin")]),
    // TODO: Add upload, reorder, delete controls
  ])
}

fn loading_view() -> Element(Msg) {
  html.div([attribute.class("loading")], [
    html.text("Loading Pockets Radio...")
  ])
}

fn error_banner(error: String) -> Element(Msg) {
  html.div([attribute.class("error-banner")], [
    html.text("Error: " <> error),
    html.button([
      attribute.class("close-error"),
      event.on_click(ClearError),
    ], [html.text("×")]),
  ])
}

// Helper functions
fn result_to_option(result: Result(a, b)) -> Option(a) {
  case result {
    Ok(value) -> Some(value)
    _ -> None
  }
}

fn find_channel(channels: List(Channel), id: String) -> Option(Channel) {
  list.find(channels, fn(channel) { channel.id == id })
  |> result_to_option()
}

fn get_current_track(channel: Channel) -> Option(Track) {
  case channel.playlist.tracks {
    [] -> None
    tracks -> {
      case channel.playlist.current_index < list.length(tracks) {
        True -> list.drop(tracks, channel.playlist.current_index) |> list.first() |> result_to_option()
        False -> None
      }
    }
  }
}

fn get_next_tracks(channel: Channel) -> List(Track) {
  let remaining = list.drop(channel.playlist.tracks, channel.playlist.current_index + 1)
  case channel.playlist.repeat {
    True -> list.append(remaining, channel.playlist.tracks)
    False -> remaining
  }
}

fn get_next_track(channel: Channel) -> Option(Track) {
  get_next_tracks(channel) |> list.first() |> result_to_option()
}

fn get_next_tracks_after(channel: Channel, _track: Option(Track)) -> List(Track) {
  get_next_tracks(channel) |> list.drop(1)
}

fn get_prev_track(_channel: Channel) -> Option(Track) {
  // TODO: Implement previous track logic
  None
}

fn get_track_duration(track: Option(Track)) -> Int {
  case track {
    Some(t) -> t.duration
    None -> 0
  }
}

fn theme_to_emoji(theme: ChannelTheme) -> String {
  case theme {
    Music(_, _) -> "🎵"
    Talk(_, _) -> "🎙️"
    Character(_, _) -> "🎭"
    Ambient(_) -> "🌙"
  }
}

fn format_time(seconds: Int) -> String {
  let minutes = seconds / 60
  let secs = seconds % 60
  string.pad_start(int_to_string(minutes), 2, "0") <> ":" <> string.pad_start(int_to_string(secs), 2, "0")
}

// External function declarations for FFI
@external(javascript, "./radio_ffi.js", "loadChannels")
fn load_channels_ffi() -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "selectChannel")
fn select_channel_ffi(channel: Channel) -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "playAudio")
fn play_audio_ffi() -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "pauseAudio")
fn pause_audio_ffi() -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "playTrack")
fn play_track_ffi(track: Track) -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "seekAudio")
fn seek_audio_ffi(position: Int) -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "setVolume")
fn set_volume_ffi(volume: Float) -> fn(fn(Msg) -> Nil) -> Nil

@external(javascript, "./radio_ffi.js", "checkBumperTrigger")
fn check_bumper_trigger_ffi(channel: Option(Channel), position: Int) -> fn(fn(Msg) -> Nil) -> Nil

// Wrapper functions to create proper effects
fn load_channels_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    load_channels_ffi()(dispatch)
  })
}

fn select_channel_effect(channel: Channel) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    select_channel_ffi(channel)(dispatch)
  })
}

fn play_audio_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    play_audio_ffi()(dispatch)
  })
}

fn pause_audio_effect() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    pause_audio_ffi()(dispatch)
  })
}

fn play_track_effect(track: Track) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    play_track_ffi(track)(dispatch)
  })
}

fn seek_audio_effect(position: Int) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    seek_audio_ffi(position)(dispatch)
  })
}

fn set_volume_effect(volume: Float) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    set_volume_ffi(volume)(dispatch)
  })
}

fn check_bumper_trigger_effect(channel: Option(Channel), position: Int) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    check_bumper_trigger_ffi(channel, position)(dispatch)
  })
}

// Helper function for float/int conversion
fn int_to_float(i: Int) -> Float {
  int.to_float(i)
}

fn float_to_string(f: Float) -> String {
  float.to_string(f)
}

fn int_to_string(i: Int) -> String {
  int.to_string(i)
}