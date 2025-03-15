import gleam/dict.{type Dict}
import gleam/int
import gleam/json
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
    method: String,
    url: String,
    headers: Dict(String, String),
    body: String,
    response: Option(Response),
    editing_header_key: String,
    editing_header_value: String,
    error: Option(String),
  )
}

pub type Response {
  Response(
    status: Int,
    headers: Dict(String, String),
    body: String,
    time_ms: Int,
  )
}

pub type Msg {
  SetMethod(String)
  SetUrl(String)
  SetBody(String)
  SetHeaderKey(String)
  SetHeaderValue(String)
  AddHeader
  RemoveHeader(String)
  SendRequest
  RequestSuccess(Response)
  RequestError(String)
}

pub fn init(_) {
  #(
    Model(
      method: "GET",
      url: "http://localhost:8000/api/revu/",
      headers: dict.from_list([#("Content-Type", "application/json")]),
      body: "{\n  \"query\": \"example\"\n}",
      response: None,
      editing_header_key: "",
      editing_header_value: "",
      error: None,
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SetMethod(method) -> #(Model(..model, method: method), effect.none())
    SetUrl(url) -> #(Model(..model, url: url), effect.none())
    SetBody(body) -> #(Model(..model, body: body), effect.none())
    SetHeaderKey(key) -> #(
      Model(..model, editing_header_key: key),
      effect.none(),
    )
    SetHeaderValue(value) -> #(
      Model(..model, editing_header_value: value),
      effect.none(),
    )

    AddHeader -> {
      let headers =
        dict.insert(
          model.headers,
          model.editing_header_key,
          model.editing_header_value,
        )
      #(
        Model(
          ..model,
          headers: headers,
          editing_header_key: "",
          editing_header_value: "",
        ),
        effect.none(),
      )
    }

    RemoveHeader(key) -> {
      let headers = dict.delete(model.headers, key)
      #(Model(..model, headers: headers), effect.none())
    }

    SendRequest -> {
      #(
        model,
        effect.map(
          send_request(model.method, model.url, model.headers, model.body),
          fn(result) {
            case result {
              Ok(response) -> RequestSuccess(response)
              Error(error) -> RequestError(error)
            }
          },
        ),
      )
    }

    RequestSuccess(response) -> #(
      Model(..model, response: Some(response), error: None),
      effect.none(),
    )

    RequestError(error) -> #(
      Model(..model, response: None, error: Some(error)),
      effect.none(),
    )
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("curl-tool")], [
    html.div([attribute.class("request-panel")], [
      html.div([attribute.class("method-url")], [
        html.select(
          [attribute.class("method-select"), event.on_input(SetMethod)],
          [
            html.option([attribute.value("GET")], "GET"),
            html.option([attribute.value("POST")], "POST"),
            html.option([attribute.value("PUT")], "PUT"),
            html.option([attribute.value("DELETE")], "DELETE"),
            html.option([attribute.value("PATCH")], "PATCH"),
          ],
        ),
        html.input([
          attribute.class("url-input"),
          attribute.type_("text"),
          attribute.value(model.url),
          event.on_input(SetUrl),
        ]),
      ]),
      html.div([attribute.class("headers-section")], [
        html.h3([], [html.text("Headers")]),
        html.div(
          [attribute.class("headers-list")],
          dict.to_list(model.headers)
            |> list.map(fn(header) {
              let #(key, value) = header
              html.div([attribute.class("header-item")], [
                html.span([attribute.class("header-key")], [html.text(key)]),
                html.span([], [html.text(": ")]),
                html.span([attribute.class("header-value")], [html.text(value)]),
                html.button(
                  [
                    attribute.class("remove-header"),
                    event.on_click(RemoveHeader(key)),
                  ],
                  [html.text("×")],
                ),
              ])
            }),
        ),
        html.div([attribute.class("add-header")], [
          html.input([
            attribute.class("header-key-input"),
            attribute.placeholder("Header name"),
            attribute.value(model.editing_header_key),
            event.on_input(SetHeaderKey),
          ]),
          html.input([
            attribute.class("header-value-input"),
            attribute.placeholder("Header value"),
            attribute.value(model.editing_header_value),
            event.on_input(SetHeaderValue),
          ]),
          html.button(
            [attribute.class("add-header-btn"), event.on_click(AddHeader)],
            [html.text("Add Header")],
          ),
        ]),
      ]),
      html.div([attribute.class("body-section")], [
        html.h3([], [html.text("Request Body")]),
        html.textarea(
          [
            attribute.class("body-input"),
            attribute.value(model.body),
            event.on_input(SetBody),
          ],
          "",
        ),
      ]),
      html.button(
        [attribute.class("send-button"), event.on_click(SendRequest)],
        [html.text("Send Request")],
      ),
    ]),
    html.div([attribute.class("response-panel")], [
      html.h3([], [html.text("Response")]),
      case model.error {
        Some(error) ->
          html.div([attribute.class("error-message")], [html.text(error)])
        None ->
          case model.response {
            Some(response) ->
              html.div([attribute.class("response-content")], [
                html.div([attribute.class("response-status")], [
                  html.text(
                    "Status: "
                    <> int.to_string(response.status)
                    <> " ("
                    <> int.to_string(response.time_ms)
                    <> "ms)",
                  ),
                ]),
                html.div([attribute.class("response-headers")], [
                  html.h4([], [html.text("Headers")]),
                  html.div(
                    [attribute.class("headers-list")],
                    dict.to_list(response.headers)
                      |> list.map(fn(header) {
                        let #(key, value) = header
                        html.div([attribute.class("header-item")], [
                          html.span([attribute.class("header-key")], [
                            html.text(key),
                          ]),
                          html.span([], [html.text(": ")]),
                          html.span([attribute.class("header-value")], [
                            html.text(value),
                          ]),
                        ])
                      }),
                  ),
                ]),
                html.div([attribute.class("response-body")], [
                  html.h4([], [html.text("Body")]),
                  html.pre([], [html.text(response.body)]),
                ]),
              ])
            None -> html.text("")
          }
      },
    ]),
  ])
}

@external(javascript, "./curl_tool_ffi.js", "sendRequest")
fn send_request(
  method: String,
  url: String,
  headers: Dict(String, String),
  body: String,
) -> effect.Effect(Result(Response, String))
