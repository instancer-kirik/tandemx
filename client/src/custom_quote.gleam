import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre/attribute.{class, id, src, alt, href, type_, placeholder, value, rows, cols, required, disabled}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import access_content.{type FetchState, Idle, Loading, Loaded, Errored}

// --- Types ---

pub type ServiceType {
  Maintenance
  Repair
  Performance
  CustomBuild
  Restoration
  Fabrication
}

pub type BikeInfo {
  BikeInfo(
    year: String,
    make: String,
    model: String,
    engine_size: String,
    mileage: String,
    condition: String,
    modifications: List(String),
  )
}

pub type ContactInfo {
  ContactInfo(
    first_name: String,
    last_name: String,
    email: String,
    phone: String,
    preferred_contact: String,
  )
}

pub type ProjectScope {
  ProjectScope(
    service_type: ServiceType,
    priority: String,
    budget_range: String,
    timeline: String,
    description: String,
    specific_parts: List(String),
    performance_goals: String,
    inspiration_images: List(String),
  )
}

pub type QuoteRequest {
  QuoteRequest(
    id: Option(Int),
    contact_info: ContactInfo,
    bike_info: BikeInfo,
    project_scope: ProjectScope,
    status: String,
    created_at: Option(String),
    estimated_cost: Option(Float),
    estimated_timeline: Option(String),
  )
}

pub type FormStep {
  ContactStep
  BikeStep
  ProjectStep
  ReviewStep
}

pub type ValidationError {
  ValidationError(field: String, message: String)
}

pub type Model {
  Model(
    current_step: FormStep,
    contact_info: ContactInfo,
    bike_info: BikeInfo,
    project_scope: ProjectScope,
    validation_errors: List(ValidationError),
    is_submitting: Bool,
    submission_status: FetchState(String),
    saved_quotes: List(QuoteRequest),
  )
}

pub type Msg {
  NextStep
  PreviousStep
  GoToStep(FormStep)
  UpdateContactInfo(String, String)
  UpdateBikeInfo(String, String)
  UpdateProjectScope(String, String)
  AddModification(String)
  RemoveModification(String)
  AddSpecificPart(String)
  RemoveSpecificPart(String)
  AddInspirationImage(String)
  RemoveInspirationImage(String)
  SubmitQuote
  QuoteSubmitted(String)
  SubmissionFailed(String)
  LoadSavedQuotes
  QuotesLoaded(List(QuoteRequest))
  ClearForm
  LoadQuoteForEdit(QuoteRequest)
}

// --- Init ---

pub fn init() -> #(Model, Effect(Msg)) {
  let model = Model(
    current_step: ContactStep,
    contact_info: ContactInfo(
      first_name: "",
      last_name: "",
      email: "",
      phone: "",
      preferred_contact: "email",
    ),
    bike_info: BikeInfo(
      year: "",
      make: "",
      model: "",
      engine_size: "",
      mileage: "",
      condition: "",
      modifications: [],
    ),
    project_scope: ProjectScope(
      service_type: Maintenance,
      priority: "normal",
      budget_range: "",
      timeline: "",
      description: "",
      specific_parts: [],
      performance_goals: "",
      inspiration_images: [],
    ),
    validation_errors: [],
    is_submitting: False,
    submission_status: Idle,
    saved_quotes: [],
  )
  
  #(model, effect.from(fn(_) { LoadSavedQuotes }))
}

