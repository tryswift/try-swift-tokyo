import Elementary

struct PageContent: HTML, Sendable {
  let page: CfPPage

  var body: some HTML {
    section(.class("hero-card")) {
      h1 { HTMLText(page.title) }
      p(.id("page-description")) { HTMLText(description) }
    }

    section(.class("status-card")) {
      h2 { "Session" }
      p(.id("auth-status")) { "Checking sign-in state..." }
    }

    switch page {
    case .home:
      section(.class("card-grid")) {
        FeatureCard(
          title: "API-driven auth",
          copy: "This frontend reads session state from /api/v1/auth/me and never inspects auth cookies directly."
        )
        FeatureCard(
          title: "Speaker workflows",
          copy: "Proposal creation, update, withdraw, and profile updates are intended to move to API-backed requests."
        )
        FeatureCard(
          title: "Organizer workflows",
          copy: "Organizer proposal and timetable operations now have dedicated /api/v1/admin endpoints."
        )
      }
    case .guidelines:
      section(.class("detail-card")) {
        p { "This page is now an independent frontend route and can later be enriched without coupling to the API server renderer." }
      }
    case .login:
      section(.class("detail-card")) {
        p { "Login starts at the API domain and returns back to the current web app route." }
      }
    case .profile:
      section(.class("page-grid")) {
        article(.class("detail-card")) {
          h3 { "Speaker Profile" }
          p { "This page reads and updates your profile through /api/v1/auth/me." }
          FormStatus(id: "profile-status")
          form(.id("profile-form"), .class("app-form")) {
            div(.class("form-grid")) {
              FormField(
                label: "Display Name",
                field: input(.type(.text), .name("displayName"))
              )
              FormField(
                label: "Email",
                field: input(.type(.email), .name("email"))
              )
            }
            FormField(label: "Bio", field: textarea(.name("bio"), .custom(name: "rows", value: "6")) {})
            div(.class("form-grid")) {
              FormField(
                label: "Website URL",
                field: input(.type(.url), .name("url"))
              )
              FormField(
                label: "Organization",
                field: input(.type(.text), .name("organization"))
              )
            }
            FormField(
              label: "Avatar URL",
              field: input(.type(.url), .name("avatarURL"))
            )
            div(.class("form-actions")) {
              button(.type(.submit), .class("button secondary")) { "Save Profile" }
            }
          }
        }
        article(.class("detail-card")) {
          h3 { "Why this matters" }
          ul(.class("plain-list")) {
            li { "The web app no longer needs to read cookies or server-side session state." }
            li { "Speaker defaults for submit pages can come from this profile response." }
            li { "The API remains the single source of truth for auth and user data." }
          }
        }
      }
    case .submit:
      section(.class("page-grid")) {
        article(.class("detail-card")) {
          h3 { "Submit a Proposal" }
          p { "This form posts directly to the API. It uses the active conference list from /api/v1/conferences/open." }
          FormStatus(id: "submit-status")
          form(.id("submit-form"), .class("app-form")) {
            div(.class("form-grid")) {
              FormField(
                label: "Conference",
                field: select(.name("conferencePath"), .id("submit-conference-path")) {}
              )
              FormField(
                label: "Talk Duration",
                field: select(.name("talkDuration"), .required, .id("submit-talk-duration")) {
                  option(.value("20min")) { "20 minutes" }
                  option(.value("LT")) { "Lightning Talk" }
                  option(.value("workshop")) { "Workshop" }
                  option(.value("invited")) { "Invited" }
                }
              )
            }
            FormField(label: "Title", field: input(.type(.text), .name("title"), .required))
            FormField(
              label: "Abstract",
              field: textarea(.name("abstract"), .required, .custom(name: "rows", value: "5")) {}
            )
            FormField(
              label: "Talk Detail",
              field: textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "8")) {}
            )
            WorkshopFields(prefix: "submit")
            div(.class("form-grid")) {
              FormField(
                label: "Speaker Name",
                field: input(.type(.text), .name("speakerName"), .required)
              )
              FormField(
                label: "Speaker Email",
                field: input(.type(.email), .name("speakerEmail"), .required)
              )
            }
            FormField(label: "Bio", field: textarea(.name("bio"), .required, .custom(name: "rows", value: "6")) {})
            div(.class("form-grid")) {
              FormField(
                label: "Avatar URL",
                field: input(.type(.url), .name("iconURL"))
              )
              FormField(
                label: "Notes",
                field: input(.type(.text), .name("notes"))
              )
            }
            div(.class("form-actions")) {
              button(.type(.submit), .class("button secondary")) { "Submit Proposal" }
            }
          }
        }
        article(.class("detail-card")) {
          h3 { "Submission Notes" }
          ul(.class("plain-list")) {
            li { "Unauthenticated visitors will be asked to sign in first." }
            li { "The API owns validation, authorization, and proposal persistence." }
            li { "The web app now handles only page state, form input, and errors." }
          }
        }
      }
    case .workshops:
      section(.class("page-grid")) {
        article(.class("detail-card")) {
          div(.class("section-heading")) {
            h3 { "Workshop Catalog" }
            button(.type(.button), .class("button ghost"), .id("workshops-refresh")) { "Refresh" }
          }
          FormStatus(id: "workshops-status")
          div(.id("workshop-list"), .class("proposal-list")) {}
        }
        article(.class("detail-card")) {
          h3 { "Verify Ticket" }
          p { "Workshop applications stay API-driven. First verify your conference ticket, then choose your workshop." }
          FormStatus(id: "workshop-verify-status")
          form(.id("workshop-verify-form"), .class("app-form")) {
            FormField(
              label: "Ticket Email",
              field: input(.type(.email), .name("email"), .required)
            )
            div(.class("form-actions")) {
              button(.type(.submit), .class("button secondary")) { "Verify Ticket" }
            }
          }
          form(
            .id("workshop-apply-form"),
            .class("app-form"),
            .custom(name: "hidden", value: "hidden")
          ) {
            input(.type(.hidden), .name("verifyToken"))
            FormField(
              label: "Applicant Name",
              field: input(.type(.text), .name("applicantName"), .required)
            )
            FormField(
              label: "First Choice",
              field: select(.name("firstChoiceID"), .required, .id("workshop-first-choice")) {}
            )
            FormField(
              label: "Second Choice",
              field: select(.name("secondChoiceID"), .id("workshop-second-choice")) {}
            )
            FormField(
              label: "Third Choice",
              field: select(.name("thirdChoiceID"), .id("workshop-third-choice")) {}
            )
            div(.class("form-actions")) {
              button(.type(.submit), .class("button secondary")) { "Apply for Workshop" }
            }
          }
        }
      }
      section(.class("page-grid")) {
        article(.class("detail-card")) {
          h3 { "Check Application Status" }
          FormStatus(id: "workshop-status-check-status")
          form(.id("workshop-status-form"), .class("app-form")) {
            FormField(
              label: "Application Email",
              field: input(.type(.email), .name("email"), .required)
            )
            div(.class("form-actions")) {
              button(.type(.submit), .class("button ghost")) { "Check Status" }
            }
          }
        }
        article(.class("detail-card")) {
          h3 { "Application Snapshot" }
          div(.id("workshop-status-result"), .class("empty-state")) {
            p { "Verify your ticket or check your status to load your current workshop application." }
          }
        }
      }
    case .myProposals:
      section(.class("page-grid")) {
        article(.class("detail-card")) {
          div(.class("section-heading")) {
            h3 { "My Proposals" }
            button(.type(.button), .class("button ghost"), .id("my-proposals-refresh")) { "Refresh" }
          }
          FormStatus(id: "my-proposals-status")
          div(.id("my-proposals-empty"), .class("empty-state")) {
            p { "Your proposals will appear here after sign-in." }
          }
          div(.id("my-proposals-list"), .class("proposal-list")) {}
        }
        article(.class("detail-card")) {
          h3 { "Edit Proposal" }
          p { "Select a proposal from the list to edit or withdraw it." }
          FormStatus(id: "proposal-editor-status")
          form(
            .id("proposal-editor-form"),
            .class("app-form"),
            .custom(name: "hidden", value: "hidden")
          ) {
            input(.type(.hidden), .name("proposalID"), .id("editor-proposal-id"))
            div(.class("form-grid")) {
              FormField(
                label: "Talk Duration",
                field: select(.name("talkDuration"), .required) {
                  option(.value("20min")) { "20 minutes" }
                  option(.value("LT")) { "Lightning Talk" }
                  option(.value("workshop")) { "Workshop" }
                  option(.value("invited")) { "Invited" }
                }
              )
              FormField(
                label: "Avatar URL",
                field: input(.type(.url), .name("iconURL"))
              )
            }
            FormField(label: "Title", field: input(.type(.text), .name("title"), .required))
            FormField(
              label: "Abstract",
              field: textarea(.name("abstract"), .required, .custom(name: "rows", value: "5")) {}
            )
            FormField(
              label: "Talk Detail",
              field: textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "8")) {}
            )
            WorkshopFields(prefix: "speaker-edit")
            div(.class("form-grid")) {
              FormField(
                label: "Speaker Name",
                field: input(.type(.text), .name("speakerName"), .required)
              )
              FormField(
                label: "Speaker Email",
                field: input(.type(.email), .name("speakerEmail"), .required)
              )
            }
            FormField(label: "Bio", field: textarea(.name("bio"), .required, .custom(name: "rows", value: "6")) {})
            FormField(label: "Notes", field: input(.type(.text), .name("notes")))
            div(.class("form-actions split")) {
              button(.type(.submit), .class("button secondary")) { "Save Changes" }
              button(.type(.button), .class("button danger"), .id("proposal-withdraw-button")) { "Withdraw Proposal" }
            }
          }
          div(.id("proposal-editor-placeholder"), .class("empty-state")) {
            p { "Choose a proposal to load it into the editor." }
          }
        }
      }
    case .feedback:
      section(.class("page-grid")) {
        article(.class("detail-card")) {
          div(.class("section-heading")) {
            h3 { "Talk Feedback" }
            button(.type(.button), .class("button ghost"), .id("feedback-refresh")) { "Refresh" }
          }
          FormStatus(id: "feedback-status")
          div(.id("feedback-empty"), .class("empty-state")) {
            p { "Feedback for your talks will appear here." }
          }
          div(.id("feedback-list"), .class("proposal-list")) {}
        }
        article(.class("detail-card")) {
          h3 { "Feedback Flow" }
          ul(.class("plain-list")) {
            li { "Audience comments stay anonymous, but speakers can review them after sign-in." }
            li { "The page uses /api/v1/feedback/my-talks as the single source of truth." }
            li { "No server-rendered feedback page is needed once this route is in place." }
          }
        }
      }
    case .organizer:
      section(.class("organizer-stack")) {
        div(.class("page-grid")) {
          article(.class("detail-card")) {
            div(.class("section-heading")) {
              h3 { "Organizer Proposal Desk" }
              button(.type(.button), .class("button ghost"), .id("organizer-refresh")) { "Refresh" }
            }
            FormStatus(id: "organizer-status")
            div(.class("toolbar-row")) {
              FormField(
                label: "Conference Filter",
                field: select(.id("organizer-conference-filter")) {}
              )
            }
            div(.id("organizer-proposals"), .class("proposal-list")) {}
          }
          article(.class("detail-card")) {
            h3 { "Create Proposal as Organizer" }
            FormStatus(id: "organizer-create-status")
            form(.id("organizer-create-form"), .class("app-form")) {
              div(.class("form-grid")) {
                FormField(
                  label: "Conference",
                  field: select(.name("conferenceId"), .required, .id("organizer-conference-id")) {}
                )
                FormField(
                  label: "Talk Duration",
                  field: select(.name("talkDuration"), .required) {
                    option(.value("20min")) { "20 minutes" }
                    option(.value("LT")) { "Lightning Talk" }
                    option(.value("workshop")) { "Workshop" }
                    option(.value("invited")) { "Invited" }
                  }
                )
              }
              FormField(
                label: "GitHub Username",
                field: input(.type(.text), .name("githubUsername"), .id("organizer-github-username"))
              )
              FormField(label: "Title", field: input(.type(.text), .name("title"), .required))
              FormField(
                label: "Abstract",
                field: textarea(.name("abstract"), .required, .custom(name: "rows", value: "4")) {}
              )
              FormField(
                label: "Talk Detail",
                field: textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "6")) {}
              )
              WorkshopFields(prefix: "organizer-create")
              div(.class("form-grid")) {
                FormField(
                  label: "Speaker Name",
                  field: input(.type(.text), .name("speakerName"), .required, .id("organizer-speaker-name"))
                )
                FormField(
                  label: "Speaker Email",
                  field: input(.type(.email), .name("speakerEmail"), .required, .id("organizer-speaker-email"))
                )
              }
              FormField(
                label: "Bio",
                field: textarea(.name("bio"), .required, .custom(name: "rows", value: "5"), .id("organizer-speaker-bio")) {}
              )
              div(.class("form-grid")) {
                FormField(
                  label: "Avatar URL",
                  field: input(.type(.url), .name("iconURL"), .id("organizer-speaker-avatar"))
                )
                FormField(
                  label: "Notes",
                  field: input(.type(.text), .name("notes"))
                )
              }
              div(.class("form-actions split")) {
                button(.type(.button), .class("button ghost"), .id("organizer-lookup-button")) { "Lookup User" }
                button(.type(.submit), .class("button secondary")) { "Create Proposal" }
              }
            }
          }
        }
        div(.class("page-grid")) {
          article(.class("detail-card")) {
            h3 { "Import and Export" }
            FormStatus(id: "organizer-import-status")
            form(
              .id("organizer-import-form"),
              .class("app-form"),
              .custom(name: "enctype", value: "multipart/form-data")
            ) {
              div(.class("form-grid")) {
                FormField(
                  label: "Conference",
                  field: select(.name("conferenceId"), .required, .id("organizer-import-conference-id")) {}
                )
                FormField(
                  label: "GitHub Username Override",
                  field: input(.type(.text), .name("githubUsername"))
                )
              }
              FormField(
                label: "Proposal File",
                field: input(.type(.file), .name("csvFile"), .accept(".csv,.json"), .required)
              )
              label(.class("checkbox-row")) {
                input(.type(.checkbox), .name("skipDuplicates"))
                span { "Skip rows that already exist" }
              }
              div(.class("form-actions")) {
                button(.type(.submit), .class("button secondary")) { "Import File" }
              }
            }
            div(.class("export-links")) {
              a(.href("#"), .class("button ghost"), .id("export-proposals-link")) { "Export Proposals CSV" }
              a(.href("#"), .class("button ghost"), .id("export-speakers-link")) { "Export Speakers JSON" }
              a(.href("#"), .class("button ghost"), .id("export-timetable-link")) { "Export Timetable JSON" }
            }
          }
          article(.class("detail-card")) {
            h3 { "Timetable" }
            FormStatus(id: "organizer-timetable-status")
            form(.id("organizer-slot-form"), .class("app-form")) {
              div(.class("form-grid")) {
                FormField(
                  label: "Conference",
                  field: select(.name("conferenceId"), .required, .id("organizer-slot-conference-id")) {}
                )
                FormField(
                  label: "Day",
                  field: input(.type(.number), .name("day"), .required, .value("1"), .custom(name: "min", value: "1"))
                )
              }
              div(.class("form-grid")) {
                FormField(
                  label: "Slot Type",
                  field: select(.name("slotType"), .required) {
                    option(.value("talk")) { "Talk" }
                    option(.value("lightning_talk")) { "Lightning Talk" }
                    option(.value("break")) { "Break" }
                    option(.value("lunch")) { "Lunch" }
                    option(.value("opening")) { "Opening" }
                    option(.value("closing")) { "Closing" }
                    option(.value("party")) { "Party" }
                    option(.value("custom")) { "Custom" }
                  }
                )
                FormField(
                  label: "Proposal",
                  field: select(.name("proposalId"), .id("organizer-slot-proposal-id")) {}
                )
              }
              div(.class("form-grid")) {
                FormField(
                  label: "Start Time",
                  field: input(.type(.datetimeLocal), .name("startTime"), .required)
                )
                FormField(
                  label: "End Time",
                  field: input(.type(.datetimeLocal), .name("endTime"))
                )
              }
              div(.class("form-grid")) {
                FormField(
                  label: "Custom Title",
                  field: input(.type(.text), .name("customTitle"))
                )
                FormField(
                  label: "Place",
                  field: input(.type(.text), .name("place"))
                )
              }
              div(.class("form-actions")) {
                button(.type(.submit), .class("button secondary")) { "Add Timetable Slot" }
              }
            }
            div(.class("toolbar-row")) {
              FormField(
                label: "Timetable Conference",
                field: select(.id("organizer-slot-conference-filter")) {}
              )
            }
            div(.id("organizer-slot-list"), .class("proposal-list compact-list")) {}
          }
        }
        article(.class("detail-card")) {
          div(.class("section-heading")) {
            h3 { "Edit Selected Slot" }
            button(.type(.button), .class("button ghost"), .id("organizer-slot-editor-reset")) { "Clear" }
          }
          FormStatus(id: "organizer-slot-editor-status")
          form(
            .id("organizer-slot-editor-form"),
            .class("app-form"),
            .custom(name: "hidden", value: "hidden")
          ) {
            input(.type(.hidden), .name("slotID"))
            div(.class("form-grid")) {
              FormField(
                label: "Day",
                field: input(.type(.number), .name("day"), .required, .custom(name: "min", value: "1"))
              )
              FormField(
                label: "Slot Type",
                field: select(.name("slotType"), .required) {
                  option(.value("talk")) { "Talk" }
                  option(.value("lightning_talk")) { "Lightning Talk" }
                  option(.value("break")) { "Break" }
                  option(.value("lunch")) { "Lunch" }
                  option(.value("opening")) { "Opening" }
                  option(.value("closing")) { "Closing" }
                  option(.value("party")) { "Party" }
                  option(.value("custom")) { "Custom" }
                }
              )
            }
            div(.class("form-grid")) {
              FormField(
                label: "Proposal",
                field: select(.name("proposalId"), .id("organizer-slot-editor-proposal-id")) {}
              )
              FormField(
                label: "Place",
                field: input(.type(.text), .name("place"))
              )
            }
            div(.class("form-grid")) {
              FormField(
                label: "Start Time",
                field: input(.type(.datetimeLocal), .name("startTime"))
              )
              FormField(
                label: "End Time",
                field: input(.type(.datetimeLocal), .name("endTime"))
              )
            }
            FormField(
              label: "Custom Title",
              field: input(.type(.text), .name("customTitle"))
            )
            div(.class("form-actions split")) {
              button(.type(.submit), .class("button secondary")) { "Save Slot" }
              button(.type(.button), .class("button ghost"), .id("organizer-slot-reorder-button")) { "Apply Day Order" }
            }
          }
          div(.id("organizer-slot-editor-placeholder"), .class("empty-state")) {
            p { "Choose a slot from the timetable list to edit its time, type, or order." }
          }
        }
        article(.class("detail-card")) {
          div(.class("section-heading")) {
            h3 { "Edit Selected Proposal" }
            button(.type(.button), .class("button ghost"), .id("organizer-editor-reset")) { "Clear" }
          }
          p { "Select a proposal from the organizer list to load the full editor." }
          FormStatus(id: "organizer-editor-status")
          form(
            .id("organizer-editor-form"),
            .class("app-form"),
            .custom(name: "hidden", value: "hidden")
          ) {
            input(.type(.hidden), .name("proposalID"))
            div(.class("form-grid")) {
              FormField(
                label: "Conference",
                field: select(.name("conferenceId"), .required, .id("organizer-editor-conference-id")) {}
              )
              FormField(
                label: "Talk Duration",
                field: select(.name("talkDuration"), .required) {
                  option(.value("20min")) { "20 minutes" }
                  option(.value("LT")) { "Lightning Talk" }
                  option(.value("workshop")) { "Workshop" }
                  option(.value("invited")) { "Invited" }
                }
              )
            }
            div(.class("form-grid")) {
              FormField(
                label: "GitHub Username",
                field: input(.type(.text), .name("githubUsername"))
              )
              FormField(
                label: "Avatar URL",
                field: input(.type(.url), .name("iconURL"))
              )
            }
            FormField(label: "Title", field: input(.type(.text), .name("title"), .required))
            FormField(
              label: "Title (JA)",
              field: input(.type(.text), .name("titleJA"))
            )
            FormField(
              label: "Abstract",
              field: textarea(.name("abstract"), .required, .custom(name: "rows", value: "4")) {}
            )
            FormField(
              label: "Abstract (JA)",
              field: textarea(.name("abstractJA"), .custom(name: "rows", value: "4")) {}
            )
            FormField(
              label: "Talk Detail",
              field: textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "7")) {}
            )
            WorkshopFields(prefix: "organizer-edit", includeJapaneseFields: true)
            div(.class("form-grid")) {
              FormField(
                label: "Speaker Name",
                field: input(.type(.text), .name("speakerName"), .required)
              )
              FormField(
                label: "Speaker Email",
                field: input(.type(.email), .name("speakerEmail"), .required)
              )
            }
            div(.class("form-grid")) {
              FormField(
                label: "Job Title",
                field: input(.type(.text), .name("jobTitle"))
              )
              FormField(
                label: "Job Title (JA)",
                field: input(.type(.text), .name("jobTitleJa"))
              )
            }
            FormField(label: "Bio", field: textarea(.name("bio"), .required, .custom(name: "rows", value: "5")) {})
            FormField(label: "Bio (JA)", field: textarea(.name("bioJa"), .custom(name: "rows", value: "5")) {})
            FormField(label: "Notes", field: input(.type(.text), .name("notes")))
            div(.class("form-actions split")) {
              button(.type(.submit), .class("button secondary")) { "Save Proposal" }
              button(.type(.button), .class("button danger"), .id("organizer-delete-proposal-button")) { "Delete Proposal" }
            }
          }
          div(.id("organizer-editor-placeholder"), .class("empty-state")) {
            p { "Choose a proposal from the desk to edit it here." }
          }
        }
        div(.class("page-grid")) {
          article(.class("detail-card")) {
            div(.class("section-heading")) {
              h3 { "Workshop Management" }
              button(.type(.button), .class("button ghost"), .id("organizer-workshops-refresh")) { "Refresh" }
            }
            FormStatus(id: "organizer-workshops-status")
            div(.id("organizer-workshops-list"), .class("proposal-list")) {}
            div(.class("form-actions split")) {
              button(.type(.button), .class("button secondary"), .id("organizer-workshop-lottery-button")) { "Run Lottery" }
              button(.type(.button), .class("button ghost"), .id("organizer-workshop-send-tickets-button")) { "Send Luma Tickets" }
            }
          }
          article(.class("detail-card")) {
            div(.class("section-heading")) {
              h3 { "Workshop Applications" }
              button(.type(.button), .class("button ghost"), .id("organizer-workshop-applications-refresh")) { "Refresh" }
            }
            FormStatus(id: "organizer-workshop-applications-status")
            div(.class("toolbar-row")) {
              FormField(
                label: "Workshop Filter",
                field: select(.id("organizer-workshop-filter")) {}
              )
            }
            div(.id("organizer-workshop-applications-list"), .class("proposal-list compact-list")) {}
          }
        }
        article(.class("detail-card")) {
          div(.class("section-heading")) {
            h3 { "Workshop Lottery Results" }
            button(.type(.button), .class("button ghost"), .id("organizer-workshop-results-refresh")) { "Refresh" }
          }
          FormStatus(id: "organizer-workshop-results-status")
          div(.id("organizer-workshop-results-list"), .class("proposal-list compact-list")) {}
        }
      }
    }
  }

  private var description: String {
    switch page {
    case .home:
      return "Standalone CfP frontend served separately from the API."
    case .guidelines:
      return "Public guidance lives here, while proposal and auth logic stay on the API."
    case .login:
      return "Authentication starts here but is executed entirely by api.tryswift.jp."
    case .profile:
      return "Profile data is loaded from the API and updated without relying on legacy SSR routes."
    case .submit:
      return "Speaker submission flow should call the API rather than post back to Server-side CfPRoutes."
    case .workshops:
      return "Workshop verification, application, and status checks now run through /api/v1/workshops."
    case .myProposals:
      return "Proposal status, edits, and withdraw actions should all run through /api/v1."
    case .feedback:
      return "Feedback remains a normal app page while data is loaded cross-subdomain from the API."
    case .organizer:
      return "Organizer tools belong in the frontend, but authorization and business rules remain API-owned."
    }
  }
}

