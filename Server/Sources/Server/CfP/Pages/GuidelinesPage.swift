import Elementary
import SharedModels

struct GuidelinesPageView: HTML, Sendable {
  let user: UserDTO?

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-4")) { "Submission Guidelines" }
      p(.class("lead text-muted mb-5")) {
        "Everything you need to know about submitting a talk proposal for try! Swift Tokyo 2026."
      }

      // What We're Looking For
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { "What We're Looking For" }
          ul(.class("mb-0")) {
            li { "Original content that hasn't been presented at other major conferences" }
            li { "Practical knowledge that attendees can apply in their work" }
            li { "Clear learning outcomes for the audience" }
            li { "Well-structured presentations with demos when applicable" }
            li { "Topics relevant to the Swift community" }
          }
        }
      }

      // Talk Formats
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { "Talk Formats" }

          h4(.class("fw-semibold mt-3")) { "Regular Talk (20 minutes)" }
          p(.class("text-muted")) {
            "A comprehensive session covering a topic in depth. Include time for context, examples, and key takeaways. Live coding and demos are welcome!"
          }

          h4(.class("fw-semibold mt-4")) { "Lightning Talk (5 minutes)" }
          p(.class("text-muted mb-0")) {
            "A focused, fast-paced presentation covering a single concept, tool, or tip. Perfect for sharing quick wins or introducing new ideas."
          }
        }
      }

      // Proposal Requirements
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { "Proposal Requirements" }

          h4(.class("fw-semibold mt-3")) { "Title" }
          p(.class("text-muted")) {
            "A clear, descriptive title that accurately represents your talk content."
          }

          h4(.class("fw-semibold mt-3")) { "Abstract" }
          p(.class("text-muted")) {
            "A 2-3 sentence summary that will be shown publicly if your talk is accepted. This should explain what attendees will learn."
          }

          h4(.class("fw-semibold mt-3")) { "Talk Details" }
          p(.class("text-muted")) {
            "A detailed description of your talk for reviewers. Include your outline, key points, and any demos you plan to show. This helps us understand your vision."
          }

          h4(.class("fw-semibold mt-3")) { "Speaker Bio" }
          p(.class("text-muted")) {
            "Tell us about yourself! Your background, experience, and what makes you excited about this topic."
          }

          h4(.class("fw-semibold mt-3")) { "Notes (Optional)" }
          p(.class("text-muted mb-0")) {
            "Any additional information for organizers, such as accessibility needs, scheduling constraints, or whether you've given this talk before."
          }
        }
      }

      // Selection Criteria
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { "Selection Criteria" }
          p { "Our review committee evaluates proposals based on:" }
          ul(.class("mb-0")) {
            li { "Relevance to the Swift community" }
            li { "Originality and uniqueness of content" }
            li { "Clarity of proposal and learning outcomes" }
            li { "Speaker's expertise and presentation ability" }
            li { "Diversity of topics across the conference program" }
          }
        }
      }

      // Tips for Success
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { "Tips for a Great Proposal" }
          ul(.class("mb-0")) {
            li { "Be specific about what attendees will learn" }
            li { "Include a clear outline or structure" }
            li { "Mention any demos or live coding" }
            li { "Show your passion for the topic" }
            li { "Proofread your submission carefully" }
            li { "Don't be afraid to submit multiple proposals!" }
          }
        }
      }

      // Speaker Benefits
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { "Speaker Benefits" }
          ul(.class("mb-0")) {
            li { "Free conference ticket" }
            li { "Speaker dinner with other speakers and organizers" }
            li { "Travel support available for international speakers" }
            li { "Professional video recording of your talk" }
            li { "Networking opportunities with Swift developers worldwide" }
          }
        }
      }

      // CTA
      div(.class("text-center mt-5")) {
        a(.class("btn btn-primary btn-lg"), .href("/cfp/submit")) { "Submit Your Proposal" }
      }
    }
  }
}