// --- Update ---

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NextStep -> {
      let next_step = case model.current_step {
        ContactStep -> BikeStep
        BikeStep -> ProjectStep
        ProjectStep -> ReviewStep
        ReviewStep -> ReviewStep
      }
      
      case validate_current_step(model) {
        [] -> #(Model(..model, current_step: next_step, validation_errors: []), effect.none())
        errors -> #(Model(..model, validation_errors: errors), effect.none())
      }
    }
    
    PreviousStep -> {
      let prev_step = case model.current_step {
        ContactStep -> ContactStep
        BikeStep -> ContactStep
        ProjectStep -> BikeStep
        ReviewStep -> ProjectStep
      }
      #(Model(..model, current_step: prev_step, validation_errors: []), effect.none())
    }
    
    GoToStep(step) -> {
      #(Model(..model, current_step: step, validation_errors: []), effect.none())
    }
    
    UpdateContactInfo(field, value) -> {
      let updated_contact = case field {
        "first_name" -> ContactInfo(..model.contact_info, first_name: value)
        "last_name" -> ContactInfo(..model.contact_info, last_name: value)
        "email" -> ContactInfo(..model.contact_info, email: value)
        "phone" -> ContactInfo(..model.contact_info, phone: value)
        "preferred_contact" -> ContactInfo(..model.contact_info, preferred_contact: value)
        _ -> model.contact_info
      }
      #(Model(..model, contact_info: updated_contact), effect.none())
    }
    
    UpdateBikeInfo(field, value) -> {
      let updated_bike = case field {
        "year" -> BikeInfo(..model.bike_info, year: value)
        "make" -> BikeInfo(..model.bike_info, make: value)
        "model" -> BikeInfo(..model.bike_info, model: value)
        "engine_size" -> BikeInfo(..model.bike_info, engine_size: value)
        "mileage" -> BikeInfo(..model.bike_info, mileage: value)
        "condition" -> BikeInfo(..model.bike_info, condition: value)
        _ -> model.bike_info
      }
      #(Model(..model, bike_info: updated_bike), effect.none())
    }
    
    UpdateProjectScope(field, value) -> {
      let updated_scope = case field {
        "service_type" -> ProjectScope(..model.project_scope, service_type: parse_service_type(value))
        "priority" -> ProjectScope(..model.project_scope, priority: value)
        "budget_range" -> ProjectScope(..model.project_scope, budget_range: value)
        "timeline" -> ProjectScope(..model.project_scope, timeline: value)
        "description" -> ProjectScope(..model.project_scope, description: value)
        "performance_goals" -> ProjectScope(..model.project_scope, performance_goals: value)
        _ -> model.project_scope
      }
      #(Model(..model, project_scope: updated_scope), effect.none())
    }
    
    AddModification(modification) -> {
      case string.trim(modification) {
        "" -> #(model, effect.none())
        mod -> {
          let updated_mods = [mod, ..model.bike_info.modifications]
          let updated_bike = BikeInfo(..model.bike_info, modifications: updated_mods)
          #(Model(..model, bike_info: updated_bike), effect.none())
        }
      }
    }
    
    RemoveModification(modification) -> {
      let updated_mods = list.filter(model.bike_info.modifications, fn(mod) { mod != modification })
      let updated_bike = BikeInfo(..model.bike_info, modifications: updated_mods)
      #(Model(..model, bike_info: updated_bike), effect.none())
    }
    
    AddSpecificPart(part) -> {
      case string.trim(part) {
        "" -> #(model, effect.none())
        p -> {
          let updated_parts = [p, ..model.project_scope.specific_parts]
          let updated_scope = ProjectScope(..model.project_scope, specific_parts: updated_parts)
          #(Model(..model, project_scope: updated_scope), effect.none())
        }
      }
    }
    
    RemoveSpecificPart(part) -> {
      let updated_parts = list.filter(model.project_scope.specific_parts, fn(p) { p != part })
      let updated_scope = ProjectScope(..model.project_scope, specific_parts: updated_parts)
      #(Model(..model, project_scope: updated_scope), effect.none())
    }
    
    AddInspirationImage(url) -> {
      case string.trim(url) {
        "" -> #(model, effect.none())
        image_url -> {
          let updated_images = [image_url, ..model.project_scope.inspiration_images]
          let updated_scope = ProjectScope(..model.project_scope, inspiration_images: updated_images)
          #(Model(..model, project_scope: updated_scope), effect.none())
        }
      }
    }
    
    RemoveInspirationImage(url) -> {
      let updated_images = list.filter(model.project_scope.inspiration_images, fn(img) { img != url })
      let updated_scope = ProjectScope(..model.project_scope, inspiration_images: updated_images)
      #(Model(..model, project_scope: updated_scope), effect.none())
    }
    
    SubmitQuote -> {
      case validate_all_steps(model) {
        [] -> {
          #(Model(..model, is_submitting: True, submission_status: Loading), submit_quote_effect(model))
        }
        errors -> {
          #(Model(..model, validation_errors: errors), effect.none())
        }
      }
    }
    
    QuoteSubmitted(quote_id) -> {
      #(Model(
        ..model, 
        is_submitting: False, 
        submission_status: Loaded("Quote submitted successfully! Reference ID: " <> quote_id)
      ), effect.none())
    }
    
    SubmissionFailed(error) -> {
      #(Model(
        ..model, 
        is_submitting: False, 
        submission_status: Errored(error)
      ), effect.none())
    }
    
    LoadSavedQuotes -> {
      #(model, load_saved_quotes_effect())
    }
    
    QuotesLoaded(quotes) -> {
      #(Model(..model, saved_quotes: quotes), effect.none())
    }
    
    ClearForm -> {
      let cleared_model = Model(
        ..model,
        current_step: ContactStep,
        validation_errors: [],
        submission_status: Idle,
        contact_info: ContactInfo(
          first_name: "",
          last_name: "",
          email: "",
          phone: "",
          preferred_contact: "email",
        ),
        bike_info: BikeInfo(
          year: "",
          make: "",
          model: "",
          engine_size: "",
          mileage: "",
          condition: "",
          modifications: [],
        ),
        project_scope: ProjectScope(
          service_type: Maintenance,
          priority: "normal",
          budget_range: "",
          timeline: "",
          description: "",
          specific_parts: [],
          performance_goals: "",
          inspiration_images: [],
        ),
      )
      #(cleared_model, effect.none())
    }
    
    LoadQuoteForEdit(quote) -> {
      #(Model(
        ..model,
        current_step: ContactStep,
        contact_info: quote.contact_info,
        bike_info: quote.bike_info,
        project_scope: quote.project_scope,
        validation_errors: [],
        submission_status: Idle,
      ), effect.none())
    }
  }
}

