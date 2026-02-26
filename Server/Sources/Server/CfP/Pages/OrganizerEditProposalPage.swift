import Elementary
import SharedModels

struct OrganizerEditProposalPageView: HTML, Sendable {
  let user: UserDTO?
  let proposal: ProposalDTO?
  let conferences: [ConferencePublicInfo]
  let errorMessage: String?
  let csrfToken: String

  init(
    user: UserDTO?,
    proposal: ProposalDTO?,
    conferences: [ConferencePublicInfo],
    errorMessage: String? = nil,
    csrfToken: String = ""
  ) {
    self.user = user
    self.proposal = proposal
    self.conferences = conferences
    self.errorMessage = errorMessage
    self.csrfToken = csrfToken
  }

  var body: some HTML {
    div(.class("container py-5")) {
      if let user, user.role == .admin {
        if let proposal {
          pageHeader(proposal: proposal)
          importedAlert(proposal: proposal)
          errorAlert
          editFormCard(proposal: proposal)
          deleteCard(proposal: proposal)
        } else {
          notFoundCard
        }
      } else {
        accessDeniedCard
      }
    }
    previewScript
  }

  private func pageHeader(proposal: ProposalDTO) -> some HTML {
    div {
      // Back button
      div(.class("mb-4")) {
        a(
          .class("btn btn-outline-secondary"),
          .href("/organizer/proposals/\(proposal.id.uuidString)")
        ) {
          "<- Back to Proposal"
        }
      }
      h1(.class("fw-bold mb-2")) { "Edit Proposal (Organizer)" }
      p(.class("lead text-muted mb-4")) {
        "Edit proposal details as an organizer."
      }
    }
  }

  @HTMLBuilder
  private func importedAlert(proposal: ProposalDTO) -> some HTML {
    // Check if this is an imported proposal (speaker is papercall-import)
    if proposal.speakerUsername == "papercall-import" {
      div(.class("alert alert-info mb-4")) {
        strong { "Imported Proposal: " }
        "This proposal was imported from PaperCall.io and is not linked to a GitHub account."
      }
    }
  }

  @HTMLBuilder
  private var errorAlert: some HTML {
    if let errorMessage {
      div(.class("alert alert-danger mb-4")) {
        HTMLText(errorMessage)
      }
    }
  }

