import Elementary
import SharedModels

struct SubmitPageView: HTML, Sendable {
  let user: UserDTO?
  let success: Bool
  let errorMessage: String?
  let openConference: ConferencePublicInfo?

  init(user: UserDTO?, success: Bool, errorMessage: String?, openConference: ConferencePublicInfo? = nil) {
    self.user = user
    self.success = success
    self.errorMessage = errorMessage
    self.openConference = openConference
  }

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-2")) { "Submit Your Proposal" }
      p(.class("lead text-muted mb-4")) {
        "Share your Swift expertise with developers from around the world."
      }

      if openConference == nil {
        // No open conference - show friendly message
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "📅" }
            h3(.class("fw-bold mb-2")) { "Call for Proposals Not Open" }
            p(.class("text-muted mb-4")) {
              "The Call for Proposals is not currently open. Please check back later for the next conference."
            }
            a(.class("btn btn-outline-primary"), .href("/cfp/")) { "Back to Home" }
          }
        }
      } else if user != nil {
        if success {
          // Success message
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              p(.class("fs-1 mb-3")) { "✅" }
              h3(.class("fw-bold mb-2")) { "Proposal Submitted!" }
              p(.class("text-muted mb-4")) {
                "Your proposal has been submitted successfully. Good luck!"
              }
              div(.class("d-flex gap-2 justify-content-center")) {
                a(.class("btn btn-primary"), .href("/cfp/my-proposals")) { "View My Proposals" }
                a(.class("btn btn-outline-primary"), .href("/cfp/submit")) { "Submit Another" }
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

              form(.method(.post), .action("/cfp/submit")) {
                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("title")) { "Title *" }
                  input(
                    .type(.text),
                    .class("form-control"),
                    .name("title"),
                    .id("title"),
                    .required,
                    .placeholder("Enter your talk title")
                  )
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("abstract")) { "Abstract *" }
                  textarea(
                    .class("form-control"),
                    .name("abstract"),
                    .id("abstract"),
                    .custom(name: "rows", value: "3"),
                    .required,
                    .placeholder("A brief summary of your talk (2-3 sentences)")
                  ) {}
                  div(.class("form-text")) {
                    "This will be shown to the audience if your talk is accepted."
                  }
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("talkDetails")) { "Talk Details *" }
                  textarea(
                    .class("form-control"),
                    .name("talkDetails"),
                    .id("talkDetails"),
                    .custom(name: "rows", value: "5"),
                    .required,
                    .placeholder("Detailed description for reviewers")
                  ) {}
                  div(.class("form-text")) {
                    "Include outline, key points, and what attendees will learn. For reviewers only."
                  }
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("talkDuration")) { "Talk Duration *" }
                  select(.class("form-select"), .name("talkDuration"), .id("talkDuration"), .required)
                  {
                    option(.value("")) { "Choose duration..." }
                    option(.value("20min")) { "Regular Talk (20 minutes)" }
                    option(.value("LT")) { "Lightning Talk (5 minutes)" }
                  }
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("bio")) { "Speaker Bio *" }
                  textarea(
                    .class("form-control"),
                    .name("bio"),
                    .id("bio"),
                    .custom(name: "rows", value: "3"),
                    .required,
                    .placeholder("Tell us about yourself")
                  ) {}
                }

                div(.class("mb-3")) {
                  label(.class("form-label fw-semibold"), .for("iconUrl")) {
                    "Profile Picture URL (Optional)"
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
                    "Notes for Organizers (Optional)"
                  }
                  textarea(
                    .class("form-control"),
                    .name("notesToOrganizers"),
                    .id("notesToOrganizers"),
                    .custom(name: "rows", value: "2"),
                    .placeholder("Any special requirements or additional information")
                  ) {}
                }

                div(.class("d-grid")) {
                  button(.type(.submit), .class("btn btn-primary btn-lg")) { "Submit Proposal" }
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
            h3(.class("fw-bold mb-2")) { "Sign In Required" }
            p(.class("text-muted mb-4")) {
              "Connect your GitHub account to submit proposals and track your submissions."
            }
            a(.class("btn btn-dark"), .href("/api/v1/auth/github?returnTo=/cfp/submit")) {
              "Sign in with GitHub"
            }
          }
        }
      }
    }
  }
}
