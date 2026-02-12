import Elementary
import Foundation
import SharedModels

struct OrganizerEmailPreviewPageView: HTML, Sendable {
  let user: UserDTO?
  let proposal: ProposalDTO?
  let emailType: EmailType
  let language: CfPLanguage
  let previewSubject: String
  let previewBody: String
  let sendResult: EmailNotifier.SendResult?
  let csrfToken: String

  var body: some HTML {
    div(.class("container py-5")) {
      if let user, user.role == .admin {
        if let proposal {
          renderHeader(proposal)
          renderLanguageSelector(proposal)

          if let sendResult {
            renderResult(sendResult)
          }

          renderPreview()
          renderSendForm(proposal)
        } else {
          renderNotFound()
        }
      } else {
        renderAccessDenied()
      }
    }
  }

  // MARK: - Header

  @HTMLBuilder
  private func renderHeader(_ proposal: ProposalDTO) -> some HTML {
    div(.class("mb-4")) {
      a(
        .class("btn btn-outline-secondary"),
        .href("/organizer/proposals/\(proposal.id.uuidString)")
      ) {
        "← Back to Proposal"
      }
    }

    div(.class("mb-4")) {
      h1(.class("fw-bold mb-2")) { "Send Email" }
      p(.class("lead text-muted mb-0")) {
        HTMLText("To: \(proposal.speakerName) (\(proposal.speakerEmail))")
      }
    }
  }

  // MARK: - Language Selector

  @HTMLBuilder
  private func renderLanguageSelector(_ proposal: ProposalDTO) -> some HTML {
    div(.class("card mb-4")) {
      div(.class("card-body")) {
        form(.method(.get), .action("/organizer/proposals/\(proposal.id.uuidString)/email")) {
          input(.type(.hidden), .name("type"), .value(emailType.rawValue))
          div(.class("row g-3 align-items-end")) {
            div(.class("col-md-5")) {
              label(.class("form-label fw-semibold"), .for("emailLang")) { "Language" }
              select(.class("form-select"), .name("lang"), .id("emailLang")) {
                option(.value("en"), language == .en ? .selected : .class("")) { "English" }
                option(.value("ja"), language == .ja ? .selected : .class("")) { "日本語" }
              }
            }
            div(.class("col-md-5")) {
              label(.class("form-label fw-semibold"), .for("emailType")) { "Email Type" }
              select(.class("form-select"), .name("type"), .id("emailType")) {
                option(
                  .value("acceptance"),
                  emailType == .acceptance ? .selected : .class("")
                ) { "Acceptance" }
                option(
                  .value("rejection"),
                  emailType == .rejection ? .selected : .class("")
                ) { "Rejection" }
              }
            }
            div(.class("col-md-2")) {
              button(.type(.submit), .class("btn btn-primary w-100")) {
                "Preview"
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

  // MARK: - Send Form

  @HTMLBuilder
  private func renderSendForm(_ proposal: ProposalDTO) -> some HTML {
    div(.class("d-flex gap-2")) {
      HTMLRaw(
        """
        <form method="post" \
        action="/organizer/proposals/\(proposal.id.uuidString)/email/send" \
        onsubmit="return confirm('Send this email to \(proposal.speakerEmail)?');">
          <input type="hidden" name="_csrf" value="\(csrfToken)">
          <input type="hidden" name="emailType" value="\(emailType.rawValue)">
          <input type="hidden" name="lang" value="\(language.rawValue)">
          <button type="submit" class="btn btn-success btn-lg">Send Email</button>
        </form>
        """)
      a(
        .class("btn btn-outline-secondary btn-lg"),
        .href("/organizer/proposals/\(proposal.id.uuidString)")
      ) {
        "Cancel"
      }
    }
  }

  // MARK: - Result

  @HTMLBuilder
  private func renderResult(_ result: EmailNotifier.SendResult) -> some HTML {
    if result.success {
      div(.class("alert alert-success alert-dismissible fade show mb-4")) {
        strong { "Email sent successfully " }
        HTMLText("to \(result.recipientEmail)")
        HTMLRaw(
          """
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          """)
      }
    } else {
      div(.class("alert alert-danger alert-dismissible fade show mb-4")) {
        strong { "Failed to send email: " }
        HTMLText(result.error ?? "Unknown error")
        HTMLRaw(
          """
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          """)
      }
    }
  }

  // MARK: - Not Found

  @HTMLBuilder
  private func renderNotFound() -> some HTML {
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
