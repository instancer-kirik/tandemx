import chat/types.{
  type ChatMessage, type ChatRoom, type MessageContent, type Participant,
  type RoomType,
}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    room: ChatRoom,
    current_user: Participant,
    draft_message: String,
    is_typing: Bool,
    selected_message: Option(String),
    reply_to: Option(String),
    websocket: Option(WebSocket),
  )
}

pub type WebSocket {
  WebSocket(id: String)
}

pub type Msg {
  SendMessage
  UpdateDraft(String)
  SelectMessage(String)
  ReplyToMessage(String)
  CancelReply
  StartTyping
  StopTyping
  AddReaction(String, String)
  RemoveReaction(String, String)
  DeleteMessage(String)
  EditMessage(String, String)
  WebSocketConnected(WebSocket)
  WebSocketMessage(WebSocketMsg)
  WebSocketError(String)
  MessageReceived(ChatMessage)
  ParticipantJoined(Participant)
  ParticipantLeft(String)
  ParticipantTyping(String)
}

pub type WebSocketMsg {
  MessageEvent(ChatMessage)
  ParticipantEvent(String, Bool)
  TypingEvent(String)
}

pub fn init(
  room: ChatRoom,
  current_user: Participant,
) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      room: room,
      current_user: current_user,
      draft_message: "",
      is_typing: False,
      selected_message: None,
      reply_to: None,
      websocket: None,
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SendMessage -> {
      case model.draft_message {
        "" -> #(model, effect.none())
        text -> {
          let new_message =
            types.ChatMessage(
              id: generate_id(),
              content: types.TextContent(text: text),
              sender: model.current_user,
              timestamp: get_current_timestamp(),
              thread_parent: model.reply_to,
              reactions: [],
              attachments: [],
              metadata: types.MessageMetadata(
                edited: False,
                edited_at: None,
                edited_by: None,
                context_type: None,
                context_id: None,
                mentions: [],
                tags: [],
                custom_data: dict.new(),
              ),
            )
          let updated_room =
            types.ChatRoom(..model.room, messages: [
              new_message,
              ..model.room.messages
            ])
          #(
            Model(
              ..model,
              room: updated_room,
              draft_message: "",
              reply_to: None,
            ),
            effect.none(),
          )
        }
      }
    }

    UpdateDraft(text) -> {
      #(Model(..model, draft_message: text), effect.none())
    }

    SelectMessage(id) -> {
      #(Model(..model, selected_message: Some(id)), effect.none())
    }

    ReplyToMessage(id) -> {
      #(Model(..model, reply_to: Some(id)), effect.none())
    }

    CancelReply -> {
      #(Model(..model, reply_to: None), effect.none())
    }

    StartTyping -> {
      #(Model(..model, is_typing: True), effect.none())
    }

    StopTyping -> {
      #(Model(..model, is_typing: False), effect.none())
    }

    AddReaction(message_id, emoji) -> {
      let updated_room =
        types.ChatRoom(
          ..model.room,
          messages: list.map(model.room.messages, fn(msg) {
            case msg.id == message_id {
              True -> {
                let existing_reaction =
                  list.find(msg.reactions, fn(r) { r.emoji == emoji })
                case existing_reaction {
                  Ok(reaction) ->
                    types.ChatMessage(
                      ..msg,
                      reactions: list.map(msg.reactions, fn(r) {
                        case r.emoji == emoji {
                          True ->
                            types.Reaction(
                              ..r,
                              count: r.count + 1,
                              participants: [
                                model.current_user.id,
                                ..r.participants
                              ],
                            )
                          False -> r
                        }
                      }),
                    )
                  Error(_) ->
                    types.ChatMessage(..msg, reactions: [
                      types.Reaction(emoji: emoji, count: 1, participants: [
                        model.current_user.id,
                      ]),
                      ..msg.reactions
                    ])
                }
              }
              False -> msg
            }
          }),
        )
      #(Model(..model, room: updated_room), effect.none())
    }

    RemoveReaction(message_id, emoji) -> {
      let updated_room =
        types.ChatRoom(
          ..model.room,
          messages: list.map(model.room.messages, fn(msg) {
            case msg.id == message_id {
              True ->
                types.ChatMessage(
                  ..msg,
                  reactions: list.map(msg.reactions, fn(r) {
                    case r.emoji == emoji {
                      True ->
                        types.Reaction(
                          ..r,
                          count: r.count - 1,
                          participants: list.filter(r.participants, fn(p) {
                            p != model.current_user.id
                          }),
                        )
                      False -> r
                    }
                  }),
                )
              False -> msg
            }
          }),
        )
      #(Model(..model, room: updated_room), effect.none())
    }

    DeleteMessage(id) -> {
      let updated_room =
        types.ChatRoom(
          ..model.room,
          messages: list.filter(model.room.messages, fn(msg) { msg.id != id }),
        )
      #(Model(..model, room: updated_room), effect.none())
    }

    EditMessage(id, new_text) -> {
      let updated_room =
        types.ChatRoom(
          ..model.room,
          messages: list.map(model.room.messages, fn(msg) {
            case msg.id == id {
              True ->
                types.ChatMessage(
                  ..msg,
                  content: types.TextContent(text: new_text),
                  metadata: types.MessageMetadata(
                    ..msg.metadata,
                    edited: True,
                    edited_at: Some(get_current_timestamp()),
                    edited_by: Some(model.current_user.id),
                  ),
                )
              False -> msg
            }
          }),
        )
      #(Model(..model, room: updated_room), effect.none())
    }

    WebSocketConnected(ws) -> {
      #(Model(..model, websocket: Some(ws)), effect.none())
    }

    WebSocketMessage(msg) -> {
      case msg {
        MessageEvent(message) -> {
          let updated_room =
            types.ChatRoom(..model.room, messages: [
              message,
              ..model.room.messages
            ])
          #(Model(..model, room: updated_room), effect.none())
        }
        ParticipantEvent(user_id, joined) -> {
          let updated_room = case joined {
            True ->
              types.ChatRoom(
                ..model.room,
                participants: list.filter(model.room.participants, fn(p) {
                  p.id != user_id
                }),
              )
            False ->
              types.ChatRoom(
                ..model.room,
                participants: list.filter(model.room.participants, fn(p) {
                  p.id != user_id
                }),
              )
          }
          #(Model(..model, room: updated_room), effect.none())
        }
        TypingEvent(_) -> #(model, effect.none())
      }
    }

    WebSocketError(_) -> #(model, effect.none())

    MessageReceived(message) -> {
      let updated_room =
        types.ChatRoom(..model.room, messages: [message, ..model.room.messages])
      #(Model(..model, room: updated_room), effect.none())
    }

    ParticipantJoined(participant) -> {
      let updated_room =
        types.ChatRoom(..model.room, participants: [
          participant,
          ..model.room.participants
        ])
      #(Model(..model, room: updated_room), effect.none())
    }

    ParticipantLeft(user_id) -> {
      let updated_room =
        types.ChatRoom(
          ..model.room,
          participants: list.filter(model.room.participants, fn(p) {
            p.id != user_id
          }),
        )
      #(Model(..model, room: updated_room), effect.none())
    }

    ParticipantTyping(_) -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("chat-container")], [
    view_header(model.room),
    view_messages(model),
    view_input(model),
  ])
}