// --- Effects ---

fn submit_quote_effect(model: Model) -> Effect(Msg) {
  // This would normally make an HTTP request to submit the quote
  effect.from(fn(_) {
    QuoteSubmitted("QT-" <> int.to_string(1000 + list.length(model.saved_quotes)))
  })
}

fn load_saved_quotes_effect() -> Effect(Msg) {
  // This would normally load saved quotes from storage or API
  effect.from(fn(_) { QuotesLoaded([]) })
}

// --- Helper Functions ---

fn parse_service_type(value: String) -> ServiceType {
  case value {
    "maintenance" -> Maintenance
    "repair" -> Repair
    "performance" -> Performance
    "custom_build" -> CustomBuild
    "restoration" -> Restoration
    "fabrication" -> Fabrication
    _ -> Maintenance
  }
}

fn service_type_to_string(service_type: ServiceType) -> String {
  case service_type {
    Maintenance -> "maintenance"
    Repair -> "repair"
    Performance -> "performance"
    CustomBuild -> "custom_build"
    Restoration -> "restoration"
    Fabrication -> "fabrication"
  }
}

fn validate_current_step(model: Model) -> List(ValidationError) {
  case model.current_step {
    ContactStep -> validate_contact_info(model.contact_info)
    BikeStep -> validate_bike_info(model.bike_info)
    ProjectStep -> validate_project_scope(model.project_scope)
    ReviewStep -> []
  }
}

fn validate_all_steps(model: Model) -> List(ValidationError) {
  list.flatten([
    validate_contact_info(model.contact_info),
    validate_bike_info(model.bike_info),
    validate_project_scope(model.project_scope),
  ])
}

fn validate_contact_info(contact: ContactInfo) -> List(ValidationError) {
  []
  |> list.append(case string.trim(contact.first_name) {
    "" -> [ValidationError("first_name", "First name is required")]
    _ -> []
  })
  |> list.append(case string.trim(contact.last_name) {
    "" -> [ValidationError("last_name", "Last name is required")]
    _ -> []
  })
  |> list.append(case string.trim(contact.email) {
    "" -> [ValidationError("email", "Email is required")]
    email -> case string.contains(email, "@") {
      True -> []
      False -> [ValidationError("email", "Please enter a valid email address")]
    }
  })
}

