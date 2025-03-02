import components/nav
import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  // Create the Lustre application
  let app = lustre.application(init, update, view)

  // Start the application
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

// MODEL ----------------------------------------------------------------------

pub type Model {
  Model(
    todos: Dict(Int, Todo),
    filter: Filter,
    last_id: Int,
    new_todo_input: String,
    existing_todo_input: String,
    nav_open: Bool,
  )
}

pub type Todo {
  Todo(id: Int, description: String, completed: Bool, editing: Bool)
}

pub type Filter {
  All
  Active
  Completed
}

fn compare(a: Todo, b: Todo) -> order.Order {
  int.compare(a.id, b.id)
}

fn init(_) -> #(Model, Effect(msg)) {
  #(
    Model(
      todos: dict.new(),
      filter: All,
      last_id: 0,
      new_todo_input: "",
      existing_todo_input: "",
      nav_open: False,
    ),
    effect.none(),
  )
}

// UPDATE ---------------------------------------------------------------------

pub type Msg {
  UserAddedTodo
  UserBlurredExistingTodo(id: Int)
  UserClickedClearCompleted
  UserClickedFilter(Filter)
  UserClickedToggle(id: Int, checked: Bool)
  UserClickedToggleAll(checked: Bool)
  UserDeletedTodo(id: Int)
  UserDoubleClickedTodo(id: Int, input: String)
  UserEditedTodo(id: Int)
  UserUpdatedExistingInput(value: String)
  UserUpdatedNewInput(value: String)
  NavMsg(nav.Msg)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let Model(todos, _, last_id, new_todo_input, existing_todo_input, nav_open) =
    model

  case msg {
    UserAddedTodo -> {
      let description = new_todo_input
      let last_id = last_id + 1
      let new = Todo(last_id, description, False, False)
      let todos = dict.insert(todos, last_id, new)
      let model = Model(..model, todos:, last_id:, new_todo_input: "")
      #(model, effect.none())
    }

    UserBlurredExistingTodo(id) -> {
      let todos =
        dict.upsert(todos, id, fn(i) {
          let assert Some(i) = i
          Todo(..i, editing: False)
        })
      let model = Model(..model, todos:, existing_todo_input: "")
      #(model, effect.none())
    }

    UserClickedClearCompleted -> {
      let todos = dict.filter(todos, fn(_, item) { !item.completed })
      #(Model(..model, todos:), effect.none())
    }

    UserClickedFilter(filter) -> {
      #(Model(..model, filter:), effect.none())
    }

    UserClickedToggle(id, checked) -> {
      let todos =
        dict.upsert(todos, id, fn(i) {
          let assert Some(i) = i
          Todo(..i, completed: checked)
        })
      let model = Model(..model, todos:)
      #(model, effect.none())
    }

    UserClickedToggleAll(checked) -> {
      let todos =
        dict.map_values(todos, fn(_, i) { Todo(..i, completed: checked) })
      let model = Model(..model, todos:)
      #(model, effect.none())
    }

    UserDeletedTodo(id) -> {
      let todos = dict.delete(todos, id)
      let model = Model(..model, todos:)
      #(model, effect.none())
    }

    UserDoubleClickedTodo(id, input) -> {
      let todos =
        dict.upsert(todos, id, fn(i) {
          let assert Some(i) = i
          Todo(..i, editing: True)
        })

      let model = Model(..model, todos:, existing_todo_input: input)
      #(model, focus_edit_input())
    }

    UserEditedTodo(id) -> {
      use <- bool.guard(existing_todo_input == "", #(model, delete_todo(id)))

      let description = existing_todo_input
      let todos =
        dict.upsert(todos, id, fn(i) {
          let assert Some(i) = i
          Todo(..i, description:, editing: False)
        })
      let model = Model(..model, todos:)
      #(model, effect.none())
    }

    UserUpdatedExistingInput(existing_todo_input) -> {
      let model = Model(..model, existing_todo_input:)
      #(model, effect.none())
    }

    UserUpdatedNewInput(new_todo_input) -> {
      #(Model(..model, new_todo_input:), effect.none())
    }

    NavMsg(nav_msg) -> {
      case nav_msg {
        nav.ToggleNav -> {
          #(Model(..model, nav_open: !model.nav_open), effect.none())
        }
      }
    }
  }
}

// VIEW -----------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(case model.nav_open {
        True -> "app-container nav-open"
        False -> "app-container"
      }),
    ],
    [
      element.map(nav.view(), NavMsg),
      html.div([attribute.class("todoapp")], [
        header(model),
        main_content(model),
        footer(model),
      ]),
      info_footer(),
    ],
  )
}

