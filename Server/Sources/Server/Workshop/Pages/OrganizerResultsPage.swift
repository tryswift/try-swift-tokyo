import Elementary

/// Winner entry for results display
struct LotteryWinner: Sendable {
  let name: String
  let email: String
}

/// Organizer page showing lottery results
struct OrganizerResultsPageView: HTML, Sendable {
  let results: [WorkshopResult]
  let lotteryRun: Bool

  struct WorkshopResult: Sendable {
    let workshopTitle: String
    let capacity: Int
    let winners: [LotteryWinner]
    let lumaEventID: String?
    let ticketsSent: Bool
  }

  var body: some HTML {
    div(.class("container py-5")) {
      // Header
      div(.class("d-flex justify-content-between align-items-center mb-4")) {
        div {
          h1(.class("fw-bold mb-2")) { "Lottery Results" }
          p(.class("lead text-muted mb-0")) {
            "Workshop assignment results."
          }
        }
        a(.class("btn btn-outline-secondary"), .href("/organizer/workshops")) {
          "← Back to Workshops"
        }
      }

      if !lotteryRun {
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🎲" }
            h3(.class("fw-bold")) { "Lottery Not Yet Run" }
            p(.class("text-muted")) { "Go to Workshop Management to run the lottery." }
          }
        }
      } else {
        // Results and summary
        HTMLRaw(resultsHTML())
        summaryCard
      }
    }
  }

  private func resultsHTML() -> String {
    var html = ""
    for result in results {
      html += "<div class=\"card mb-4\">"
      html += "<div class=\"card-header d-flex justify-content-between align-items-center\">"
      html += "<h5 class=\"mb-0 fw-bold\">\(escapeHTML(result.workshopTitle))</h5>"
      html += "<div class=\"d-flex gap-2\">"
      html +=
        "<span class=\"badge bg-secondary\">\(result.winners.count)/\(result.capacity)</span>"
      if result.lumaEventID != nil {
        if result.ticketsSent {
          html += "<span class=\"badge bg-success\">Tickets Sent</span>"
        } else {
          html += "<span class=\"badge bg-warning text-dark\">Luma Event Created</span>"
        }
      }
      html += "</div></div>"

      html += "<div class=\"card-body\">"
      if result.winners.isEmpty {
        html += "<p class=\"text-muted\">No winners assigned.</p>"
      } else {
        html += "<div class=\"table-responsive\">"
        html += "<table class=\"table table-sm mb-0\">"
        html += "<thead><tr><th>#</th><th>Name</th><th>Email</th></tr></thead><tbody>"
        for (index, winner) in result.winners.enumerated() {
          html += "<tr>"
          html += "<td>\(index + 1)</td>"
          html += "<td>\(escapeHTML(winner.name))</td>"
          html += "<td>\(escapeHTML(winner.email))</td>"
          html += "</tr>"
        }
        html += "</tbody></table></div>"
        // mailto: link for winners
        let emails = result.winners.map { $0.email }.joined(separator: ",")
        let subjectText =
          "try! Swift Tokyo 2026 Workshop: \(escapeHTML(result.workshopTitle))"
        let bccEncoded =
          emails.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subjectEncoded =
          subjectText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        html += "<div class=\"mt-3\">"
        html +=
          "<a href=\"mailto:?bcc=\(bccEncoded)&amp;subject=\(subjectEncoded)\" class=\"btn btn-outline-primary btn-sm\">"
        html += "&#9993; Email All Winners (\(result.winners.count))"
        html += "</a></div>"
      }
      html += "</div></div>"
    }
    return html
  }

  private var summaryCard: some HTML {
    div(.class("card")) {
      div(.class("card-body")) {
        h5(.class("fw-bold mb-3")) { "Summary" }
        div(.class("row")) {
          div(.class("col-md-4")) {
            div(.class("text-center")) {
              p(.class("fs-3 fw-bold mb-0")) { HTMLText("\(results.count)") }
              p(.class("text-muted")) { "Workshops" }
            }
          }
          div(.class("col-md-4")) {
            div(.class("text-center")) {
              p(.class("fs-3 fw-bold mb-0 text-success")) {
                HTMLText("\(results.reduce(0) { $0 + $1.winners.count })")
              }
              p(.class("text-muted")) { "Assigned" }
            }
          }
          div(.class("col-md-4")) {
            div(.class("text-center")) {
              p(.class("fs-3 fw-bold mb-0")) {
                HTMLText("\(results.reduce(0) { $0 + $1.capacity })")
              }
              p(.class("text-muted")) { "Total Capacity" }
            }
          }
        }
      }
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
