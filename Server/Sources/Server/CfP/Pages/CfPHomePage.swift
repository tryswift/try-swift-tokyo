import Elementary
import SharedModels

struct CfPHomePage: HTML, Sendable {
  let user: UserDTO?

  var body: some HTML {
    // Hero Section
    section(.class("hero-section text-center py-5")) {
      div(.class("container py-5")) {
        p(.class("text-white-50 fs-5 mb-2")) { "try! Swift Tokyo 2026" }
        h1(.class("display-3 fw-bold text-white mb-3")) { "Call for Proposals" }
        p(.class("lead text-white-50 mb-4 mx-auto"), .style("max-width: 600px;")) {
          "Share your Swift expertise with developers from around the world. Submit your talk proposal for try! Swift Tokyo 2026!"
        }
        div(.class("d-flex gap-3 justify-content-center flex-wrap")) {
          a(.class("btn btn-light btn-lg fw-bold"), .href("/cfp/submit")) { "Submit Your Proposal" }
          a(.class("btn btn-outline-light btn-lg"), .href("/cfp/guidelines")) { "View Guidelines" }
        }
      }
    }

    // Important Dates Section
    section(.class("py-5")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) { "Important Dates" }
        div(.class("row g-4")) {
          dateCard(emoji: "📅", title: "CfP Opens", date: "January 15, 2026")
          dateCard(emoji: "⏰", title: "Submission Deadline", date: "February 1, 2026")
          dateCard(emoji: "📣", title: "Notifications", date: "February 8, 2026")
          dateCard(emoji: "🎤", title: "Conference", date: "April 12-14, 2026")
        }
      }
    }

    // Talk Formats Section
    section(.class("py-5 bg-light")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) { "Talk Formats" }
        div(.class("row g-4")) {
          div(.class("col-md-6")) {
            div(.class("card h-100")) {
              div(.class("card-body text-center p-4")) {
                h3(.class("fw-bold")) { "🎯 Regular Talk" }
                p(.class("lead text-muted")) { "20 minutes" }
                p(.class("mt-3")) {
                  "Deep dive into a specific topic with detailed examples and live demos. Perfect for sharing comprehensive knowledge about Swift development."
                }
              }
            }
          }
          div(.class("col-md-6")) {
            div(.class("card h-100")) {
              div(.class("card-body text-center p-4")) {
                h3(.class("fw-bold")) { "⚡ Lightning Talk" }
                p(.class("lead text-muted")) { "5 minutes" }
                p(.class("mt-3")) {
                  "Quick, focused presentation on a single idea, tip, or tool. Great for first-time speakers or sharing quick wins!"
                }
              }
            }
          }
        }
      }
    }

    // Topics Section
    section(.class("py-5")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) { "Topics We're Looking For" }
        div(.class("row g-4")) {
          topicCard(
            title: "Swift Language",
            description: "New features, best practices, and language evolution")
          topicCard(
            title: "SwiftUI", description: "Modern UI development, animations, and architecture")
          topicCard(
            title: "iOS/macOS/visionOS", description: "Platform-specific development and APIs")
          topicCard(
            title: "Server-Side Swift",
            description: "Vapor, backend development, and cloud deployment")
          topicCard(
            title: "Testing & Quality", description: "Unit testing, UI testing, and code quality")
          topicCard(
            title: "Tools & Productivity", description: "Xcode, debugging, and developer experience"
          )
        }
      }
    }

    // CTA Section
    section(.class("py-5 bg-purple text-center")) {
      div(.class("container py-4")) {
        h2(.class("fw-bold text-white mb-3")) { "Ready to Share Your Knowledge?" }
        p(.class("lead text-white-50 mb-4")) {
          "We welcome speakers of all experience levels. First-time speakers are encouraged to apply!"
        }
        a(.class("btn btn-light btn-lg fw-bold"), .href("/cfp/submit")) { "Submit Your Proposal" }
      }
    }
  }

  @HTMLBuilder
  private func dateCard(emoji: String, title: String, date: String) -> some HTML {
    div(.class("col-md-3 col-sm-6")) {
      div(.class("card text-center h-100")) {
        div(.class("card-body")) {
          p(.class("fs-1 mb-2")) { emoji }
          h5(.class("fw-semibold")) { title }
          p(.class("text-muted mb-0")) { date }
        }
      }
    }
  }

  @HTMLBuilder
  private func topicCard(title: String, description: String) -> some HTML {
    div(.class("col-md-4 col-sm-6")) {
      div(.class("card h-100")) {
        div(.class("card-body text-center")) {
          h5(.class("fw-semibold")) { title }
          p(.class("text-muted mb-0")) { description }
        }
      }
    }
  }
}