fn validate_bike_info(bike: BikeInfo) -> List(ValidationError) {
  []
  |> list.append(case string.trim(bike.make) {
    "" -> [ValidationError("make", "Bike make is required")]
    _ -> []
  })
  |> list.append(case string.trim(bike.model) {
    "" -> [ValidationError("model", "Bike model is required")]
    _ -> []
  })
}

fn validate_project_scope(scope: ProjectScope) -> List(ValidationError) {
  []
  |> list.append(case string.trim(scope.description) {
    "" -> [ValidationError("description", "Project description is required")]
    _ -> []
  })
}

fn get_field_error(errors: List(ValidationError), field: String) -> Option(String) {
  list.find(errors, fn(error) { error.field == field })
  |> result.map(fn(error) { error.message })
  |> result.to_option()
}

// --- View ---

pub fn view(model: Model) -> Element(Msg) {
  html.div([class("quote-form-container")], [
    view_header(),
    view_progress_indicator(model),
    html.div([class("quote-form-content")], [
      html.div([class("quote-form-main")], [
        case model.current_step {
          ContactStep -> view_contact_step(model)
          BikeStep -> view_bike_step(model)
          ProjectStep -> view_project_step(model)
          ReviewStep -> view_review_step(model)
        }
      ]),
      view_sidebar(model),
    ]),
    view_navigation(model),
  ])
}

fn view_header() -> Element(Msg) {
  html.header([class("quote-header")], [
    html.div([class("quote-header-content")], [
      html.h1([class("quote-title")], [html.text("Get Your Custom Quote")]),
      html.p([class("quote-subtitle")], [
        html.text("Tell us about your motorcycle and what you'd like to accomplish. We'll provide a detailed quote for your project.")
      ])
    ])
  ])
}

fn view_progress_indicator(model: Model) -> Element(Msg) {
  html.div([class("progress-indicator")], [
    view_progress_step("Contact", ContactStep, model.current_step),
    view_progress_step("Motorcycle", BikeStep, model.current_step),
    view_progress_step("Project", ProjectStep, model.current_step),
    view_progress_step("Review", ReviewStep, model.current_step),
  ])
}

fn view_progress_step(label: String, step: FormStep, current_step: FormStep) -> Element(Msg) {
  let is_current = step == current_step
  let is_completed = case step, current_step {
    ContactStep, BikeStep -> True
    ContactStep, ProjectStep -> True
    ContactStep, ReviewStep -> True
    BikeStep, ProjectStep -> True
    BikeStep, ReviewStep -> True
    ProjectStep, ReviewStep -> True
    _, _ -> False
  }
  
  let step_class = case is_current, is_completed {
    True, _ -> "progress-step current"
    _, True -> "progress-step completed"
    _, False -> "progress-step"
  }
  
  html.div([class(step_class), event.on_click(GoToStep(step))], [
    html.div([class("step-indicator")], [
      case is_completed {
        True -> html.text("✓")
        False -> html.text("")
      }
    ]),
    html.span([class("step-label")], [html.text(label)])
  ])
}

fn view_contact_step(model: Model) -> Element(Msg) {
  html.div([class("form-step contact-step")], [
    html.h2([class("step-title")], [html.text("Contact Information")]),
    html.p([class("step-description")], [
      html.text("Let us know how to reach you with your quote and any follow-up questions.")
    ]),
    
    html.div([class("form-grid")], [
      view_form_group("First Name", "first_name", model.contact_info.first_name, True, model.validation_errors, fn(value) {
        UpdateContactInfo("first_name", value)
      }),
      view_form_group("Last Name", "last_name", model.contact_info.last_name, True, model.validation_errors, fn(value) {
        UpdateContactInfo("last_name", value)
      }),
    ]),
    
    view_form_group("Email Address", "email", model.contact_info.email, True, model.validation_errors, fn(value) {
      UpdateContactInfo("email", value)
    }),
    
    view_form_group("Phone Number", "phone", model.contact_info.phone, False, model.validation_errors, fn(value) {
      UpdateContactInfo("phone", value)
    }),
    
    html.div([class("form-group")], [
      html.label([class("form-label")], [html.text("Preferred Contact Method")]),
      html.select([
        class("form-select"),
        value(model.contact_info.preferred_contact),
        event.on_input(fn(value) { UpdateContactInfo("preferred_contact", value) })
      ], [
        html.option([value("email")], [html.text("Email")]),
        html.option([value("phone")], [html.text("Phone")]),
        html.option([value("either")], [html.text("Either")]),
      ])
    ])
  ])
}