fn view_header(room: ChatRoom) -> Element(Msg) {
  html.div([attribute.class("chat-header")], [
    html.h2([attribute.class("room-name")], [html.text(room.name)]),
    case room.description {
      Some(desc) ->
        html.p([attribute.class("room-description")], [html.text(desc)])
      None -> html.text("")
    },
    html.div(
      [attribute.class("participant-list")],
      list.map(room.participants, view_participant),
    ),
  ])
}

fn view_participant(participant: Participant) -> Element(Msg) {
  html.div([attribute.class("participant")], [
    case participant.avatar_url {
      Some(url) ->
        html.img([
          attribute.class("avatar"),
          attribute.src(url),
          attribute.alt(participant.name),
        ])
      None ->
        html.div([attribute.class("avatar-placeholder")], [
          html.text(string.slice(participant.name, 0, 1)),
        ])
    },
    html.span([attribute.class("participant-name")], [
      html.text(participant.name),
    ]),
    html.span(
      [
        attribute.class(
          "participant-status "
          <> string.lowercase(participant_status_class(participant.status)),
        ),
      ],
      [],
    ),
  ])
}

fn view_messages(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("messages-container")],
    list.map(model.room.messages, fn(msg) { view_message(msg, model) }),
  )
}

fn view_message(message: ChatMessage, model: Model) -> Element(Msg) {
  let is_own_message = message.sender.id == model.current_user.id
  let is_selected = model.selected_message == Some(message.id)
  let is_reply = model.reply_to == Some(message.id)

  html.div(
    [
      attribute.class(case is_own_message {
        True -> "message own-message"
        False -> "message"
      }),
      case is_selected {
        True -> attribute.class("selected")
        False -> attribute.class("")
      },
      case is_reply {
        True -> attribute.class("replying-to")
        False -> attribute.class("")
      },
      event.on_click(SelectMessage(message.id)),
    ],
    [
      html.div([attribute.class("message-header")], [
        html.span([attribute.class("sender-name")], [
          html.text(message.sender.name),
        ]),
        html.span([attribute.class("timestamp")], [html.text(message.timestamp)]),
      ]),
      html.div([attribute.class("message-content")], [
        case message.thread_parent {
          Some(parent_id) ->
            html.div([attribute.class("reply-to")], [
              html.text("Replying to message " <> parent_id),
            ])
          None -> html.text("")
        },
        case message.content {
          types.TextContent(text) ->
            html.p([attribute.class("text-content")], [html.text(text)])
          types.CodeContent(code, language) ->
            html.pre([attribute.class("code-content " <> language)], [
              html.code([], [html.text(code)]),
            ])
          types.SystemContent(text) ->
            html.p([attribute.class("system-content")], [html.text(text)])
          types.FileContent(file) ->
            html.div([attribute.class("file-content")], [
              html.a([attribute.class("file-link"), attribute.href(file.url)], [
                html.text(file.name),
              ]),
            ])
          types.CustomContent(_, _) -> html.text("")
        },
      ]),
      case list.length(message.attachments) > 0 {
        True ->
          html.div(
            [attribute.class("attachments")],
            list.map(message.attachments, fn(attachment) {
              html.a(
                [
                  attribute.class("attachment"),
                  attribute.href(attachment.url),
                  attribute.target("_blank"),
                ],
                [html.text(attachment.name)],
              )
            }),
          )
        False -> html.text("")
      },
      case list.length(message.reactions) > 0 {
        True ->
          html.div(
            [attribute.class("reactions")],
            list.map(message.reactions, fn(reaction) {
              html.button(
                [
                  attribute.class(case
                    list.contains(reaction.participants, model.current_user.id)
                  {
                    True -> "reaction active"
                    False -> "reaction"
                  }),
                  event.on_click(case
                    list.contains(reaction.participants, model.current_user.id)
                  {
                    True -> RemoveReaction(message.id, reaction.emoji)
                    False -> AddReaction(message.id, reaction.emoji)
                  }),
                ],
                [
                  html.span([attribute.class("emoji")], [
                    html.text(reaction.emoji),
                  ]),
                  html.span([attribute.class("count")], [
                    html.text(int.to_string(reaction.count)),
                  ]),
                ],
              )
            }),
          )
        False -> html.text("")
      },
      case is_own_message {
        True ->
          html.div([attribute.class("message-actions")], [
            html.button(
              [
                attribute.class("action-btn"),
                event.on_click(DeleteMessage(message.id)),
              ],
              [html.text("Delete")],
            ),
            html.button(
              [
                attribute.class("action-btn"),
                event.on_click(EditMessage(message.id, "")),
              ],
              [html.text("Edit")],
            ),
          ])
        False ->
          html.div([attribute.class("message-actions")], [
            html.button(
              [
                attribute.class("action-btn"),
                event.on_click(ReplyToMessage(message.id)),
              ],
              [html.text("Reply")],
            ),
          ])
      },
    ],
  )
}

