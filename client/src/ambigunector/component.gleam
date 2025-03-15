import ambigunector/types.{
  type AmbiGuEvent, type AmbiguityQuery, type AmbiguityResponse,
  type AmbiguityStatus, type ConversationType, type Participant,
  type ParticipantRole, type Reaction, type TextSelection,
}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Model {
  Model(
    queries: Dict(Int, AmbiguityQuery),
    last_query_id: Int,
    selected_query: Option(Int),
    conversation_id: String,
    conversation_type: ConversationType,
    current_user_id: Int,
  )
}

pub type Msg {
  CreateQuery(String, TextSelection)
  SelectQuery(Int)
  AddResponse(Int, String)
  UpdateStatus(Int, AmbiguityStatus)
  AddReaction(Int, String)
  // Response ID and emoji
  RemoveReaction(Int, String)
  // Response ID and emoji
  AddParticipant(Int, ParticipantRole)
  RemoveParticipant(Int)
  UpdateTags(Int, List(String))
  UserCreatedQuery(String, TextSelection)
  UserResolvedQuery(Int)
  UserEscalatedQuery(Int)
  UserAddedResponse(Int, String)
  UserUpdatedTags(Int, List(String))
  UserWithdrawnQuery(Int)
}

pub fn init(
  conversation_id: String,
  conversation_type: ConversationType,
  current_user_id: Int,
) {
  #(
    Model(
      queries: dict.new(),
      last_query_id: 0,
      selected_query: None,
      conversation_id: conversation_id,
      conversation_type: conversation_type,
      current_user_id: current_user_id,
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserCreatedQuery(query_text, selection) -> {
      let query_id = model.last_query_id + 1
      let new_query =
        types.AmbiguityQuery(
          id: query_id,
          section: selection,
          query: query_text,
          status: types.Open,
          created_by: model.current_user_id,
          created_at: get_current_timestamp(),
          responses: [],
          tags: [],
          conversation_id: Some(model.conversation_id),
          conversation_type: model.conversation_type,
          participants: [
            types.Participant(
              id: model.current_user_id,
              role: types.Author,
              joined_at: get_current_timestamp(),
              last_active: get_current_timestamp(),
              notification_preferences: types.NotificationPreferences(
                mentions: True,
                responses: True,
                status_changes: True,
                resolution: True,
                email_notifications: True,
              ),
            ),
          ],
        )
      let queries = dict.insert(model.queries, query_id, new_query)
      #(
        Model(..model, queries: queries, last_query_id: query_id),
        effect.none(),
      )
    }

    UserResolvedQuery(id) -> {
      let queries = case dict.get(model.queries, id) {
        Ok(query) ->
          dict.insert(
            model.queries,
            id,
            types.AmbiguityQuery(..query, status: types.Resolved),
          )
        Error(_) -> model.queries
      }
      #(Model(..model, queries: queries), effect.none())
    }

    UserEscalatedQuery(id) -> {
      let queries = case dict.get(model.queries, id) {
        Ok(query) ->
          dict.insert(
            model.queries,
            id,
            types.AmbiguityQuery(..query, status: types.Escalated),
          )
        Error(_) -> model.queries
      }
      #(Model(..model, queries: queries), effect.none())
    }

    UserAddedResponse(query_id, response_text) -> {
      let queries = case dict.get(model.queries, query_id) {
        Ok(query) -> {
          let new_response =
            types.AmbiguityResponse(
              id: list.length(query.responses) + 1,
              query_id: query_id,
              responder_id: model.current_user_id,
              response: response_text,
              created_at: get_current_timestamp(),
              attachments: [],
              mentions: [],
              reactions: [],
              thread_parent: None,
            )
          dict.insert(
            model.queries,
            query_id,
            types.AmbiguityQuery(..query, responses: [
              new_response,
              ..query.responses
            ]),
          )
        }
        Error(_) -> model.queries
      }
      #(Model(..model, queries: queries), effect.none())
    }

    UserUpdatedTags(query_id, tags) -> {
      let queries = case dict.get(model.queries, query_id) {
        Ok(query) ->
          dict.insert(
            model.queries,
            query_id,
            types.AmbiguityQuery(..query, tags: tags),
          )
        Error(_) -> model.queries
      }
      #(Model(..model, queries: queries), effect.none())
    }

    AddParticipant(_, _) -> #(model, effect.none())
    AddReaction(_, _) -> #(model, effect.none())
    AddResponse(_, _) -> #(model, effect.none())
    CreateQuery(_, _) -> #(model, effect.none())
    RemoveParticipant(_) -> #(model, effect.none())
    RemoveReaction(_, _) -> #(model, effect.none())
    SelectQuery(_) -> #(model, effect.none())
    UpdateStatus(_, _) -> #(model, effect.none())
    UpdateTags(_, _) -> #(model, effect.none())
    UserWithdrawnQuery(_) -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("ambigunector")], [
    html.div(
      [attribute.class("queries-list")],
      dict.values(model.queries)
        |> list.map(view_query(_, model.current_user_id)),
    ),
  ])
}

