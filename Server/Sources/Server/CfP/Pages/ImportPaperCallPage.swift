import Elementary
import SharedModels

struct ImportPaperCallPageView: HTML, Sendable {
  let user: UserDTO?
  let conferences: [ConferencePublicInfo]
  let errorMessage: String?
  let successMessage: String?
  let importedCount: Int?
  let skippedCount: Int?

  init(
    user: UserDTO?,
    conferences: [ConferencePublicInfo],
    errorMessage: String? = nil,
    successMessage: String? = nil,
    importedCount: Int? = nil,
    skippedCount: Int? = nil
  ) {
    self.user = user
    self.conferences = conferences
    self.errorMessage = errorMessage
    self.successMessage = successMessage
    self.importedCount = importedCount
    self.skippedCount = skippedCount
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
      // Back button
      div(.class("mb-4")) {
        a(.class("btn btn-outline-secondary"), .href("/organizer/proposals")) {
          "<- Back to All Proposals"
        }
      }
      h1(.class("fw-bold mb-2")) { "Import from PaperCall.io" }
      p(.class("lead text-muted mb-4")) {
        "Upload a CSV file exported from PaperCall.io to import proposals."
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
        HTMLText("\(imported) proposals imported, \(skipped) duplicates skipped.")
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
          conferenceField
          csvFileField
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
        "All imported proposals will be associated with this conference."
      }
    }
  }

  private var csvFileField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("csvFile")) {
        "CSV File *"
      }
      input(
        .type(.file),
        .class("form-control"),
        .name("csvFile"),
        .id("csvFile"),
        .required,
        .custom(name: "accept", value: ".csv,text/csv")
      )
      div(.class("form-text")) {
        "Supported formats: PaperCall.io standard export or custom export with columns: ID, Title, Abstract, etc."
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
          "Skip duplicate entries (based on PaperCall ID)"
        }
      }
    }
  }

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        "Import Proposals"
      }
    }
  }

  private var csvFormatHelp: some HTML {
    div(.class("card mt-4")) {
      div(.class("card-header")) {
        strong { "CSV Format Reference" }
      }
      div(.class("card-body")) {
        p { "Two CSV formats are supported:" }
        div(.class("mb-3")) {
          p(.class("fw-semibold mb-2")) { "1. PaperCall.io Standard Export (recommended)" }
          HTMLRaw(
            """
            <pre class="bg-light p-3 rounded"><code>name,email,avatar,location,bio,twitter,url,organization,shirt_size,talk_format,title,abstract,description,notes,audience_level,tags,rating,state,confirmed,created_at,additional_info</code></pre>
            """)
          p(.class("text-muted small")) {
            "This is the default export format from PaperCall.io's proposal export feature."
          }
        }
        div {
          p(.class("fw-semibold mb-2")) { "2. Custom Export Format" }
          HTMLRaw(
            """
            <pre class="bg-light p-3 rounded"><code>ID,Title,Abstract,Talk Details,Duration,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At</code></pre>
            """)
          p(.class("text-muted small")) {
            "Use this format if you're manually creating or transforming the CSV."
          }
        }
        div(.class("alert alert-warning mt-3 mb-0")) {
          strong { "Note: " }
          "Imported proposals will be associated with a system user (papercall-import) since they don't have GitHub accounts. You can edit the proposals after import using the Edit function."
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