fn view_bike_step(model: Model) -> Element(Msg) {
  html.div([class("form-step bike-step")], [
    html.h2([class("step-title")], [html.text("Motorcycle Information")]),
    html.p([class("step-description")], [
      html.text("Tell us about your bike so we can provide accurate pricing and recommendations.")
    ]),
    
    html.div([class("form-grid")], [
      view_form_group("Year", "year", model.bike_info.year, False, model.validation_errors, fn(value) {
        UpdateBikeInfo("year", value)
      }),
      view_form_group("Make", "make", model.bike_info.make, True, model.validation_errors, fn(value) {
        UpdateBikeInfo("make", value)
      }),
    ]),
    
    view_form_group("Model", "model", model.bike_info.model, True, model.validation_errors, fn(value) {
      UpdateBikeInfo("model", value)
    }),
    
    html.div([class("form-grid")], [
      view_form_group("Engine Size", "engine_size", model.bike_info.engine_size, False, model.validation_errors, fn(value) {
        UpdateBikeInfo("engine_size", value)
      }),
      view_form_group("Mileage", "mileage", model.bike_info.mileage, False, model.validation_errors, fn(value) {
        UpdateBikeInfo("mileage", value)
      }),
    ]),
    
    html.div([class("form-group")], [
      html.label([class("form-label")], [html.text("Condition")]),
      html.select([
        class("form-select"),
        value(model.bike_info.condition),
        event.on_input(fn(value) { UpdateBikeInfo("condition", value) })
      ], [
        html.option([value("")], [html.text("Select condition...")]),
        html.option([value("excellent")], [html.text("Excellent")]),
        html.option([value("good")], [html.text("Good")]),
        html.option([value("fair")], [html.text("Fair")]),
        html.option([value("poor")], [html.text("Poor")]),
        html.option([value("project")], [html.text("Project Bike")]),
      ])
    ]),
    
    view_modifications_section(model.bike_info.modifications),
  ])
}

fn view_project_step(model: Model) -> Element(Msg) {
  html.div([class("form-step project-step")], [
    html.h2([class("step-title")], [html.text("Project Details")]),
    html.p([class("step-description")], [
      html.text("Describe what you'd like to accomplish with your motorcycle.")
    ]),
    
    view_service_type_section(model.project_scope.service_type),
    
    html.div([class("form-grid")], [
      view_priority_section(model.project_scope.priority),
      view_budget_section(model.project_scope.budget_range),
    ]),
    
    view_timeline_section(model.project_scope.timeline),
    
    view_textarea_group("Project Description", "description", model.project_scope.description, True, model.validation_errors, fn(value) {
      UpdateProjectScope("description", value)
    }),
    
    view_specific_parts_section(model.project_scope.specific_parts),
    
    view_textarea_group("Performance Goals", "performance_goals", model.project_scope.performance_goals, False, model.validation_errors, fn(value) {
      UpdateProjectScope("performance_goals", value)
    }),
    
    view_inspiration_images_section(model.project_scope.inspiration_images),
  ])
}

