import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre/attribute.{class, type_, placeholder, value, id, required}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// --- Types ---

pub type ServiceType {
  Performance
  Restoration
  Custom
  Repair
  Maintenance
}

pub type QuoteRequest {
  QuoteRequest(
    id: Option(String),
    customer_name: String,
    customer_email: String,
    customer_phone: String,
    service_type: ServiceType,
    bike_make: String,
    bike_model: String,
    bike_year: String,
    description: String,
    budget_range: Option(String),
    timeline: Option(String),
    status: String,
    created_at: Option(String),
  )
}

pub type FormField {
  FormField(
    value: String,
    error: Option(String),
    touched: Bool,
  )
}

pub type Model {
  Model(
    form: Dict(String, FormField),
    service_type: ServiceType,
    submitting: Bool,
    submitted: Bool,
    error: Option(String),
    quote_id: Option(String),
  )
}

pub type Msg {
  FieldChanged(String, String)
  FieldBlurred(String)
  ServiceTypeChanged(ServiceType)
  SubmitForm
  FormSubmitted(Result(String, String))
  ResetForm
  ValidateForm
}

// --- Init ---

pub fn init() -> #(Model, Effect(Msg)) {
  let initial_form = dict.from_list([
    #("customer_name", FormField("", None, False)),
    #("customer_email", FormField("", None, False)),
    #("customer_phone", FormField("", None, False)),
    #("bike_make", FormField("", None, False)),
    #("bike_model", FormField("", None, False)),
    #("bike_year", FormField("", None, False)),
    #("description", FormField("", None, False)),
    #("budget_range", FormField("", None, False)),
    #("timeline", FormField("", None, False)),
  ])
  
  let model = Model(
    form: initial_form,
    service_type: Performance,
    submitting: False,
    submitted: False,
    error: None,
    quote_id: None,
  )
  
  #(model, effect.none())
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    FieldChanged(field, value) -> {
      let updated_field = FormField(value, None, True)
      let new_form = dict.insert(model.form, field, updated_field)
      #(Model(..model, form: new_form), effect.none())
    }
    
    FieldBlurred(field) -> {
      let field_value = get_field_value(model.form, field)
      let error = validate_field(field, field_value)
      let updated_field = FormField(field_value, error, True)
      let new_form = dict.insert(model.form, field, updated_field)
      #(Model(..model, form: new_form), effect.none())
    }
    
    ServiceTypeChanged(service_type) -> #(
      Model(..model, service_type: service_type),
      effect.none(),
    )
    
    SubmitForm -> {
      case is_form_valid(model.form) {
        True -> #(
          Model(..model, submitting: True, error: None),
          submit_quote_effect(model),
        )
        False -> {
          let validated_form = validate_all_fields(model.form)
          #(Model(..model, form: validated_form), effect.none())
        }
      }
    }
    
    FormSubmitted(result) -> {
      case result {
        Ok(quote_id) -> #(
          Model(
            ..model,
            submitting: False,
            submitted: True,
            quote_id: Some(quote_id),
          ),
          effect.none(),
        )
        Error(error) -> #(
          Model(..model, submitting: False, error: Some(error)),
          effect.none(),
        )
      }
    }
    
    ResetForm -> init()
    
    ValidateForm -> {
      let validated_form = validate_all_fields(model.form)
      #(Model(..model, form: validated_form), effect.none())
    }
  }
}

// --- Effects ---

fn submit_quote_effect(model: Model) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    // Simulate API call - replace with actual API integration
    let _quote_request = QuoteRequest(
      id: None,
      customer_name: get_field_value(model.form, "customer_name"),
      customer_email: get_field_value(model.form, "customer_email"),
      customer_phone: get_field_value(model.form, "customer_phone"),
      service_type: model.service_type,
      bike_make: get_field_value(model.form, "bike_make"),
      bike_model: get_field_value(model.form, "bike_model"),
      bike_year: get_field_value(model.form, "bike_year"),
      description: get_field_value(model.form, "description"),
      budget_range: case get_field_value(model.form, "budget_range") {
        "" -> None
        value -> Some(value)
      },
      timeline: case get_field_value(model.form, "timeline") {
        "" -> None
        value -> Some(value)
      },
      status: "pending",
      created_at: None,
    )
    
    // Simulate async operation
    dispatch(FormSubmitted(Ok("QT-" <> int.to_string(123456))))
  })
}

