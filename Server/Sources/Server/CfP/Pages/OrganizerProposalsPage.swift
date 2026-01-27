import Elementary
import Foundation
import SharedModels

struct OrganizerProposalsPageView: HTML, Sendable {
  let user: UserDTO?
  let proposals: [ProposalDTO]
  let conferencePath: String?

  var body: some HTML {
    div(.class("container py-5")) {
      // Header
      div(.class("d-flex justify-content-between align-items-center mb-4")) {
        div {
          h1(.class("fw-bold mb-2")) { "All Proposals" }
          p(.class("lead text-muted mb-0")) {
            "Review all submitted CfP proposals."
          }
        }
        // Export button
        a(
          .class("btn btn-success"),
          .href(
            "/cfp/organizer/proposals/export\(conferencePath.map { "?conference=\($0)" } ?? "")")
        ) {
          "Export CSV"
        }
      }

      if let user, user.role == .admin {
        // Stats card
        div(.class("row mb-4")) {
          div(.class("col-md-4")) {
            div(.class("card bg-primary text-white")) {
              div(.class("card-body")) {
                h3(.class("card-title mb-0")) { HTMLText("\(proposals.count)") }
                p(.class("card-text mb-0")) { "Total Proposals" }
              }
            }
          }
          div(.class("col-md-4")) {
            let regularCount = proposals.filter { $0.talkDuration == .regular }.count
            div(.class("card bg-info text-white")) {
              div(.class("card-body")) {
                h3(.class("card-title mb-0")) { HTMLText("\(regularCount)") }
                p(.class("card-text mb-0")) { "Regular Talks (20min)" }
              }
            }
          }
          div(.class("col-md-4")) {
            let ltCount = proposals.filter { $0.talkDuration == .lightning }.count
            div(.class("card bg-warning text-dark")) {
              div(.class("card-body")) {
                h3(.class("card-title mb-0")) { HTMLText("\(ltCount)") }
                p(.class("card-text mb-0")) { "Lightning Talks" }
              }
            }
          }
        }

        // Google Sheets integration tip
        div(.class("alert alert-info mb-4")) {
          strong { "Google Sheets Integration: " }
          "You can import the CSV directly into Google Sheets using "
          code { "File > Import" }
          " or link it with "
          code { "=IMPORTDATA(\"url\")" }
          " function."
        }

        // Proposals table
        if proposals.isEmpty {
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("text-muted mb-0")) { "No proposals submitted yet." }
            }
          }
        } else {
          div(.class("card")) {
            div(.class("table-responsive")) {
              table(.class("table table-hover mb-0")) {
                thead(.class("table-light")) {
                  tr {
                    th(.style("width: 5%")) { "#" }
                    th(.style("width: 25%")) { "Title" }
                    th(.style("width: 15%")) { "Speaker" }
                    th(.style("width: 10%")) { "Duration" }
                    th(.style("width: 15%")) { "Conference" }
                    th(.style("width: 15%")) { "Submitted" }
                    th(.style("width: 15%")) { "Actions" }
                  }
                }
                tbody {
                  for (index, proposal) in proposals.enumerated() {
                    OrganizerProposalRow(proposal: proposal, index: index + 1)
                  }
                }
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
            a(.class("btn btn-primary"), .href("/cfp/")) { "Return to Home" }
          }
        }
      }
    }
  }
}

struct OrganizerProposalRow: HTML, Sendable {
  let proposal: ProposalDTO
  let index: Int

  var body: some HTML {
    tr {
      td(.class("align-middle")) { HTMLText("\(index)") }
      td(.class("align-middle")) {
        a(
          .href("/cfp/organizer/proposals/\(proposal.id)"),
          .class("text-decoration-none fw-semibold")
        ) {
          HTMLText(proposal.title)
        }
      }
      td(.class("align-middle")) {
        div(.class("d-flex align-items-center")) {
          if let iconURL = proposal.iconURL {
            img(
              .src(iconURL),
              .alt(proposal.speakerUsername),
              .class("rounded-circle me-2"),
              .style("width: 24px; height: 24px;")
            )
          }
          HTMLText(proposal.speakerUsername)
        }
      }
      td(.class("align-middle")) {
        span(
          .class(
            proposal.talkDuration == .regular
              ? "badge bg-primary" : "badge bg-warning text-dark"
          )
        ) {
          HTMLText(proposal.talkDuration.rawValue)
        }
      }
      td(.class("align-middle")) {
        small(.class("text-muted")) {
          HTMLText(proposal.conferenceDisplayName)
        }
      }
      td(.class("align-middle")) {
        if let createdAt = proposal.createdAt {
          small(.class("text-muted")) {
            HTMLText(formatDate(createdAt))
          }
        }
      }
      td(.class("align-middle")) {
        a(
          .href("/cfp/organizer/proposals/\(proposal.id)"),
          .class("btn btn-sm btn-outline-primary")
        ) {
          "View"
        }
      }
    }
  }

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
