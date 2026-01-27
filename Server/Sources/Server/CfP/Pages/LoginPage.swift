import Elementary
import SharedModels

struct LoginPageView: HTML, Sendable {
  let user: UserDTO?
  let error: String?
  let language: CfPLanguage

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          if let error {
            div(.class("alert alert-danger mb-4")) {
              strong { CfPStrings.Login.loginFailed(language) }
              HTMLText(error)
            }
          }

          if let user {
            // LOGGED IN VIEW - Server-side rendered with correct state
            div(.class("card")) {
              div(.class("card-body text-center p-5")) {
                p(.class("fs-1 mb-3")) { "✅" }
                h2(.class("fw-bold mb-2")) {
                  HTMLText(CfPStrings.Login.welcomeUser(language, username: user.username))
                }
                p(.class("text-muted mb-4")) {
                  CfPStrings.Login.welcomeDescription(language)
                }
                div(.class("d-flex gap-2 justify-content-center flex-wrap")) {
                  a(.class("btn btn-primary"), .href("/cfp/\(language.urlPrefix)/submit")) {
                    CfPStrings.Login.submitAProposal(language)
                  }
                  a(.class("btn btn-secondary"), .href("/cfp/\(language.urlPrefix)/my-proposals")) {
                    CfPStrings.Login.myProposals(language)
                  }
                }
                div(.class("mt-4")) {
                  a(
                    .class("text-muted text-decoration-none"),
                    .href("/cfp/\(language.urlPrefix)/logout")
                  ) {
                    CfPStrings.Login.logout(language)
                  }
                }
              }
            }
          } else {
            // NOT LOGGED IN VIEW
            div(.class("card")) {
              div(.class("card-body text-center p-5")) {
                p(.class("fs-1 mb-3")) { "🔐" }
                h2(.class("fw-bold mb-2")) { CfPStrings.Login.signInTitle(language) }
                p(.class("text-muted mb-4")) {
                  CfPStrings.Login.signInDescription(language)
                }
                a(.class("btn btn-dark btn-lg"), .href("/api/v1/auth/github")) {
                  CfPStrings.Login.signInWithGitHub(language)
                }
                p(.class("text-muted small mt-4 mb-0")) {
                  CfPStrings.Login.termsNotice(language)
                }
              }
            }
          }
        }
      }
    }
  }
}