fn view_review_step(model: Model) -> Element(Msg) {
  html.div([class("form-step review-step")], [
    html.h2([class("step-title")], [html.text("Review Your Quote Request")]),
    html.p([class("step-description")], [
      html.text("Please review all the information before submitting your quote request.")
    ]),
    
    view_review_section("Contact Information", [
      #("Name", model.contact_info.first_name <> " " <> model.contact_info.last_name),
      #("Email", model.contact_info.email),
      #("Phone", model.contact_info.phone),
      #("Preferred Contact", model.contact_info.preferred_contact),
    ]),
    
    view_review_section("Motorcycle", [
      #("Make & Model", model.bike_info.make <> " " <> model.bike_info.model),
      #("Year", model.bike_info.year),
      #("Engine Size", model.bike_info.engine_size),
      #("Mileage", model.bike_info.mileage),
      #("Condition", model.bike_info.condition),
    ]),
    
    view_review_section("Project", [
      #("Service Type", service_type_display(model.project_scope.service_type)),
      #("Priority", model.project_scope.priority),
      #("Budget Range", model.project_scope.budget_range),
      #("Timeline", model.project_scope.timeline),
      #("Description", model.project_scope.description),
    ]),
    
    case model.submission_status {
      Loading -> view_submission_loading()
      Loaded(message) -> view_submission_success(message)
      Errored(error) -> view_submission_error(error)
      Idle -> html.text("")
    }
  ])
}

fn view_sidebar(model: Model) -> Element(Msg) {
  html.aside([class("quote-sidebar")], [
    html.div([class("sidebar-card")], [
      html.h3([class("sidebar-title")], [html.text("Need Help?")]),
      html.p([class("sidebar-text")], [
        html.text("Have questions about your project? Our team is here to help you get the most out of your motorcycle.")
      ]),
      html.div([class("sidebar-contact")], [
        html.div([class("contact-item")], [
          html.strong([], [html.text("Call us:")]),
          html.br([]),
          html.text("(555) 123-BIKE")
        ]),
        html.div([class("contact-item")], [
          html.strong([], [html.text("Email:")]),
          html.br([]),
          html.text("quotes@tandemxmoto.com")
        ]),
        html.div([class("contact-item")], [
          html.strong([], [html.text("Hours:")]),
          html.br([]),
          html.text("Mon-Sat 8AM-6PM")
        ])
      ])
    ]),
    
    html.div([class("sidebar-card")], [
      html.h3([class("sidebar-title")], [html.text("Quote Process")]),
      html.ol([class("process-list")], [
        html.li([], [html.text("Complete the form")]),
        html.li([], [html.text("We review your request")]),
        html.li([], [html.text("Receive detailed quote")]),
        html.li([], [html.text("Schedule consultation")]),
      ])
    ])
  ])
}

fn view_navigation(model: Model) -> Element(Msg) {
  html.div([class("quote-navigation")], [
    case model.current_step {
      ContactStep -> html.text("")
      _ -> html.button([
        class("nav-btn secondary"),
        event.on_click(PreviousStep)
      ], [html.text("← Previous")])
    },
    
    case model.current_step {
      ReviewStep -> html.div([class("nav-actions")], [
        html.button([
          class("nav-btn secondary"),
          event.on_click(ClearForm)
        ], [html.text("Clear Form")]),
        html.button([
          class(case model.is_submitting {
            True -> "nav-btn primary disabled"
            False -> "nav-btn primary"
          }),
          disabled(model.is_submitting),
          event.on_click(SubmitQuote)
        ], [
          html.text(case model.is_submitting {
            True -> "Submitting..."
            False -> "Submit Quote Request"
          })
        ])
      ])
      _ -> html.button([
        class("nav-btn primary"),
        event.on_click(NextStep)
      ], [html.text("Next →")])
    }
  ])
}

// --- Helper View Functions ---

fn view_form_group(label: String, field: String, current_value: String, is_required: Bool, errors: List(ValidationError), on_input: fn(String) -> Msg) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [
      html.text(label),
      case is_required {
        True -> html.span([class("required")], [html.text(" *")])
        False -> html.text("")
      }
    ]),
    html.input([
      type_("text"),
      class(case get_field_error(errors, field) {
        Some(_) -> "form-input error"
        None -> "form-input"
      }),
      value(current_value),
      required(is_required),
      event.on_input(on_input)
    ]),
    case get_field_error(errors, field) {
      Some(error) -> html.div([class("field-error")], [html.text(error)])
      None -> html.text("")
    }
  ])
}

