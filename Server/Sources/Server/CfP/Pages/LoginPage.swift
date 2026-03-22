import Elementary
import SharedModels

struct LoginPageView: HTML, Sendable {
  let user: UserDTO?
  let error: String?
  let language: CfPLanguage

  init(user: UserDTO?, error: String?, language: CfPLanguage = .en) {
    self.user = user
    self.error = error
    self.language = language
  }

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          if let error {
            div(.class("alert alert-danger mb-4")) {
              strong {
                language == .ja ? "ログイン失敗: " : "Login failed: "
              }
              HTMLText(error)
            }
          }

          if let user {
            // LOGGED IN VIEW - Server-side rendered with correct state
            div(.class("card")) {
              div(.class("card-body text-center p-5")) {
                p(.class("fs-1 mb-3")) { "✅" }
                h2(.class("fw-bold mb-2")) {
                  HTMLText(
                    language == .ja ? "ようこそ、\(user.username)さん！" : "Welcome, \(user.username)!")
                }
                p(.class("text-muted mb-4")) {
                  language == .ja
                    ? "ログインしました。トークプロポーザルの提出と管理ができます。"
                    : "You are now signed in. You can submit and manage your talk proposals."
                }
                div(.class("d-flex gap-2 justify-content-center flex-wrap")) {
                  a(.class("btn btn-primary"), .href(language.path(for: "/submit"))) {
                    language == .ja ? "プロポーザルを提出" : "Submit a Proposal"
                  }
                  a(.class("btn btn-secondary"), .href(language.path(for: "/my-proposals"))) {
                    language == .ja ? "マイプロポーザル" : "My Proposals"
                  }
                }
                div(.class("mt-4")) {
                  a(.class("text-muted text-decoration-none"), .href(language.path(for: "/logout")))
                  {
                    language == .ja ? "ログアウト" : "Logout"
                  }
                }
              }
            }
          } else {
            // NOT LOGGED IN VIEW
            div(.class("card")) {
              div(.class("card-body text-center p-5")) {
                p(.class("fs-1 mb-3")) { "🔐" }
                h2(.class("fw-bold mb-2")) {
                  language == .ja ? "try! Swift CfPにログイン" : "Sign in to try! Swift CfP"
                }
                p(.class("text-muted mb-4")) {
                  language == .ja
                    ? "GitHubアカウントでログインして、トークプロポーザルの提出と管理ができます。"
                    : "Connect your GitHub account to submit and manage your talk proposals."
                }
                a(.class("btn btn-dark btn-lg"), .href(AuthURL.login(returnTo: "/"))) {
                  language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
                }
                p(.class("text-muted small mt-4 mb-0")) {
                  language == .ja
                    ? "ログインすることで、利用規約とプライバシーポリシーに同意したことになります。"
                    : "By signing in, you agree to our terms of service and privacy policy."
                }
              }
            }
          }
        }
      }
    }
  }
}
