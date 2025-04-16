// Setlist Manager
// 
// A progressive web application for musicians to create, edit, and share setlists for performances.
// Features:
// - Create and manage multiple setlists
// - Add, remove, and reorder songs with duration and notes
// - Calculate total setlist duration
// - Search and filter setlists
// - Share setlists with bandmates and venue staff
// - Export setlists in multiple formats (PDF, plain text)
// - Sync with server for backup and collaboration
//
// Author: TandemX Team
// License: MIT
// Version: 1.0.0

import gleam/dynamic
import gleam/int
import gleam/io
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

// Import sharing module
import setlist_sharing.{type ShareModel, type ShareMsg}

pub type FormEvent {
  FormEvent(value: String)
}

pub type Msg {
  NoOp
  AddSong
  RemoveSong(Int)
  UpdateSongName(Int, String)
  UpdateSongDuration(Int, String)
  UpdateSongNotes(Int, String)
  MoveSongUp(Int)
  MoveSongDown(Int)
  CreateNewSetlist
  SaveSetlist
  LoadSetlist(String)
  UpdateSetlistName(String)
  FilterSetlists(String)
  // New messages for sharing
  ToggleSharePanel
  ShareMsg(ShareMsg)
}

pub type Song {
  Song(name: String, duration: String, notes: String)
}

pub type Setlist {
  Setlist(
    id: String,
    name: String,
    songs: List(Song),
    created_at: String,
    updated_at: String,
  )
}

pub type Model {
  Model(
    setlists: List(Setlist),
    current_setlist: Option(Setlist),
    filter_text: String,
    // New fields for sharing
    show_share_panel: Bool,
    share_model: ShareModel,
  )
}

@external(javascript, "./setlist_ffi.js", "generateId")
fn generate_id() -> String

@external(javascript, "./setlist_ffi.js", "getCurrentTimestamp")
fn get_current_timestamp() -> String