fn header(model: Model) -> Element(Msg) {
  html.header([attribute.class("header")], [
    html.h1([], [html.text("todos")]),
    new_todo(model),
  ])
}

fn main_content(model: Model) -> Element(Msg) {
  let visible_todos = case model.filter {
    All ->
      dict.values(model.todos)
      |> list.sort(compare)
    Active ->
      dict.values(model.todos)
      |> list.filter(fn(i) { !i.completed })
      |> list.sort(compare)
    Completed ->
      dict.values(model.todos)
      |> list.filter(fn(i) { i.completed })
      |> list.sort(compare)
  }
  let input =
    input(
      on_enter: UserAddedTodo,
      on_input: UserUpdatedNewInput,
      on_blur: None,
      placeholder: "What needs to be done?",
      autofocus: True,
      label: "Add a todo",
      value: model.new_todo_input,
    )
  html.main([attribute.class("main")], [
    toggle(dict.values(model.todos) |> list.sort(compare)),
    todo_list(visible_todos, model),
  ])
}

fn footer(model: Model) -> Element(Msg) {
  let active_count =
    dict.values(model.todos)
    |> list.count(fn(i) { !i.completed })
  html.footer([attribute.class("footer")], [
    todo_count(active_count),
    filters(model.filter),
    clear_completed(model),
  ])
}

fn new_todo(model: Model) -> Element(Msg) {
  html.div([attribute.class("new-todo-container")], [
    html.input([
      attribute.class("new-todo"),
      attribute.type_("text"),
      attribute.placeholder("What needs to be done?"),
      attribute.value(model.new_todo_input),
      event.on_input(UserUpdatedNewInput),
    ]),
    html.button([attribute.class("add-todo"), event.on_click(UserAddedTodo)], [
      html.text("Add"),
    ]),
  ])
}

fn toggle(visible_todos: List(Todo)) -> Element(Msg) {
  use <- bool.guard(list.is_empty(visible_todos), element.none())

  html.div([attribute.class("toggle-all-container")], [
    html.input([
      attribute.class("toggle-all"),
      attribute.type_("checkbox"),
      attribute.id("toggle-all"),
      event.on_check(UserClickedToggleAll),
    ]),
    html.label(
      [attribute.class("toggle-all-label"), attribute.for("toggle-all")],
      [html.text("Toggle All Input")],
    ),
  ])
}

fn todo_list(visible_todos: List(Todo), model: Model) -> Element(Msg) {
  let items = list.map(visible_todos, todo_item(_, model))
  html.ul([attribute.class("todo-list")], items)
}

fn todo_item(item: Todo, model: Model) -> Element(Msg) {
  let cn = case item.completed {
    True -> "completed"
    False -> ""
  }

  let el = case item.editing {
    True -> todo_item_edit(item, model)
    False -> todo_item_not_edit(item)
  }

  html.li([attribute.class(cn)], [el])
}

fn todo_item_edit(item: Todo, model: Model) -> Element(Msg) {
  html.div([attribute.class("view")], [
    html.input([
      attribute.class("edit"),
      attribute.type_("text"),
      attribute.value(model.existing_todo_input),
      event.on_input(UserUpdatedExistingInput),
      event.on_blur(UserBlurredExistingTodo(item.id)),
    ]),
    html.button(
      [attribute.class("save-todo"), event.on_click(UserEditedTodo(item.id))],
      [html.text("Save")],
    ),
  ])
}

