import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

// No longer imports app
import access_content.{
  type FetchState, type SupabaseUser, Errored, Idle, Loaded, Loading,
}
import gleam/option.{type Option, None, Some}

// Reintroduce nav.Msg
pub type Msg {
  Navigated(String)
  LoginAttempted
  LogoutAttempted
}

// View function returns Element(nav.Msg)
pub fn view(user_state: FetchState(Option(SupabaseUser))) -> Element(Msg) {
  html.nav([attribute.class("navbar main-nav")], [
    html.div([attribute.class("nav-content")], [
      html.a([attribute.class("logo"), attribute.href("/")], [
        html.text("TandemX"),
      ]),
      html.div([attribute.class("nav-links")], [
        // Core links - dispatch Navigated
        html.a([attribute.href("/"), event.on_click(Navigated("home"))], [
          html.text("Home"),
        ]),
        html.a(
          [attribute.href("/projects"), event.on_click(Navigated("projects"))],
          [html.text("Projects")],
        ),
        html.a(
          [
            attribute.href("/access-content"),
            event.on_click(Navigated("access-content")),
          ],
          [html.text("Content")],
        ),
        html.a(
          [attribute.href("/calendar"), event.on_click(Navigated("calendar"))],
          [html.text("Calendar")],
        ),
      ]),
      // Auth actions - dispatch LoginAttempted/LogoutAttempted
      html.div([attribute.class("nav-actions")], [
        case user_state {
          Loaded(Some(_user)) ->
            html.button(
              [
                attribute.class("nav-btn logout"),
                event.on_click(LogoutAttempted),
                // Dispatch LogoutAttempted
              ],
              [html.text("Logout")],
            )
          Loaded(None) | Idle | Errored(_) ->
            html.button(
              [
                attribute.class("nav-btn login"),
                event.on_click(LoginAttempted),
                // Dispatch LoginAttempted
              ],
              [html.text("Login with GitHub")],
            )
          Loading ->
            html.span([attribute.class("nav-loading")], [html.text("...")])
        },
      ]),
    ]),
  ])
}
