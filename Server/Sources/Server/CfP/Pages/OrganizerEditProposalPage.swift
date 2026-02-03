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
      speakerInfoSection(proposal: proposal)
      githubUsernameField(value: proposal.speakerUsername)
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
        "Talk Duration *"
      }
      select(
        .class("form-select"), .name("talkDuration"), .id("talkDuration"), .required
      ) {
        option(.value("")) { "Choose duration..." }
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

  private func githubUsernameField(value: String) -> some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("githubUsername")) {
        "GitHub Username (Optional)"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("githubUsername"),
        .id("githubUsername"),
        .value(value == "papercall-import" ? "" : value),
        .placeholder("e.g. octocat")
      )
      div(.class("form-text")) {
        "If specified, the proposal will be linked to this GitHub user account. "
        "Leave blank to keep the current association."
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
          const preview = document.getElementById('iconPreview');
          if (url && url.trim() !== '') {
            preview.src = url;
          }
        }
      </script>
      """)
  }
}