fn todo_item_not_edit(item: Todo) -> Element(Msg) {
  html.div([attribute.class("view")], [
    html.input([
      attribute.class("toggle"),
      attribute.type_("checkbox"),
      attribute.checked(item.completed),
      event.on_check(UserClickedToggle(item.id, _)),
    ]),
    html.label(
      [on_double_click(UserDoubleClickedTodo(item.id, item.description))],
      [html.text(item.description)],
    ),
    html.button(
      [attribute.class("destroy"), event.on_click(UserDeletedTodo(item.id))],
      [],
    ),
  ])
}

fn todo_count(count: Int) -> Element(c) {
  let text = case count {
    1 -> "1 item left!"
    n -> int.to_string(n) <> " items left!"
  }
  html.span([attribute.class("todo-count")], [html.text(text)])
}

fn filters(current: Filter) -> Element(Msg) {
  [All, Active, Completed]
  |> list.map(filter_item(_, current))
  |> html.ul([attribute.class("filters")], _)
}

fn filter_item(item: Filter, current: Filter) -> Element(Msg) {
  let cn = case item == current {
    True -> "selected"
    False -> ""
  }

  let text = case item {
    All -> "All"
    Active -> "Active"
    Completed -> "Completed"
  }
  html.li([], [
    html.a([attribute.class(cn), event.on_click(UserClickedFilter(item))], [
      html.text(text),
    ]),
  ])
}

fn clear_completed(model: Model) -> Element(Msg) {
  let disabled = dict.is_empty(model.todos)
  html.button(
    [
      attribute.class("clear-completed"),
      attribute.disabled(disabled),
      event.on_click(UserClickedClearCompleted),
    ],
    [html.text("Clear Completed")],
  )
}

fn input(
  on_enter on_enter: Msg,
  on_input on_input: fn(String) -> Msg,
  on_blur on_blur: Option(Msg),
  placeholder placeholder: String,
  autofocus autofocus: Bool,
  label label: String,
  value value: String,
) -> Element(Msg) {
  let on_blur =
    on_blur
    |> option.map(event.on_blur)
    |> option.unwrap(attribute.none())

  html.div([attribute.class("input-container")], [
    html.input([
      attribute.class("new-todo"),
      attribute.id("todo-input"),
      attribute.type_("text"),
      attribute.autofocus(autofocus),
      attribute.placeholder(placeholder),
      attribute.value(value),
      on_enter_down(on_enter),
      event.on_input(on_input),
      on_blur,
    ]),
    html.label(
      [attribute.class("visually-hidden"), attribute.for("todo-input")],
      [html.text(label)],
    ),
  ])
}

fn info_footer() -> Element(msg) {
  html.footer([attribute.class("info")], [
    html.p([], [html.text("Double-click to edit a todo")]),
  ])
}

fn delete_todo(id: Int) -> Effect(Msg) {
  use dispatch <- effect.from
  dispatch(UserDeletedTodo(id))
}

fn on_double_click(msg: Msg) -> Attribute(Msg) {
  use _ <- event.on("dblclick")
  Ok(msg)
}

fn focus_edit_input() -> Effect(msg) {
  use _ <- effect.from
  use <- after_render
  focus(".todo-list .edit")
}

@external(javascript, "./todomvc_ffi.mjs", "focus")
fn focus(selector: String) -> Nil

@external(javascript, "./todomvc_ffi.mjs", "after_render")
fn after_render(do: fn() -> a) -> Nil

fn on_enter_down(msg: Msg) -> Attribute(Msg) {
  use event <- event.on("keydown")
  event
  |> dynamic.field("key", dynamic.string)
  |> result.try(fn(key) {
    case key {
      "Enter" -> Ok(msg)
      _ -> Error([])
    }
  })
}
