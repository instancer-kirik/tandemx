import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type ChatMessage {
  ChatMessage(
    id: String,
    content: MessageContent,
    sender: Participant,
    timestamp: String,
    thread_parent: Option(String),
    reactions: List(Reaction),
    attachments: List(Attachment),
    metadata: MessageMetadata,
  )
}

pub type MessageContent {
  TextContent(text: String)
  CodeContent(code: String, language: String)
  FileContent(file: Attachment)
  SystemContent(text: String)
  CustomContent(content_type: String, data: String)
}

pub type Attachment {
  Attachment(
    id: String,
    name: String,
    url: String,
    mime_type: String,
    size: Int,
    metadata: Dict(String, String),
  )
}

pub type Participant {
  Participant(
    id: String,
    name: String,
    avatar_url: Option(String),
    role: ParticipantRole,
    status: ParticipantStatus,
    metadata: Dict(String, String),
  )
}

pub type ParticipantRole {
  User
  Admin
  Bot
  Guest
  CustomRole(String)
}

pub type ParticipantStatus {
  Online
  Away
  Offline
  DoNotDisturb
  Custom(String)
}

pub type MessageMetadata {
  MessageMetadata(
    edited: Bool,
    edited_at: Option(String),
    edited_by: Option(String),
    context_type: Option(String),
    context_id: Option(String),
    mentions: List(String),
    tags: List(String),
    custom_data: Dict(String, String),
  )
}

pub type Reaction {
  Reaction(emoji: String, count: Int, participants: List(String))
}

pub type ChatRoom {
  ChatRoom(
    id: String,
    name: String,
    description: Option(String),
    room_type: RoomType,
    participants: List(Participant),
    messages: List(ChatMessage),
    metadata: RoomMetadata,
  )
}

pub type RoomType {
  DirectMessage
  Group
  Channel
  Thread
  AmbiGuityDiscussion
  ContractDiscussion
  ChartspaceDiscussion
  CustomRoom(String)
}

pub type RoomMetadata {
  RoomMetadata(
    created_at: String,
    created_by: String,
    last_message_at: Option(String),
    participant_count: Int,
    message_count: Int,
    is_archived: Bool,
    custom_data: Dict(String, String),
  )
}

pub type ChatEvent {
  MessageSent(ChatMessage)
  MessageEdited(ChatMessage)
  MessageDeleted(String)
  ReactionAdded(String, Reaction)
  ReactionRemoved(String, String)
  ParticipantJoined(Participant)
  ParticipantLeft(String)
  ParticipantTyping(String)
  RoomCreated(ChatRoom)
  RoomArchived(String)
  RoomDeleted(String)
  CustomEvent(String, String)
}
