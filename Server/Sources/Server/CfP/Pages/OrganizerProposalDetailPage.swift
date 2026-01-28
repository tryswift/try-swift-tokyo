import Elementary
import Foundation
import SharedModels

struct OrganizerProposalDetailPageView: HTML, Sendable {
  let user: UserDTO?
  let proposal: ProposalDTO?

  var body: some HTML {
    div(.class("container py-5")) {
      if let user, user.role == .admin {
        if let proposal {
          // Back button
          div(.class("mb-4")) {
            a(.class("btn btn-outline-secondary"), .href("/organizer/proposals")) {
              "← Back to All Proposals"
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
                  HTMLText(proposal.talkDuration.displayName)
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
              strong { "Speaker Information" }
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
                    "View GitHub Profile"
                  }
                }
              }
              h6(.class("fw-bold mb-2")) { "Bio" }
              p(.class("mb-0")) { HTMLText(proposal.bio) }
            }
          }

          // Abstract card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { "Abstract" }
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
              strong { "Talk Details (for reviewers)" }
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
                strong { "Notes to Organizers" }
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
              strong { "Metadata" }
            }
            div(.class("card-body")) {
              dl(.class("row mb-0")) {
                dt(.class("col-sm-3")) { "Proposal ID" }
                dd(.class("col-sm-9")) {
                  code { HTMLText(proposal.id.uuidString) }
                }
                dt(.class("col-sm-3")) { "Submitted" }
                dd(.class("col-sm-9")) {
                  if let createdAt = proposal.createdAt {
                    HTMLText(formatDate(createdAt))
                  } else {
                    "Unknown"
                  }
                }
                dt(.class("col-sm-3")) { "Last Updated" }
                dd(.class("col-sm-9")) {
                  if let updatedAt = proposal.updatedAt {
                    HTMLText(formatDate(updatedAt))
                  } else {
                    "Never"
                  }
                }
              }
            }
          }
        } else {
          // Proposal not found
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              h3(.class("fw-bold mb-2")) { "Proposal Not Found" }
              p(.class("text-muted mb-4")) {
                "The proposal you are looking for does not exist."
              }
              a(.class("btn btn-primary"), .href("/organizer/proposals")) {
                "Back to All Proposals"
              }
            }
          }
        }
      } else {
        // Not authorized
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            h3(.class("fw-bold mb-2")) { "Access Denied" }
            p(.class("text-muted mb-4")) {
              "You need organizer permissions to view this page."
            }
            a(.class("btn btn-primary"), .href("/")) { "Return to Home" }
          }
        }
      }
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
