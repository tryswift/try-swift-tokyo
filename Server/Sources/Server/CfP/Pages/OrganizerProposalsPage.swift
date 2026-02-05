import Elementary
import Foundation
import SharedModels

struct OrganizerProposalsPageView: HTML, Sendable {
  let user: UserDTO?
  let proposals: [ProposalDTO]
  let conferencePath: String?
  let conferences: [ConferencePublicInfo]
  let csrfToken: String

  var body: some HTML {
    div(.class("container py-5")) {
      // Header
      renderHeader()

      if let user, user.role == .admin {
        // Inline add proposal form (collapsible)
        renderAddProposalForm()

        // Stats card
        renderStatsCards()

        // Google Sheets integration tip
        renderGoogleSheetsTip()

        // Proposals table
        renderProposalsTable()
      } else {
        // Not authorized
        renderAccessDenied()
      }

      // JavaScript for filtering
      renderFilterScript()
    }
  }

  @HTMLBuilder
  private func renderHeader() -> some HTML {
    div(.class("d-flex justify-content-between align-items-center mb-4")) {
      div {
        h1(.class("fw-bold mb-2")) { "All Proposals" }
        p(.class("lead text-muted mb-0")) {
          "Review all submitted CfP proposals."
        }
      }
      // Action buttons
      div(.class("d-flex gap-2")) {
        // Add Proposal button (toggles inline form)
        HTMLRaw(
          """
          <button class="btn btn-primary" type="button" data-bs-toggle="collapse" data-bs-target="#addProposalForm" aria-expanded="false" aria-controls="addProposalForm">
            + Add Proposal
          </button>
          """)
        // Import button
        a(
          .class("btn btn-outline-primary"),
          .href("/organizer/proposals/import")
        ) {
          "Import"
        }
        // Export button
        a(
          .class("btn btn-success"),
          .href(
            "/organizer/proposals/export\(conferencePath.map { "?conference=\($0)" } ?? "")")
        ) {
          "Export CSV"
        }
      }
    }
  }

