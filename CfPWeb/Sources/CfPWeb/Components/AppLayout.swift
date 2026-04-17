import Elementary

struct AppLayout: HTMLDocument, Sendable {
  let routePath: String
  let page: CfPPage
  let apiBaseURL: String

  private var language: AppLanguage {
    routePath.hasPrefix("/ja") ? .ja : .en
  }

  var title: String { "\(page.title(for: language)) - try! Swift Tokyo CfP" }
  var lang: String { language.rawValue }

  var head: some HTML {
    meta(.charset(.utf8))
    meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
    meta(.name(.description), .content(page.description(for: language)))
    meta(.property("og:title"), .content("\(page.title(for: language)) - try! Swift Tokyo 2026"))
    meta(.property("og:description"), .content("Submit your talk proposal for try! Swift Tokyo 2026. Share your Swift expertise with developers from around the world."))
    meta(.property("og:image"), .content("https://tryswift.jp/images/ogp.jpg"))
    meta(.name("twitter:card"), .content("summary_large_image"))
    meta(.name("twitter:title"), .content("\(page.title(for: language)) - try! Swift Tokyo 2026"))
    meta(.name("twitter:image"), .content("https://tryswift.jp/images/ogp.jpg"))
    link(.rel(.stylesheet), .href("https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"))
    link(.rel(.stylesheet), .href("/styles/app.css"))
    link(.rel(.icon), .custom(name: "type", value: "image/png"), .href("https://tryswift.jp/images/favicon.png"))
    script(.src("/scripts/app.js"), .custom(name: "defer", value: "defer")) {}
    script(.src("https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js")) {}
    meta(.custom(name: "name", value: "cfp-api-base-url"), .content(apiBaseURL))
  }

  var body: some HTML {
    div(.class("site-shell")) {
      AppNavigation(routePath: routePath, currentPage: page, language: language)
      main(.class("content-shell")) {
        PageContent(page: page, language: language)
      }
      footer(.class("footer")) {
        div(.class("footer-links")) {
          a(.href("https://tryswift.jp")) { HTMLText(language == .ja ? "メインサイト" : "Main Website") }
          a(.href("https://tryswift.jp/code-of-conduct")) { HTMLText(language == .ja ? "行動規範" : "Code of Conduct") }
          a(.href("https://tryswift.jp/privacy-policy")) { HTMLText(language == .ja ? "プライバシーポリシー" : "Privacy Policy") }
        }
        div(.class("footer-links social")) {
          a(.href("https://x.com/tryswiftconf")) { "X" }
          a(.href("https://github.com/tryswift")) { "GitHub" }
        }
        p(.class("copyright")) { "© 2026 try! Swift Tokyo. All rights reserved." }
      }
    }
  }
}
