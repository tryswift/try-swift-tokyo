import Elementary
import SharedModels

struct SubmitPageView: HTML, Sendable {
  let user: UserDTO?
  let success: Bool
  let errorMessage: String?
  let openConference: ConferencePublicInfo?
  let language: CfPLanguage

  init(
    user: UserDTO?, success: Bool, errorMessage: String?, openConference: ConferencePublicInfo? = nil,
    language: CfPLanguage
  ) {
    self.user = user
    self.success = success
    self.errorMessage = errorMessage
    self.openConference = openConference
    self.language = language
  }

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-2")) { CfPStrings.Submit.title(language) }
      p(.class("lead text-muted mb-4")) {
        CfPStrings.Submit.subtitle(language)
      }

      if openConference == nil {
        // No open conference - show friendly message
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "📅" }
            h3(.class("fw-bold mb-2")) { CfPStrings.Submit.cfpNotOpen(language) }
            p(.class("text-muted mb-4")) {
              CfPStrings.Submit.cfpNotOpenDescription(language)
            }
            a(.class("btn btn-outline-primary"), .href("/cfp/\(language.urlPrefix)/")) {
              CfPStrings.Submit.backToHome(language)
            }
          }
        }
      } else if user != nil {
        if success {
          // Success message
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("fs-1 mb-3")) { "✅" }
              h3(.class("fw-bold mb-2")) { CfPStrings.Submit.proposalSubmitted(language) }
              p(.class("text-muted mb-4")) {
                CfPStrings.Submit.proposalSubmittedDescription(language)
              }
              div(.class("d-flex gap-2 justify-content-center")) {
                a(.class("btn btn-primary"), .href("/cfp/\(language.urlPrefix)/my-proposals")) {
                  CfPStrings.Submit.viewMyProposals(language)
                }
                a(.class("btn btn-outline-primary"), .href("/cfp/\(language.urlPrefix)/submit")) {
                  CfPStrings.Submit.submitAnother(language)
                }
              }
            }
          }
        } else {
          // Show proposal form
          div(.class("card")) {
            div(.class("card-body p-4")) {
              if let errorMessage {
                div(.class("alert alert-danger mb-4")) {
                  HTMLText(errorMessage)
                }
              }

              form(.method(.post), .action("/cfp/\(language.urlPrefix)/submit")) {
                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("title")) {
                    CfPStrings.Submit.formTitleLabel(language)
                  }
                  input(
                    .type(.text),
                    .class("form-control"),
                    .name("title"),
                    .id("title"),
                    .required,
                    .placeholder(CfPStrings.Submit.formTitlePlaceholder(language))
                  )
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("abstract")) {
                    CfPStrings.Submit.formAbstractLabel(language)
                  }
                  textarea(
                    .class("form-control"),
                    .name("abstract"),
                    .id("abstract"),
                    .custom(name: "rows", value: "3"),
                    .required,
                    .placeholder(CfPStrings.Submit.formAbstractPlaceholder(language))
                  ) {}
                  div(.class("form-text")) {
                    CfPStrings.Submit.formAbstractHint(language)
                  }
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("talkDetails")) {
                    CfPStrings.Submit.formTalkDetailsLabel(language)
                  }
                  textarea(
                    .class("form-control"),
                    .name("talkDetails"),
                    .id("talkDetails"),
                    .custom(name: "rows", value: "5"),
                    .required,
                    .placeholder(CfPStrings.Submit.formTalkDetailsPlaceholder(language))
                  ) {}
                  div(.class("form-text")) {
                    CfPStrings.Submit.formTalkDetailsHint(language)
                  }
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("talkDuration")) {
                    CfPStrings.Submit.formDurationLabel(language)
                  }
                  select(.class("form-select"), .name("talkDuration"), .id("talkDuration"), .required)
                  {
                    option(.value("")) { CfPStrings.Submit.formDurationPlaceholder(language) }
                    option(.value("20min")) { CfPStrings.Submit.formDurationRegular(language) }
                    option(.value("LT")) { CfPStrings.Submit.formDurationLightning(language) }
                  }
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("bio")) {
                    CfPStrings.Submit.formBioLabel(language)
                  }
                  textarea(
                    .class("form-control"),
                    .name("bio"),
                    .id("bio"),
                    .custom(name: "rows", value: "3"),
                    .required,
                    .placeholder(CfPStrings.Submit.formBioPlaceholder(language))
                  ) {}
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("iconUrl")) {
                    CfPStrings.Submit.formIconUrlLabel(language)
                  }
                  input(
                    .type(.url),
                    .class("form-control"),
                    .name("iconUrl"),
                    .id("iconUrl"),
                    .placeholder("https://example.com/your-photo.jpg")
                  )
                }

                div(.class("mb-4")) {
                  label(.class("form-label fw-semibold"), .for("notesToOrganizers")) {
                    CfPStrings.Submit.formNotesLabel(language)
                  }
                  textarea(
                    .class("form-control"),
                    .name("notesToOrganizers"),
                    .id("notesToOrganizers"),
                    .custom(name: "rows", value: "2"),
                    .placeholder(CfPStrings.Submit.formNotesPlaceholder(language))
                  ) {}
                }

                div(.class("d-grid")) {
                  button(.type(.submit), .class("btn btn-primary btn-lg")) {
                    CfPStrings.Submit.submitProposal(language)
                  }
                }
              }
            }
          }
        }
      } else {
        // Not logged in - show login prompt
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🔐" }
            h3(.class("fw-bold mb-2")) { CfPStrings.Submit.signInRequired(language) }
            p(.class("text-muted mb-4")) {
              CfPStrings.Submit.signInDescription(language)
            }
            a(
              .class("btn btn-dark"),
              .href("/api/v1/auth/github?returnTo=/cfp/\(language.urlPrefix)/submit")
            ) {
              CfPStrings.Submit.signInWithGitHub(language)
            }
          }
        }
      }
    }
  }
}