// --- View ---

pub fn view(model: Model) -> Element(Msg) {
  case model.submitted {
    True -> view_success(model)
    False -> view_form(model)
  }
}

fn view_form(model: Model) -> Element(Msg) {
  html.div([class("custom-quote-container")], [
    view_header(),
    html.div([class("quote-form-wrapper")], [
      view_service_types(model),
      view_quote_form(model),
    ]),
  ])
}

fn view_header() -> Element(msg) {
  html.section([class("quote-header")], [
    html.div([class("header-content")], [
      html.h1([class("header-title")], [html.text("Get Your Custom Quote")]),
      html.p([class("header-subtitle")], [
        html.text("Tell us about your project and we'll provide a detailed quote within 24 hours")
      ]),
      html.div([class("header-features")], [
        html.div([class("feature")], [
          html.span([class("feature-icon")], [html.text("⚡")]),
          html.text("Fast Response"),
        ]),
        html.div([class("feature")], [
          html.span([class("feature-icon")], [html.text("🏆")]),
          html.text("Expert Service"),
        ]),
        html.div([class("feature")], [
          html.span([class("feature-icon")], [html.text("💰")]),
          html.text("Competitive Pricing"),
        ]),
      ]),
    ]),
  ])
}

fn view_service_types(model: Model) -> Element(Msg) {
  html.div([class("service-types")], [
    html.h2([class("section-title")], [html.text("Select Service Type")]),
    html.div([class("service-grid")], [
      view_service_card(Performance, "Performance Upgrades", "Boost your bike's power and handling", "🚀", model.service_type),
      view_service_card(Restoration, "Restoration", "Bring classic bikes back to life", "🛠️", model.service_type),
      view_service_card(Custom, "Custom Builds", "One-of-a-kind custom motorcycles", "🎨", model.service_type),
      view_service_card(Repair, "Repairs", "Professional repair services", "🔧", model.service_type),
      view_service_card(Maintenance, "Maintenance", "Keep your bike running smooth", "⚙️", model.service_type),
    ]),
  ])
}

fn view_service_card(service_type: ServiceType, title: String, description: String, icon: String, selected: ServiceType) -> Element(Msg) {
  let is_selected = service_type == selected
  html.button([
    class(case is_selected {
      True -> "service-card selected"
      False -> "service-card"
    }),
    event.on_click(ServiceTypeChanged(service_type)),
  ], [
    html.div([class("service-icon")], [html.text(icon)]),
    html.h3([class("service-title")], [html.text(title)]),
    html.p([class("service-description")], [html.text(description)]),
  ])
}

fn view_quote_form(model: Model) -> Element(Msg) {
  html.form([
    class("quote-form"),
  ], [
    view_form_section("Contact Information", [
      view_form_field("customer_name", "Full Name", "text", True, model.form),
      view_form_field("customer_email", "Email Address", "email", True, model.form),
      view_form_field("customer_phone", "Phone Number", "tel", True, model.form),
    ]),
    
    view_form_section("Motorcycle Details", [
      view_form_field("bike_make", "Make", "text", True, model.form),
      view_form_field("bike_model", "Model", "text", True, model.form),
      view_form_field("bike_year", "Year", "number", True, model.form),
    ]),
    
    view_form_section("Project Details", [
      view_textarea_field("description", "Project Description", True, model.form),
      view_select_field("budget_range", "Budget Range", [
        #("", "Select budget range"),
        #("under-1000", "Under $1,000"),
        #("1000-5000", "$1,000 - $5,000"),
        #("5000-10000", "$5,000 - $10,000"),
        #("10000-25000", "$10,000 - $25,000"),
        #("25000-plus", "$25,000+"),
      ], False, model.form),
      view_select_field("timeline", "Desired Timeline", [
        #("", "Select timeline"),
        #("asap", "ASAP"),
        #("1-month", "Within 1 month"),
        #("3-months", "Within 3 months"),
        #("6-months", "Within 6 months"),
        #("flexible", "Flexible"),
      ], False, model.form),
    ]),
    
    view_form_actions(model),
  ])
}

