import Elementary
import SharedModels

struct OrganizerNewProposalPageView: HTML, Sendable {
  let user: UserDTO?
  let conferences: [ConferencePublicInfo]
  let errorMessage: String?
  let csrfToken: String

  init(
    user: UserDTO?,
    conferences: [ConferencePublicInfo],
    errorMessage: String? = nil,
    csrfToken: String = ""
  ) {
    self.user = user
    self.conferences = conferences
    self.errorMessage = errorMessage
    self.csrfToken = csrfToken
  }

  var body: some HTML {
    div(.class("container py-5")) {
      if let user, user.role == .admin {
        pageHeader
        errorAlert
        newProposalFormCard
      } else {
        accessDeniedCard
      }
    }
    previewScript
  }

  private var pageHeader: some HTML {
    div {
      div(.class("mb-4")) {
        a(
          .class("btn btn-outline-secondary"),
          .href("/organizer/proposals")
        ) {
          "<- Back to All Proposals"
        }
      }
      h1(.class("fw-bold mb-2")) { "Add Proposal" }
      p(.class("lead text-muted mb-4")) {
        "Manually add a proposal that was not imported from PaperCall or Google Sheets."
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

  private var newProposalFormCard: some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        newProposalForm
      }
    }
  }

  private var newProposalForm: some HTML {
    form(
      .method(.post),
      .action("/organizer/proposals/new")
    ) {
      input(.type(.hidden), .name("_csrf"), .value(csrfToken))
      conferenceField
      titleField
      abstractField
      talkDetailsField
      durationField
      speakerInfoSection
      githubUsernameField
      notesField
      submitButton
    }
  }

  private var conferenceField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("conferenceId")) {
        "Conference *"
      }
      select(.class("form-select"), .name("conferenceId"), .id("conferenceId"), .required) {
        option(.value("")) { "Select conference..." }
        for conf in conferences {
          option(.value(conf.id.uuidString)) {
            HTMLText(conf.displayName)
          }
        }
      }
    }
  }

  private var titleField: some HTML {
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
        .placeholder("Enter talk title")
      )
    }
  }

  private var abstractField: some HTML {
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
      ) { "" }
      div(.class("form-text")) {
        "This will be shown to the audience if the talk is accepted."
      }
    }
  }

  private var talkDetailsField: some HTML {
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
      ) { "" }
      div(.class("form-text")) {
        "Include outline, key points, and what attendees will learn. For reviewers only."
      }
    }
  }

  private var durationField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("talkDuration")) {
        "Talk Duration *"
      }
      select(
        .class("form-select"), .name("talkDuration"), .id("talkDuration"), .required
      ) {
        option(.value("")) { "Choose duration..." }
        for duration in TalkDuration.allCases {
          option(.value(duration.rawValue)) {
            HTMLText(duration.displayName)
          }
        }
      }
    }
  }

  private var speakerInfoSection: some HTML {
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) { "Speaker Information" }
        p(.class("text-muted small mb-3")) {
          "Enter the speaker information for this proposal."
        }
        div(.class("row")) {
          speakerTextFields
          speakerIconField
        }
      }
    }
  }

  private var speakerTextFields: some HTML {
    div(.class("col-md-8")) {
      speakerNameField
      speakerEmailField
      speakerBioField
    }
  }

  private var speakerNameField: some HTML {
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
        .placeholder("Speaker display name")
      )
    }
  }

  private var speakerEmailField: some HTML {
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
        .placeholder("speaker@email.com")
      )
      div(.class("form-text")) {
        "Used to contact the speaker about their proposal."
      }
    }
  }

  private var speakerBioField: some HTML {
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
      ) { "" }
    }
  }

  private var speakerIconField: some HTML {
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
          .placeholder("https://example.com/photo.jpg"),
          .custom(name: "oninput", value: "updateIconPreview(this.value)")
        )
      }
      iconPreview
    }
  }

  private var iconPreview: some HTML {
    div(.class("text-center mt-3")) {
      p(.class("text-muted small mb-2")) { "Preview:" }
      img(
        .id("iconPreview"),
        .src(""),
        .alt("Profile picture preview"),
        .class("rounded-circle border"),
        .style("width: 100px; height: 100px; object-fit: cover;")
      )
    }
  }

  private var githubUsernameField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("githubUsername")) {
        "GitHub Username (Optional)"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("githubUsername"),
        .id("githubUsername"),
        .placeholder("e.g. octocat")
      )
      div(.class("form-text")) {
        "If specified, the proposal will be linked to this GitHub user account. "
        "Leave blank to use the system import user."
      }
    }
  }

  private var notesField: some HTML {
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
      ) { "" }
    }
  }

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        "Add Proposal"
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
