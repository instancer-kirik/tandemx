import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type FormField {
  TextField(
    id: String,
    name: String,
    required: Bool,
    value: String,
    selector: String,
  )
  SelectField(
    id: String,
    name: String,
    options: List(String),
    selected: Option(String),
    selector: String,
  )
  CheckboxField(id: String, name: String, checked: Bool, selector: String)
  SubmitButton(id: String, text: String, selector: String)
}

pub type FormState {
  FormState(
    fields: List(FormField),
    current_step: Int,
    is_valid: Bool,
    errors: List(String),
    selector: String,
    url: String,
  )
}

pub type Model {
  Model(
    forms: List(FormState),
    selected_form: Option(FormState),
    analyzing: Bool,
    extension_connected: Bool,
    connected_url: Option(String),
  )
}

pub type ExtensionMessage {
  Connect(String)
  Disconnect
  FormsAnalyzed(List(FormState))
  FieldUpdated(String, String)
  FormSubmitted(String)
  Error(String)
}

pub type FormElementType {
  Clickable
  Typeable
  Selectable
  Submittable
}

pub type FormElement {
  FormElement(
    type_: FormElementType,
    id: Option(String),
    name: Option(String),
    selector: String,
    value: Option(String),
    is_visible: Bool,
    attributes: Dict(String, String),
    label: Option(String),
  )
}

pub type FormInteraction {
  FormInteraction(element: FormElement, interaction: InteractionDetails)
}

pub type InteractionDetails {
  InteractionDetails(type_: String, value: Option(String), timestamp: Int)
}

pub type Msg {
  AnalyzeForm
  FormDetected(FormState)
  SelectForm(FormState)
  UpdateField(FormField)
  ValidateForm
  SubmitForm
  ExtensionMsg(ExtensionMessage)
  FormElementFound(FormElement)
  FormInteractionOccurred(FormInteraction)
}

@external(javascript, "./extension_bridge.js", "send_message")
fn send_to_extension(message: String) -> Nil

pub fn init() -> Model {
  Model(
    forms: [],
    selected_form: None,
    analyzing: False,
    extension_connected: False,
    connected_url: None,
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AnalyzeForm -> {
      send_to_extension(
        json.to_string(json.object([#("type", json.string("ANALYZE_FORMS"))])),
      )
      #(Model(..model, analyzing: True), effect.none())
    }

    FormDetected(form) -> #(
      Model(..model, forms: [form, ..model.forms], analyzing: False),
      effect.none(),
    )

    SelectForm(form) -> #(
      Model(..model, selected_form: Some(form)),
      effect.none(),
    )

    UpdateField(field) -> {
      let selector = case field {
        TextField(selector: s, ..) -> s
        SelectField(selector: s, ..) -> s
        CheckboxField(selector: s, ..) -> s
        SubmitButton(selector: s, ..) -> s
      }
      let value = case field {
        TextField(value: v, ..) -> v
        SelectField(selected: Some(v), ..) -> v
        SelectField(selected: None, ..) -> ""
        CheckboxField(checked: c, ..) ->
          case c {
            True -> "true"
            False -> "false"
          }
        SubmitButton(..) -> ""
      }
      send_to_extension(
        json.to_string(
          json.object([
            #("type", json.string("UPDATE_FIELD")),
            #("selector", json.string(selector)),
            #("value", json.string(value)),
          ]),
        ),
      )
      #(model, effect.none())
    }

    ValidateForm -> #(model, effect.none())

    SubmitForm -> {
      case model.selected_form {
        Some(form) -> {
          send_to_extension(
            json.to_string(
              json.object([
                #("type", json.string("SUBMIT_FORM")),
                #("selector", json.string(form.selector)),
              ]),
            ),
          )
          #(model, effect.none())
        }
        None -> #(model, effect.none())
      }
    }

    ExtensionMsg(Connect(url)) -> #(
      Model(
        ..model,
        extension_connected: True,
        connected_url: Some(url),
        forms: [],
      ),
      effect.none(),
    )

    ExtensionMsg(Disconnect) -> #(
      Model(..model, extension_connected: False, connected_url: None, forms: []),
      effect.none(),
    )

    ExtensionMsg(FormsAnalyzed(forms)) -> #(
      Model(..model, forms: forms, analyzing: False),
      effect.none(),
    )

    ExtensionMsg(FieldUpdated(selector, value)) -> {
      #(model, effect.none())
    }

    ExtensionMsg(FormSubmitted(selector)) -> {
      #(model, effect.none())
    }

    ExtensionMsg(Error(message)) -> {
      #(model, effect.none())
    }

    FormElementFound(element) -> #(model, effect.none())

    FormInteractionOccurred(interaction) -> #(model, effect.none())
  }
}

