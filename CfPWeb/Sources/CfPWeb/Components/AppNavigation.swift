import Elementary

struct AppNavigation: HTML, Sendable {
  let currentPage: CfPPage

  private var visiblePages: [CfPPage] {
    CfPPage.allCases.filter { $0 != .home }
  }

  var body: some HTML {
    header(.class("topbar")) {
      div(.class("brand")) {
        a(.href("/")) { "try! Swift CfP" }
      }
      nav(.class("nav")) {
        for page in visiblePages {
          a(
            .href(page.path),
            .class(page == currentPage ? "nav-link active" : "nav-link")
          ) {
            HTMLText(page.title)
          }
        }
      }
      div(.class("auth-area")) {
        button(
          .type(.button),
          .id("login-button"),
          .class("button secondary")
        ) { "GitHub Login" }
        button(
          .type(.button),
          .id("logout-button"),
          .class("button ghost"),
          .custom(name: "hidden", value: "hidden")
        ) { "Logout" }
      }
    }
  }
}