fn view_textarea_group(label: String, field: String, current_value: String, is_required: Bool, errors: List(ValidationError), on_input: fn(String) -> Msg) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [
      html.text(label),
      case is_required {
        True -> html.span([class("required")], [html.text(" *")])
        False -> html.text("")
      }
    ]),
    html.textarea([
      class(case get_field_error(errors, field) {
        Some(_) -> "form-textarea error"
        None -> "form-textarea"
      }),
      value(current_value),
      rows(4),
      required(is_required),
      event.on_input(on_input)
    ], [html.text(current_value)]),
    case get_field_error(errors, field) {
      Some(error) -> html.div([class("field-error")], [html.text(error)])
      None -> html.text("")
    }
  ])
}

fn view_service_type_section(current_type: ServiceType) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Service Type *")]),
    html.div([class("service-type-grid")], [
      view_service_type_option("Maintenance", "Regular maintenance and tune-ups", Maintenance, current_type),
      view_service_type_option("Repair", "Fix existing problems", Repair, current_type),
      view_service_type_option("Performance", "Upgrades and modifications", Performance, current_type),
      view_service_type_option("Custom Build", "Complete custom motorcycles", CustomBuild, current_type),
      view_service_type_option("Restoration", "Restore vintage bikes", Restoration, current_type),
      view_service_type_option("Fabrication", "Custom parts and welding", Fabrication, current_type),
    ])
  ])
}

fn view_service_type_option(title: String, description: String, service_type: ServiceType, current_type: ServiceType) -> Element(Msg) {
  let is_selected = service_type == current_type
  let option_class = case is_selected {
    True -> "service-type-option selected"
    False -> "service-type-option"
  }
  
  html.div([
    class(option_class),
    event.on_click(UpdateProjectScope("service_type", service_type_to_string(service_type)))
  ], [
    html.h4([class("option-title")], [html.text(title)]),
    html.p([class("option-description")], [html.text(description)])
  ])
}

fn view_priority_section(current_priority: String) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Priority")]),
    html.select([
      class("form-select"),
      value(current_priority),
      event.on_input(fn(value) { UpdateProjectScope("priority", value) })
    ], [
      html.option([value("low")], [html.text("Low - Flexible timing")]),
      html.option([value("normal")], [html.text("Normal - Standard timeline")]),
      html.option([value("high")], [html.text("High - Rush job")]),
      html.option([value("urgent")], [html.text("Urgent - ASAP")])
    ])
  ])
}

fn view_budget_section(current_budget: String) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Budget Range")]),
    html.select([
      class("form-select"),
      value(current_budget),
      event.on_input(fn(value) { UpdateProjectScope("budget_range", value) })
    ], [
      html.option([value("")], [html.text("Select budget range...")]),
      html.option([value("under-500")], [html.text("Under $500")]),
      html.option([value("500-1000")], [html.text("$500 - $1,000")]),
      html.option([value("1000-2500")], [html.text("$1,000 - $2,500")]),
      html.option([value("2500-5000")], [html.text("$2,500 - $5,000")]),
      html.option([value("5000-10000")], [html.text("$5,000 - $10,000")]),
      html.option([value("over-10000")], [html.text("Over $10,000")]),
      html.option([value("discuss")], [html.text("Let's discuss")])
    ])
  ])
}

fn view_timeline_section(current_timeline: String) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Desired Timeline")]),
    html.select([
      class("form-select"),
      value(current_timeline),
      event.on_input(fn(value) { UpdateProjectScope("timeline", value) })
    ], [
      html.option([value("")], [html.text("Select timeline...")]),
      html.option([value("asap")], [html.text("As soon as possible")]),
      html.option([value("1-week")], [html.text("Within 1 week")]),
      html.option([value("2-weeks")], [html.text("Within 2 weeks")]),
      html.option([value("1-month")], [html.text("Within 1 month")]),
      html.option([value("2-3-months")], [html.text("2-3 months")]),
      html.option([value("flexible")], [html.text("Flexible")]),
      html.option([value("winter")], [html.text("Winter project")])
    ])
  ])
}

fn view_modifications_section(modifications: List(String)) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Current Modifications")]),
    html.p([class("form-help")], [html.text("List any modifications already done to your bike")]),
    html.div([class("modifications-list")], 
      list.map(modifications, view_modification_item)
    ),
    html.div([class("add-modification")], [
      html.input([
        type_("text"),
        class("add-input"),
        placeholder("Add a modification..."),
        id("new-modification")
      ]),
      html.button([
        class("add-btn"),
        event.on_click(AddModification(""))
      ], [html.text("Add")])
    ])
  ])
}