fn render_field(field: FormField) -> Element(Msg) {
  case field {
    TextField(id, name, required, value, _) -> {
      html.div([class("field")], [
        html.label([attribute.for(id)], [html.text(name)]),
        html.input([
          attribute.type_("text"),
          attribute.id(id),
          attribute.name(name),
          attribute.value(value),
          attribute.required(required),
          event.on_input(fn(new_value) {
            UpdateField(TextField(..field, value: new_value))
          }),
        ]),
      ])
    }

    SelectField(id, name, options, selected, _) -> {
      html.div([class("field")], [
        html.label([attribute.for(id)], [html.text(name)]),
        html.input([
          attribute.type_("text"),
          attribute.id(id),
          attribute.name(name),
          attribute.value(case selected {
            Some(value) -> value
            None -> ""
          }),
          event.on_input(fn(new_value) {
            UpdateField(SelectField(..field, selected: Some(new_value)))
          }),
        ]),
        html.div(
          [class("suggestions")],
          list.map(options, fn(option) {
            html.div(
              [
                class("suggestion"),
                event.on_click(UpdateField(
                  SelectField(..field, selected: Some(option)),
                )),
              ],
              [html.text(option)],
            )
          }),
        ),
      ])
    }

    CheckboxField(id, name, checked, _) -> {
      html.div([class("field")], [
        html.label([attribute.for(id)], [
          html.input([
            attribute.type_("checkbox"),
            attribute.id(id),
            attribute.name(name),
            attribute.checked(checked),
            event.on_check(fn(is_checked) {
              UpdateField(CheckboxField(..field, checked: is_checked))
            }),
          ]),
          html.text(name),
        ]),
      ])
    }

    SubmitButton(id, text, _) -> {
      html.button(
        [
          attribute.type_("submit"),
          attribute.id(id),
          event.on_click(SubmitForm),
        ],
        [html.text(text)],
      )
    }
  }
}

pub fn render(model: Model) -> Element(Msg) {
  html.div([class("form-analyzer")], [
    html.div([class("status-bar")], [
      html.div([class("extension-status")], [
        html.text(case model.extension_connected {
          True ->
            "Connected to: "
            <> case model.connected_url {
              Some(url) -> url
              None -> "Unknown page"
            }
          False -> "Extension Not Connected"
        }),
      ]),
    ]),
    html.div([class("controls")], [
      html.button(
        [
          class("analyze-button"),
          event.on_click(AnalyzeForm),
          attribute.disabled(!model.extension_connected || model.analyzing),
        ],
        [
          html.text(case model.analyzing {
            True -> "Analyzing..."
            False -> "Analyze Forms"
          }),
        ],
      ),
    ]),
    html.div([class("forms-list")], case model.forms {
      [] -> [html.p([], [html.text("No forms detected yet")])]
      forms ->
        list.map(forms, fn(form) {
          html.div(
            [
              class("form-item"),
              event.on_click(SelectForm(form)),
              class(case model.selected_form {
                Some(selected) if selected == form -> "selected"
                _ -> ""
              }),
            ],
            [
              html.div(
                [class("form-fields")],
                list.map(form.fields, render_field),
              ),
              html.div([class("form-controls")], [
                html.button([class("submit"), event.on_click(SubmitForm)], [
                  html.text("Submit"),
                ]),
              ]),
            ],
          )
        })
    }),
  ])
}