fn view_form_section(title: String, fields: List(Element(Msg))) -> Element(Msg) {
  html.div([class("form-section")], [
    html.h3([class("form-section-title")], [html.text(title)]),
    html.div([class("form-fields")], fields),
  ])
}

fn view_form_field(field_name: String, label: String, input_type: String, is_required: Bool, form: Dict(String, FormField)) -> Element(Msg) {
  let field = dict.get(form, field_name) |> result.unwrap(FormField("", None, False))
  
  html.div([class("form-field")], [
    html.label([class("field-label")], [
      html.text(label),
      case is_required {
        True -> html.span([class("required")], [html.text(" *")])
        False -> html.span([], [])
      },
    ]),
    html.input([
      type_(input_type),
      id(field_name),
      value(field.value),
      class(case field.error {
        Some(_) -> "field-input error"
        None -> "field-input"
      }),
      event.on_input(fn(value) { FieldChanged(field_name, value) }),
      event.on_blur(FieldBlurred(field_name)),
    ] |> add_required_if(is_required)),
    case field.error {
      Some(error) -> html.div([class("field-error")], [html.text(error)])
      None -> html.div([], [])
    },
  ])
}

fn view_textarea_field(field_name: String, label: String, is_required: Bool, form: Dict(String, FormField)) -> Element(Msg) {
  let field = dict.get(form, field_name) |> result.unwrap(FormField("", None, False))
  
  html.div([class("form-field")], [
    html.label([class("field-label")], [
      html.text(label),
      case is_required {
        True -> html.span([class("required")], [html.text(" *")])
        False -> html.span([], [])
      },
    ]),
    html.textarea([
      id(field_name),
      value(field.value),
      placeholder("Describe your project in detail..."),
      class(case field.error {
        Some(_) -> "field-textarea error"
        None -> "field-textarea"
      }),
      event.on_input(fn(value) { FieldChanged(field_name, value) }),
      event.on_blur(FieldBlurred(field_name)),
    ] |> add_required_if(is_required), ""),
    case field.error {
      Some(error) -> html.div([class("field-error")], [html.text(error)])
      None -> html.div([], [])
    },
  ])
}

