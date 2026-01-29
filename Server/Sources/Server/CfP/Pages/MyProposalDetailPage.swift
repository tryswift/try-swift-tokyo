import Elementary
import Foundation
import SharedModels

struct MyProposalDetailPageView: HTML, Sendable {
  let user: UserDTO?
  let proposal: ProposalDTO?
  let language: CfPLanguage

  init(user: UserDTO?, proposal: ProposalDTO?, language: CfPLanguage = .en) {
    self.user = user
    self.proposal = proposal
    self.language = language
  }

  var body: some HTML {
    div(.class("container py-5")) {
      if let user {
        if let proposal {
          // Back button
          div(.class("mb-4")) {
            a(.class("btn btn-outline-secondary"), .href(language.path(for: "/my-proposals"))) {
              language == .ja ? "← プロポーザル一覧に戻る" : "← Back to My Proposals"
            }
          }

          // Header
          div(.class("d-flex justify-content-between align-items-start mb-4")) {
            div {
              h1(.class("fw-bold mb-2")) { HTMLText(proposal.title) }
              div(.class("d-flex align-items-center gap-3")) {
                span(
                  .class(
                    proposal.talkDuration == .regular
                      ? "badge bg-primary fs-6" : "badge bg-warning text-dark fs-6"
                  )
                ) {
                  HTMLText(
                    language == .ja
                      ? (proposal.talkDuration == .regular ? "レギュラートーク" : "ライトニングトーク")
                      : proposal.talkDuration.displayName)
                }
                span(.class("text-muted")) {
                  HTMLText(proposal.conferenceDisplayName)
                }
              }
            }
          }

          // Speaker info card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { language == .ja ? "スピーカー情報" : "Speaker Information" }
            }
            div(.class("card-body")) {
              div(.class("d-flex align-items-center mb-3")) {
                if let iconURL = proposal.iconURL {
                  img(
                    .src(iconURL),
                    .alt(proposal.speakerUsername),
                    .class("rounded-circle me-3"),
                    .style("width: 64px; height: 64px;")
                  )
                } else {
                  img(
                    .src("https://github.com/identicons/\(proposal.speakerUsername).png"),
                    .alt(proposal.speakerUsername),
                    .class("rounded-circle me-3"),
                    .style("width: 64px; height: 64px;")
                  )
                }
                div {
                  h5(.class("mb-1")) { HTMLText(proposal.speakerName) }
                  p(.class("text-muted mb-1 small")) { HTMLText(proposal.speakerEmail) }
                  a(
                    .href("https://github.com/\(proposal.speakerUsername)"),
                    .target(.blank),
                    .class("text-muted small")
                  ) {
                    language == .ja ? "GitHubプロフィールを見る" : "View GitHub Profile"
                  }
                }
              }
              h6(.class("fw-bold mb-2")) { language == .ja ? "自己紹介" : "Bio" }
              p(.class("mb-0"), .style("white-space: pre-wrap;")) { HTMLText(proposal.bio) }
            }
          }

          // Abstract card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { language == .ja ? "概要" : "Abstract" }
            }
            div(.class("card-body")) {
              p(.class("mb-0"), .style("white-space: pre-wrap;")) {
                HTMLText(proposal.abstract)
              }
            }
          }

          // Talk details card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { language == .ja ? "トーク詳細（レビュアー向け）" : "Talk Details (for reviewers)" }
            }
            div(.class("card-body")) {
              p(.class("mb-0"), .style("white-space: pre-wrap;")) {
                HTMLText(proposal.talkDetail)
              }
            }
          }

          // Notes to organizers (if any)
          if let notes = proposal.notes, !notes.isEmpty {
            div(.class("card mb-4 border-warning")) {
              div(.class("card-header bg-warning text-dark")) {
                strong { language == .ja ? "運営者へのメモ" : "Notes to Organizers" }
              }
              div(.class("card-body")) {
                p(.class("mb-0"), .style("white-space: pre-wrap;")) {
                  HTMLText(notes)
                }
              }
            }
          }

          // Metadata card
          div(.class("card")) {
            div(.class("card-header")) {
              strong { language == .ja ? "メタデータ" : "Metadata" }
            }
            div(.class("card-body")) {
              dl(.class("row mb-0")) {
                dt(.class("col-sm-3")) { language == .ja ? "提出日" : "Submitted" }
                dd(.class("col-sm-9")) {
                  if let createdAt = proposal.createdAt {
                    HTMLText(formatDate(createdAt))
                  } else {
                    language == .ja ? "不明" : "Unknown"
                  }
                }
                dt(.class("col-sm-3")) { language == .ja ? "最終更新" : "Last Updated" }
                dd(.class("col-sm-9")) {
                  if let updatedAt = proposal.updatedAt {
                    HTMLText(formatDate(updatedAt))
                  } else {
                    language == .ja ? "なし" : "Never"
                  }
                }
              }
            }
          }
        } else {
          // Proposal not found
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              h3(.class("fw-bold mb-2")) {
                language == .ja ? "プロポーザルが見つかりません" : "Proposal Not Found"
              }
              p(.class("text-muted mb-4")) {
                language == .ja
                  ? "お探しのプロポーザルは存在しないか、アクセス権限がありません。"
                  : "The proposal you are looking for does not exist or you don't have access to it."
              }
              a(.class("btn btn-primary"), .href(language.path(for: "/my-proposals"))) {
                language == .ja ? "マイプロポーザルに戻る" : "Back to My Proposals"
              }
            }
          }
        }
      } else {
        // Not logged in
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🔐" }
            h3(.class("fw-bold mb-2")) {
              language == .ja ? "ログインが必要です" : "Sign In Required"
            }
            p(.class("text-muted mb-4")) {
              language == .ja
                ? "プロポーザルを確認するにはログインしてください。"
                : "Please sign in to view your proposals."
            }
            a(
              .class("btn btn-dark"),
              .href("/api/v1/auth/github?returnTo=\(language.path(for: "/my-proposals"))")
            ) {
              language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
            }
          }
        }
      }
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    if language == .ja {
      formatter.locale = Locale(identifier: "ja_JP")
    }
    return formatter.string(from: date)
  }
}
