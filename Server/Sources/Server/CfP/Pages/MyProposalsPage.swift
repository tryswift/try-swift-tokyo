import Elementary
import Foundation
import SharedModels

struct MyProposalsPageView: HTML, Sendable {
  let user: UserDTO?
  let proposals: [ProposalDTO]
  let language: CfPLanguage

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-2")) { CfPStrings.MyProposals.title(language) }
      p(.class("lead text-muted mb-4")) {
        CfPStrings.MyProposals.subtitle(language)
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
                        ? CfPStrings.MyProposals.organizer(language)
                        : CfPStrings.MyProposals.speaker(language))
                  }
                }
              }
              a(
                .class("btn btn-outline-danger btn-sm"),
                .href("/cfp/\(language.urlPrefix)/logout")
              ) {
                CfPStrings.MyProposals.logout(language)
              }
            }
          }
        }

        // Proposals section
        h3(.class("fw-bold mb-3")) { CfPStrings.MyProposals.yourSubmissions(language) }

        if proposals.isEmpty {
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("text-muted mb-3")) { CfPStrings.MyProposals.noProposalsYet(language) }
              p(.class("text-muted small mb-4")) {
                CfPStrings.MyProposals.submitFirstProposal(language)
              }
              a(.class("btn btn-primary"), .href("/cfp/\(language.urlPrefix)/submit")) {
                CfPStrings.MyProposals.submitAProposal(language)
              }
            }
          }
        } else {
          for proposal in proposals {
            ProposalCard(proposal: proposal)
          }

          div(.class("text-center mt-4")) {
            a(.class("btn btn-primary"), .href("/cfp/\(language.urlPrefix)/submit")) {
              CfPStrings.MyProposals.submitAnotherProposal(language)
            }
          }
        }
      } else {
        // Not logged in - redirect via meta refresh or show login prompt
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🔐" }
            h3(.class("fw-bold mb-2")) { CfPStrings.MyProposals.signInRequired(language) }
            p(.class("text-muted mb-4")) {
              CfPStrings.MyProposals.signInDescription(language)
            }
            a(
              .class("btn btn-dark"),
              .href("/api/v1/auth/github?returnTo=/cfp/\(language.urlPrefix)/my-proposals")
            ) {
              CfPStrings.Submit.signInWithGitHub(language)
            }
          }
        }
      }
    }
  }
}

struct ProposalCard: HTML, Sendable {
  let proposal: ProposalDTO

  var body: some HTML {
    div(.class("card mb-3")) {
      div(.class("card-body")) {
        div(.class("d-flex justify-content-between align-items-start")) {
          div {
            h5(.class("card-title mb-1")) { HTMLText(proposal.title) }
            span(
              .class(
                proposal.talkDuration == .regular
                  ? "badge bg-primary" : "badge bg-warning text-dark"
              )
            ) {
              HTMLText(proposal.talkDuration.rawValue)
            }
          }
          if let createdAt = proposal.createdAt {
            small(.class("text-muted")) {
              HTMLText(formatDate(createdAt))
            }
          }
        }
        p(.class("card-text text-muted mt-2 mb-0")) {
          HTMLText(proposal.abstract)
        }
      }
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}
