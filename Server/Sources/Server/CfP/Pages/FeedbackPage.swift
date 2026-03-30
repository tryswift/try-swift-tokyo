import Elementary
import Foundation
import SharedModels

struct FeedbackPageView: HTML, Sendable {
  let user: UserDTO?
  let feedbackGroups: [FeedbackForTalk]
  let language: CfPLanguage

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-2")) {
        language == .ja ? "フィードバック" : "Feedback"
      }
      p(.class("lead text-muted mb-4")) {
        language == .ja
          ? "参加者からのフィードバックを確認できます。"
          : "View feedback from attendees on your talks."
      }

      if user != nil {
        if feedbackGroups.isEmpty {
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("fs-1 mb-3")) { "💬" }
              h3(.class("fw-bold mb-2")) {
                language == .ja ? "フィードバックはまだありません" : "No feedback yet"
              }
              p(.class("text-muted")) {
                language == .ja
                  ? "参加者からのフィードバックが届くと、ここに表示されます。"
                  : "Feedback from attendees will appear here."
              }
            }
          }
        } else {
          for group in feedbackGroups {
            div(.class("card mb-4")) {
              div(.class("card-header")) {
                h5(.class("mb-0")) {
                  HTMLText(group.proposalTitle)
                }
                span(.class("badge bg-secondary")) {
                  let count = group.feedbacks.count
                  HTMLText(
                    language == .ja
                      ? "\(count)件のフィードバック"
                      : "\(count) feedback\(count == 1 ? "" : "s")"
                  )
                }
              }
              ul(.class("list-group list-group-flush")) {
                for feedback in group.feedbacks {
                  li(.class("list-group-item")) {
                    p(.class("mb-1")) { HTMLText(feedback.comment) }
                    if let createdAt = feedback.createdAt {
                      small(.class("text-muted")) {
                        HTMLRaw(
                          "<time class=\"local-time\" datetime=\"\(formatISO(createdAt))\" data-style=\"relative\"></time>"
                        )
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } else {
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🔐" }
            h3(.class("fw-bold mb-2")) {
              language == .ja ? "ログインが必要です" : "Sign In Required"
            }
            p(.class("text-muted mb-4")) {
              language == .ja
                ? "フィードバックを確認するにはログインしてください。"
                : "Please sign in to view feedback on your talks."
            }
            a(
              .class("btn btn-dark"),
              .href("/api/v1/auth/github?returnTo=\(language.path(for: "/feedback"))")
            ) {
              language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
            }
          }
        }
      }
    }
  }

  private func formatISO(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }
}