  @HTMLBuilder
  private func renderStatsCards() -> some HTML {
    let acceptedCount = proposals.filter { $0.status == .accepted }.count
    let rejectedCount = proposals.filter { $0.status == .rejected }.count
    let submittedCount = proposals.filter { $0.status == .submitted }.count
    let regularCount = proposals.filter { $0.talkDuration == .regular }.count
    let ltCount = proposals.filter { $0.talkDuration == .lightning }.count

    // Status stats row
    div(.class("row mb-3")) {
      div(.class("col-md-3")) {
        div(
          .class("card bg-primary text-white proposal-filter-card"),
          .data("filter", value: "all"),
          .data("filter-type", value: "status"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(proposals.count)") }
            p(.class("card-text mb-0")) { "Total Proposals" }
          }
        }
      }
      div(.class("col-md-3")) {
        div(
          .class("card bg-secondary text-white proposal-filter-card"),
          .data("filter", value: "submitted"),
          .data("filter-type", value: "status"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(submittedCount)") }
            p(.class("card-text mb-0")) { "Submitted" }
          }
        }
      }
      div(.class("col-md-3")) {
        div(
          .class("card bg-success text-white proposal-filter-card"),
          .data("filter", value: "accepted"),
          .data("filter-type", value: "status"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(acceptedCount)") }
            p(.class("card-text mb-0")) { "Accepted" }
          }
        }
      }
      div(.class("col-md-3")) {
        div(
          .class("card bg-danger text-white proposal-filter-card"),
          .data("filter", value: "rejected"),
          .data("filter-type", value: "status"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(rejectedCount)") }
            p(.class("card-text mb-0")) { "Rejected" }
          }
        }
      }
    }

    // Duration stats row
    div(.class("row mb-4")) {
      div(.class("col-md-4")) {
        div(
          .class("card bg-info text-white proposal-filter-card"),
          .data("filter", value: "20min"),
          .data("filter-type", value: "duration"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(regularCount)") }
            p(.class("card-text mb-0")) { "Regular Talks (20min)" }
          }
        }
      }
      div(.class("col-md-4")) {
        let invitedCount = proposals.filter { $0.talkDuration == .invited }.count
        div(
          .class("card bg-dark text-white proposal-filter-card"),
          .data("filter", value: "invited"),
          .data("filter-type", value: "duration"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(invitedCount)") }
            p(.class("card-text mb-0")) { "Invited Talks" }
          }
        }
      }
      div(.class("col-md-4")) {
        div(
          .class("card bg-warning text-dark proposal-filter-card"),
          .data("filter", value: "LT"),
          .data("filter-type", value: "duration"),
          .style("cursor: pointer;"),
          .role("button")
        ) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) { HTMLText("\(ltCount)") }
            p(.class("card-text mb-0")) { "Lightning Talks" }
          }
        }
      }
    }
  }

  @HTMLBuilder
  private func renderGoogleSheetsTip() -> some HTML {
    div(.class("alert alert-info mb-4")) {
      strong { "Google Sheets Integration: " }
      "You can import the CSV directly into Google Sheets using "
      code { "File > Import" }
      " or link it with "
      code { "=IMPORTDATA(\"url\")" }
      " function."
    }
  }

  @HTMLBuilder
  private func renderProposalsTable() -> some HTML {
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
                th(.style("width: 4%")) { "#" }
                th(.style("width: 22%")) { "Title" }
                th(.style("width: 12%")) { "Speaker" }
                th(.style("width: 8%")) { "Duration" }
                th(.style("width: 8%")) { "Status" }
                th(.style("width: 12%")) { "Conference" }
                th(.style("width: 12%")) { "Submitted" }
                th(.style("width: 22%")) { "Actions" }
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
  }

  @HTMLBuilder
  private func renderAddProposalForm() -> some HTML {
    HTMLRaw(
      """
      <div class="collapse mb-4" id="addProposalForm">
        <div class="card">
          <div class="card-header d-flex justify-content-between align-items-center">
            <strong>Add New Proposal</strong>
            <button type="button" class="btn-close" data-bs-toggle="collapse" data-bs-target="#addProposalForm"></button>
          </div>
          <div class="card-body p-4">
            <form method="post" action="/organizer/proposals/new">
              <input type="hidden" name="_csrf" value="\(csrfToken)">
              <div class="row">
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineConferenceId">Conference *</label>
                    <select class="form-select" name="conferenceId" id="inlineConferenceId" required>
                      <option value="">Select conference...</option>
      """)
    for conf in conferences {
      option(.value(conf.id.uuidString)) {
        HTMLText(conf.displayName)
      }
    }
    HTMLRaw(
      """
                    </select>
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineTitle">Title *</label>
                    <input type="text" class="form-control" name="title" id="inlineTitle" required placeholder="Enter talk title">
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineAbstract">Abstract *</label>
                    <textarea class="form-control" name="abstract" id="inlineAbstract" rows="3" required placeholder="A brief summary of the talk"></textarea>
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineTalkDetails">Talk Details *</label>
                    <textarea class="form-control" name="talkDetails" id="inlineTalkDetails" rows="3" required placeholder="Detailed description for reviewers"></textarea>
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineTalkDuration">Talk Duration *</label>
                    <select class="form-select" name="talkDuration" id="inlineTalkDuration" required>
                      <option value="">Choose duration...</option>
                      <option value="20min">Regular Talk (20 min)</option>
                      <option value="LT">Lightning Talk (5 min)</option>
                      <option value="invited">Invited Talk</option>
                    </select>
                  </div>
                </div>
                <div class="col-md-6">
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineSpeakerName">Speaker Name *</label>
                    <input type="text" class="form-control" name="speakerName" id="inlineSpeakerName" required placeholder="Speaker display name">
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineSpeakerEmail">Speaker Email *</label>
                    <input type="email" class="form-control" name="speakerEmail" id="inlineSpeakerEmail" required placeholder="speaker@email.com">
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineBio">Speaker Bio *</label>
                    <textarea class="form-control" name="bio" id="inlineBio" rows="3" required placeholder="Speaker biography"></textarea>
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineIconUrl">Profile Picture URL</label>
                    <input type="url" class="form-control" name="iconUrl" id="inlineIconUrl" placeholder="https://example.com/photo.jpg">
                  </div>
                  <div class="mb-3">
                    <label class="form-label fw-semibold" for="inlineGithubUsername">GitHub Username</label>
                    <input type="text" class="form-control" name="githubUsername" id="inlineGithubUsername" placeholder="e.g. octocat">
                    <div class="form-text">If specified, the proposal will be linked to this GitHub user account. Leave blank to use the system import user.</div>
                  </div>
                </div>
              </div>
              <div class="mb-3">
                <label class="form-label fw-semibold" for="inlineNotes">Notes for Organizers</label>
                <textarea class="form-control" name="notesToOrganizers" id="inlineNotes" rows="2" placeholder="Any special requirements or additional information"></textarea>
              </div>
              <div class="d-grid">
                <button type="submit" class="btn btn-primary btn-lg">Add Proposal</button>
              </div>
            </form>
          </div>
        </div>
      </div>
      """)
  }

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

  @HTMLBuilder
  private func renderFilterScript() -> some HTML {
    script {
      HTMLRaw(
        """
        document.addEventListener('DOMContentLoaded', function() {
          const filterCards = document.querySelectorAll('.proposal-filter-card');
          const proposalRows = document.querySelectorAll('.proposal-row');
          let activeStatusFilter = 'all';
          let activeDurationFilter = null;

          function applyFilters() {
            proposalRows.forEach(row => {
              const status = row.getAttribute('data-status');
              const duration = row.getAttribute('data-duration');
              let show = true;
              if (activeStatusFilter !== 'all') {
                show = show && (status === activeStatusFilter);
              }
              if (activeDurationFilter) {
                show = show && (duration === activeDurationFilter);
              }
              row.style.display = show ? '' : 'none';
            });
          }

          filterCards.forEach(card => {
            card.addEventListener('click', function() {
              const filter = this.getAttribute('data-filter');
              const filterType = this.getAttribute('data-filter-type');

              if (filterType === 'status') {
                activeStatusFilter = filter;
                // Reset duration filter when clicking status
                activeDurationFilter = null;
                document.querySelectorAll('[data-filter-type="duration"]').forEach(c => {
                  c.style.opacity = '0.6';
                  c.style.transform = 'scale(0.98)';
                });
              } else if (filterType === 'duration') {
                // Toggle duration filter
                if (activeDurationFilter === filter) {
                  activeDurationFilter = null;
                } else {
                  activeDurationFilter = filter;
                }
              }

              // Update card styles for this filter type
              document.querySelectorAll('[data-filter-type="' + filterType + '"]').forEach(c => {
                c.style.opacity = '0.6';
                c.style.transform = 'scale(0.98)';
              });
              if (filterType === 'duration' && activeDurationFilter === null) {
                // All duration cards dimmed
              } else {
                this.style.opacity = '1';
                this.style.transform = 'scale(1.02)';
              }

              applyFilters();
            });
          });

          // Set initial active state
          const allFilterCard = document.querySelector('[data-filter="all"]');
          if (allFilterCard) {
            allFilterCard.style.transform = 'scale(1.02)';
            filterCards.forEach(c => {
              if (c !== allFilterCard) {
                c.style.opacity = '0.6';
                c.style.transform = 'scale(0.98)';
              }
            });
          }
        });
        """)
    }
  }
}

