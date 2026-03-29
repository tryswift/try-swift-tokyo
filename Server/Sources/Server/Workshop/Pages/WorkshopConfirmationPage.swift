import Elementary

/// Page showing application confirmation
struct WorkshopConfirmationPageView: HTML, Sendable {
  let email: String
  let applicantName: String
  let firstChoice: String
  let secondChoice: String?
  let thirdChoice: String?
  let language: CfPLanguage
  let isUpdate: Bool

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("fs-1 mb-3")) { "✅" }
              h2(.class("fw-bold mb-3")) {
                if isUpdate {
                  language == .ja
                    ? "申し込みを更新しました！"
                    : "Application Updated!"
                } else {
                  language == .ja
                    ? "申し込みが完了しました！"
                    : "Application Submitted!"
                }
              }
              p(.class("text-muted mb-4")) {
                if isUpdate {
                  language == .ja
                    ? "ワークショップの希望が更新されました。抽選結果はメールでお知らせします。"
                    : "Your workshop preferences have been updated. You will be notified of the lottery results by email."
                } else {
                  language == .ja
                    ? "抽選結果はメールでお知らせします。"
                    : "You will be notified of the lottery results by email."
                }
              }

              div(.class("text-start")) {
                div(.class("mb-3")) {
                  strong {
                    language == .ja ? "お名前: " : "Name: "
                  }
                  HTMLText(applicantName)
                }
                div(.class("mb-3")) {
                  strong {
                    language == .ja ? "メール: " : "Email: "
                  }
                  HTMLText(email)
                }
                div(.class("mb-3")) {
                  strong {
                    language == .ja ? "第1希望: " : "1st Choice: "
                  }
                  HTMLText(firstChoice)
                }
                if let secondChoice {
                  div(.class("mb-3")) {
                    strong {
                      language == .ja ? "第2希望: " : "2nd Choice: "
                    }
                    HTMLText(secondChoice)
                  }
                }
                if let thirdChoice {
                  div(.class("mb-3")) {
                    strong {
                      language == .ja ? "第3希望: " : "3rd Choice: "
                    }
                    HTMLText(thirdChoice)
                  }
                }
              }

              div(.class("mt-4")) {
                a(
                  .class("btn btn-primary"),
                  .href(language.path(for: "/workshops"))
                ) {
                  language == .ja ? "ワークショップ一覧に戻る" : "Back to Workshops"
                }
              }
            }
          }
        }
      }
    }
  }
}