private struct FeatureCard: HTML, Sendable {
  let title: String
  let copy: String

  var body: some HTML {
    article(.class("detail-card")) {
      h3 { HTMLText(title) }
      p { HTMLText(copy) }
    }
  }
}

private struct APIPreviewCard: HTML, Sendable {
  let heading: String
  let endpoint: String
  let copy: String

  var body: some HTML {
    article(.class("detail-card")) {
      h3 { HTMLText(heading) }
      p(.class("endpoint")) { HTMLText(endpoint) }
      p { HTMLText(copy) }
      pre(.class("api-preview"), .id("api-preview")) { "Waiting for frontend wiring..." }
    }
  }
}

private struct FormField<Field: HTML>: HTML {
  let label: String
  let field: Field

  var body: some HTML {
    Elementary.label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(label) }
      field
    }
  }
}

private struct WorkshopFields: HTML, Sendable {
  let prefix: String
  var includeJapaneseFields: Bool = false

  var body: some HTML {
    section(.class("workshop-section"), .id("\(prefix)-workshop-section")) {
      h4 { "Workshop Details" }
      p(.class("field-hint")) { "These fields are used only when Talk Duration is set to Workshop." }
      div(.class("form-grid")) {
        FormField(
          label: "Workshop Language",
          field: select(.name("workshopLanguage")) {
            option(.value("english")) { "English" }
            option(.value("japanese")) { "Japanese" }
            option(.value("bilingual")) { "Bilingual" }
            option(.value("other")) { "Other" }
          }
        )
        FormField(
          label: "Number of Tutors",
          field: input(.type(.number), .name("workshopNumberOfTutors"), .custom(name: "min", value: "1"), .value("1"))
        )
      }
      FormField(
        label: "Key Takeaways",
        field: textarea(.name("workshopKeyTakeaways"), .custom(name: "rows", value: "4")) {}
      )
      if includeJapaneseFields {
        FormField(
          label: "Key Takeaways (JA)",
          field: textarea(.name("workshopKeyTakeawaysJa"), .custom(name: "rows", value: "4")) {}
        )
      }
      FormField(
        label: "Prerequisites",
        field: textarea(.name("workshopPrerequisites"), .custom(name: "rows", value: "3")) {}
      )
      if includeJapaneseFields {
        FormField(
          label: "Prerequisites (JA)",
          field: textarea(.name("workshopPrerequisitesJa"), .custom(name: "rows", value: "3")) {}
        )
      }
      FormField(
        label: "Agenda Schedule",
        field: textarea(.name("workshopAgendaSchedule"), .custom(name: "rows", value: "4")) {}
      )
      if includeJapaneseFields {
        FormField(
          label: "Agenda Schedule (JA)",
          field: textarea(.name("workshopAgendaScheduleJa"), .custom(name: "rows", value: "4")) {}
        )
      }
      FormField(
        label: "Participant Requirements",
        field: textarea(.name("workshopParticipantRequirements"), .custom(name: "rows", value: "4")) {}
      )
      if includeJapaneseFields {
        FormField(
          label: "Participant Requirements (JA)",
          field: textarea(.name("workshopParticipantRequirementsJa"), .custom(name: "rows", value: "4")) {}
        )
      }
      FormField(
        label: "Required Software",
        field: textarea(.name("workshopRequiredSoftware"), .custom(name: "rows", value: "3")) {}
      )
      if includeJapaneseFields {
        FormField(
          label: "Required Software (JA)",
          field: textarea(.name("workshopRequiredSoftwareJa"), .custom(name: "rows", value: "3")) {}
        )
      }
      FormField(
        label: "Network Requirements",
        field: textarea(.name("workshopNetworkRequirements"), .custom(name: "rows", value: "3")) {}
      )
      if includeJapaneseFields {
        FormField(
          label: "Network Requirements (JA)",
          field: textarea(.name("workshopNetworkRequirementsJa"), .custom(name: "rows", value: "3")) {}
        )
      }
      div(.class("detail-card inset-card")) {
        h5 { "Facilities" }
        div(.class("checkbox-grid")) {
          FacilityCheckbox(name: "workshopFacilityProjector", label: "Projector")
          FacilityCheckbox(name: "workshopFacilityMicrophone", label: "Microphone")
          FacilityCheckbox(name: "workshopFacilityWhiteboard", label: "Whiteboard")
          FacilityCheckbox(name: "workshopFacilityPowerStrips", label: "Power Strips")
        }
        FormField(
          label: "Other Facility Needs",
          field: input(.type(.text), .name("workshopFacilityOther"))
        )
      }
      FormField(
        label: "Motivation",
        field: textarea(.name("workshopMotivation"), .custom(name: "rows", value: "4")) {}
      )
      FormField(
        label: "Uniqueness",
        field: textarea(.name("workshopUniqueness"), .custom(name: "rows", value: "4")) {}
      )
      FormField(
        label: "Potential Risks",
        field: textarea(.name("workshopPotentialRisks"), .custom(name: "rows", value: "3")) {}
      )
      div(.class("detail-card inset-card")) {
        h5 { "Co-Instructors" }
        CoInstructorFields(prefix: "\(prefix)-co1")
        CoInstructorFields(prefix: "\(prefix)-co2")
      }
    }
  }
}

