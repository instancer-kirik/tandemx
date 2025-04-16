import gleam/dynamic.{type Dynamic}
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  html.div([attribute.class("about-container")], [
    html.div([attribute.class("about-header")], [
      html.h1([attribute.class("about-title")], [html.text("About TandemX")]),
      html.p([attribute.class("about-subtitle")], [
        html.text("Your Collaborative Calendar Solution"),
      ]),
    ]),
    html.div([attribute.class("about-content")], [
      html.section([attribute.class("about-section")], [
        html.h2([], [html.text("Our Mission")]),
        html.p([], [
          html.text(
            "TandemX is designed to simplify the way teams schedule and manage meetings. We believe in making collaboration effortless, allowing you to focus on what matters most - your work and your team.",
          ),
        ]),
      ]),
      html.section([attribute.class("about-section")], [
        html.h2([], [html.text("Key Features")]),
        html.ul([attribute.class("features-list")], [
          html.li([], [html.text("Smart Calendar Management")]),
          html.li([], [html.text("Seamless Team Scheduling")]),
          html.li([], [html.text("Intuitive Meeting Organization")]),
          html.li([], [html.text("Real-time Updates")]),
        ]),
      ]),
      html.section([attribute.class("about-section")], [
        html.h2([], [html.text("Get Started")]),
        html.p([], [
          html.text("Ready to transform your team's scheduling experience? "),
          html.a([attribute.href("/signup")], [html.text("Sign up now")]),
          html.text(" or "),
          html.a([attribute.href("/")], [html.text("explore our features")]),
          html.text("."),
        ]),
      ]),
    ]),
    html.footer([attribute.class("about-footer")], [
      html.p([], [html.text("© 2024 TandemX. All rights reserved.")]),
    ]),
  ])
}
