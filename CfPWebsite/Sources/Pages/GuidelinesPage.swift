import Ignite

struct GuidelinesPage: StaticPage {
  var title = "Submission Guidelines"

  var body: some HTML {
    Section {
      Text("Submission Guidelines")
        .font(.title1)
        .fontWeight(.bold)
        .margin(.bottom, .large)

      Text("Everything you need to know about submitting a talk proposal for try! Swift Tokyo 2026.")
        .font(.lead)
        .foregroundStyle(.secondary)
        .margin(.bottom, .large)

      // What We're Looking For
      Card {
        Text("What We're Looking For")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        List {
          "Original content that hasn't been presented at other major conferences"
          "Practical knowledge that attendees can apply in their work"
          "Clear learning outcomes for the audience"
          "Well-structured presentations with demos when applicable"
          "Topics relevant to the Swift community"
        }
      }
      .margin(.bottom, .large)

      // Talk Formats
      Card {
        Text("Talk Formats")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        Text("Regular Talk (20 minutes)")
          .font(.title3)
          .fontWeight(.semibold)
        Text("A comprehensive session covering a topic in depth. Include time for context, examples, and key takeaways. Live coding and demos are welcome!")
          .margin(.bottom, .medium)

        Text("Lightning Talk (5 minutes)")
          .font(.title3)
          .fontWeight(.semibold)
        Text("A focused, fast-paced presentation covering a single concept, tool, or tip. Perfect for sharing quick wins or introducing new ideas.")
      }
      .margin(.bottom, .large)

      // Proposal Requirements
      Card {
        Text("Proposal Requirements")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        Text("Title")
          .font(.title3)
          .fontWeight(.semibold)
        Text("A clear, descriptive title that accurately represents your talk content.")
          .margin(.bottom, .medium)

        Text("Abstract")
          .font(.title3)
          .fontWeight(.semibold)
        Text("A 2-3 sentence summary that will be shown publicly if your talk is accepted. This should explain what attendees will learn.")
          .margin(.bottom, .medium)

        Text("Talk Details")
          .font(.title3)
          .fontWeight(.semibold)
        Text("A detailed description of your talk for reviewers. Include your outline, key points, and any demos you plan to show. This helps us understand your vision.")
          .margin(.bottom, .medium)

        Text("Speaker Bio")
          .font(.title3)
          .fontWeight(.semibold)
        Text("Tell us about yourself! Your background, experience, and what makes you excited about this topic.")
          .margin(.bottom, .medium)

        Text("Notes (Optional)")
          .font(.title3)
          .fontWeight(.semibold)
        Text("Any additional information for organizers, such as accessibility needs, scheduling constraints, or whether you've given this talk before.")
      }
      .margin(.bottom, .large)

      // Selection Criteria
      Card {
        Text("Selection Criteria")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        Text("Our review committee evaluates proposals based on:")
          .margin(.bottom, .small)

        List {
          "Relevance to the Swift community"
          "Originality and uniqueness of content"
          "Clarity of proposal and learning outcomes"
          "Speaker's expertise and presentation ability"
          "Diversity of topics across the conference program"
        }
      }
      .margin(.bottom, .large)

      // Tips for Success
      Card {
        Text("Tips for a Great Proposal")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        List {
          "Be specific about what attendees will learn"
          "Include a clear outline or structure"
          "Mention any demos or live coding"
          "Show your passion for the topic"
          "Proofread your submission carefully"
          "Don't be afraid to submit multiple proposals!"
        }
      }
      .margin(.bottom, .large)

      // Speaker Benefits
      Card {
        Text("Speaker Benefits")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        List {
          "Free conference ticket"
          "Speaker dinner with other speakers and organizers"
          "Travel support available for international speakers"
          "Professional video recording of your talk"
          "Networking opportunities with Swift developers worldwide"
        }
      }
      .margin(.bottom, .large)

      // CTA
      Section {
        Link("Submit Your Proposal", target: SubmitPage())
          .linkStyle(.button)
          .role(.primary)
      }
      .horizontalAlignment(.center)
    }
    .padding(.vertical, .large)
  }
}