fn view_select_field(field_name: String, label: String, options: List(#(String, String)), is_required: Bool, form: Dict(String, FormField)) -> Element(Msg) {
  let field = dict.get(form, field_name) |> result.unwrap(FormField("", None, False))
  
  html.div([class("form-field")], [
    html.label([class("field-label")], [
      html.text(label),
      case is_required {
        True -> html.span([class("required")], [html.text(" *")])
        False -> html.span([], [])
      },
    ]),
    html.select([
      id(field_name),
      value(field.value),
      class(case field.error {
        Some(_) -> "field-select error"
        None -> "field-select"
      }),
      event.on_input(fn(value) { FieldChanged(field_name, value) }),
      event.on_blur(FieldBlurred(field_name)),
    ] |> add_required_if(is_required), 
      list.map(options, fn(option) {
        html.option([value(option.0)], option.1)
      })
    ),
    case field.error {
      Some(error) -> html.div([class("field-error")], [html.text(error)])
      None -> html.div([], [])
    },
  ])
}

fn view_form_actions(model: Model) -> Element(Msg) {
  html.div([class("form-actions")], [
    case model.error {
      Some(error) -> html.div([class("form-error")], [html.text(error)])
      None -> html.div([], [])
    },
    html.div([class("action-buttons")], [
      html.button([
        type_("button"),
        class("btn btn-secondary"),
        event.on_click(ResetForm),
      ], [html.text("Reset")]),
      html.button([
        type_("button"),
        class(case model.submitting {
          True -> "btn btn-primary submitting"
          False -> "btn btn-primary"
        }),
        attribute.disabled(model.submitting),
        event.on_click(SubmitForm),
      ], [
        case model.submitting {
          True -> html.text("Submitting...")
          False -> html.text("Submit Quote Request")
        }
      ]),
    ]),
  ])
}

fn view_success(model: Model) -> Element(Msg) {
  html.div([class("quote-success")], [
    html.div([class("success-content")], [
      html.div([class("success-icon")], [html.text("✅")]),
      html.h1([class("success-title")], [html.text("Quote Request Submitted!")]),
      html.p([class("success-message")], [
        html.text("Thank you for your interest! We've received your quote request"),
        case model.quote_id {
          Some(id) -> html.text(" (Reference: " <> id <> ").")
          None -> html.text(".")
        },
      ]),
      html.div([class("next-steps")], [
        html.h3([], [html.text("What happens next?")]),
        html.ul([class("steps-list")], [
          html.li([], [html.text("We'll review your project details within 24 hours")]),
          html.li([], [html.text("Our team will contact you to discuss any questions")]),
          html.li([], [html.text("You'll receive a detailed quote via email")]),
          html.li([], [html.text("We'll schedule your project once approved")]),
        ]),
      ]),
      html.div([class("contact-info")], [
        html.p([], [html.text("Need to speak with us immediately?")]),
        html.p([class("phone")], [html.text("📞 (555) 123-BIKE")]),
        html.p([class("email")], [html.text("✉️ quotes@tandemxmoto.com")]),
      ]),
      html.button([
        class("btn btn-primary"),
        event.on_click(ResetForm),
      ], [html.text("Submit Another Quote")]),
    ]),
  ])
}

// --- Helper Functions ---

fn get_field_value(form: Dict(String, FormField), field_name: String) -> String {
  dict.get(form, field_name)
  |> result.map(fn(field) { field.value })
  |> result.unwrap("")
}

fn validate_field(field_name: String, value: String) -> Option(String) {
  case field_name, string.trim(value) {
    "customer_name", "" -> Some("Name is required")
    "customer_email", email -> validate_email(email)
    "customer_phone", "" -> Some("Phone number is required")
    "bike_make", "" -> Some("Bike make is required")
    "bike_model", "" -> Some("Bike model is required")
    "bike_year", year -> validate_year(year)
    "description", "" -> Some("Project description is required")
    _, _ -> None
  }
}

fn validate_email(email: String) -> Option(String) {
  case email {
    "" -> Some("Email is required")
    _ -> {
      case string.contains(email, "@") && string.contains(email, ".") {
        True -> None
        False -> Some("Please enter a valid email address")
      }
    }
  }
}

fn validate_year(year: String) -> Option(String) {
  case year {
    "" -> Some("Year is required")
    _ -> {
      case int.parse(year) {
        Ok(y) -> {
          case y >= 1900 && y <= 2025 {
            True -> None
            False -> Some("Please enter a valid year (1900-2025)")
          }
        }
        Error(_) -> Some("Please enter a valid year")
      }
    }
  }
}

fn is_form_valid(form: Dict(String, FormField)) -> Bool {
  let required_fields = ["customer_name", "customer_email", "customer_phone", "bike_make", "bike_model", "bike_year", "description"]
  
  list.all(required_fields, fn(field_name) {
    let field_value = get_field_value(form, field_name)
    let error = validate_field(field_name, field_value)
    case error {
      None -> True
      Some(_) -> False
    }
  })
}

fn validate_all_fields(form: Dict(String, FormField)) -> Dict(String, FormField) {
  dict.map_values(form, fn(field_name, field) {
    let error = validate_field(field_name, field.value)
    FormField(..field, error: error, touched: True)
  })
}

fn add_required_if(attributes: List(attribute.Attribute(msg)), is_required: Bool) -> List(attribute.Attribute(msg)) {
  case is_required {
    True -> [required(True), ..attributes]
    False -> attributes
  }
}