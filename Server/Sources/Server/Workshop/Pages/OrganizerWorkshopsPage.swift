import Elementary
import Foundation
import SharedModels

/// Organizer page for managing workshops (capacity settings, overview)
struct OrganizerWorkshopsPageView: HTML, Sendable {
  let user: UserDTO?
  let workshops: [WorkshopInfo]
  let csrfToken: String
  let successMessage: String?

  struct WorkshopInfo: Sendable {
    let registrationID: UUID
    let proposalTitle: String
    let speakerName: String
    let capacity: Int
    let applicationCount: Int
    let lumaEventID: String?
    let winnerEmails: [String]
  }

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("d-flex justify-content-between align-items-center mb-4")) {
        div {
          h1(.class("fw-bold mb-2")) { "Workshop Management" }
          p(.class("lead text-muted mb-0")) {
            "Manage workshop capacity and lottery."
          }
        }
        div(.class("d-flex gap-2")) {
          a(.class("btn btn-outline-primary"), .href("/organizer/workshops/applications")) {
            "View Applications"
          }
          a(.class("btn btn-outline-success"), .href("/organizer/workshops/results")) {
            "View Results"
          }
        }
      }

      if let user, user.role == .admin {
        if let successMessage {
          div(.class("alert alert-success mb-4")) {
            HTMLText(successMessage)
          }
        }

        // Workshops table
        div(.class("card mb-4")) {
          div(.class("card-body")) {
            HTMLRaw(workshopsTableHTML())
          }
        }

        // Lottery actions
        div(.class("card")) {
          div(.class("card-body")) {
            h5(.class("fw-bold mb-3")) { "Lottery Actions" }
            div(.class("d-flex gap-2")) {
              HTMLRaw(lotteryActionsHTML())
            }
          }
        }
      } else {
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🔒" }
            h3(.class("fw-bold")) { "Access Denied" }
            p(.class("text-muted")) { "Only organizers can access this page." }
          }
        }
      }
    }
  }

  private func workshopsTableHTML() -> String {
    var html = "<div class=\"table-responsive\"><table class=\"table table-hover\">"
    html += "<thead><tr>"
    html += "<th>Workshop</th><th>Speaker</th><th>Capacity</th>"
    html += "<th>Applications</th><th>Luma Event</th><th>Actions</th>"
    html += "</tr></thead><tbody>"

    for ws in workshops {
      html += "<tr>"
      html += "<td>\(escapeHTML(ws.proposalTitle))</td>"
      html += "<td>\(escapeHTML(ws.speakerName))</td>"
      html += """
        <td>
          <form method="post" action="/organizer/workshops/\(ws.registrationID.uuidString)/capacity" class="d-flex gap-1 align-items-center">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <input type="number" name="capacity" value="\(ws.capacity)" class="form-control form-control-sm" style="width: 80px;" min="1">
            <button type="submit" class="btn btn-sm btn-outline-primary">Set</button>
          </form>
        </td>
        """
      let badgeClass = ws.applicationCount > ws.capacity ? "badge bg-danger" : "badge bg-secondary"
      html += "<td><span class=\"\(badgeClass)\">\(ws.applicationCount)</span></td>"

      html += """
        <td colspan="2">
          <form method="post" action="/organizer/workshops/\(ws.registrationID.uuidString)/luma-event" class="d-flex gap-1 align-items-center">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <input type="text" name="luma_event_id" value="\(escapeHTML(ws.lumaEventID ?? ""))" class="form-control form-control-sm" style="min-width: 160px;" placeholder="Luma Event ID" aria-label="Luma Event ID">
            <button type="submit" class="btn btn-sm btn-outline-primary">Save</button>
        """
      if ws.lumaEventID == nil {
        html += """
          </form>
          <form method="post" action="/organizer/workshops/\(ws.registrationID.uuidString)/create-luma-event" class="d-inline">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <button type="submit" class="btn btn-sm btn-outline-success">Create</button>
          </form>
          """
      } else {
        html += "</form>"
      }
      html += "</td>"
      html += "</tr>"
    }

    html += "</tbody></table></div>"
    return html
  }

  private func lotteryActionsHTML() -> String {
    var html = ""
    html += """
      <form method="post" action="/organizer/workshops/lottery" class="d-inline">
        <input type="hidden" name="_csrf" value="\(csrfToken)">
        <button type="submit" class="btn btn-warning">🎲 Run Lottery</button>
      </form>
      <form method="post" action="/organizer/workshops/send-tickets" class="d-inline">
        <input type="hidden" name="_csrf" value="\(csrfToken)">
        <button type="submit" class="btn btn-success">📧 Send Luma Tickets</button>
      </form>
      """

    let allWinnerEmails = Array(Set(workshops.flatMap(\.winnerEmails)))
    if !allWinnerEmails.isEmpty {
      var components = URLComponents()
      components.scheme = "mailto"
      components.queryItems = [
        URLQueryItem(name: "bcc", value: allWinnerEmails.joined(separator: ",")),
        URLQueryItem(name: "subject", value: "try! Swift Tokyo 2026 Workshop"),
      ]
      let mailtoURL = components.url?.absoluteString ?? "mailto:"
      html +=
        " <a href=\"\(escapeHTML(mailtoURL))\" class=\"btn btn-info\">&#9993; Email All Winners (\(allWinnerEmails.count))</a>"
    }

    return html
  }

  private func escapeHTML(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