pub fn view_queries(
  contract_id: Int,
  queries: Dict(Int, AmbiguityQuery),
) -> Element(Msg) {
  html.div([attribute.class("ambiguity-queries")], [
    html.h4([], [html.text("Ambiguity Queries")]),
    html.div(
      [attribute.class("query-list")],
      dict.values(queries)
        |> list.filter(fn(query) {
          query.section.document_id == int.to_string(contract_id)
        })
        |> list.map(fn(query) { view_query(query, 1) }),
    ),
  ])
}

fn view_query(query: AmbiguityQuery, current_user_id: Int) -> Element(Msg) {
  html.div([attribute.class("query-card")], [
    html.div([attribute.class("query-header")], [
      html.span(
        [attribute.class("query-status " <> query_status_class(query.status))],
        [html.text(query_status_text(query.status))],
      ),
      html.div(
        [attribute.class("query-tags")],
        list.map(query.tags, fn(tag) {
          html.span([attribute.class("query-tag")], [html.text(tag)])
        }),
      ),
    ]),
    html.div([attribute.class("query-content")], [
      html.div([attribute.class("selected-text")], [
        html.p([attribute.class("context-before")], [
          html.text(query.section.context),
        ]),
        html.p([attribute.class("highlighted-text")], [
          html.text(query.section.selected_text),
        ]),
      ]),
      html.p([attribute.class("query-text")], [html.text(query.query)]),
    ]),
    html.div([attribute.class("query-responses")], [
      html.h5([], [
        html.text(
          "Responses (" <> int.to_string(list.length(query.responses)) <> ")",
        ),
      ]),
      html.div(
        [attribute.class("response-list")],
        list.map(query.responses, view_response(_, current_user_id)),
      ),
      html.div([attribute.class("add-response")], [
        html.textarea(
          [
            attribute.class("response-input"),
            attribute.placeholder("Add your response..."),
          ],
          "",
        ),
        html.button(
          [
            attribute.class("btn-primary"),
            event.on_click(UserAddedResponse(query.id, "")),
          ],
          [html.text("Submit Response")],
        ),
      ]),
    ]),
    html.div([attribute.class("query-actions")], [
      case query.status {
        types.Open ->
          html.div([attribute.class("action-buttons")], [
            html.button(
              [
                attribute.class("btn-success"),
                event.on_click(UserResolvedQuery(query.id)),
              ],
              [html.text("Mark as Resolved")],
            ),
            html.button(
              [
                attribute.class("btn-warning"),
                event.on_click(UserEscalatedQuery(query.id)),
              ],
              [html.text("Escalate")],
            ),
          ])
        types.UnderDiscussion ->
          html.div([attribute.class("action-buttons")], [
            html.button(
              [
                attribute.class("btn-success"),
                event.on_click(UserResolvedQuery(query.id)),
              ],
              [html.text("Mark as Resolved")],
            ),
            html.button(
              [
                attribute.class("btn-warning"),
                event.on_click(UserEscalatedQuery(query.id)),
              ],
              [html.text("Escalate")],
            ),
          ])
        _ -> html.div([attribute.class("action-buttons")], [])
      },
    ]),
  ])
}

fn view_response(
  response: AmbiguityResponse,
  current_user_id: Int,
) -> Element(Msg) {
  html.div([attribute.class("response-item")], [
    html.div([attribute.class("response-header")], [
      html.span([attribute.class("responder")], [
        html.text("User " <> int.to_string(response.responder_id)),
      ]),
      html.span([attribute.class("response-date")], [
        html.text(response.created_at),
      ]),
    ]),
    html.p([attribute.class("response-text")], [html.text(response.response)]),
    case list.length(response.attachments) {
      0 -> html.text("")
      _ ->
        html.div(
          [attribute.class("response-attachments")],
          list.map(response.attachments, fn(attachment) {
            html.a(
              [attribute.class("attachment-link"), attribute.href(attachment)],
              [html.text("📎 Attachment")],
            )
          }),
        )
    },
    html.div(
      [attribute.class("response-reactions")],
      list.map(response.reactions, view_reaction(_, current_user_id)),
    ),
  ])
}

fn view_reaction(reaction: Reaction, current_user_id: Int) -> Element(Msg) {
  html.span(
    [
      attribute.class(case reaction.user_id == current_user_id {
        True -> "reaction active"
        False -> "reaction"
      }),
      event.on_click(case reaction.user_id == current_user_id {
        True -> UserAddedResponse(reaction.user_id, reaction.emoji)
        False -> UserAddedResponse(reaction.user_id, reaction.emoji)
      }),
    ],
    [html.text(reaction.emoji)],
  )
}

fn query_status_class(status: AmbiguityStatus) -> String {
  case status {
    types.Open -> "status-open"
    types.UnderDiscussion -> "status-discussion"
    types.Resolved -> "status-resolved"
    types.Escalated -> "status-escalated"
    types.Withdrawn -> "status-withdrawn"
  }
}

fn query_status_text(status: AmbiguityStatus) -> String {
  case status {
    types.Open -> "Open"
    types.UnderDiscussion -> "Under Discussion"
    types.Resolved -> "Resolved"
    types.Escalated -> "Escalated"
    types.Withdrawn -> "Withdrawn"
  }
}

@external(javascript, "./ambigunector_ffi.js", "getCurrentTimestamp")
fn get_current_timestamp() -> String
