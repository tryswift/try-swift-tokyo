import Elementary

struct AppNavigation: HTML, Sendable {
  let routePath: String
  let currentPage: CfPPage
  let language: AppLanguage

  var body: some HTML {
    header(.class("topbar")) {
      div(.class("topbar-inner")) {
        div(.class("topbar-row")) {
          div(.class("brand")) {
            a(.href(language.rootPath)) {
              img(.src("/images/riko.png"), .alt("Riko"), .class("brand-icon"))
              span { "try! Swift Tokyo CfP" }
            }
          }
          button(
            .type(.button),
            .class("nav-toggle"),
            .custom(name: "data-bs-toggle", value: "collapse"),
            .custom(name: "data-bs-target", value: "#site-nav-panel"),
            .custom(name: "aria-controls", value: "site-nav-panel"),
            .custom(name: "aria-expanded", value: "false"),
            .custom(name: "aria-label", value: language == .ja ? "メニューを開く" : "Open navigation menu")
          ) {
            span(.class("nav-toggle-line")) {}
            span(.class("nav-toggle-line")) {}
            span(.class("nav-toggle-line")) {}
          }
        }
        div(.id("site-nav-panel"), .class("topbar-panel collapse")) {
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
              .class("button light"),
              .custom(name: "hidden", value: "hidden")
            ) { HTMLText(language == .ja ? "ログアウト" : "Logout") }
            div(.class("language-switch")) {
              span(.class("language-switch-icon"), .custom(name: "aria-hidden", value: "true")) { "🌐" }
              div(.class("language-switch-track")) {
                a(.href(languageSwitchPath(for: .en)), .class(language == .en ? "lang-link active" : "lang-link")) { "EN" }
                a(.href(languageSwitchPath(for: .ja)), .class(language == .ja ? "lang-link active" : "lang-link")) { "JP" }
              }
            }
          }
        }
      }
    }
  }

  private var navigationPages: [CfPPage] {
    [.home, .guidelines, .submit, .workshops]
  }

  private func languageSwitchPath(for target: AppLanguage) -> String {
    let concretePaths = Set(SiteRoutes.concrete.map(\.path))
    let candidate: String

    switch target {
    case .en:
      if routePath == "/ja" {
        candidate = "/"
      } else if routePath.hasPrefix("/ja/") {
        candidate = String(routePath.dropFirst(3))
      } else {
        candidate = routePath
      }
    case .ja:
      if routePath == "/" {
        candidate = "/ja"
      } else if routePath.hasPrefix("/ja") {
        candidate = routePath
      } else {
        candidate = "/ja\(routePath)"
      }
    }

    if concretePaths.contains(candidate) {
      return candidate
    }

    if currentPage == .organizer {
      return target == .ja ? "/ja/organizer/proposals" : "/organizer"
    }

    return currentPage.path(for: target)
  }
}