  private func editFormCard(proposal: ProposalDTO) -> some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        editForm(proposal: proposal)
      }
    }
  }

  private func editForm(proposal: ProposalDTO) -> some HTML {
    form(
      .method(.post),
      .action("/organizer/proposals/\(proposal.id.uuidString)/edit")
    ) {
      input(.type(.hidden), .name("_csrf"), .value(csrfToken))
      conferenceField(proposal: proposal)
      titleField(value: proposal.title)
      abstractField(value: proposal.abstract)
      talkDetailsField(value: proposal.talkDetail)
      durationField(selected: proposal.talkDuration)
      workshopFieldsSection(proposal: proposal)
      coInstructorFieldsSection(proposal: proposal)
      speakerInfoSection(proposal: proposal)
      notesField(value: proposal.notes)
      submitButton
    }
  }

  private func conferenceField(proposal: ProposalDTO) -> some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("conferenceId")) {
        "Conference *"
      }
      select(.class("form-select"), .name("conferenceId"), .id("conferenceId"), .required) {
        for conf in conferences {
          if conf.id == proposal.conferenceId {
            option(.value(conf.id.uuidString), .selected) {
              HTMLText(conf.displayName)
            }
          } else {
            option(.value(conf.id.uuidString)) {
              HTMLText(conf.displayName)
            }
          }
        }
      }
    }
  }

  private func titleField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("title")) {
        "Title *"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("title"),
        .id("title"),
        .required,
        .value(value),
        .placeholder("Enter talk title")
      )
    }
  }

  private func abstractField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("abstract")) {
        "Abstract *"
      }
      textarea(
        .class("form-control"),
        .name("abstract"),
        .id("abstract"),
        .custom(name: "rows", value: "3"),
        .required,
        .placeholder("A brief summary of the talk (2-3 sentences)")
      ) {
        HTMLText(value)
      }
      div(.class("form-text")) {
        "This will be shown to the audience if the talk is accepted."
      }
    }
  }

  private func talkDetailsField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("talkDetails")) {
        "Talk Details *"
      }
      textarea(
        .class("form-control"),
        .name("talkDetails"),
        .id("talkDetails"),
        .custom(name: "rows", value: "5"),
        .required,
        .placeholder("Detailed description for reviewers")
      ) {
        HTMLText(value)
      }
      div(.class("form-text")) {
        "Include outline, key points, and what attendees will learn. For reviewers only."
      }
    }
  }

  private func durationField(selected: TalkDuration) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("talkDuration")) {
        "Type *"
      }
      select(
        .class("form-select"), .name("talkDuration"), .id("talkDuration"), .required
      ) {
        option(.value("")) { "Choose type..." }
        for duration in TalkDuration.allCases {
          if duration == selected {
            option(.value(duration.rawValue), .selected) {
              HTMLText(duration.displayName)
            }
          } else {
            option(.value(duration.rawValue)) {
              HTMLText(duration.displayName)
            }
          }
        }
      }
    }
  }

  // MARK: - Workshop Fields

  @HTMLBuilder
  private func workshopFieldsSection(proposal: ProposalDTO) -> some HTML {
    let isWorkshop = proposal.talkDuration == .workshop
    let details = proposal.workshopDetails

    HTMLRaw(
      """
      <div id="workshopFields" style="display: \(isWorkshop ? "block" : "none");">
      """)
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) { "Workshop Details" }

        // Language
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) { "Language *" }
          div {
            for lang in WorkshopLanguage.allCases {
              div(.class("form-check form-check-inline")) {
                if lang == details?.language {
                  input(
                    .type(.radio), .class("form-check-input"),
                    .name("workshop_language"),
                    .id("workshop_language_\(lang.rawValue)"),
                    .value(lang.rawValue),
                    .custom(name: "data-workshop-required", value: "true"),
                    .checked
                  )
                } else {
                  input(
                    .type(.radio), .class("form-check-input"),
                    .name("workshop_language"),
                    .id("workshop_language_\(lang.rawValue)"),
                    .value(lang.rawValue),
                    .custom(name: "data-workshop-required", value: "true")
                  )
                }
                label(
                  .class("form-check-label"), .for("workshop_language_\(lang.rawValue)")
                ) {
                  HTMLText(lang.displayName)
                }
              }
            }
          }
        }

        // Number of Tutors
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_numberOfTutors")) {
            "Number of Tutors *"
          }
          input(
            .type(.number), .class("form-control"),
            .name("workshop_numberOfTutors"),
            .id("workshop_numberOfTutors"),
            .custom(name: "min", value: "0"),
            .custom(name: "data-workshop-required", value: "true"),
            .value(details.map { "\($0.numberOfTutors)" } ?? "")
          )
        }

        // Key Takeaways
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_keyTakeaways")) {
            "Key Takeaways *"
          }
          textarea(
            .class("form-control"), .name("workshop_keyTakeaways"),
            .id("workshop_keyTakeaways"),
            .custom(name: "rows", value: "3"),
            .custom(name: "data-workshop-required", value: "true")
          ) { HTMLText(details?.keyTakeaways ?? "") }
        }

        // Prerequisites
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_prerequisites")) {
            "Prerequisites"
          }
          input(
            .type(.text), .class("form-control"),
            .name("workshop_prerequisites"), .id("workshop_prerequisites"),
            .value(details?.prerequisites ?? "")
          )
        }

        // Agenda & Schedule
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_agendaSchedule")) {
            "Agenda & Schedule *"
          }
          textarea(
            .class("form-control"), .name("workshop_agendaSchedule"),
            .id("workshop_agendaSchedule"),
            .custom(name: "rows", value: "4"),
            .custom(name: "data-workshop-required", value: "true")
          ) { HTMLText(details?.agendaSchedule ?? "") }
        }

        // Participant Requirements
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_participantRequirements")) {
            "What Participants Need to Bring *"
          }
          textarea(
            .class("form-control"), .name("workshop_participantRequirements"),
            .id("workshop_participantRequirements"),
            .custom(name: "rows", value: "2"),
            .custom(name: "data-workshop-required", value: "true")
          ) { HTMLText(details?.participantRequirements ?? "") }
        }

        // Required Software
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_requiredSoftware")) {
            "Required Tools / Software to Install in Advance"
          }
          textarea(
            .class("form-control"), .name("workshop_requiredSoftware"),
            .id("workshop_requiredSoftware"),
            .custom(name: "rows", value: "2")
          ) { HTMLText(details?.requiredSoftware ?? "") }
        }

        // Network Requirements
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_networkRequirements")) {
            "Network Requirements *"
          }
          textarea(
            .class("form-control"), .name("workshop_networkRequirements"),
            .id("workshop_networkRequirements"),
            .custom(name: "rows", value: "2"),
            .custom(name: "data-workshop-required", value: "true")
          ) { HTMLText(details?.networkRequirements ?? "") }
        }

        // Facilities
        workshopFacilitiesField(
          selected: details?.requiredFacilities ?? [],
          otherValue: details?.facilityOther
        )

        // Motivation
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_motivation")) {
            "Motivation *"
          }
          textarea(
            .class("form-control"), .name("workshop_motivation"),
            .id("workshop_motivation"),
            .custom(name: "rows", value: "3"),
            .custom(name: "data-workshop-required", value: "true")
          ) { HTMLText(details?.motivation ?? "") }
        }

        // Uniqueness
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_uniqueness")) {
            "Uniqueness *"
          }
          textarea(
            .class("form-control"), .name("workshop_uniqueness"),
            .id("workshop_uniqueness"),
            .custom(name: "rows", value: "3"),
            .custom(name: "data-workshop-required", value: "true")
          ) { HTMLText(details?.uniqueness ?? "") }
        }

        // Potential Risks
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("workshop_potentialRisks")) {
            "Potential Risks or Concerns"
          }
          textarea(
            .class("form-control"), .name("workshop_potentialRisks"),
            .id("workshop_potentialRisks"),
            .custom(name: "rows", value: "2")
          ) { HTMLText(details?.potentialRisks ?? "") }
        }
      }
    }
    HTMLRaw("</div>")
  }

  private func workshopFacilitiesField(
    selected: [FacilityRequirement], otherValue: String?
  ) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold")) {
        "Required Facilities / Equipment"
      }
      div {
        for facility in FacilityRequirement.allCases {
          div(.class("form-check")) {
            if selected.contains(facility) {
              input(
                .type(.checkbox), .class("form-check-input"),
                .name("workshop_requiredFacilities"),
                .id("facility_\(facility.rawValue)"),
                .value(facility.rawValue), .checked
              )
            } else {
              input(
                .type(.checkbox), .class("form-check-input"),
                .name("workshop_requiredFacilities"),
                .id("facility_\(facility.rawValue)"),
                .value(facility.rawValue)
              )
            }
            label(.class("form-check-label"), .for("facility_\(facility.rawValue)")) {
              HTMLText(facility.displayName)
            }
          }
        }
        div(.class("form-check")) {
          if otherValue != nil {
            input(
              .type(.checkbox), .class("form-check-input"),
              .name("workshop_hasFacilityOther"), .id("facility_other_check"),
              .value("true"), .checked,
              .custom(name: "onchange", value: "toggleFacilityOther(this.checked)")
            )
          } else {
            input(
              .type(.checkbox), .class("form-check-input"),
              .name("workshop_hasFacilityOther"), .id("facility_other_check"),
              .value("true"),
              .custom(name: "onchange", value: "toggleFacilityOther(this.checked)")
            )
          }
          label(.class("form-check-label"), .for("facility_other_check")) { "Other" }
        }
        input(
          .type(.text), .class("form-control mt-2"),
          .name("workshop_facilityOther"), .id("workshop_facilityOther"),
          .style(otherValue != nil ? "" : "display: none;"),
          .value(otherValue ?? "")
        )
      }
    }
  }

  // MARK: - Co-Instructor Fields

  @HTMLBuilder
  private func coInstructorFieldsSection(proposal: ProposalDTO) -> some HTML {
    let isWorkshop = proposal.talkDuration == .workshop
    let instructors = proposal.coInstructors ?? []
    let hasInstructor3 = instructors.count >= 2

    HTMLRaw(
      """
      <div id="coInstructorFields" style="display: \(isWorkshop ? "block" : "none");">
      """)
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) { "Co-Instructors" }
        p(.class("text-muted small mb-3")) {
          "You can register up to 3 instructors for a workshop (including the main speaker)."
        }

        coInstructorBlock(
          index: 2, instructor: instructors.count >= 1 ? instructors[0] : nil)

        HTMLRaw(
          """
          <div id="coInstructor3Block" style="display: \(hasInstructor3 ? "block" : "none");">
          """)
        coInstructorBlock(
          index: 3, instructor: instructors.count >= 2 ? instructors[1] : nil)
        HTMLRaw("</div>")

        HTMLRaw(
          """
          <div class="d-flex gap-2 mt-3">
            <button type="button" class="btn btn-outline-secondary btn-sm" id="addInstructor3Btn" style="display: \(hasInstructor3 ? "none" : "inline-block");" onclick="showInstructor3()">
          """)
        HTMLText("+ Add Instructor 3")
        HTMLRaw(
          """
            </button>
            <button type="button" class="btn btn-outline-danger btn-sm" id="removeInstructor3Btn" style="display: \(hasInstructor3 ? "inline-block" : "none");" onclick="hideInstructor3()">
          """)
        HTMLText("Remove Instructor 3")
        HTMLRaw(
          """
            </button>
          </div>
          """)
      }
    }
    HTMLRaw("</div>")
  }

  private func coInstructorBlock(index: Int, instructor: CoInstructor?) -> some HTML {
    let prefix = "coInstructor\(index)"
    let labelPrefix = "Instructor \(index)"

    return div(.class("border rounded p-3 mb-3")) {
      h6(.class("fw-semibold mb-3")) { HTMLText(labelPrefix) }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_githubUsername")) {
          HTMLText("\(labelPrefix): GitHub *")
        }
        div(.class("input-group")) {
          input(
            .type(.text), .class("form-control"),
            .name("\(prefix)_githubUsername"),
            .id("\(prefix)_githubUsername"),
            .value(instructor?.githubUsername ?? ""),
            .placeholder("GitHub username")
          )
          HTMLRaw(
            """
            <button class="btn btn-outline-primary" type="button" onclick="lookupCoInstructor(\(index))">Lookup</button>
            """)
        }
        HTMLRaw(
          """
          <div id="\(prefix)_lookupStatus" class="form-text"></div>
          """)
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_name")) {
          HTMLText("\(labelPrefix): Name *")
        }
        input(
          .type(.text), .class("form-control"),
          .name("\(prefix)_name"), .id("\(prefix)_name"),
          .value(instructor?.name ?? "")
        )
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_email")) {
          HTMLText("\(labelPrefix): Email *")
        }
        input(
          .type(.email), .class("form-control"),
          .name("\(prefix)_email"), .id("\(prefix)_email"),
          .value(instructor?.email ?? "")
        )
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_sns")) {
          HTMLText("\(labelPrefix): SNS")
        }
        input(
          .type(.text), .class("form-control"),
          .name("\(prefix)_sns"), .id("\(prefix)_sns"),
          .value(instructor?.sns ?? "")
        )
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_bio")) {
          HTMLText("\(labelPrefix): Short Bio *")
        }
        textarea(
          .class("form-control"),
          .name("\(prefix)_bio"), .id("\(prefix)_bio"),
          .custom(name: "rows", value: "2")
        ) { HTMLText(instructor?.bio ?? "") }
      }

      input(
        .type(.hidden),
        .name("\(prefix)_iconUrl"), .id("\(prefix)_iconUrl"),
        .value(instructor?.iconURL ?? "")
      )
    }
  }

  private func speakerInfoSection(proposal: ProposalDTO) -> some HTML {
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) { "Speaker Information" }
        p(.class("text-muted small mb-3")) {
          "Edit the speaker information for this proposal."
        }
        div(.class("row")) {
          speakerTextFields(proposal: proposal)
          speakerIconField(iconURL: proposal.iconURL)
        }
      }
    }
  }

  private func speakerTextFields(proposal: ProposalDTO) -> some HTML {
    div(.class("col-md-8")) {
      speakerNameField(value: proposal.speakerName)
      speakerEmailField(value: proposal.speakerEmail)
      githubUsernameField(proposal: proposal)
      speakerBioField(value: proposal.bio)
    }
  }

  private func speakerNameField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("speakerName")) {
        "Name *"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("speakerName"),
        .id("speakerName"),
        .required,
        .value(value),
        .placeholder("Speaker display name")
      )
    }
  }

  private func speakerEmailField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("speakerEmail")) {
        "Email *"
      }
      input(
        .type(.email),
        .class("form-control"),
        .name("speakerEmail"),
        .id("speakerEmail"),
        .required,
        .value(value),
        .placeholder("speaker@email.com")
      )
      div(.class("form-text")) {
        "Used to contact the speaker about their proposal."
      }
    }
  }

  private func speakerBioField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("bio")) {
        "Speaker Bio *"
      }
      textarea(
        .class("form-control"),
        .name("bio"),
        .id("bio"),
        .custom(name: "rows", value: "3"),
        .required,
        .placeholder("Speaker biography")
      ) {
        HTMLText(value)
      }
    }
  }

  private func githubUsernameField(proposal: ProposalDTO) -> some HTML {
    let currentValue =
      proposal.speakerUsername == "papercall-import" ? "" : proposal.speakerUsername
    return div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("githubUsername")) {
        "GitHub Username"
      }
      div(.class("input-group")) {
        span(.class("input-group-text")) { "@" }
        input(
          .type(.text),
          .class("form-control"),
          .name("githubUsername"),
          .id("githubUsername"),
          .value(currentValue),
          .placeholder("e.g. octocat")
        )
      }
      div(.class("form-text")) {
        "Link this proposal to a GitHub user account. "
        "The user must have logged in at least once. "
        "Leave blank to unlink."
      }
    }
  }

  private func speakerIconField(iconURL: String?) -> some HTML {
    div(.class("col-md-4")) {
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("iconUrl")) {
          "Profile Picture URL"
        }
        input(
          .type(.url),
          .class("form-control"),
          .name("iconUrl"),
          .id("iconUrl"),
          .value(iconURL ?? ""),
          .placeholder("https://example.com/photo.jpg"),
          .custom(name: "oninput", value: "updateIconPreview(this.value)")
        )
      }
      iconPreview(iconURL: iconURL)
    }
  }

  private func iconPreview(iconURL: String?) -> some HTML {
    div(.class("text-center mt-3")) {
      p(.class("text-muted small mb-2")) { "Preview:" }
      img(
        .id("iconPreview"),
        .src(iconURL ?? ""),
        .alt("Profile picture preview"),
        .class("rounded-circle border"),
        .style("width: 100px; height: 100px; object-fit: cover;")
      )
    }
  }

  private func deleteCard(proposal: ProposalDTO) -> some HTML {
    div(.class("card mt-4 border-danger")) {
      div(.class("card-header bg-danger text-white")) {
        strong { "Danger Zone" }
      }
      div(.class("card-body")) {
        h5(.class("card-title text-danger")) { "Delete this proposal" }
        p(.class("text-muted mb-3")) {
          "Once deleted, this proposal cannot be recovered. "
          "Any associated timetable slots will be unlinked."
        }
        form(
          .method(.post),
          .action("/organizer/proposals/\(proposal.id.uuidString)/delete"),
          .custom(
            name: "onsubmit",
            value:
              "return confirm('Are you sure you want to delete this proposal? This action cannot be undone.');"
          )
        ) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          button(.type(.submit), .class("btn btn-danger")) {
            "Delete Proposal"
          }
        }
      }
    }
  }

  private func notesField(value: String?) -> some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("notesToOrganizers")) {
        "Notes for Organizers (Optional)"
      }
      textarea(
        .class("form-control"),
        .name("notesToOrganizers"),
        .id("notesToOrganizers"),
        .custom(name: "rows", value: "2"),
        .placeholder("Any special requirements or additional information")
      ) {
        if let value {
          HTMLText(value)
        }
      }
    }
  }

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        "Update Proposal"
      }
    }
  }

  private var notFoundCard: some HTML {
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

  private var accessDeniedCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) { "Access Denied" }
        p(.class("text-muted mb-4")) {
          "You need organizer permissions to access this page."
        }
        a(.class("btn btn-primary"), .href("/")) { "Return to Home" }
      }
    }
  }

  private var previewScript: some HTML {
    HTMLRaw(
      """
      <script>
        function updateIconPreview(url) {
          var preview = document.getElementById('iconPreview');
          if (url && url.trim() !== '') { preview.src = url; }
        }
        document.addEventListener('DOMContentLoaded', function() {
          var typeSelect = document.getElementById('talkDuration');
          if (typeSelect) {
            typeSelect.addEventListener('change', function() {
              toggleWorkshopFields(this.value === 'workshop');
            });
          }
        });
        function toggleWorkshopFields(show) {
          var workshopFields = document.getElementById('workshopFields');
          var coInstructorFields = document.getElementById('coInstructorFields');
          if (workshopFields) {
            workshopFields.style.display = show ? 'block' : 'none';
            workshopFields.querySelectorAll('[data-workshop-required]').forEach(function(el) {
              if (show) { el.setAttribute('required', ''); } else { el.removeAttribute('required'); }
            });
          }
          if (coInstructorFields) { coInstructorFields.style.display = show ? 'block' : 'none'; }
        }
        function showInstructor3() {
          document.getElementById('coInstructor3Block').style.display = 'block';
          document.getElementById('addInstructor3Btn').style.display = 'none';
          document.getElementById('removeInstructor3Btn').style.display = 'inline-block';
        }
        function hideInstructor3() {
          document.getElementById('coInstructor3Block').style.display = 'none';
          document.getElementById('addInstructor3Btn').style.display = 'inline-block';
          document.getElementById('removeInstructor3Btn').style.display = 'none';
          ['_githubUsername', '_name', '_email', '_sns', '_bio', '_iconUrl'].forEach(function(suffix) {
            var el = document.getElementById('coInstructor3' + suffix);
            if (el) el.value = '';
          });
        }
        function toggleFacilityOther(show) {
          document.getElementById('workshop_facilityOther').style.display = show ? 'block' : 'none';
        }
        async function lookupCoInstructor(index) {
          var prefix = 'coInstructor' + index;
          var usernameField = document.getElementById(prefix + '_githubUsername');
          var statusDiv = document.getElementById(prefix + '_lookupStatus');
          var username = usernameField ? usernameField.value.trim() : '';
          if (!username) { statusDiv.innerHTML = '<span class="text-danger">Please enter a GitHub username.</span>'; return; }
          statusDiv.innerHTML = '<span class="text-muted">Looking up...</span>';
          try {
            var response = await fetch('/api/user-lookup/' + encodeURIComponent(username));
            if (response.ok) {
              var data = await response.json();
              if (data.name) document.getElementById(prefix + '_name').value = data.name;
              if (data.email) document.getElementById(prefix + '_email').value = data.email;
              if (data.bio) document.getElementById(prefix + '_bio').value = data.bio;
              if (data.avatarURL) document.getElementById(prefix + '_iconUrl').value = data.avatarURL;
              statusDiv.innerHTML = '<span class="text-success">User found! Info pre-filled.</span>';
            } else if (response.status === 404) {
              document.getElementById(prefix + '_iconUrl').value = 'https://github.com/' + username + '.png';
              statusDiv.innerHTML = '<span class="text-warning">User not found. Please fill in manually.</span>';
            } else {
              statusDiv.innerHTML = '<span class="text-danger">Lookup failed.</span>';
            }
          } catch (e) { statusDiv.innerHTML = '<span class="text-danger">Lookup error.</span>'; }
        }
      </script>
      """)
  }
}
