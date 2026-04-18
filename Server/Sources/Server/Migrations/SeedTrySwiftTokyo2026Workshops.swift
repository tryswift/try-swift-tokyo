import Fluent
import Foundation
import SharedModels

struct SeedTrySwiftTokyo2026Workshops: AsyncMigration {
  func prepare(on database: Database) async throws {
    guard
      let conference = try await Conference.query(on: database)
        .filter(\.$path == "tryswift-tokyo-2026")
        .first(),
      let conferenceID = conference.id
    else {
      return
    }

    for workshop in workshopSeeds {
      let speaker = try await upsertSpeaker(workshop.speaker, on: database)
      guard let speakerID = speaker.id else { continue }

      let proposal = try await upsertProposal(
        workshop,
        conferenceID: conferenceID,
        speakerID: speakerID,
        on: database
      )
      guard let proposalID = proposal.id else { continue }

      try await upsertRegistration(
        proposalID: proposalID,
        capacity: workshop.capacity,
        on: database
      )
    }
  }

  func revert(on database: Database) async throws {
    guard
      let conference = try await Conference.query(on: database)
        .filter(\.$path == "tryswift-tokyo-2026")
        .first(),
      let conferenceID = conference.id
    else {
      return
    }

    for workshop in workshopSeeds {
      if let proposal = try await Proposal.query(on: database)
        .filter(\.$conference.$id == conferenceID)
        .filter(\.$title == workshop.title)
        .first()
      {
        try await proposal.delete(on: database)
      }
    }

    for speaker in workshopSeeds.map(\.speaker) {
      try await User.query(on: database)
        .filter(\.$githubID == speaker.githubID)
        .delete()
    }
  }

  private func upsertSpeaker(_ seed: SpeakerSeed, on database: Database) async throws -> User {
    let speaker =
      try await User.query(on: database)
      .filter(\.$githubID == seed.githubID)
      .first()
      ?? User(
        githubID: seed.githubID,
        username: seed.username,
        role: .speaker
      )

    speaker.username = seed.username
    speaker.role = .speaker
    speaker.displayName = seed.displayName
    speaker.email = seed.email
    speaker.bio = seed.bio
    speaker.organization = seed.organization
    speaker.avatarURL = seed.avatarURL

    try await speaker.save(on: database)
    return speaker
  }

  private func upsertProposal(
    _ seed: WorkshopSeed,
    conferenceID: UUID,
    speakerID: UUID,
    on database: Database
  ) async throws -> Proposal {
    let proposal =
      try await Proposal.query(on: database)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$title == seed.title)
      .first()
      ?? Proposal(
        conferenceID: conferenceID,
        title: seed.title,
        abstract: seed.abstract,
        talkDetail: seed.talkDetail,
        talkDuration: .workshop,
        speakerName: seed.speaker.displayName,
        speakerEmail: seed.speaker.email,
        bio: seed.speaker.bio,
        bioJa: seed.speaker.bioJa,
        jobTitle: seed.speaker.organization,
        iconURL: seed.speaker.avatarURL,
        notes: "Seeded from https://cfp.tryswift.jp/workshops for local demo data.",
        speakerID: speakerID,
        status: .accepted,
        githubUsername: seed.speaker.username,
        titleJA: seed.titleJA,
        abstractJA: seed.abstractJA,
        workshopDetails: seed.details,
        coInstructors: seed.coInstructors
      )

    proposal.$conference.id = conferenceID
    proposal.title = seed.title
    proposal.abstract = seed.abstract
    proposal.talkDetail = seed.talkDetail
    proposal.talkDuration = .workshop
    proposal.speakerName = seed.speaker.displayName
    proposal.speakerEmail = seed.speaker.email
    proposal.bio = seed.speaker.bio
    proposal.bioJa = seed.speaker.bioJa
    proposal.jobTitle = seed.speaker.organization
    proposal.iconURL = seed.speaker.avatarURL
    proposal.notes = "Seeded from https://cfp.tryswift.jp/workshops for local demo data."
    proposal.$speaker.id = speakerID
    proposal.status = .accepted
    proposal.githubUsername = seed.speaker.username
    proposal.titleJA = seed.titleJA
    proposal.abstractJA = seed.abstractJA
    proposal.workshopDetails = seed.details
    proposal.workshopDetailsJA = seed.detailsJA
    proposal.coInstructors = seed.coInstructors.map(CoInstructorList.init)

