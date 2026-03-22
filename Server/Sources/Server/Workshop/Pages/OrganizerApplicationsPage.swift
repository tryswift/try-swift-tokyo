import Elementary
import Foundation

/// Workshop filter option for the applications page
struct WorkshopFilterOption: Sendable {
  let id: UUID
  let title: String
}

/// Organizer page showing all workshop applications
struct OrganizerApplicationsPageView: HTML, Sendable {
  let applications: [ApplicationRow]
  let workshopFilter: String?
  let workshops: [WorkshopFilterOption]

  struct ApplicationRow: Sendable {
    let id: UUID
    let email: String
    let applicantName: String
    let firstChoice: String
    let secondChoice: String?
    let thirdChoice: String?
    let status: WorkshopApplicationStatus
    let assignedWorkshop: String?
    let createdAt: String
  }

  var body: some HTML {
    div(.class("container py-5")) {
      // Header
      div(.class("d-flex justify-content-between align-items-center mb-4")) {
        div {
          h1(.class("fw-bold mb-2")) { "Workshop Applications" }
          p(.class("lead text-muted mb-0")) {
            HTMLText("Total: \(applications.count) applications")
          }
        }
        a(.class("btn btn-outline-secondary"), .href("/organizer/workshops")) {
          "← Back to Workshops"
        }
      }

      // Filter
      div(.class("card mb-4")) {
        div(.class("card-body")) {
          HTMLRaw(filterFormHTML())
        }
      }

      // Table
      div(.class("card")) {
        div(.class("card-body")) {
          HTMLRaw(applicationsTableHTML())
        }
      }
    }
  }

  private func filterFormHTML() -> String {
    var html = "<form method=\"get\" class=\"d-flex gap-2 align-items-end\">"
    html += "<div>"
    html += "<label class=\"form-label small\" for=\"workshop\">Filter by Workshop</label>"
    html += "<select class=\"form-select\" id=\"workshop\" name=\"workshop\">"
    html += "<option value=\"\">All Workshops</option>"
    for ws in workshops {
      let selected = workshopFilter == ws.id.uuidString ? " selected" : ""
      html += "<option value=\"\(ws.id.uuidString)\"\(selected)>\(escapeHTML(ws.title))</option>"
    }
    html += "</select></div>"
    html += "<button type=\"submit\" class=\"btn btn-primary\">Filter</button>"
    html += "</form>"
    return html
  }

  private func applicationsTableHTML() -> String {
    var html = "<div class=\"table-responsive\">"
    html += "<table class=\"table table-hover table-sm\">"
    html += "<thead><tr>"
    html += "<th>Name</th><th>Email</th><th>1st Choice</th><th>2nd Choice</th>"
    html += "<th>3rd Choice</th><th>Status</th><th>Assigned</th><th>Date</th>"
    html += "</tr></thead><tbody>"

    for app in applications {
      html += "<tr>"
      html += "<td>\(escapeHTML(app.applicantName))</td>"
      html += "<td>\(escapeHTML(app.email))</td>"
      html += "<td>\(escapeHTML(app.firstChoice))</td>"
      html += "<td>\(escapeHTML(app.secondChoice ?? "-"))</td>"
      html += "<td>\(escapeHTML(app.thirdChoice ?? "-"))</td>"
      html += "<td>\(statusBadgeHTML(app.status))</td>"
      html += "<td>\(escapeHTML(app.assignedWorkshop ?? "-"))</td>"
      html += "<td class=\"text-muted small\">\(escapeHTML(app.createdAt))</td>"
      html += "</tr>"
    }

    html += "</tbody></table></div>"
    return html
  }

  private func statusBadgeHTML(_ status: WorkshopApplicationStatus) -> String {
    switch status {
    case .pending:
      return "<span class=\"badge bg-warning text-dark\">Pending</span>"
    case .won:
      return "<span class=\"badge bg-success\">Won</span>"
    case .lost:
      return "<span class=\"badge bg-danger\">Lost</span>"
    }
  }

  private func escapeHTML(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
