import Elementary
import Foundation
import SharedModels

struct MyProposalsPageView: HTML, Sendable {
  let user: UserDTO?
  let proposals: [ProposalDTO]
  let language: CfPLanguage
  let showWithdrawnMessage: Bool

  init(
    user: UserDTO?, proposals: [ProposalDTO], language: CfPLanguage = .en,
    showWithdrawnMessage: Bool = false
  ) {
    self.user = user
    self.proposals = proposals
    self.language = language
    self.showWithdrawnMessage = showWithdrawnMessage
  }

  var body: some HTML {
    div(.class("container py-5")) {
      // Withdrawn success message
      if showWithdrawnMessage {
        div(
          .class("alert alert-info alert-dismissible fade show mb-4"),
          .custom(name: "role", value: "alert")
        ) {
          language == .ja ? "プロポーザルが取り下げられました。" : "Proposal has been withdrawn."
          button(
            .type(.button), .class("btn-close"), .custom(name: "data-bs-dismiss", value: "alert")
          ) {}
        }
      }

      h1(.class("fw-bold mb-2")) {
        language == .ja ? "マイプロポーザル" : "My Proposals"
      }
      p(.class("lead text-muted mb-4")) {
        language == .ja
          ? "提出したトークプロポーザルを確認・管理できます。"
          : "View and manage your submitted talk proposals."
      }

      if let user {
        // User info card
        div(.class("card mb-4")) {
          div(.class("card-body")) {
            div(.class("d-flex align-items-center justify-content-between")) {
              div(.class("d-flex align-items-center")) {
                img(
                  .src(user.avatarURL ?? "https://github.com/identicons/\(user.username).png"),
                  .alt(user.username),
                  .class("rounded-circle me-3"),
                  .style("width: 50px; height: 50px;")
                )
                div {
                  strong { HTMLText(user.username) }
                  div(.class("text-muted small")) {
                    HTMLText(
                      user.role == .admin
                        ? (language == .ja ? "運営者" : "Organizer")
                        : (language == .ja ? "スピーカー" : "Speaker"))
                  }
                }
              }
              a(.class("btn btn-outline-danger btn-sm"), .href(language.path(for: "/logout"))) {
                language == .ja ? "ログアウト" : "Logout"
              }
            }
          }
        }

        // Proposals section
        h3(.class("fw-bold mb-3")) {
          language == .ja ? "提出済みプロポーザル" : "Your Submissions"
        }

        if proposals.isEmpty {
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("text-muted mb-3")) {
                language == .ja ? "まだプロポーザルがありません" : "No proposals yet"
              }
              p(.class("text-muted small mb-4")) {
                language == .ja
                  ? "最初のプロポーザルを提出すると、ここに表示されます。"
                  : "Submit your first proposal to see it here."
              }
              a(.class("btn btn-primary"), .href(language.path(for: "/submit"))) {
                language == .ja ? "プロポーザルを提出" : "Submit a Proposal"
              }
            }
          }
        } else {
          HTMLRaw(
            """
            <style>
              .proposal-card:hover {
                box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
                transform: translateY(-2px);
                transition: all 0.2s ease-in-out;
              }
              .proposal-card {
                transition: all 0.2s ease-in-out;
              }
            </style>
            """)
          for proposal in proposals {
            ProposalCard(proposal: proposal, language: language)
          }

          div(.class("text-center mt-4")) {
            a(.class("btn btn-primary"), .href(language.path(for: "/submit"))) {
              language == .ja ? "別のプロポーザルを提出" : "Submit Another Proposal"
            }
          }
        }
      } else {
        // Not logged in - redirect via meta refresh or show login prompt
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
              .href(AuthURL.login(returnTo: language.path(for: "/my-proposals")))
            ) {
              language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
            }
          }
        }
      }
    }
  }
}

struct ProposalCard: HTML, Sendable {
  let proposal: ProposalDTO
  let language: CfPLanguage

  init(proposal: ProposalDTO, language: CfPLanguage = .en) {
    self.proposal = proposal
    self.language = language
  }

  var body: some HTML {
    a(
      .href(language.path(for: "/my-proposals/\(proposal.id.uuidString)")),
      .class("text-decoration-none")
    ) {
      div(.class("card mb-3 proposal-card")) {
        div(.class("card-body")) {
          div(.class("d-flex justify-content-between align-items-start")) {
            div {
              h5(.class("card-title mb-1 text-dark")) { HTMLText(proposal.title) }
              span(
                .class(
                  {
                    switch proposal.talkDuration {
                    case .regular: return "badge bg-primary"
                    case .workshop: return "badge bg-success"
                    case .invited: return "badge bg-dark"
                    case .lightning: return "badge bg-warning text-dark"
                    }
                  }())
              ) {
                HTMLText(
                  language == .ja
                    ? ({
                      switch proposal.talkDuration {
                      case .regular: return "レギュラートーク"
                      case .workshop: return "ワークショップ"
                      case .lightning: return "ライトニングトーク"
                      case .invited: return "招待トーク"
                      }
                    }())
                    : proposal.talkDuration.displayName)
              }
            }
            if let createdAt = proposal.createdAt {
              small(.class("text-muted")) {
                HTMLRaw(
                  "<time class=\"local-time\" datetime=\"\(formatISO(createdAt))\" data-style=\"date\"></time>"
                )
              }
            }
          }
          p(.class("card-text text-muted mt-2 mb-0")) {
            HTMLText(proposal.abstract)
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