fn view_input(model: Model) -> Element(Msg) {
  html.div([attribute.class("chat-input")], [
    case model.reply_to {
      Some(id) ->
        html.div([attribute.class("reply-indicator")], [
          html.span([], [html.text("Replying to message " <> id)]),
          html.button(
            [attribute.class("cancel-reply"), event.on_click(CancelReply)],
            [html.text("×")],
          ),
        ])
      None -> html.text("")
    },
    html.div([attribute.class("input-container")], [
      html.textarea(
        [
          attribute.class("message-input"),
          attribute.placeholder("Type a message..."),
          attribute.value(model.draft_message),
          event.on_input(UpdateDraft),
          event.on("focus", fn(_) { Ok(StartTyping) }),
          event.on("blur", fn(_) { Ok(StopTyping) }),
        ],
        "",
      ),
      html.button(
        [attribute.class("send-button"), event.on_click(SendMessage)],
        [html.text("Send")],
      ),
    ]),
  ])
}

fn participant_status_class(status: types.ParticipantStatus) -> String {
  case status {
    types.Online -> "online"
    types.Away -> "away"
    types.Offline -> "offline"
    types.DoNotDisturb -> "dnd"
    types.Custom(_) -> "custom"
  }
}

@external(javascript, "./chat_ffi.js", "generateId")
fn generate_id() -> String

@external(javascript, "./chat_ffi.js", "getCurrentTimestamp")
fn get_current_timestamp() -> String
