import Elementary
import Foundation
import SharedModels

struct OrganizerEmailsPageView: HTML, Sendable {
  let user: UserDTO?
  let proposals: [ProposalDTO]
  let statusFilter: String
  let language: CfPLanguage
  let emailType: EmailType
  let previewSubject: String
  let previewBody: String
  let sendResults: [EmailNotifier.SendResult]?
  let csrfToken: String

  var body: some HTML {
    div(.class("container py-5")) {
      if let user, user.role == .admin {
        renderHeader()
        renderFilterForm()
        renderPreview()
        renderRecipientList()

        if let sendResults {
          renderResults(sendResults)
        }
      } else {
        renderAccessDenied()
      }
    }
  }

  // MARK: - Header

  @HTMLBuilder
  private func renderHeader() -> some HTML {
    div(.class("mb-4")) {
      a(.class("btn btn-outline-secondary"), .href("/organizer/proposals")) {
        "← Back to All Proposals"
      }
    }

    div(.class("mb-4")) {
      h1(.class("fw-bold mb-2")) { "Email Notifications" }
      p(.class("lead text-muted mb-0")) {
        "Send acceptance or rejection emails to speakers."
      }
    }
  }

  // MARK: - Filter Form

  @HTMLBuilder
  private func renderFilterForm() -> some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { "Filter & Template" }
      }
      div(.class("card-body")) {
        form(.method(.get), .action("/organizer/emails")) {
          div(.class("row g-3 align-items-end")) {
            div(.class("col-md-4")) {
              label(.class("form-label fw-semibold"), .for("statusFilter")) { "Status" }
              select(.class("form-select"), .name("status"), .id("statusFilter")) {
                option(
                  .value("accepted"),
                  statusFilter == "accepted" ? .selected : .class("")
                ) { "Accepted" }
                option(
                  .value("rejected"),
                  statusFilter == "rejected" ? .selected : .class("")
                ) { "Rejected" }
              }
            }
            div(.class("col-md-4")) {
              label(.class("form-label fw-semibold"), .for("langFilter")) { "Language" }
              select(.class("form-select"), .name("lang"), .id("langFilter")) {
                option(
                  .value("en"),
                  language == .en ? .selected : .class("")
                ) { "English" }
                option(
                  .value("ja"),
                  language == .ja ? .selected : .class("")
                ) { "日本語" }
              }
            }
            div(.class("col-md-4")) {
              button(.type(.submit), .class("btn btn-primary w-100")) {
                "Update Preview"
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Preview

  @HTMLBuilder
  private func renderPreview() -> some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { "Email Preview" }
      }
      div(.class("card-body")) {
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) { "Subject:" }
          div(.class("form-control-plaintext border rounded px-3 py-2 bg-light")) {
            HTMLText(previewSubject)
          }
        }
        div {
          label(.class("form-label fw-semibold")) { "Body:" }
          div(
            .class("border rounded p-3 bg-light"),
            .style("max-height: 400px; overflow-y: auto;")
          ) {
            HTMLRaw(previewBody)
          }
        }
      }
    }
  }

  // MARK: - Recipient List

  @HTMLBuilder
  private func renderRecipientList() -> some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header d-flex justify-content-between align-items-center")) {
        strong {
          "Recipients (\(proposals.count))"
        }
        if !proposals.isEmpty {
          HTMLRaw(
            """
            <form method="post" action="/organizer/emails/send" \
            onsubmit="return confirm('Are you sure you want to send \(proposals.count) email(s)?');">
              <input type="hidden" name="_csrf" value="\(csrfToken)">
              <input type="hidden" name="status" value="\(statusFilter)">
              <input type="hidden" name="lang" value="\(language.rawValue)">
              <input type="hidden" name="emailType" value="\(emailType.rawValue)">
              <button type="submit" class="btn btn-success">
                Send to All \(proposals.count) Recipients
              </button>
            </form>
            """)
        }
      }

      if proposals.isEmpty {
        div(.class("card-body text-center p-4")) {
          p(.class("text-muted mb-0")) {
            "No proposals with this status."
          }
        }
      } else {
        div(.class("table-responsive")) {
          table(.class("table table-hover mb-0")) {
            thead(.class("table-light")) {
              tr {
                th(.style("width: 5%")) { "#" }
                th(.style("width: 25%")) { "Speaker Name" }
                th(.style("width: 30%")) { "Email" }
                th(.style("width: 40%")) { "Proposal Title" }
              }
            }
            tbody {
              for (index, proposal) in proposals.enumerated() {
                tr {
                  td(.class("align-middle")) { HTMLText("\(index + 1)") }
                  td(.class("align-middle")) { HTMLText(proposal.speakerName) }
                  td(.class("align-middle")) {
                    HTMLText(proposal.speakerEmail)
                  }
                  td(.class("align-middle")) { HTMLText(proposal.title) }
                }
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Results

  @HTMLBuilder
  private func renderResults(_ results: [EmailNotifier.SendResult]) -> some HTML {
    let successCount = results.filter(\.success).count
    let failedCount = results.count - successCount

    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { "Send Results" }
      }
      div(.class("card-body")) {
        div(.class("row mb-3")) {
          div(.class("col-md-4")) {
            div(.class("card bg-success text-white")) {
              div(.class("card-body")) {
                h4(.class("mb-0")) { HTMLText("\(successCount)") }
                p(.class("mb-0")) { "Sent" }
              }
            }
          }
          div(.class("col-md-4")) {
            div(.class("card bg-danger text-white")) {
              div(.class("card-body")) {
                h4(.class("mb-0")) { HTMLText("\(failedCount)") }
                p(.class("mb-0")) { "Failed" }
              }
            }
          }
          div(.class("col-md-4")) {
            div(.class("card bg-primary text-white")) {
              div(.class("card-body")) {
                h4(.class("mb-0")) { HTMLText("\(results.count)") }
                p(.class("mb-0")) { "Total" }
              }
            }
          }
        }

        if failedCount > 0 {
          div(.class("table-responsive")) {
            table(.class("table table-sm")) {
              thead(.class("table-light")) {
                tr {
                  th { "Email" }
                  th { "Status" }
                  th { "Error" }
                }
              }
              tbody {
                for result in results where !result.success {
                  tr {
                    td { HTMLText(result.recipientEmail) }
                    td {
                      span(.class("badge bg-danger")) { "Failed" }
                    }
                    td { HTMLText(result.error ?? "Unknown error") }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Access Denied

  @HTMLBuilder
  private func renderAccessDenied() -> some HTML {
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
