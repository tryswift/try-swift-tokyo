import Elementary
import SharedModels

struct CfPNotFoundPage: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage

  var body: some HTML {
    div(.class("container py-5 text-center")) {
      div(.class("py-5")) {
        p(.class("display-1 mb-3")) { "404" }
        h1(.class("fw-bold mb-3")) {
          language == .ja ? "ページが見つかりません" : "Page Not Found"
        }
        p(.class("lead text-muted mb-4")) {
          language == .ja
            ? "お探しのページは存在しないか、移動された可能性があります。"
            : "The page you're looking for doesn't exist or has been moved."
        }
        div(.class("d-flex gap-3 justify-content-center flex-wrap")) {
          a(.class("btn btn-primary btn-lg"), .href("/cfp/\(language.urlPrefix)/")) {
            language == .ja ? "CfPホームに戻る" : "Back to CfP Home"
          }
          a(.class("btn btn-outline-secondary btn-lg"), .href("/cfp/\(language.urlPrefix)/submit"))
          {
            language == .ja ? "トークを応募する" : "Submit a Proposal"
          }
        }
      }
    }
  }
}