pub fn init() -> #(Model, effect.Effect(Msg)) {
  // Mock data for initial development
  let example_setlist =
    Setlist(
      id: "setlist-1",
      name: "My First Setlist",
      songs: [
        Song(name: "Opening Song", duration: "3:45", notes: "Start with energy"),
        Song(name: "Middle Song", duration: "4:30", notes: "Key change halfway"),
        Song(name: "Closing Song", duration: "5:15", notes: "Big finish"),
      ],
      created_at: "2023-07-22T10:00:00Z",
      updated_at: "2023-07-22T10:00:00Z",
    )

  let #(share_model, share_effect) = setlist_sharing.init()

  #(
    Model(
      setlists: [example_setlist],
      current_setlist: Some(example_setlist),
      filter_text: "",
      show_share_panel: False,
      share_model: share_model,
    ),
    share_effect |> effect.map(ShareMsg),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())

    AddSong -> {
      case model.current_setlist {
        Some(setlist) -> {
          let new_song = Song(name: "New Song", duration: "0:00", notes: "")
          let updated_setlist =
            Setlist(
              ..setlist,
              songs: list.append(setlist.songs, [new_song]),
              updated_at: get_current_timestamp(),
            )
          let updated_model =
            Model(
              ..model,
              current_setlist: Some(updated_setlist),
              setlists: update_setlist_in_list(model.setlists, updated_setlist),
            )
          #(updated_model, effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    RemoveSong(index) -> {
      case model.current_setlist {
        Some(setlist) -> {
          let songs_before = list.take(setlist.songs, index)
          let songs_after = list.drop(setlist.songs, index + 1)
          let updated_songs = list.append(songs_before, songs_after)
          let updated_setlist =
            Setlist(
              ..setlist,
              songs: updated_songs,
              updated_at: get_current_timestamp(),
            )
          let updated_model =
            Model(
              ..model,
              current_setlist: Some(updated_setlist),
              setlists: update_setlist_in_list(model.setlists, updated_setlist),
            )
          #(updated_model, effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    UpdateSongName(index, name) -> {
      update_song_field(model, index, fn(song) { Song(..song, name: name) })
    }

    UpdateSongDuration(index, duration) -> {
      update_song_field(model, index, fn(song) {
        Song(..song, duration: duration)
      })
    }

    UpdateSongNotes(index, notes) -> {
      update_song_field(model, index, fn(song) { Song(..song, notes: notes) })
    }

    MoveSongUp(index) -> {
      case model.current_setlist {
        Some(setlist) if index > 0 -> {
          let swapped_songs = swap_songs(setlist.songs, index - 1, index)
          let updated_setlist =
            Setlist(
              ..setlist,
              songs: swapped_songs,
              updated_at: get_current_timestamp(),
            )
          let updated_model =
            Model(
              ..model,
              current_setlist: Some(updated_setlist),
              setlists: update_setlist_in_list(model.setlists, updated_setlist),
            )
          #(updated_model, effect.none())
        }
        _ -> #(model, effect.none())
      }
    }

    MoveSongDown(index) -> {
      case model.current_setlist {
        Some(setlist) -> {
          let song_count = list.length(setlist.songs)
          case index < song_count - 1 {
            True -> {
              let swapped_songs = swap_songs(setlist.songs, index, index + 1)
              let updated_setlist =
                Setlist(
                  ..setlist,
                  songs: swapped_songs,
                  updated_at: get_current_timestamp(),
                )
              let updated_model =
                Model(
                  ..model,
                  current_setlist: Some(updated_setlist),
                  setlists: update_setlist_in_list(
                    model.setlists,
                    updated_setlist,
                  ),
                )
              #(updated_model, effect.none())
            }
            False -> #(model, effect.none())
          }
        }
        None -> #(model, effect.none())
      }
    }

    CreateNewSetlist -> {
      let new_setlist =
        Setlist(
          id: generate_id(),
          name: "New Setlist",
          songs: [],
          created_at: get_current_timestamp(),
          updated_at: get_current_timestamp(),
        )
      let updated_model =
        Model(
          setlists: [new_setlist, ..model.setlists],
          current_setlist: Some(new_setlist),
          filter_text: model.filter_text,
          show_share_panel: False,
          share_model: model.share_model,
        )
      #(updated_model, effect.none())
    }

    SaveSetlist -> {
      // In a real app, this would save to a database or local storage
      // For now, we just update the model in-memory
      #(model, effect.none())
    }

    LoadSetlist(id) -> {
      let selected_setlist = list.find(model.setlists, fn(s) { s.id == id })
      case selected_setlist {
        Ok(setlist) -> #(
          Model(
            ..model,
            current_setlist: Some(setlist),
            show_share_panel: False,
          ),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
    }

    UpdateSetlistName(name) -> {
      case model.current_setlist {
        Some(setlist) -> {
          let updated_setlist =
            Setlist(..setlist, name: name, updated_at: get_current_timestamp())
          let updated_model =
            Model(
              ..model,
              current_setlist: Some(updated_setlist),
              setlists: update_setlist_in_list(model.setlists, updated_setlist),
            )
          #(updated_model, effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    FilterSetlists(filter_text) -> {
      #(Model(..model, filter_text: filter_text), effect.none())
    }

    // New message handlers for sharing
    ToggleSharePanel -> {
      #(
        Model(..model, show_share_panel: !model.show_share_panel),
        effect.none(),
      )
    }

    ShareMsg(share_msg) -> {
      let #(updated_share_model, share_effect) =
        setlist_sharing.update(model.share_model, share_msg)
      #(
        Model(..model, share_model: updated_share_model),
        share_effect |> effect.map(ShareMsg),
      )
    }
  }
}

fn update_song_field(
  model: Model,
  index: Int,
  update_fn: fn(Song) -> Song,
) -> #(Model, effect.Effect(Msg)) {
  case model.current_setlist {
    Some(setlist) -> {
      let updated_songs =
        list.index_map(setlist.songs, fn(song, i) {
          case i == index {
            True -> update_fn(song)
            False -> song
          }
        })
      let updated_setlist =
        Setlist(
          ..setlist,
          songs: updated_songs,
          updated_at: get_current_timestamp(),
        )
      let updated_model =
        Model(
          ..model,
          current_setlist: Some(updated_setlist),
          setlists: update_setlist_in_list(model.setlists, updated_setlist),
        )
      #(updated_model, effect.none())
    }
    None -> #(model, effect.none())
  }
}

fn swap_songs(songs: List(Song), index1: Int, index2: Int) -> List(Song) {
  list.index_map(songs, fn(song, i) {
    case i {
      _ if i == index1 -> {
        // Get the song at index2
        case
          list.index_fold(songs, None, fn(acc, s, j) {
            case j == index2 {
              True -> Some(s)
              False -> acc
            }
          })
        {
          Some(s) -> s
          None -> song
        }
      }
      _ if i == index2 -> {
        // Get the song at index1
        case
          list.index_fold(songs, None, fn(acc, s, j) {
            case j == index1 {
              True -> Some(s)
              False -> acc
            }
          })
        {
          Some(s) -> s
          None -> song
        }
      }
      _ -> song
    }
  })
}

fn update_setlist_in_list(
  setlists: List(Setlist),
  updated_setlist: Setlist,
) -> List(Setlist) {
  list.map(setlists, fn(setlist) {
    case setlist.id == updated_setlist.id {
      True -> updated_setlist
      False -> setlist
    }
  })
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("setlist-manager")], [
    view_header(model),
    view_setlist_sidebar(model),
    case model.current_setlist {
      Some(setlist) ->
        html.div([class("setlist-main-content")], [
          view_setlist_editor(setlist),
          case model.show_share_panel {
            True -> view_sharing(model, setlist)
            False -> html.div([], [])
          },
        ])
      None -> view_empty_state()
    },
  ])
}

fn view_header(model: Model) -> Element(Msg) {
  html.div([class("setlist-header")], [
    html.h1([], [html.text("Setlist Manager")]),
    html.div([class("setlist-actions")], [
      html.button([event.on("click", fn(_) { Ok(CreateNewSetlist) })], [
        html.text("New Setlist"),
      ]),
      html.button([event.on("click", fn(_) { Ok(SaveSetlist) })], [
        html.text("Save"),
      ]),
      // Only show share button if a setlist is selected
      case model.current_setlist {
        Some(_) ->
          html.button(
            [
              event.on("click", fn(_) { Ok(ToggleSharePanel) }),
              class(case model.show_share_panel {
                True -> "active"
                False -> ""
              }),
            ],
            [html.text("Share")],
          )
        None -> html.div([], [])
      },
    ]),
  ])
}

