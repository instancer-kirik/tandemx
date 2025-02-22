import gleam/dynamic
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute.{class, style}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type Position {
  Position(x: Float, y: Float)
}

pub type Node {
  Node(id: String, position: Position, label: String, node_type: String)
}

pub type Model {
  Model(
    nodes: List(Node),
    selected: Option(Node),
    scale: Float,
    offset: Position,
    dragging: Bool,
  )
}

pub type Msg {
  AddNode
  SelectNode(Node)
  DeselectNode
  StartDrag
  StopDrag
  UpdateDrag(Position)
  UpdateScale(Float)
  ResetView
}

pub fn init() -> Model {
  Model(
    nodes: [],
    selected: None,
    scale: 1.0,
    offset: Position(x: 0.0, y: 0.0),
    dragging: False,
  )
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    AddNode -> {
      let new_node =
        Node(
          id: "node-" <> int.to_string(1),
          // TODO: Generate unique ID
          position: Position(x: 100.0, y: 100.0),
          label: "New Node",
          node_type: "default",
        )
      Model(..model, nodes: [new_node, ..model.nodes])
    }

    SelectNode(node) -> Model(..model, selected: Some(node))

    DeselectNode -> Model(..model, selected: None)

    StartDrag -> Model(..model, dragging: True)

    StopDrag -> Model(..model, dragging: False)

    UpdateDrag(pos) ->
      case model.dragging {
        True -> Model(..model, offset: pos)
        False -> model
      }

    UpdateScale(new_scale) ->
      Model(..model, scale: float.clamp(new_scale, 0.1, 3.0))

    ResetView -> Model(..model, scale: 1.0, offset: Position(x: 0.0, y: 0.0))
  }
}

fn handle_click(
  msg: Msg,
) -> fn(dynamic.Dynamic) -> Result(Msg, List(dynamic.DecodeError)) {
  fn(_) { Ok(msg) }
}

fn handle_select_node(
  node: Node,
) -> fn(dynamic.Dynamic) -> Result(Msg, List(dynamic.DecodeError)) {
  fn(_) { Ok(SelectNode(node)) }
}

fn handle_drag_event(
  evt: dynamic.Dynamic,
) -> Result(Msg, List(dynamic.DecodeError)) {
  Ok(UpdateDrag(Position(x: 0.0, y: 0.0)))
  // TODO: Extract coordinates
}

fn render_node(node: Node, selected: Bool) -> Element(Msg) {
  let pos_style = [
    #(
      "transform",
      "translate("
        <> float.to_string(node.position.x)
        <> "px, "
        <> float.to_string(node.position.y)
        <> "px)",
    ),
  ]

  html.div(
    [
      class("node"),
      class(case selected {
        True -> "selected"
        False -> ""
      }),
      style(pos_style),
      event.on_click(SelectNode(node)),
    ],
    [html.text(node.label)],
  )
}

pub fn render(model: Model) -> Element(Msg) {
  let transform_style = [
    #(
      "transform",
      "scale("
        <> float.to_string(model.scale)
        <> ") translate("
        <> float.to_string(model.offset.x)
        <> "px, "
        <> float.to_string(model.offset.y)
        <> "px)",
    ),
  ]

  html.div([class("chartspace-container")], [
    html.div(
      [
        class("canvas"),
        style(transform_style),
        event.on_mouse_down(StartDrag),
        event.on_mouse_up(StopDrag),
        event.on_mouse_over(UpdateDrag(Position(x: 0.0, y: 0.0))),
      ],
      list.map(model.nodes, fn(node) {
        render_node(node, case model.selected {
          Some(selected) -> selected.id == node.id
          None -> False
        })
      }),
    ),
    html.div([class("toolbar")], [
      html.button([event.on_click(AddNode)], [html.text("Add Node")]),
      html.button([event.on_click(ResetView)], [html.text("Reset View")]),
    ]),
  ])
}
