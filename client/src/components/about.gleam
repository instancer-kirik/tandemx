import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(msg) {
  html.div([attribute.class("about-container")], [
    html.div([attribute.class("about-header")], [
      html.h1([attribute.class("about-title")], [html.text("About TandemX")]),
      html.p([attribute.class("about-subtitle")], [
        html.text("A Project by instance.select"),
      ]),
    ]),
    html.div([attribute.class("about-content")], [
      html.section([attribute.class("about-section")], [
        html.h2([], [html.text("About Us")]),
        html.p([], [
          html.text(
            "Welcome to the hub of my projects, tools, and creative works. I'm known as Ultimate Starter Kit or instancer-kirik, and this platform serves as an index for everything I'm working on.",
          ),
        ]),
      ]),
      html.section([attribute.class("about-section")], [
        html.h2([], [html.text("Get Started")]),
        html.p([], [
          html.text("Ready to explore our projects and tools? "),
          html.a([attribute.href("/projects")], [html.text("Browse projects")]),
          html.text(" or "),
          html.a([attribute.href("/tools")], [html.text("check out our tools")]),
          html.text("."),
        ]),
      ]),
    ]),
    html.footer([attribute.class("about-footer")], [
      html.p([], [html.text("© 2025 Veix DAO LLC. All rights reserved.")]),
    ]),
  ])
}
