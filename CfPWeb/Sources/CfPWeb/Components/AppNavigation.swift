import Elementary

struct AppNavigation: HTML, Sendable {
  let routePath: String
  let currentPage: CfPPage
  let language: AppLanguage

  var body: some HTML {
    header(.class("topbar")) {
      div(.class("topbar-inner")) {
        div(.class("brand")) {
          a(.href(language.rootPath)) {
            img(.src("https://cfp.tryswift.jp/cfp/images/riko.png"), .alt("Riko"), .class("brand-icon"))
            span { "try! Swift Tokyo CfP" }
          }
        }
        nav(.class("nav")) {
          for page in navigationPages {
            a(
              .href(page.path(for: language)),
              .class(page == currentPage ? "nav-link active" : "nav-link")
            ) {
              HTMLText(page.navigationTitle(for: language))
            }
          }
        }
        div(.class("auth-area")) {
          button(.type(.button), .id("login-button"), .class("button login-link")) {
            HTMLText(language == .ja ? "GitHubでログイン" : "Login with GitHub")
          }
          button(
            .type(.button),
            .id("logout-button"),
            .class("button ghost"),
            .custom(name: "hidden", value: "hidden")
          ) { HTMLText(language == .ja ? "ログアウト" : "Logout") }
          div(.class("language-switch")) {
            a(.href(currentPage.path(for: .en)), .class(language == .en ? "lang-link active" : "lang-link")) { "English" }
            a(.href(currentPage.path(for: .ja)), .class(language == .ja ? "lang-link active" : "lang-link")) { "日本語" }
          }
        }
      }
    }
  }

  private var navigationPages: [CfPPage] {
    [.home, .guidelines, .submit, .workshops]
  }
}