    try await proposal.save(on: database)
    return proposal
  }

  private func upsertRegistration(
    proposalID: UUID,
    capacity: Int,
    on database: Database
  ) async throws {
    let registration =
      try await WorkshopRegistration.query(on: database)
      .filter(\.$proposal.$id == proposalID)
      .first() ?? WorkshopRegistration(proposalID: proposalID, capacity: capacity)

    registration.capacity = capacity
    try await registration.save(on: database)
  }

  private struct SpeakerSeed {
    let githubID: Int
    let username: String
    let displayName: String
    let email: String
    let bio: String
    let bioJa: String?
    let organization: String?
    let avatarURL: String?
  }

  private struct WorkshopSeed {
    let title: String
    let titleJA: String?
    let abstract: String
    let abstractJA: String?
    let talkDetail: String
    let capacity: Int
    let speaker: SpeakerSeed
    let details: WorkshopDetails
    let detailsJA: WorkshopDetailsJA?
    let coInstructors: [CoInstructor]?
  }

  private var workshopSeeds: [WorkshopSeed] {
    [
      WorkshopSeed(
        title: "Designing Visual Effects with Metal and SwiftUI",
        titleJA: nil,
        abstract:
          "Metal shaders unlock a level of visual expression in SwiftUI that goes far beyond built-in modifiers, but they are often perceived as complex, low-level, or hard to approach. This workshop is designed to make Metal shaders accessible, visual, and fun for SwiftUI developers, even for those with no prior graphics or Metal experience.",
        abstractJA: nil,
        talkDetail: """
          Metal shaders unlock a level of visual expression in SwiftUI that goes far beyond built-in modifiers, but they are often perceived as complex, low-level, or hard to approach. This workshop is designed to make Metal shaders accessible, visual, and fun for SwiftUI developers, even for those with no prior graphics or Metal experience.

          The workshop starts with a visual-first approach using MetalGraph, a macOS app created specifically to explore and design Metal shaders through a node-based interface with real-time previews. Participants will experiment with coordinates, color, animation, and interaction visually, without writing Metal code at first. This helps build intuition around how shaders work and how complex effects emerge from simple ideas.

          Once participants are comfortable with the concepts, we transition from visual experimentation to real SwiftUI + Metal code. Participants will learn how to translate what they built visually into Metal shader functions, integrate them into SwiftUI using modern APIs such as colorEffect and distortionEffect, and drive them using SwiftUI state, gestures, and time.

          Rather than focusing on project setup or boilerplate, the workshop emphasizes how to think in shaders: how to invent new effects, how to iterate quickly, and how to avoid common pitfalls related to performance and coordinate systems. By the end of the workshop, participants will have a solid mental model of Metal shaders in SwiftUI, hands-on experience building custom visual effects, and the confidence to continue experimenting in their own projects.
          """,
        capacity: 96,
        speaker: SpeakerSeed(
          githubID: 910001,
          username: "victorbaro",
          displayName: "Victor Baro",
          email: "victor.baro@demo.tryswift.jp",
          bio:
            "iOS developer with around 10 years of experience across startups and large companies. Co-founder and CEO of Panels, a digital comics reading app, with a background rooted in UI, interaction, and animation.",
          bioJa: nil,
          organization: "Panels",
          avatarURL: nil
        ),
        details: WorkshopDetails(
          language: .english,
          numberOfTutors: 1,
          keyTakeaways:
            "A clear mental model of how Metal shaders work in SwiftUI. Ability to design shader effects visually before writing code. Practical experience integrating shaders using modern SwiftUI APIs. Understanding of common pitfalls and performance considerations. Confidence to experiment and create original visual effects.",
          prerequisites:
            "Basic Swift knowledge (around one year recommended), plus basic familiarity with SwiftUI and iOS or macOS development. No prior Metal or graphics programming experience is required.",
          agendaSchedule:
            "0:00-0:15 introduction to shader concepts and SwiftUI APIs. 0:15-1:15 visual exploration with MetalGraph. 1:25-1:55 translating node graphs into Metal shader code. 1:55-2:25 integrating shaders into SwiftUI and iterating on effects. 2:25-2:30 wrap-up and Q&A.",
          participantRequirements:
            "Bring a MacBook. An iPad is also useful for the MetalGraph portion. Workshop licenses will be provided to attendees.",
          requiredSoftware:
            "Latest version of Xcode with the Metal toolchain enabled, plus MetalGraph (free version is fine; licenses will be provided).",
          networkRequirements: "None.",
          motivation:
            "This workshop gives SwiftUI developers a practical path into custom visual effects without requiring prior graphics programming experience.",
          uniqueness:
            "It combines a visual-first workflow with direct translation into production SwiftUI and Metal code.",
          potentialRisks: nil
        ),
        detailsJA: nil,
        coInstructors: nil
      ),
      WorkshopSeed(
        title: "Enhance your apps with the Foundation Models",
        titleJA: nil,
        abstract:
          "Attendee will get hands-on experience using the Foundation Models framework to access Apple's on-device LLM. Over the workshop, developer will explore text manipulation, language support, guided generation, tool calling, localization techniques, and how to combine Foundation Models with Speech or Vision frameworks.",
        abstractJA: nil,
        talkDetail: """
          Attendee will get hands-on experience using the Foundation Models framework to access Apple's on-device LLM. Over the workshop, developer will explore text manipulation, including language support, guided generation, tool calling, and localization techniques. Developer will also learn how to engineer effective prompts, and combine the Foundation Models framework with Speech or Vision frameworks.

          Original content is for a longer workshop, and the session will be adapted into a half-day format for try! Swift Tokyo 2026 with hands-on tasks and guided explanations.
          """,
        capacity: 60,
        speaker: SpeakerSeed(
          githubID: 910002,
          username: "shun-takeishi",
          displayName: "Shun Takeishi",
          email: "shun.takeishi@demo.tryswift.jp",
          bio: "Technology Evangelist, Apple Worldwide Developer Relations.",
          bioJa: nil,
          organization: "Apple Worldwide Developer Relations",
          avatarURL: nil
        ),
        details: WorkshopDetails(
          language: .bilingual,
          numberOfTutors: 2,
          keyTakeaways:
            "Understand what the Foundation Models framework is, how it works inside a project, how to combine it with frameworks like Vision or Speech, and how to work effectively within the limits of on-device models.",
          prerequisites: "Basic knowledge of iOS development.",
          agendaSchedule:
            "0:00-0:20 introduction to the Foundation Models framework. 0:20-0:40 project setup and sample app overview. 0:40-2:30 hands-on challenges with guided explanations and reference implementations.",
          participantRequirements:
            "Bring a MacBook, MacBook Pro, or Mac mini/studio with a display. An iPhone or iPad is optional.",
          requiredSoftware:
            "Xcode 26.0 or later on macOS 26 Tahoe. This setup does not work on earlier macOS releases such as Sequoia or Sonoma.",
          networkRequirements:
            "No ongoing network requirement, but attendees need access to download sample projects from Box.",
          motivation:
            "This workshop helps developers get practical, hands-on experience with Apple's newest on-device model APIs.",
          uniqueness:
            "It blends prompt design, tool calling, localization, and multimodal framework integration in one guided session.",
          potentialRisks:
            "The original material was designed for a longer format, so pacing may need to be adjusted during delivery."
        ),
        detailsJA: nil,
        coInstructors: [
          CoInstructor(
            name: "Alberto Ricci",
            email: "alberto.ricci@demo.tryswift.jp",
            sns: "https://www.linkedin.com/in/albertoricci/",
            githubUsername: "none2",
            bio: "Technology Evangelist, EMEA. Focus on AI/ML.",
            iconURL: nil
          )
        ]
      ),
      WorkshopSeed(
        title: "High-Performance Swift",
        titleJA: nil,
        abstract:
          "This workshop will teach a range of techniques to increase the performance of Swift apps. Participants will use Instruments to identify performance issues, work through fixes, and verify the improvements with performance tests and follow-up profiling.",
        abstractJA: nil,
        talkDetail: """
          This workshop will teach a range of techniques to increase the performance of Swift apps. We will follow a simple pattern several times over: identify a performance problem using Instruments, work through code to resolve the issue, then run Instruments again to ensure the problem is resolved.

          As we work through the sample project, students will learn to use different parts of Instruments effectively, what makes Swift and SwiftUI code slow, how to write more efficient code in the future, and how to write performance tests to ensure performance problems do not return.
          """,
        capacity: 96,
        speaker: SpeakerSeed(
          githubID: 910003,
          username: "twostraws",
          displayName: "Paul Hudson",
          email: "paul.hudson@demo.tryswift.jp",
          bio:
            "Author of Hacking with Swift, Pro Swift, Swift Design Patterns, Testing Swift, Swift Interview Challenges, and more. He enjoys teaching Swift almost as much as coffee.",
          bioJa: nil,
          organization: "Hacking with Swift",
          avatarURL: nil
        ),
        details: WorkshopDetails(
          language: .english,
          numberOfTutors: 1,
          keyTakeaways:
            "Identify performance hotspots with Instruments, write reusable fixes for common bottlenecks, and create performance tests so regressions do not return.",
          prerequisites:
            "This workshop is aimed at intermediate to advanced Swift and SwiftUI developers and is not suitable for complete beginners.",
          agendaSchedule:
            "The session is organized around five 25-minute topics: memoization, concurrency, SwiftUI, Observation, and leaks. Each block covers profiling, testing, explaining a solution, and applying it to the sample project, with additional time for intro and wrap-up.",
          participantRequirements:
            "Bring a laptop and an iPhone. A USB-C cable is recommended for faster debugging against a device.",
          requiredSoftware: "Xcode 26 with the iOS 26 SDK.",
          networkRequirements:
            "Attendees need to download the sample project, but there are otherwise no special network requirements.",
          motivation:
            "Performance work is often abstract; this workshop turns it into a repeatable, tool-driven workflow developers can apply immediately.",
          uniqueness:
            "The session is structured around repeated profiling and remediation loops, which makes the improvement process concrete and measurable.",
          potentialRisks: nil
        ),
        detailsJA: nil,
        coInstructors: nil
      ),
      WorkshopSeed(
        title: "iOS Private Playgrounds",
        titleJA: nil,
        abstract:
          "This experimental workshop temporarily sets aside the App Store Review Guidelines to peek inside the iOS black box. By deliberately using private APIs and undocumented behaviors, participants will gain a deeper understanding of how UIKit and SwiftUI operate under the hood.",
        abstractJA: nil,
        talkDetail: """
          This workshop is an experimental session where we temporarily set aside the App Store Review Guidelines and take a peek inside the iOS black box. By deliberately using Private APIs and undocumented behaviors—topics that are normally considered taboo in everyday development—the goal is to gain a deeper understanding of how UIKit and SwiftUI operate under the hood.

          Participants will explore runtime techniques, view hierarchy inspection, undocumented APIs, and the risks of brittle implementations that can break across OS updates.
          """,
        capacity: 60,
        speaker: SpeakerSeed(
          githubID: 910004,
          username: "b33ster",
          displayName: "ビスター",
          email: "b33ster@demo.tryswift.jp",
          bio: "iOS Developer and private API researcher.",
          bioJa: "iOSアプリケーション開発者。Private API のリサーチにも取り組んでいる。",
          organization: "Independent",
          avatarURL: nil
        ),
        details: WorkshopDetails(
          language: .japanese,
          numberOfTutors: 2,
          keyTakeaways:
            "Learn how to access dynamic functionality from Swift via Objective-C Runtime, inspect view hierarchies and internal component structure, investigate undocumented APIs, and understand the risks of fragile implementations across OS updates.",
          prerequisites:
            "Basic Swift and iOS development knowledge, basic Git/GitHub operations such as clone, pull, and push, and curiosity about Objective-C Runtime.",
          agendaSchedule:
            "0:00-0:20 intro, environment setup, and repository sharing. 0:20-0:50 lecture and demo. 0:50-1:25 hands-on part 1. 1:25-1:35 intermediate review. 1:35-2:10 hands-on part 2. 2:10-2:30 wrap-up and sharing.",
          participantRequirements:
            "Bring a Mac with Xcode. An iPhone device is optional; the simulator is acceptable. A GitHub account is optional.",
          requiredSoftware: "Xcode.",
          networkRequirements: "No extra external API access is required and no VPN is needed.",
          motivation:
            "Understanding the unsupported edges of the platform helps developers better understand the supported ones too.",
          uniqueness:
            "It treats private APIs as a learning tool for system internals rather than a production recommendation.",
          potentialRisks:
            "Examples intentionally cover brittle techniques that should not be used in App Store production apps."
        ),
        detailsJA: WorkshopDetailsJA(
          keyTakeaways:
            "Objective-C Runtimeを用いたSwiftからの動的な機能アクセスの方法、View Hierarchyの解析手法と標準コンポーネント内部へのアクセス、ドキュメントに記載されていないAPIやクラスの調査テクニック、OSアップデートで壊れうる脆い実装の実例を学びます。",
          prerequisites: "SwiftおよびiOS開発の基礎知識、Git/GitHubの基本操作、Objective-C Runtimeへの興味がある方を対象にしています。",
          agendaSchedule:
            "0:00-0:20 導入と環境構築。0:20-0:50 講義とデモ。0:50-1:25 ハンズオン前半。1:25-1:35 中間レビュー。1:35-2:10 ハンズオン後半。2:10-2:30 成果発表とクロージング。",
          participantRequirements: "Mac（Xcode）を持参してください。可能ならiOS実機も歓迎ですが必須ではありません。GitHubアカウントも任意です。",
          requiredSoftware: "Xcode",
          networkRequirements: "追加の外部APIアクセスは不要で、VPNも不要です。"
        ),
        coInstructors: [
          CoInstructor(
            name: "Kazuki Nakashima",
            email: "kazuki.nakashima@demo.tryswift.jp",
            sns: nil,
            githubUsername: "lynnswap",
            bio: "iOSアプリケーション開発",
            iconURL: nil
          )
        ]
      ),
      WorkshopSeed(
        title: "The road to your app is paved with App Intents",
        titleJA: nil,
        abstract:
          "Allow users to discover and more quickly access all that your app can do, sometimes without even opening your app. This workshop demonstrates how to use App Intents to expose app functionality through Shortcuts, Spotlight, Siri, Widgets, and Controls.",
        abstractJA: nil,
        talkDetail: """
          Allow users to discover and more quickly access all that your app can do, sometimes without even opening your app. This fast moving workshop demonstrates how and why to use App Intents to expose your app's functionality through Shortcuts, Spotlight, Siri, Widgets, and Controls. App Intents are clearly central to Apple's idea of how your app interacts with the system.
          """,
        capacity: 60,
        speaker: SpeakerSeed(
          githubID: 910005,
          username: "dimsumthinking",
          displayName: "Daniel H Steinberg",
          email: "daniel.steinberg@demo.tryswift.jp",
          bio:
            "Author of more than a dozen books including The Curious Case of the Async Cafe, A SwiftUI Kickstart, and A Swift Kickstart. Daniel teaches iOS, SwiftUI, and Swift through training and consulting at Dim Sum Thinking.",
          bioJa: nil,
          organization: "Dim Sum Thinking",
          avatarURL: nil
        ),
        details: WorkshopDetails(
          language: .english,
          numberOfTutors: 1,
          keyTakeaways:
            "Understand how App Intents help users discover app functionality through system surfaces such as Shortcuts, Spotlight, Siri, Widgets, and Controls.",
          prerequisites: nil,
          agendaSchedule: "N/A",
          participantRequirements: "N/A",
          requiredSoftware: nil,
          networkRequirements: "N/A",
          motivation:
            "App Intents are becoming a central integration point for modern Apple platforms and deserve hands-on exploration.",
          uniqueness:
            "The session focuses on practical exposure of app functionality across multiple system entry points.",
          potentialRisks: nil
        ),
        detailsJA: nil,
        coInstructors: nil
      ),
    ]
  }
}
