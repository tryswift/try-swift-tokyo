import Elementary
import SharedModels

struct CfPNavigation: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let currentPath: String

  init(user: UserDTO?, language: CfPLanguage = .en, currentPath: String = "/") {
    self.user = user
    self.language = language
    self.currentPath = currentPath
  }

  var body: some HTML {
    nav(
      .class("navbar navbar-expand-lg navbar-dark fixed-top"),
      .style("background: rgba(0, 32, 63, 0.95);")
    ) {
      div(.class("container")) {
        a(.class("navbar-brand fw-bold text-white d-flex align-items-center"), .href(language.path(for: "/"))) {
          img(
            .src("/cfp/images/riko.png"),
            .alt("Riko"),
            .class("me-2"),
            .style("height: 28px; width: 28px;")
          )
          "try! Swift Tokyo CfP"
        }

        button(
          .class("navbar-toggler"),
          .type(.button),
          .data("bs-toggle", value: "collapse"),
          .data("bs-target", value: "#navbarNav")
        ) {
          span(.class("navbar-toggler-icon")) {}
        }

        div(.class("collapse navbar-collapse"), .id("navbarNav")) {
          ul(.class("navbar-nav ms-auto align-items-center")) {
            li(.class("nav-item")) {
              a(.class("nav-link text-white"), .href(language.path(for: "/"))) {
                language == .ja ? "ホーム" : "Home"
              }
            }
            li(.class("nav-item")) {
              a(.class("nav-link text-white"), .href(language.path(for: "/guidelines"))) {
                language == .ja ? "ガイドライン" : "Guidelines"
              }
            }
            li(.class("nav-item")) {
              a(.class("nav-link text-white"), .href(language.path(for: "/submit"))) {
                language == .ja ? "応募する" : "Submit"
              }
            }

            if let user {
              li(.class("nav-item")) {
                a(.class("nav-link text-white"), .href(language.path(for: "/my-proposals"))) {
                  language == .ja ? "マイプロポーザル" : "My Proposals"
                }
              }
              li(.class("nav-item")) {
                span(.class("nav-link text-white fw-bold")) {
                  HTMLText("👤 \(user.username)")
                }
              }
              li(.class("nav-item ms-2")) {
                a(.class("btn btn-sm btn-danger"), .href(language.path(for: "/logout"))) {
                  language == .ja ? "ログアウト" : "Sign Out"
                }
              }
            } else {
              li(.class("nav-item ms-2")) {
                a(.class("btn btn-sm btn-light"), .href("/api/v1/auth/github")) {
                  language == .ja ? "GitHubでログイン" : "Login with GitHub"
                }
              }
            }

            // Language Switcher
            li(.class("nav-item ms-3")) {
              CfPLanguageSwitcher(currentLanguage: language, currentPath: currentPath)
            }
          }
        }
      }
    }
  }
}

/// Language switcher component
struct CfPLanguageSwitcher: HTML, Sendable {
  let currentLanguage: CfPLanguage
  let currentPath: String

  var body: some HTML {
    div(.class("d-flex align-items-center")) {
      for lang in CfPLanguage.allCases {
        a(
          .class(lang == currentLanguage ? "text-white fw-bold me-2" : "text-white-50 me-2"),
          .href(lang.path(for: currentPath)),
          .style("text-decoration: none;")
        ) {
          lang.displayName
        }
      }
    }
  }
}