struct OrganizerProposalRow: HTML, Sendable {
  let proposal: ProposalDTO
  let index: Int

  var body: some HTML {
    tr(
      .class("proposal-row"),
      .data("duration", value: proposal.talkDuration.rawValue),
      .data("status", value: proposal.status.rawValue)
    ) {
      td(.class("align-middle")) { HTMLText("\(index)") }
      td(.class("align-middle")) {
        a(
          .href("/organizer/proposals/\(proposal.id)"),
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
        span(.class("badge \(proposal.status.badgeClass)")) {
          HTMLText(proposal.status.displayName)
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
            HTMLRaw(
              "<time class=\"local-time\" datetime=\"\(formatISO(createdAt))\" data-style=\"short\"></time>"
            )
          }
        }
      }
      td(.class("align-middle")) {
        div(.class("d-flex gap-1")) {
          a(
            .href("/organizer/proposals/\(proposal.id)"),
            .class("btn btn-sm btn-outline-primary")
          ) {
            "View"
          }
          if proposal.status == .submitted || proposal.status == .rejected {
            HTMLRaw(
              """
              <form method="post" action="/organizer/proposals/\(proposal.id)/accept" style="display:inline">
                <button type="submit" class="btn btn-sm btn-success">Accept</button>
              </form>
              """)
          }
          if proposal.status == .submitted || proposal.status == .accepted {
            HTMLRaw(
              """
              <form method="post" action="/organizer/proposals/\(proposal.id)/reject" style="display:inline">
                <button type="submit" class="btn btn-sm btn-outline-danger">Reject</button>
              </form>
              """)
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