private struct FacilityCheckbox: HTML, Sendable {
  let name: String
  let label: String

  var body: some HTML {
    Elementary.label(.class("checkbox-row")) {
      input(.type(.checkbox), .name(name))
      span { HTMLText(label) }
    }
  }
}

private struct CoInstructorFields: HTML, Sendable {
  let prefix: String

  var body: some HTML {
    div(.class("co-instructor-card")) {
      h6 { "Co-Instructor" }
      div(.class("form-grid")) {
        FormField(
          label: "Name",
          field: input(.type(.text), .name("\(prefix)Name"))
        )
        FormField(
          label: "Email",
          field: input(.type(.email), .name("\(prefix)Email"))
        )
      }
      div(.class("form-grid")) {
        FormField(
          label: "GitHub Username",
          field: input(.type(.text), .name("\(prefix)GithubUsername"))
        )
        FormField(
          label: "SNS",
          field: input(.type(.text), .name("\(prefix)Sns"))
        )
      }
      FormField(
        label: "Bio",
        field: textarea(.name("\(prefix)Bio"), .custom(name: "rows", value: "3")) {}
      )
      FormField(
        label: "Icon URL",
        field: input(.type(.url), .name("\(prefix)IconURL"))
      )
    }
  }
}

private struct FormStatus: HTML, Sendable {
  let id: String

  var body: some HTML {
    p(.id(id), .class("form-status"), .custom(name: "hidden", value: "hidden")) {}
  }
}
