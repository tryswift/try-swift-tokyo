import Ignite

struct CfPHome: StaticPage {
  var title = "Call for Proposals"

  var body: some HTML {
    // Hero Section
    Section {
      Text("try! Swift Tokyo 2026")
        .font(.title3)
        .foregroundStyle(.white.opacity(0.9))

      Text("Call for Proposals")
        .font(.title1)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .margin(.bottom, .medium)

      Text("Share your Swift expertise with developers from around the world. Submit your talk proposal for try! Swift Tokyo 2026!")
        .font(.lead)
        .foregroundStyle(.white.opacity(0.9))
        .margin(.bottom, .large)

      Text {
        Link("Submit Your Proposal", target: SubmitPage())
          .linkStyle(.button)
          .role(.light)
          .fontWeight(.bold)
          .margin(.trailing, .medium)

        Link("View Guidelines", target: GuidelinesPage())
          .linkStyle(.button)
          .role(.secondary)
      }
    }
    .padding(.vertical, 100)
    .background(.darkBlue)
    .horizontalAlignment(.center)

    // Key Dates Section
    Section {
      Text("Important Dates")
        .font(.title2)
        .fontWeight(.bold)
        .horizontalAlignment(.center)
        .foregroundStyle(.bootstrapPurple)
        .margin(.bottom, .large)

      Grid {
        Card {
          Text("📅")
            .font(.title1)
          Text("CfP Opens")
            .font(.title3)
            .fontWeight(.semibold)
          Text("January 15, 2026")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("⏰")
            .font(.title1)
          Text("Submission Deadline")
            .font(.title3)
            .fontWeight(.semibold)
          Text("February 28, 2026")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("📣")
            .font(.title1)
          Text("Notifications")
            .font(.title3)
            .fontWeight(.semibold)
          Text("March 15, 2026")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("🎤")
            .font(.title1)
          Text("Conference")
            .font(.title3)
            .fontWeight(.semibold)
          Text("April 12-14, 2026")
            .foregroundStyle(.secondary)
        }
      }
      .columns(4)
    }
    .padding(.vertical, .large)

    // Talk Formats Section
    Section {
      Text("Talk Formats")
        .font(.title2)
        .fontWeight(.bold)
        .horizontalAlignment(.center)
        .foregroundStyle(.bootstrapPurple)
        .margin(.bottom, .large)

      Grid {
        Card {
          Text("🎯 Regular Talk")
            .font(.title3)
            .fontWeight(.bold)
          Text("20 minutes")
            .font(.lead)
            .foregroundStyle(.secondary)
          Text("Deep dive into a specific topic with detailed examples and live demos. Perfect for sharing comprehensive knowledge about Swift development.")
            .margin(.top, .medium)
        }

        Card {
          Text("⚡ Lightning Talk")
            .font(.title3)
            .fontWeight(.bold)
          Text("5 minutes")
            .font(.lead)
            .foregroundStyle(.secondary)
          Text("Quick, focused presentation on a single idea, tip, or tool. Great for first-time speakers or sharing quick wins!")
            .margin(.top, .medium)
        }
      }
      .columns(2)
    }
    .padding(.vertical, .large)
    .background(.white)

    // Topics Section
    Section {
      Text("Topics We're Looking For")
        .font(.title2)
        .fontWeight(.bold)
        .horizontalAlignment(.center)
        .foregroundStyle(.bootstrapPurple)
        .margin(.bottom, .large)

      Grid {
        Card {
          Text("Swift Language")
            .font(.title3)
            .fontWeight(.semibold)
          Text("New features, best practices, and language evolution")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("SwiftUI")
            .font(.title3)
            .fontWeight(.semibold)
          Text("Modern UI development, animations, and architecture")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("iOS/macOS/visionOS")
            .font(.title3)
            .fontWeight(.semibold)
          Text("Platform-specific development and APIs")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("Server-Side Swift")
            .font(.title3)
            .fontWeight(.semibold)
          Text("Vapor, backend development, and cloud deployment")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("Testing & Quality")
            .font(.title3)
            .fontWeight(.semibold)
          Text("Unit testing, UI testing, and code quality")
            .foregroundStyle(.secondary)
        }

        Card {
          Text("Tools & Productivity")
            .font(.title3)
            .fontWeight(.semibold)
          Text("Xcode, debugging, and developer experience")
            .foregroundStyle(.secondary)
        }
      }
      .columns(3)
    }
    .padding(.vertical, .large)

    // CTA Section
    Section {
      Text("Ready to Share Your Knowledge?")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .margin(.bottom, .medium)

      Text("We welcome speakers of all experience levels. First-time speakers are encouraged to apply!")
        .font(.lead)
        .foregroundStyle(.white.opacity(0.9))
        .margin(.bottom, .large)

      Link("Submit Your Proposal", target: SubmitPage())
        .linkStyle(.button)
        .role(.light)
        .fontWeight(.bold)
    }
    .padding(.vertical, .large)
    .background(.bootstrapPurple)
    .horizontalAlignment(.center)
  }
}
