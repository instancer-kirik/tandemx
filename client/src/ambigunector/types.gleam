import gleam/option.{type Option}

pub type AmbiguityQuery {
  AmbiguityQuery(
    id: Int,
    section: TextSelection,
    query: String,
    status: AmbiguityStatus,
    created_by: Int,
    created_at: String,
    responses: List(AmbiguityResponse),
    tags: List(String),
    conversation_id: Option(String),
    conversation_type: ConversationType,
    participants: List(Participant),
  )
}

pub type TextSelection {
  TextSelection(
    document_id: String,
    start_offset: Int,
    end_offset: Int,
    selected_text: String,
    context: String,
  )
}

pub type AmbiguityStatus {
  Open
  UnderDiscussion
  Resolved
  Escalated
  Withdrawn
}

pub type AmbiguityResponse {
  AmbiguityResponse(
    id: Int,
    query_id: Int,
    responder_id: Int,
    response: String,
    created_at: String,
    attachments: List(String),
    mentions: List(Int),
    reactions: List(Reaction),
    thread_parent: Option(Int),
  )
}

pub type Selection {
  Selection(text: String, start: Int, end: Int)
}

pub type ConversationType {
  ContractConversation
  ChatConversation
  DocumentConversation
  EmailConversation
  CommentConversation
  ReviewConversation
  CustomConversation(String)
}

pub type Participant {
  Participant(
    id: Int,
    role: ParticipantRole,
    joined_at: String,
    last_active: String,
    notification_preferences: NotificationPreferences,
  )
}

pub type ParticipantRole {
  Author
  Reviewer
  Observer
  Moderator
  CustomRole(String)
}

pub type NotificationPreferences {
  NotificationPreferences(
    mentions: Bool,
    responses: Bool,
    status_changes: Bool,
    resolution: Bool,
    email_notifications: Bool,
  )
}

pub type Reaction {
  Reaction(emoji: String, user_id: Int, created_at: String)
}

// Events that can be triggered by AmbiGuNector
pub type AmbiGuEvent {
  QueryCreated(AmbiguityQuery)
  QueryUpdated(AmbiguityQuery)
  ResponseAdded(AmbiguityResponse)
  StatusChanged(Int, AmbiguityStatus)
  ParticipantJoined(Int, ParticipantRole)
  ParticipantLeft(Int)
  QueryResolved(Int)
  QueryEscalated(Int, String)
  ReactionAdded(Int, Reaction)
  ReactionRemoved(Int, String)
}
