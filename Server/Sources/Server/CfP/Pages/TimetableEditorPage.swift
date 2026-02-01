import Elementary
import Foundation
import SharedModels

struct TimetableEditorPageView: HTML, Sendable {
  let user: UserDTO?
  let conference: ConferencePublicInfo?
  let acceptedProposals: [ProposalDTO]
  let slots: [ScheduleSlotDTO]
  let days: [CfPRoutes.DayInfo]

  /// Generate JS object mapping dayNumber -> ISO date string
  private var dayDatesJSON: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    let entries = days.compactMap { day -> String? in
      guard let date = day.date else { return nil }
      return "\(day.dayNumber): '\(formatter.string(from: date))'"
    }
    return entries.joined(separator: ", ")
  }

  var body: some HTML {
    div(.class("container-fluid py-4 px-4")) {
      if let user, user.role == .admin {
        renderHeader()
        renderDayTabs()
        renderDayTabContent()
        renderAddSlotModal()
        renderEditSlotModal()
        renderScripts()
      } else {
        renderAccessDenied()
      }
    }
  }

  // MARK: - Header

  @HTMLBuilder
  private func renderHeader() -> some HTML {
    div(.class("d-flex justify-content-between align-items-center mb-4")) {
      div {
        div(.class("mb-2")) {
          a(.class("btn btn-outline-secondary btn-sm"), .href("/organizer/proposals")) {
            HTMLRaw("&larr; Back to Proposals")
          }
        }
        h1(.class("fw-bold mb-1")) { "Timetable Editor" }
        if let conference {
          p(.class("text-muted mb-0")) {
            HTMLText(conference.displayName)
          }
        }
      }
      div(.class("d-flex gap-2 align-items-start flex-wrap")) {
        for day in days {
          a(
            .class("btn btn-outline-success btn-sm"),
            .href("/organizer/timetable/export/\(day.dayNumber)")
          ) {
            HTMLText("Export \(day.label)")
          }
        }
        a(
          .class("btn btn-success btn-sm"),
          .href("/organizer/timetable/export")
        ) {
          "Export All"
        }
      }
    }
  }

  // MARK: - Day Tabs

  @HTMLBuilder
  private func renderDayTabs() -> some HTML {
    HTMLRaw(buildDayTabsHTML())
  }

  private func buildDayTabsHTML() -> String {
    var html = "<ul class=\"nav nav-tabs\" id=\"timetableTabs\" role=\"tablist\">"
    for (index, day) in days.enumerated() {
      let activeClass = index == 0 ? "nav-link active" : "nav-link"
      let selected = index == 0 ? "true" : "false"
      let slotCount = slots.filter { $0.day == day.dayNumber }.count
      html +=
        """
        <li class="nav-item" role="presentation">
          <button class="\(activeClass)" id="day-tab-\(day.dayNumber)" data-day="\(day.dayNumber)" type="button" role="tab" aria-controls="day-pane-\(day.dayNumber)" aria-selected="\(selected)">\(escapeHTML(day.label)) <span class="badge bg-secondary ms-1">\(slotCount)</span></button>
        </li>
        """
    }
    html += "</ul>"
    return html
  }

  // MARK: - Day Tab Content

  @HTMLBuilder
  private func renderDayTabContent() -> some HTML {
    HTMLRaw(buildDayTabContentHTML())
  }

  private func buildDayTabContentHTML() -> String {
    var html = "<div class=\"tab-content mt-3\" id=\"timetableTabContent\">"
    for (index, day) in days.enumerated() {
      let activeClass =
        index == 0 ? "tab-pane fade show active" : "tab-pane fade"
      html +=
        """
        <div class="\(activeClass)" id="day-pane-\(day.dayNumber)" role="tabpanel" aria-labelledby="day-tab-\(day.dayNumber)">
          \(buildDayContentHTML(day: day))
        </div>
        """
    }
    html += "</div>"
    return html
  }

  private func buildDayContentHTML(day: CfPRoutes.DayInfo) -> String {
    var html = "<div class=\"row\">"
    // Left Panel: Timeline
    html += "<div class=\"col-md-8\">"
    html +=
      """
      <div class="d-flex justify-content-between align-items-center mb-3">
        <h5 class="fw-semibold mb-0">\(escapeHTML(day.label)) Schedule</h5>
        <button type="button" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addSlotModal" onclick="document.getElementById('addSlotDay').value='\(day.dayNumber)'">+ Add Slot</button>
      </div>
      """
    html += buildTimelineHTML(day: day.dayNumber)
    html += "</div>"
    // Right Panel: Unassigned Proposals
    html += "<div class=\"col-md-4\">"
    html += buildUnassignedProposalsHTML(day: day.dayNumber)
    html += "</div>"
    html += "</div>"
    return html
  }

  // MARK: - Timeline

  private func buildTimelineHTML(day: Int) -> String {
    let daySlots = slots.filter { $0.day == day }.sorted { $0.sortOrder < $1.sortOrder }
    var html =
      """
      <div class="timeline-list border rounded p-2 bg-light" id="timeline-\(day)" data-day="\(day)" style="min-height: 200px;">
      """
    if daySlots.isEmpty {
      html +=
        """
        <div class="text-center text-muted py-5">
          <p class="mb-1">No slots yet.</p>
          <p class="small">Drag proposals here or click &quot;+ Add Slot&quot; to begin.</p>
        </div>
        """
    } else {
      for slot in daySlots {
        html += buildSlotCardHTML(slot: slot)
      }
    }
    html += "</div>"
    return html
  }

  // MARK: - Slot Card

  private func buildSlotCardHTML(slot: ScheduleSlotDTO) -> String {
    let isTalk = slot.slotType == "talk" || slot.slotType == "lightning_talk"
    let borderClass: String
    switch slot.slotType {
    case "talk", "lightning_talk":
      borderClass = "border-start border-4 border-primary"
    case "break":
      borderClass = "border-start border-4 border-secondary"
    case "lunch":
      borderClass = "border-start border-4 border-warning"
    case "opening", "closing":
      borderClass = "border-start border-4 border-success"
    case "party":
      borderClass = "border-start border-4 border-info"
    default:
      borderClass = "border-start border-4 border-dark"
    }

    let slotId = slot.id?.uuidString ?? ""
    let startISO = formatISO(slot.startTime)
    let endISO = slot.endTime.map { formatISO($0) } ?? ""

    var html =
      """
      <div class="card mb-2 slot-card \(borderClass)" data-slot-id="\(slotId)" data-sort-order="\(slot.sortOrder)">
        <div class="card-body py-2 px-3">
          <div class="d-flex align-items-center">
            <span class="drag-handle me-2 text-muted" style="cursor: grab; font-size: 1.2rem; user-select: none;">&#9776;</span>
            <div class="me-3" style="min-width: 90px;">
              <small class="fw-semibold text-nowrap slot-time" data-start="\(startISO)" data-end="\(endISO)"></small>
            </div>
            <div class="flex-grow-1">
              <div class="d-flex align-items-center">
      """

    if isTalk {
      if let iconURL = slot.speakerIconURL, !iconURL.isEmpty {
        html +=
          """
                  <img src="\(escapeAttr(iconURL))" class="rounded-circle me-2" style="width: 28px; height: 28px; object-fit: cover;" alt="\(escapeAttr(slot.speakerName ?? "Speaker"))">
          """
      }
      html += "<div>"
      html +=
        """
                  <div class="fw-semibold small">\(escapeHTML(slot.proposalTitle ?? "Untitled Talk"))</div>
        """
      if let speaker = slot.speakerName {
        html +=
          """
                    <div class="text-muted" style="font-size: 0.78rem;">\(escapeHTML(speaker))</div>
          """
      }
      html += "</div>"
    } else {
      html +=
        """
                <div class="fw-semibold small">\(escapeHTML(slot.customTitle ?? slotTypeDisplayName(slot.slotType)))</div>
        """
    }

    html +=
      """
              </div>
            </div>
            <div class="d-flex gap-1 align-items-center me-2">
              <span class="badge \(slotTypeBadgeClass(slot.slotType))">\(escapeHTML(slotTypeDisplayName(slot.slotType)))</span>
      """

    if let duration = slot.talkDuration {
      html +=
        """
                <span class="badge bg-info text-dark">\(escapeHTML(duration))</span>
        """
    }
    if let place = slot.place, !place.isEmpty {
      html +=
        """
                <span class="badge bg-light text-dark border">\(escapeHTML(place))</span>
        """
    }

    html +=
      """
            </div>
            <div class="d-flex gap-1">
              <button type="button" class="btn btn-outline-secondary btn-sm edit-slot-btn" data-slot-id="\(slotId)" data-start="\(startISO)" data-end="\(endISO)" data-place="\(escapeAttr(slot.place ?? ""))" data-place-ja="\(escapeAttr(slot.placeJa ?? ""))" data-custom-title="\(escapeAttr(slot.customTitle ?? ""))" data-custom-title-ja="\(escapeAttr(slot.customTitleJa ?? ""))" data-slot-type="\(slot.slotType)" data-day="\(slot.day)" title="Edit">&#9998;</button>
              <button type="button" class="btn btn-outline-danger btn-sm delete-slot-btn" data-slot-id="\(slotId)" title="Delete">&times;</button>
            </div>
          </div>
        </div>
      </div>
      """

    return html
  }

  // MARK: - Unassigned Proposals Sidebar

  private func buildUnassignedProposalsHTML(day: Int) -> String {
    var html =
      """
      <div class="card">
        <div class="card-header bg-white">
          <div class="d-flex justify-content-between align-items-center">
            <h6 class="mb-0 fw-semibold">Unassigned Proposals</h6>
            <span class="badge bg-primary">\(acceptedProposals.count)</span>
          </div>
        </div>
        <div class="card-body p-2" style="max-height: 70vh; overflow-y: auto;">
          <div class="unassigned-list" id="unassigned-\(day)" data-day="\(day)">
      """

    if acceptedProposals.isEmpty {
      html +=
        """
            <div class="text-center text-muted py-4">
              <p class="small mb-0">All accepted proposals have been assigned.</p>
            </div>
        """
    } else {
      for proposal in acceptedProposals {
        html += buildProposalCardHTML(proposal: proposal)
      }
    }

    html +=
      """
          </div>
        </div>
      </div>
      """
    return html
  }

  private func buildProposalCardHTML(proposal: ProposalDTO) -> String {
    let durationBadgeClass =
      proposal.talkDuration == .lightning
      ? "badge bg-warning text-dark" : "badge bg-primary"

    var html =
      """
      <div class="card mb-2 proposal-card" data-proposal-id="\(proposal.id.uuidString)" data-proposal-title="\(escapeAttr(proposal.title))" data-speaker-name="\(escapeAttr(proposal.speakerName))" data-talk-duration="\(proposal.talkDuration.rawValue)" style="cursor: grab;">
        <div class="card-body py-2 px-3">
          <div class="d-flex align-items-center">
            <span class="me-2 text-muted" style="font-size: 0.9rem; user-select: none;">&#8942;&#8942;</span>
      """

    if let iconURL = proposal.iconURL, !iconURL.isEmpty {
      html +=
        """
            <img src="\(escapeAttr(iconURL))" class="rounded-circle me-2" style="width: 24px; height: 24px; object-fit: cover;" alt="\(escapeAttr(proposal.speakerName))">
        """
    }

    html +=
      """
            <div class="flex-grow-1">
              <div class="fw-semibold" style="font-size: 0.85rem;">\(escapeHTML(proposal.title))</div>
              <div class="text-muted" style="font-size: 0.75rem;">\(escapeHTML(proposal.speakerName))</div>
            </div>
            <span class="\(durationBadgeClass)">\(escapeHTML(proposal.talkDuration.rawValue))</span>
          </div>
        </div>
      </div>
      """
    return html
  }

  // MARK: - Add Slot Modal

  @HTMLBuilder
  private func renderAddSlotModal() -> some HTML {
    HTMLRaw(buildAddSlotModalHTML())
  }

  private func buildAddSlotModalHTML() -> String {
    var dayOptions = ""
    for day in days {
      dayOptions += "<option value=\"\(day.dayNumber)\">\(escapeHTML(day.label))</option>"
    }

    return """
      <div class="modal fade" id="addSlotModal" tabindex="-1" aria-labelledby="addSlotModalLabel" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="addSlotModalLabel">Add Slot</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <form id="addSlotForm">
                <input type="hidden" id="addSlotConferenceId" value="\(conference?.id.uuidString ?? "")">
                <div class="mb-3">
                  <label for="addSlotDay" class="form-label fw-semibold">Day *</label>
                  <select class="form-select" id="addSlotDay" required>
                    \(dayOptions)
                  </select>
                </div>
                <div class="mb-3">
                  <label for="addSlotType" class="form-label fw-semibold">Slot Type *</label>
                  <select class="form-select" id="addSlotType" required>
                    <option value="break">Break</option>
                    <option value="lunch">Lunch</option>
                    <option value="opening">Opening</option>
                    <option value="closing">Closing</option>
                    <option value="party">Party</option>
                    <option value="custom">Custom</option>
                  </select>
                </div>
                <div class="mb-3">
                  <label for="addSlotCustomTitle" class="form-label fw-semibold">Custom Title</label>
                  <input type="text" class="form-control" id="addSlotCustomTitle" placeholder="e.g. Lunch Break, Networking">
                </div>
                <div class="mb-3">
                  <label for="addSlotCustomTitleJa" class="form-label">Custom Title (Japanese)</label>
                  <input type="text" class="form-control" id="addSlotCustomTitleJa" placeholder="e.g. \u{6F14}\u{5F0C}\u{4F11}\u{61A9}">
                </div>
                <div class="row">
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="addSlotStartTime" class="form-label fw-semibold">Start Time *</label>
                      <input type="time" class="form-control" id="addSlotStartTime" required>
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="addSlotEndTime" class="form-label">End Time</label>
                      <input type="time" class="form-control" id="addSlotEndTime">
                    </div>
                  </div>
                </div>
                <div class="row">
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="addSlotPlace" class="form-label">Place</label>
                      <input type="text" class="form-control" id="addSlotPlace" placeholder="e.g. Main Hall">
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="addSlotPlaceJa" class="form-label">Place (Japanese)</label>
                      <input type="text" class="form-control" id="addSlotPlaceJa" placeholder="e.g. \u{30E1}\u{30A4}\u{30F3}\u{30DB}\u{30FC}\u{30EB}">
                    </div>
                  </div>
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-primary" id="addSlotSubmitBtn">Add Slot</button>
            </div>
          </div>
        </div>
      </div>
      """
  }

  // MARK: - Edit Slot Modal

  @HTMLBuilder
  private func renderEditSlotModal() -> some HTML {
    HTMLRaw(buildEditSlotModalHTML())
  }

  private func buildEditSlotModalHTML() -> String {
    var dayOptions = ""
    for day in days {
      dayOptions += "<option value=\"\(day.dayNumber)\">\(escapeHTML(day.label))</option>"
    }

    return """
      <div class="modal fade" id="editSlotModal" tabindex="-1" aria-labelledby="editSlotModalLabel" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="editSlotModalLabel">Edit Slot</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <form id="editSlotForm">
                <input type="hidden" id="editSlotId" value="">
                <div class="mb-3">
                  <label for="editSlotDay" class="form-label fw-semibold">Day</label>
                  <select class="form-select" id="editSlotDay">
                    \(dayOptions)
                  </select>
                </div>
                <div class="mb-3">
                  <label for="editSlotType" class="form-label fw-semibold">Slot Type</label>
                  <select class="form-select" id="editSlotType">
                    <option value="talk">Talk</option>
                    <option value="lightning_talk">Lightning Talk</option>
                    <option value="break">Break</option>
                    <option value="lunch">Lunch</option>
                    <option value="opening">Opening</option>
                    <option value="closing">Closing</option>
                    <option value="party">Party</option>
                    <option value="custom">Custom</option>
                  </select>
                </div>
                <div class="mb-3">
                  <label for="editSlotCustomTitle" class="form-label fw-semibold">Custom Title</label>
                  <input type="text" class="form-control" id="editSlotCustomTitle">
                </div>
                <div class="mb-3">
                  <label for="editSlotCustomTitleJa" class="form-label">Custom Title (Japanese)</label>
                  <input type="text" class="form-control" id="editSlotCustomTitleJa">
                </div>
                <div class="row">
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="editSlotStartTime" class="form-label fw-semibold">Start Time *</label>
                      <input type="time" class="form-control" id="editSlotStartTime" required>
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="editSlotEndTime" class="form-label">End Time</label>
                      <input type="time" class="form-control" id="editSlotEndTime">
                    </div>
                  </div>
                </div>
                <div class="row">
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="editSlotPlace" class="form-label">Place</label>
                      <input type="text" class="form-control" id="editSlotPlace">
                    </div>
                  </div>
                  <div class="col-6">
                    <div class="mb-3">
                      <label for="editSlotPlaceJa" class="form-label">Place (Japanese)</label>
                      <input type="text" class="form-control" id="editSlotPlaceJa">
                    </div>
                  </div>
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
              <button type="button" class="btn btn-primary" id="editSlotSubmitBtn">Save Changes</button>
            </div>
          </div>
        </div>
      </div>
      """
  }

  // MARK: - Scripts

  @HTMLBuilder
  private func renderScripts() -> some HTML {
    script(.src("https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/Sortable.min.js")) {}

    HTMLRaw(
      """
      <style>
        .slot-card { transition: box-shadow 0.15s ease; }
        .slot-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
        .slot-card.sortable-ghost { opacity: 0.4; background: #e3f2fd; }
        .slot-card.sortable-chosen { box-shadow: 0 4px 16px rgba(0,0,0,0.2); }
        .proposal-card { transition: box-shadow 0.15s ease; }
        .proposal-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
        .proposal-card.sortable-ghost { opacity: 0.4; background: #e8f5e9; }
        .timeline-list { transition: background 0.2s; }
        .timeline-list.sortable-drag-over { background: #e3f2fd !important; }
        .drag-handle:active { cursor: grabbing; }
      </style>
      """
    )

    script {
      HTMLRaw(
        """
        document.addEventListener('DOMContentLoaded', function() {
          var conferenceId = '\(conference?.id.uuidString ?? "")';
          var dayDates = {\(dayDatesJSON)};

          // ============================================================
          // Utility: Format ISO date string to HH:MM in JST
          // ============================================================
          function formatTimeHHMM(isoString) {
            if (!isoString) return '';
            var d = new Date(isoString);
            if (isNaN(d.getTime())) return isoString;
            try {
              return d.toLocaleTimeString('en-GB', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: false,
                timeZone: 'Asia/Tokyo'
              });
            } catch(e) {
              var h = d.getUTCHours().toString().padStart(2, '0');
              var m = d.getUTCMinutes().toString().padStart(2, '0');
              return h + ':' + m;
            }
          }

          // ============================================================
          // Utility: Convert HH:MM time input + day to ISO 8601 string
          // Uses a reference date for the conference day in JST (UTC+9)
          // ============================================================
          function timeInputToISO(timeStr, dayNumber) {
            if (!timeStr) return null;
            var parts = timeStr.split(':');
            if (parts.length < 2) return null;
            var hours = parseInt(parts[0], 10);
            var minutes = parseInt(parts[1], 10);
            // Use conference day dates from server data
            var dayISO = dayDates[dayNumber];
            if (dayISO) {
              var ref = new Date(dayISO);
              var baseDate = new Date(Date.UTC(ref.getUTCFullYear(), ref.getUTCMonth(), ref.getUTCDate(), hours - 9, minutes, 0));
              return baseDate.toISOString();
            }
            // Fallback: use epoch-based date
            var baseDate = new Date(Date.UTC(2026, 3, 8 + dayNumber, hours - 9, minutes, 0));
            return baseDate.toISOString();
          }

          // ============================================================
          // Utility: Extract HH:MM from ISO string for time input
          // ============================================================
          function isoToTimeInput(isoString) {
            if (!isoString) return '';
            var d = new Date(isoString);
            if (isNaN(d.getTime())) return '';
            try {
              return d.toLocaleTimeString('en-GB', {
                hour: '2-digit',
                minute: '2-digit',
                hour12: false,
                timeZone: 'Asia/Tokyo'
              });
            } catch(e) {
              return '';
            }
          }

          // ============================================================
          // Format all time displays on the page
          // ============================================================
          function formatAllTimes() {
            document.querySelectorAll('.slot-time').forEach(function(el) {
              var start = el.getAttribute('data-start');
              var end = el.getAttribute('data-end');
              var text = formatTimeHHMM(start);
              if (end) {
                text += ' - ' + formatTimeHHMM(end);
              }
              el.textContent = text;
            });
          }
          formatAllTimes();

          // ============================================================
          // Tab switching logic
          // ============================================================
          var tabButtons = document.querySelectorAll('#timetableTabs button[data-day]');
          tabButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
              var day = this.getAttribute('data-day');

              tabButtons.forEach(function(b) {
                b.classList.remove('active');
                b.setAttribute('aria-selected', 'false');
              });
              document.querySelectorAll('#timetableTabContent .tab-pane').forEach(function(pane) {
                pane.classList.remove('show', 'active');
              });

              this.classList.add('active');
              this.setAttribute('aria-selected', 'true');
              var pane = document.getElementById('day-pane-' + day);
              if (pane) {
                pane.classList.add('show', 'active');
              }
            });
          });

          // ============================================================
          // Get current active day number
          // ============================================================
          function getActiveDay() {
            var activeBtn = document.querySelector('#timetableTabs button.active');
            return activeBtn ? parseInt(activeBtn.getAttribute('data-day'), 10) : 1;
          }

          // ============================================================
          // API Helper
          // ============================================================
          function apiCall(url, method, body) {
            var opts = {
              method: method,
              headers: { 'Content-Type': 'application/json' }
            };
            if (body) {
              opts.body = JSON.stringify(body);
            }
            return fetch(url, opts).then(function(res) {
              if (!res.ok) {
                return res.text().then(function(t) {
                  throw new Error('API error ' + res.status + ': ' + t);
                });
              }
              if (res.status === 204 || res.headers.get('content-length') === '0') {
                return null;
              }
              var ct = res.headers.get('content-type') || '';
              if (ct.indexOf('json') !== -1) {
                return res.json();
              }
              return null;
            });
          }

          // ============================================================
          // Initialize SortableJS on each day's timeline
          // ============================================================
          document.querySelectorAll('.timeline-list').forEach(function(list) {
            var dayNum = parseInt(list.getAttribute('data-day'), 10);

            new Sortable(list, {
              group: {
                name: 'timeline-' + dayNum,
                put: ['unassigned-' + dayNum]
              },
              animation: 150,
              handle: '.drag-handle',
              ghostClass: 'sortable-ghost',
              chosenClass: 'sortable-chosen',
              dragClass: 'sortable-drag',
              onSort: function(evt) {
                if (evt.from !== evt.to) return;
                handleReorder(list);
              },
              onAdd: function(evt) {
                var item = evt.item;
                if (item.classList.contains('proposal-card')) {
                  var proposalId = item.getAttribute('data-proposal-id');
                  var talkDuration = item.getAttribute('data-talk-duration');

                  item.remove();

                  var slotType = (talkDuration === 'LT') ? 'lightning_talk' : 'talk';

                  var startTime = timeInputToISO('10:00', dayNum);
                  var slotCards = list.querySelectorAll('.slot-card');
                  if (slotCards.length > 0) {
                    var lastCard = slotCards[slotCards.length - 1];
                    var timeEl = lastCard.querySelector('.slot-time');
                    if (timeEl) {
                      var lastEnd = timeEl.getAttribute('data-end');
                      if (!lastEnd) {
                        lastEnd = timeEl.getAttribute('data-start');
                      }
                      if (lastEnd) {
                        startTime = lastEnd;
                      }
                    }
                  }

                  var durationMin = (talkDuration === 'LT') ? 5 : 20;
                  var startDate = new Date(startTime);
                  var endDate = new Date(startDate.getTime() + durationMin * 60000);
                  var endTime = endDate.toISOString();

                  apiCall('/organizer/timetable/api/slots', 'POST', {
                    conferenceId: conferenceId,
                    proposalId: proposalId,
                    day: dayNum,
                    startTime: startTime,
                    endTime: endTime,
                    slotType: slotType,
                    place: null
                  }).then(function() {
                    location.reload();
                  }).catch(function(err) {
                    alert('Failed to create slot: ' + err.message);
                    location.reload();
                  });
                }
              }
            });
          });

          // ============================================================
          // Initialize SortableJS on each day's unassigned proposals list
          // ============================================================
          document.querySelectorAll('.unassigned-list').forEach(function(list) {
            var dayNum = parseInt(list.getAttribute('data-day'), 10);

            new Sortable(list, {
              group: {
                name: 'unassigned-' + dayNum,
                pull: true,
                put: false
              },
              animation: 150,
              sort: false,
              ghostClass: 'sortable-ghost'
            });
          });

          // ============================================================
          // Handle reorder: collect new sort orders and POST
          // ============================================================
          function handleReorder(list) {
            var items = list.querySelectorAll('.slot-card');
            var reorderData = [];
            items.forEach(function(card, index) {
              var slotId = card.getAttribute('data-slot-id');
              if (slotId) {
                reorderData.push({ id: slotId, sortOrder: index });
              }
            });

            if (reorderData.length > 0) {
              apiCall('/organizer/timetable/api/reorder', 'POST', reorderData)
                .catch(function(err) {
                  alert('Failed to reorder: ' + err.message);
                  location.reload();
                });
            }
          }

          // ============================================================
          // Delete slot handler
          // ============================================================
          document.addEventListener('click', function(e) {
            var btn = e.target.closest('.delete-slot-btn');
            if (!btn) return;
            var slotId = btn.getAttribute('data-slot-id');
            if (!slotId) return;
            if (!confirm('Are you sure you want to delete this slot?')) return;

            apiCall('/organizer/timetable/api/slots/' + slotId + '/delete', 'POST', {})
              .then(function() {
                location.reload();
              })
              .catch(function(err) {
                alert('Failed to delete slot: ' + err.message);
              });
          });

          // ============================================================
          // Edit slot handler - populate and show modal
          // ============================================================
          document.addEventListener('click', function(e) {
            var btn = e.target.closest('.edit-slot-btn');
            if (!btn) return;

            document.getElementById('editSlotId').value = btn.getAttribute('data-slot-id') || '';
            document.getElementById('editSlotStartTime').value = isoToTimeInput(btn.getAttribute('data-start'));
            document.getElementById('editSlotEndTime').value = isoToTimeInput(btn.getAttribute('data-end'));
            document.getElementById('editSlotPlace').value = btn.getAttribute('data-place') || '';
            document.getElementById('editSlotPlaceJa').value = btn.getAttribute('data-place-ja') || '';
            document.getElementById('editSlotCustomTitle').value = btn.getAttribute('data-custom-title') || '';
            document.getElementById('editSlotCustomTitleJa').value = btn.getAttribute('data-custom-title-ja') || '';
            document.getElementById('editSlotDay').value = btn.getAttribute('data-day') || '1';

            var slotTypeSelect = document.getElementById('editSlotType');
            var slotTypeVal = btn.getAttribute('data-slot-type') || 'talk';
            for (var i = 0; i < slotTypeSelect.options.length; i++) {
              if (slotTypeSelect.options[i].value === slotTypeVal) {
                slotTypeSelect.selectedIndex = i;
                break;
              }
            }

            var modal = new bootstrap.Modal(document.getElementById('editSlotModal'));
            modal.show();
          });

          // ============================================================
          // Edit slot form submit
          // ============================================================
          document.getElementById('editSlotSubmitBtn').addEventListener('click', function() {
            var slotId = document.getElementById('editSlotId').value;
            if (!slotId) return;

            var dayVal = parseInt(document.getElementById('editSlotDay').value, 10);
            var startTimeStr = document.getElementById('editSlotStartTime').value;
            var endTimeStr = document.getElementById('editSlotEndTime').value;

            if (!startTimeStr) {
              alert('Start time is required.');
              return;
            }

            var body = {
              day: dayVal,
              startTime: timeInputToISO(startTimeStr, dayVal),
              slotType: document.getElementById('editSlotType').value,
              customTitle: document.getElementById('editSlotCustomTitle').value || null,
              customTitleJa: document.getElementById('editSlotCustomTitleJa').value || null,
              place: document.getElementById('editSlotPlace').value || null,
              placeJa: document.getElementById('editSlotPlaceJa').value || null
            };

            if (endTimeStr) {
              body.endTime = timeInputToISO(endTimeStr, dayVal);
            }

            apiCall('/organizer/timetable/api/slots/' + slotId, 'POST', body)
              .then(function() {
                location.reload();
              })
              .catch(function(err) {
                alert('Failed to update slot: ' + err.message);
              });
          });

          // ============================================================
          // Add slot form submit
          // ============================================================
          document.getElementById('addSlotSubmitBtn').addEventListener('click', function() {
            var dayVal = parseInt(document.getElementById('addSlotDay').value, 10);
            var startTimeStr = document.getElementById('addSlotStartTime').value;
            var endTimeStr = document.getElementById('addSlotEndTime').value;
            var slotType = document.getElementById('addSlotType').value;

            if (!startTimeStr) {
              alert('Start time is required.');
              return;
            }

            var body = {
              conferenceId: conferenceId,
              day: dayVal,
              startTime: timeInputToISO(startTimeStr, dayVal),
              slotType: slotType,
              customTitle: document.getElementById('addSlotCustomTitle').value || null,
              customTitleJa: document.getElementById('addSlotCustomTitleJa').value || null,
              place: document.getElementById('addSlotPlace').value || null,
              placeJa: document.getElementById('addSlotPlaceJa').value || null
            };

            if (endTimeStr) {
              body.endTime = timeInputToISO(endTimeStr, dayVal);
            }

            apiCall('/organizer/timetable/api/slots', 'POST', body)
              .then(function() {
                location.reload();
              })
              .catch(function(err) {
                alert('Failed to create slot: ' + err.message);
              });
          });

        }); // end DOMContentLoaded
        """
      )
    }
  }

  // MARK: - Access Denied

  @HTMLBuilder
  private func renderAccessDenied() -> some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) { "Access Denied" }
        p(.class("text-muted mb-4")) {
          "You need organizer permissions to view the timetable editor."
        }
        a(.class("btn btn-primary"), .href("/")) { "Return to Home" }
      }
    }
  }

  // MARK: - Helpers

  private func formatISO(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }

  private func escapeAttr(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }

  private func escapeHTML(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }

  private func slotTypeDisplayName(_ rawType: String) -> String {
    switch rawType {
    case "talk": return "Talk"
    case "lightning_talk": return "Lightning Talk"
    case "break": return "Break"
    case "lunch": return "Lunch"
    case "opening": return "Opening"
    case "closing": return "Closing"
    case "party": return "Party"
    case "custom": return "Custom"
    default: return rawType
    }
  }

  private func slotTypeBadgeClass(_ rawType: String) -> String {
    switch rawType {
    case "talk": return "bg-primary"
    case "lightning_talk": return "bg-warning text-dark"
    case "break": return "bg-secondary"
    case "lunch": return "bg-warning text-dark"
    case "opening": return "bg-success"
    case "closing": return "bg-success"
    case "party": return "bg-info text-dark"
    case "custom": return "bg-dark"
    default: return "bg-secondary"
    }
  }
}