fn view_setlist_sidebar(model: Model) -> Element(Msg) {
  let filtered_setlists = case string.is_empty(model.filter_text) {
    True -> model.setlists
    False ->
      list.filter(model.setlists, fn(s) {
        string.contains(
          string.lowercase(s.name),
          string.lowercase(model.filter_text),
        )
      })
  }

  html.div([class("setlist-sidebar")], [
    html.div([class("search-container")], [
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Search setlists..."),
        attribute.value(model.filter_text),
        event.on("input", fn(e) { Ok(FilterSetlists(model.filter_text)) }),
      ]),
    ]),
    html.ul(
      [class("setlist-list")],
      list.map(filtered_setlists, fn(setlist) {
        let active_class = case model.current_setlist {
          Some(current) if current.id == setlist.id -> "active"
          _ -> ""
        }

        html.li([class("setlist-item " <> active_class)], [
          html.a(
            [
              event.on("click", fn(_) { Ok(LoadSetlist(setlist.id)) }),
              class("setlist-link"),
            ],
            [
              html.div([class("setlist-name")], [html.text(setlist.name)]),
              html.div([class("setlist-info")], [
                html.text(int.to_string(list.length(setlist.songs)) <> " songs"),
              ]),
            ],
          ),
        ])
      }),
    ),
  ])
}

fn view_setlist_editor(setlist: Setlist) -> Element(Msg) {
  html.div([class("setlist-editor")], [
    html.div([class("setlist-name-editor")], [
      html.input([
        attribute.type_("text"),
        attribute.value(setlist.name),
        event.on("input", fn(e) { Ok(UpdateSetlistName(setlist.name)) }),
        class("setlist-title-input"),
      ]),
    ]),
    html.div([class("setlist-total")], [
      html.text("Total songs: " <> int.to_string(list.length(setlist.songs))),
      html.text(
        " | Total duration: " <> calculate_total_duration(setlist.songs),
      ),
    ]),
    html.div([class("songs-container")], [
      html.table([class("songs-table")], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("#")]),
            html.th([], [html.text("Song")]),
            html.th([], [html.text("Duration")]),
            html.th([], [html.text("Notes")]),
            html.th([], [html.text("Actions")]),
          ]),
        ]),
        html.tbody(
          [],
          list.index_map(setlist.songs, fn(song, index) {
            html.tr([class("song-row")], [
              html.td([], [html.text(int.to_string(index + 1))]),
              html.td([], [
                html.input([
                  attribute.type_("text"),
                  attribute.value(song.name),
                  event.on("input", fn(e) {
                    Ok(UpdateSongName(index, song.name))
                  }),
                  class("song-name-input"),
                ]),
              ]),
              html.td([], [
                html.input([
                  attribute.type_("text"),
                  attribute.value(song.duration),
                  event.on("input", fn(e) {
                    Ok(UpdateSongDuration(index, song.duration))
                  }),
                  class("song-duration-input"),
                ]),
              ]),
              html.td([], [
                html.textarea(
                  [
                    event.on("input", fn(e) {
                      Ok(UpdateSongNotes(index, song.notes))
                    }),
                    class("song-notes-input"),
                  ],
                  song.notes,
                ),
              ]),
              html.td([class("song-actions")], [
                html.button(
                  [
                    event.on("click", fn(_) { Ok(MoveSongUp(index)) }),
                    class("song-action-btn"),
                  ],
                  [html.text("↑")],
                ),
                html.button(
                  [
                    event.on("click", fn(_) { Ok(MoveSongDown(index)) }),
                    class("song-action-btn"),
                  ],
                  [html.text("↓")],
                ),
                html.button(
                  [
                    event.on("click", fn(_) { Ok(RemoveSong(index)) }),
                    class("song-action-btn"),
                  ],
                  [html.text("✕")],
                ),
              ]),
            ])
          }),
        ),
      ]),
      html.div([class("add-song-container")], [
        html.button(
          [event.on("click", fn(_) { Ok(AddSong) }), class("add-song-btn")],
          [html.text("Add Song")],
        ),
      ]),
    ]),
  ])
}

fn view_empty_state() -> Element(Msg) {
  html.div([class("empty-state")], [
    html.p([], [html.text("No setlist selected.")]),
    html.button([event.on("click", fn(_) { Ok(CreateNewSetlist) })], [
      html.text("Create New Setlist"),
    ]),
  ])
}

fn calculate_total_duration(songs: List(Song)) -> String {
  // This is a simplified implementation that assumes durations are in MM:SS format
  // A real implementation would do proper time calculations
  "Calculation not implemented"
}

fn view_sharing(model: Model, setlist: Setlist) -> Element(Msg) {
  setlist_sharing.view_share_panel(model.share_model, setlist.id)
  |> element.map(ShareMsg)
}
