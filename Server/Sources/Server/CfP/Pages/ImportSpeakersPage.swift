import Elementary
import SharedModels

struct ImportSpeakersPageView: HTML, Sendable {
  let user: UserDTO?
  let conferences: [ConferencePublicInfo]
  let errorMessage: String?
  let successMessage: String?
  let importedCount: Int?
  let skippedCount: Int?
  let csrfToken: String

  init(
    user: UserDTO?,
    conferences: [ConferencePublicInfo],
    errorMessage: String? = nil,
    successMessage: String? = nil,
    importedCount: Int? = nil,
    skippedCount: Int? = nil,
    csrfToken: String = ""
  ) {
    self.user = user
    self.conferences = conferences
    self.errorMessage = errorMessage
    self.successMessage = successMessage
    self.importedCount = importedCount
    self.skippedCount = skippedCount
    self.csrfToken = csrfToken
  }

  var body: some HTML {
    div(.class("container py-5")) {
      if let user, user.role == .admin {
        pageHeader
        alerts
        importFormCard
        csvFormatHelp
      } else {
        accessDeniedCard
      }
    }
  }

  private var pageHeader: some HTML {
    div {
      div(.class("mb-4")) {
        a(.class("btn btn-outline-secondary"), .href("/organizer/proposals")) {
          "<- Back to All Proposals"
        }
      }
      h1(.class("fw-bold mb-2")) { "Import Speaker Candidates" }
      p(.class("lead text-muted mb-4")) {
        "Upload a CSV or JSON file to import speaker candidates."
      }
    }
  }

  @HTMLBuilder
  private var alerts: some HTML {
    if let errorMessage {
      div(.class("alert alert-danger mb-4")) {
        HTMLText(errorMessage)
      }
    }
    if let successMessage {
      div(.class("alert alert-success mb-4")) {
        HTMLText(successMessage)
      }
    }
    if let imported = importedCount, let skipped = skippedCount {
      div(.class("alert alert-info mb-4")) {
        strong { "Import completed: " }
        HTMLText("\(imported) candidates imported, \(skipped) duplicates skipped.")
      }
    }
  }

  private var importFormCard: some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        form(
          .method(.post),
          .action("/organizer/proposals/import"),
          .custom(name: "enctype", value: "multipart/form-data")
        ) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          conferenceField
          csvFileField
          githubUsernameField
          optionsField
          submitButton
        }
      }
    }
  }

  private var conferenceField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("conferenceId")) {
        "Target Conference *"
      }
      select(.class("form-select"), .name("conferenceId"), .id("conferenceId"), .required) {
        option(.value("")) { "Select conference..." }
        for conf in conferences {
          option(.value(conf.id.uuidString)) {
            HTMLText(conf.displayName)
          }
        }
      }
      div(.class("form-text")) {
        "All imported candidates will be associated with this conference."
      }
    }
  }

  private var csvFileField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("csvFile")) {
        "CSV / JSON File *"
      }
      input(
        .type(.file),
        .class("form-control"),
        .name("csvFile"),
        .id("csvFile"),
        .required,
        .custom(name: "accept", value: ".csv,.json,text/csv,application/json")
      )
      div(.class("form-text")) {
        "Supported formats: Google Form CSV export or PaperCall.io JSON export."
      }
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
        "If specified, all imported proposals will be linked to this GitHub user account. "
        "Leave blank to use the system import user."
      }
    }
  }

  private var optionsField: some HTML {
    div(.class("mb-4")) {
      div(.class("form-check")) {
        input(
          .type(.checkbox),
          .class("form-check-input"),
          .name("skipDuplicates"),
          .id("skipDuplicates"),
          .value("true"),
          .checked
        )
        label(.class("form-check-label"), .for("skipDuplicates")) {
          "Skip duplicate entries (based on speaker email and talk title)"
        }
      }
    }
  }

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        "Import Candidates"
      }
    }
  }

  private var csvFormatHelp: some HTML {
    div(.class("card mt-4")) {
      div(.class("card-header")) {
        strong { "Format Reference" }
      }
      div(.class("card-body")) {
        p { "Two formats are supported:" }
        div(.class("mb-3")) {
          p(.class("fw-semibold mb-2")) { "1. Google Form CSV Export" }
          HTMLRaw(
            """
            <pre class="bg-light p-3 rounded" style="white-space: pre-wrap;"><code>タイムスタンプ, Email, Your Name / お名前, メールアドレス, You want to…, SNS, GitHub, Short Bio / 自己紹介, Expertise / 専門性, Links of your speaking experience, Where are you currently located?, Company support?, Title of your talk, Summary, Talk Detail for organizers, ...</code></pre>
            """)
          p(.class("text-muted small")) {
            "CSV exported from the Google Form for speaker candidates."
          }
        }
        div(.class("mb-3")) {
          p(.class("fw-semibold mb-2")) { "2. PaperCall.io JSON Export" }
          HTMLRaw(
            """
            <pre class="bg-light p-3 rounded"><code>[{"name":"...","email":"...","avatar":"...","title":"...","abstract":"...","talk_format":"...","description":"...","notes":"...","created_at":"...", ...}]</code></pre>
            """)
          p(.class("text-muted small")) {
            "JSON array of proposal objects exported from PaperCall.io."
          }
        }
        div(.class("alert alert-warning mt-3 mb-0")) {
          strong { "Note: " }
          "Imported candidates will be associated with a system user since they don't have CfP accounts. You can edit the proposals after import using the Edit function on each proposal detail page."
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
}