fn view_modification_item(modification: String) -> Element(Msg) {
  html.div([class("list-item")], [
    html.span([class("item-text")], [html.text(modification)]),
    html.button([
      class("remove-btn"),
      event.on_click(RemoveModification(modification))
    ], [html.text("×")])
  ])
}

fn view_specific_parts_section(parts: List(String)) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Specific Parts Needed")]),
    html.p([class("form-help")], [html.text("List any specific parts you want included")]),
    html.div([class("parts-list")], 
      list.map(parts, view_part_item)
    ),
    html.div([class("add-part")], [
      html.input([
        type_("text"),
        class("add-input"),
        placeholder("Add a part..."),
        id("new-part")
      ]),
      html.button([
        class("add-btn"),
        event.on_click(AddSpecificPart(""))
      ], [html.text("Add")])
    ])
  ])
}

fn view_part_item(part: String) -> Element(Msg) {
  html.div([class("list-item")], [
    html.span([class("item-text")], [html.text(part)]),
    html.button([
      class("remove-btn"),
      event.on_click(RemoveSpecificPart(part))
    ], [html.text("×")])
  ])
}

fn view_inspiration_images_section(images: List(String)) -> Element(Msg) {
  html.div([class("form-group")], [
    html.label([class("form-label")], [html.text("Inspiration Images")]),
    html.p([class("form-help")], [html.text("Add URLs to images that inspire your build")]),
    html.div([class("images-list")], 
      list.map(images, view_image_item)
    ),
    html.div([class("add-image")], [
      html.input([
        type_("url"),
        class("add-input"),
        placeholder("Add image URL..."),
        id("new-image")
      ]),
      html.button([
        class("add-btn"),
        event.on_click(AddInspirationImage(""))
      ], [html.text("Add")])
    ])
  ])
}

fn view_image_item(image_url: String) -> Element(Msg) {
  html.div([class("list-item image-item")], [
    html.img([
      src(image_url),
      alt("Inspiration image"),
      class("inspiration-thumbnail")
    ]),
    html.span([class("item-text")], [html.text(image_url)]),
    html.button([
      class("remove-btn"),
      event.on_click(RemoveInspirationImage(image_url))
    ], [html.text("×")])
  ])
}

fn view_review_section(title: String, items: List(#(String, String))) -> Element(Msg) {
  html.div([class("review-section")], [
    html.h3([class("review-title")], [html.text(title)]),
    html.dl([class("review-list")], 
      list.flatten(list.map(items, fn(item) {
        let #(label, value) = item
        case string.trim(value) {
          "" -> []
          v -> [
            html.dt([class("review-label")], [html.text(label)]),
            html.dd([class("review-value")], [html.text(v)])
          ]
        }
      }))
    )
  ])
}

fn view_submission_loading() -> Element(Msg) {
  html.div([class("submission-status loading")], [
    html.div([class("loading-spinner")], []),
    html.p([], [html.text("Submitting your quote request...")])
  ])
}

fn view_submission_success(message: String) -> Element(Msg) {
  html.div([class("submission-status success")], [
    html.div([class("success-icon")], [html.text("✓")]),
    html.p([], [html.text(message)]),
    html.button([
      class("nav-btn primary"),
      event.on_click(ClearForm)
    ], [html.text("Submit Another Quote")])
  ])
}

fn view_submission_error(error: String) -> Element(Msg) {
  html.div([class("submission-status error")], [
    html.div([class("error-icon")], [html.text("✗")]),
    html.p([], [html.text("Error: " <> error)]),
    html.button([
      class("nav-btn primary"),
      event.on_click(SubmitQuote)
    ], [html.text("Try Again")])
  ])
}

fn service_type_display(service_type: ServiceType) -> String {
  case service_type {
    Maintenance -> "Maintenance"
    Repair -> "Repair"
    Performance -> "Performance"
    CustomBuild -> "Custom Build"
    Restoration -> "Restoration"
    Fabrication -> "Fabrication"
  }
}