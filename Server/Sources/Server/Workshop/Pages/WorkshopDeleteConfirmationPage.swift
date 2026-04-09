import Elementary

/// Page showing confirmation after a user deletes their application or cancels participation
struct WorkshopDeleteConfirmationView: HTML, Sendable {
  let language: CfPLanguage
  var isCancellation: Bool = false

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("fs-1 mb-3")) { isCancellation ? "✅" : "🗑️" }
              h2(.class("fw-bold mb-3")) {
                if isCancellation {
                  language == .ja
                    ? "参加を取り消しました"
                    : "Participation Cancelled"
                } else {
                  language == .ja
                    ? "申し込みを取り消しました"
                    : "Application Deleted"
                }
              }
              p(.class("text-muted mb-4")) {
                if isCancellation {
                  language == .ja
                    ? "ワークショップ参加が取り消されました。再度申し込むことができます。"
                    : "Your workshop participation has been cancelled. You can apply again if you wish."
                } else {
                  language == .ja
                    ? "ワークショップの申し込みが取り消されました。再度申し込むことができます。"
                    : "Your workshop application has been deleted. You can apply again if you wish."
                }
              }
              div(.class("mt-4")) {
                a(
                  .class("btn btn-primary me-2"),
                  .href(language.path(for: "/workshops/apply"))
                ) {
                  language == .ja ? "再度申し込む" : "Apply Again"
                }
                a(
                  .class("btn btn-outline-secondary"),
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
