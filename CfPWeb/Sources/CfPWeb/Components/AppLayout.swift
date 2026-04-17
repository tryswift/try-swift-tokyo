import Elementary

struct AppLayout: HTMLDocument, Sendable {
  let page: CfPPage

  var title: String { "\(page.title) - try! Swift CfP" }
  var lang: String { "en" }

  var head: some HTML {
    meta(.charset(.utf8))
    meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
    link(.rel(.stylesheet), .href("/styles/app.css"))
    script(.src("/scripts/app.js"), .custom(name: "defer", value: "defer")) {}
    meta(.custom(name: "cfp-api-base-url", value: AppConfiguration.apiBaseURL()))
  }

  var body: some HTML {
    div(.class("site-shell")) {
      AppNavigation(currentPage: page)
      main(.class("content-shell")) {
        PageContent(page: page)
      }
      footer(.class("footer")) {
        p { "try! Swift CfP Web App" }
      }
    }
  }
}
