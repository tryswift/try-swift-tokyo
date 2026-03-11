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
              HTMLRaw(
                """
                <form method="post" action="/organizer/workshops/lottery" class="d-inline">
                  <input type="hidden" name="_csrf" value="\(csrfToken)">
                  <button type="submit" class="btn btn-warning">🎲 Run Lottery</button>
                </form>
                <form method="post" action="/organizer/workshops/send-tickets" class="d-inline">
                  <input type="hidden" name="_csrf" value="\(csrfToken)">
                  <button type="submit" class="btn btn-success">📧 Send Luma Tickets</button>
                </form>
                """)
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

      if let lumaID = ws.lumaEventID {
        html +=
          "<td><span class=\"badge bg-success\">\(escapeHTML(lumaID))</span></td>"
        html += "<td></td>"
      } else {
        html += "<td><span class=\"text-muted\">Not created</span></td>"
        html += """
          <td>
            <form method="post" action="/organizer/workshops/\(ws.registrationID.uuidString)/create-luma-event" class="d-inline">
              <input type="hidden" name="_csrf" value="\(csrfToken)">
              <button type="submit" class="btn btn-sm btn-outline-success">Create Luma Event</button>
            </form>
          </td>
          """
      }
      html += "</tr>"
    }

    html += "</tbody></table></div>"
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
