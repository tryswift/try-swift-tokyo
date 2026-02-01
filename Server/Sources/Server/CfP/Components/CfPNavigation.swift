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
        a(
          .class("navbar-brand fw-bold text-white d-flex align-items-center"),
          .href(language.path(for: "/"))
        ) {
          img(
            .src("/images/riko.png"),
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
              if user.role == .admin {
                li(.class("nav-item")) {
                  a(.class("nav-link text-warning fw-bold"), .href("/organizer/proposals")) {
                    "📋 Organizer"
                  }
                }
              }
              li(.class("nav-item")) {
                span(.class("nav-link text-white fw-bold")) {
                  HTMLRaw(
                    """
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="me-1" viewBox="0 0 16 16" style="vertical-align: -0.125em;"><path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z"/></svg>
                    """
                  )
                  HTMLText(" \(user.username)")
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
