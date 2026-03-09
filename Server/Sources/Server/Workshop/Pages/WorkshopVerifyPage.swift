import Elementary

/// Page for email verification against Luma ticket
struct WorkshopVerifyPageView: HTML, Sendable {
  let language: CfPLanguage
  let csrfToken: String
  let errorMessage: String?

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          if let errorMessage {
            div(.class("alert alert-danger mb-4")) {
              strong {
                language == .ja ? "エラー: " : "Error: "
              }
              HTMLText(errorMessage)
            }
          }

          div(.class("card")) {
            div(.class("card-body p-4")) {
              div(.class("text-center mb-4")) {
                p(.class("fs-1 mb-2")) { "🎟️" }
                h2(.class("fw-bold mb-2")) {
                  language == .ja
                    ? "チケット確認"
                    : "Verify Your Ticket"
                }
                p(.class("text-muted")) {
                  language == .ja
                    ? "try! Swift Tokyo 2026のチケットに登録したメールアドレスを入力してください。"
                    : "Enter the email address used to register for your try! Swift Tokyo 2026 ticket."
                }
              }

              form(
                .method(.post),
                .action(language.path(for: "/workshops/verify"))
              ) {
                input(.type(.hidden), .name("_csrf"), .value(csrfToken))

                div(.class("mb-3")) {
                  label(.class("form-label fw-bold"), .for("email")) {
                    language == .ja ? "メールアドレス" : "Email Address"
                  }
                  input(
                    .type(.email),
                    .class("form-control form-control-lg"),
                    .id("email"),
                    .name("email"),
                    .custom(
                      name: "placeholder",
                      value: language == .ja ? "your@email.com" : "your@email.com"),
                    .required
                  )
                }

                button(
                  .type(.submit),
                  .class("btn btn-primary btn-lg w-100")
                ) {
                  language == .ja ? "チケットを確認" : "Verify Ticket"
                }
              }
            }
          }

          div(.class("text-center mt-3")) {
            a(
              .class("text-muted"),
              .href(language.path(for: "/workshops"))
            ) {
              language == .ja ? "← ワークショップ一覧に戻る" : "← Back to Workshops"
            }
          }
        }
      }
    }
  }
}
