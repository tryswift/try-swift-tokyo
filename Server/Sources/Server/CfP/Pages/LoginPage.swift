import Elementary
import SharedModels

struct LoginPageView: HTML, Sendable {
  let user: UserDTO?
  let error: String?

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          if let error {
            div(.class("alert alert-danger mb-4")) {
              strong { "Login failed: " }
              HTMLText(error)
            }
          }

          if let user {
            // LOGGED IN VIEW - Server-side rendered with correct state
            div(.class("card")) {
              div(.class("card-body text-center p-5")) {
                p(.class("fs-1 mb-3")) { "✅" }
                h2(.class("fw-bold mb-2")) {
                  HTMLText("Welcome, \(user.username)!")
                }
                p(.class("text-muted mb-4")) {
                  "You are now signed in. You can submit and manage your talk proposals."
                }
                div(.class("d-flex gap-2 justify-content-center flex-wrap")) {
                  a(.class("btn btn-primary"), .href("/cfp/submit")) { "Submit a Proposal" }
                  a(.class("btn btn-secondary"), .href("/cfp/my-proposals")) { "My Proposals" }
                }
                div(.class("mt-4")) {
                  a(.class("text-muted text-decoration-none"), .href("/cfp/logout")) { "Logout" }
                }
              }
            }
          } else {
            // NOT LOGGED IN VIEW
            div(.class("card")) {
              div(.class("card-body text-center p-5")) {
                p(.class("fs-1 mb-3")) { "🔐" }
                h2(.class("fw-bold mb-2")) { "Sign in to try! Swift CfP" }
                p(.class("text-muted mb-4")) {
                  "Connect your GitHub account to submit and manage your talk proposals."
                }
                a(.class("btn btn-dark btn-lg"), .href("/api/v1/auth/github")) {
                  "Sign in with GitHub"
                }
                p(.class("text-muted small mt-4 mb-0")) {
                  "By signing in, you agree to our terms of service and privacy policy."
                }
              }
            }
          }
        }
      }
    }
  }
}
