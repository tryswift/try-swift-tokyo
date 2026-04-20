import Ignite

struct CallForProposalComponent: HTML {
  let language: SupportedLanguage

  private struct ImportantDate: Identifiable {
    let id: String
    let title: String
    let date: String
  }

  private struct TalkFormat: Identifiable {
    let id: String
    let title: String
    let duration: String
    let description: String
  }

  private struct Topic: Identifiable {
    let id: String
    let title: String
    let description: String
  }

  var body: some HTML {
    Section {
      Text(heroEyebrow)
        .font(.title5)
        .fontWeight(.semibold)
        .foregroundStyle(.orangeRed)
        .margin(.bottom, .px(12))

      Text(heroTitle)
        .font(.title1)
        .fontWeight(.bold)
        .foregroundStyle(.darkBlue)
        .margin(.bottom, .px(16))

      Text(heroDescription)
        .font(.lead)
        .foregroundStyle(.dimGray)
        .margin(.bottom, .px(32))

      Grid(alignment: .center, spacing: 16) {
        Link(primaryActionLabel, target: "https://cfp.tryswift.jp/submit")
          .target(.newWindow)
          .linkStyle(.button)
          .role(.primary)
          .fontWeight(.semibold)

        Link(secondaryActionLabel, target: "https://cfp.tryswift.jp/guidelines")
          .target(.newWindow)
          .linkStyle(.button)
          .role(.light)
          .fontWeight(.semibold)

        Link(workshopsActionLabel, target: "https://cfp.tryswift.jp/workshops")
          .target(.newWindow)
          .linkStyle(.button)
          .role(.light)
          .fontWeight(.semibold)
      }
      .columns(3)
      .margin(.bottom, .px(56))

      sectionTitle(title: importantDatesTitle)
      Grid(alignment: .stretch, spacing: 20) {
        ForEach(importantDates) { item in
          VStack(alignment: .center) {
            Text(item.title)
              .font(.title5)
              .fontWeight(.bold)
              .foregroundStyle(.darkBlue)
              .margin(.bottom, .px(12))

            Text(item.date)
              .font(.lead)
              .foregroundStyle(.dimGray)
          }
          .padding(.vertical, .px(28))
          .padding(.horizontal, .px(20))
          .background(.white)
          .border(.init(hex: "#D9E2F2"), width: 1)
          .cornerRadius(20)
        }
      }
      .columns(4)
      .margin(.bottom, .px(56))

      sectionTitle(title: talkFormatsTitle)
      Grid(alignment: .stretch, spacing: 20) {
        ForEach(talkFormats) { format in
          VStack(alignment: .leading) {
            Text(format.title)
              .font(.title4)
              .fontWeight(.bold)
              .foregroundStyle(.darkBlue)
              .margin(.bottom, .px(8))

            Text(format.duration)
              .font(.lead)
              .fontWeight(.semibold)
              .foregroundStyle(.orangeRed)
              .margin(.bottom, .px(12))

            Text(format.description)
              .foregroundStyle(.dimGray)
          }
          .padding(.all, .px(24))
          .background(.init(hex: "#F7F9FC"))
          .border(.init(hex: "#D9E2F2"), width: 1)
          .cornerRadius(20)
        }
      }
      .columns(2)
      .margin(.bottom, .px(56))

      sectionTitle(title: topicsTitle)
      Grid(alignment: .stretch, spacing: 20) {
        ForEach(topics) { topic in
          VStack(alignment: .leading) {
            Text(topic.title)
              .font(.title5)
              .fontWeight(.bold)
              .foregroundStyle(.darkBlue)
              .margin(.bottom, .px(8))

            Text(topic.description)
              .foregroundStyle(.dimGray)
          }
          .padding(.all, .px(24))
          .background(.white)
          .border(.init(hex: "#D9E2F2"), width: 1)
          .cornerRadius(20)
        }
      }
      .columns(3)
      .margin(.bottom, .px(56))

      VStack(alignment: .center) {
        Text(finalTitle)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(.darkBlue)
          .margin(.bottom, .px(12))

        Text(finalDescription)
          .font(.lead)
          .foregroundStyle(.dimGray)
          .margin(.bottom, .px(24))

        Link(primaryActionLabel, target: "https://cfp.tryswift.jp/submit")
          .target(.newWindow)
          .linkStyle(.button)
          .role(.primary)
          .fontWeight(.semibold)
      }
      .padding(.vertical, .px(40))
      .padding(.horizontal, .px(24))
      .background(.init(hex: "#F2F7FF"))
      .cornerRadius(24)
    }
    .padding(.all, .px(24))
    .horizontalAlignment(.center)
  }

  @HTMLBuilder
  private func sectionTitle(title: String) -> some HTML {
    Text(title)
      .font(.title3)
      .fontWeight(.bold)
      .foregroundStyle(.darkBlue)
      .margin(.bottom, .px(24))
  }

  private var heroEyebrow: String {
    switch language {
    case .ja: "try! Swift Tokyo 2026"
    case .en: "try! Swift Tokyo 2026"
    }
  }

  private var heroTitle: String {
    switch language {
    case .ja: "Call for Proposals"
    case .en: "Call for Proposals"
    }
  }

  private var heroDescription: String {
    switch language {
    case .ja:
      "世界中の Swift 開発者に向けて、あなたの知見を共有しませんか。try! Swift Tokyo 2026 のセッション提案を募集しています。"
    case .en:
      "Share your Swift expertise with developers from around the world. Submit your talk proposal for try! Swift Tokyo 2026."
    }
  }

  private var primaryActionLabel: String {
    switch language {
    case .ja: "プロポーザルを提出"
    case .en: "Submit Your Proposal"
    }
  }

  private var secondaryActionLabel: String {
    switch language {
    case .ja: "ガイドラインを見る"
    case .en: "View Guidelines"
    }
  }

  private var workshopsActionLabel: String {
    switch language {
    case .ja: "ワークショップを見る"
    case .en: "View Workshops"
    }
  }

  private var importantDatesTitle: String {
    switch language {
    case .ja: "重要日程"
    case .en: "Important Dates"
    }
  }

  private var talkFormatsTitle: String {
    switch language {
    case .ja: "トーク形式"
    case .en: "Talk Formats"
    }
  }

  private var topicsTitle: String {
    switch language {
    case .ja: "募集トピック"
    case .en: "Topics We're Looking For"
    }
  }

  private var finalTitle: String {
    switch language {
    case .ja: "あなたの知識をシェアしませんか？"
    case .en: "Ready to Share Your Knowledge?"
    }
  }

  private var finalDescription: String {
    switch language {
    case .ja: "登壇経験は問いません。初めての CfP 応募も歓迎しています。"
    case .en:
      "We welcome speakers of all experience levels. First-time speakers are encouraged to apply!"
    }
  }

  private var importantDates: [ImportantDate] {
    switch language {
    case .ja:
      [
        .init(id: "open", title: "CfP 開始", date: "2026年1月15日"),
        .init(id: "deadline", title: "提出締切", date: "2026年2月1日"),
        .init(id: "notification", title: "結果通知", date: "2026年2月8日"),
        .init(id: "conference", title: "カンファレンス", date: "2026年4月12日 - 14日"),
      ]
    case .en:
      [
        .init(id: "open", title: "CfP Opens", date: "January 15, 2026"),
        .init(id: "deadline", title: "Submission Deadline", date: "February 1, 2026"),
        .init(id: "notification", title: "Notifications", date: "February 8, 2026"),
        .init(id: "conference", title: "Conference", date: "April 12-14, 2026"),
      ]
    }
  }

  private var talkFormats: [TalkFormat] {
    switch language {
    case .ja:
      [
        .init(
          id: "regular",
          title: "Regular Talk",
          duration: "20分",
          description: "ひとつのテーマをしっかり深掘りするセッション形式です。具体例やデモを交えながら、学びを持ち帰れる内容を歓迎します。"
        ),
        .init(
          id: "lightning",
          title: "Lightning Talk",
          duration: "5分",
          description: "ひとつのアイデアや Tips をすばやく共有する短い発表です。初登壇の方や、鋭い知見をコンパクトに届けたい方にも向いています。"
        ),
      ]
    case .en:
      [
        .init(
          id: "regular",
          title: "Regular Talk",
          duration: "20 minutes",
          description:
            "Deep dive into a specific topic with detailed examples and live demos. Perfect for sharing comprehensive knowledge about Swift development."
        ),
        .init(
          id: "lightning",
          title: "Lightning Talk",
          duration: "5 minutes",
          description:
            "Quick, focused presentation on a single idea, tip, or tool. Great for first-time speakers or sharing quick wins!"
        ),
      ]
    }
  }

  private var topics: [Topic] {
    switch language {
    case .ja:
      [
        .init(id: "swift", title: "Swift Language", description: "新機能、ベストプラクティス、言語進化に関する内容"),
        .init(id: "swiftui", title: "SwiftUI", description: "モダンな UI 開発、アニメーション、設計に関する内容"),
        .init(id: "platforms", title: "iOS/macOS/visionOS", description: "各プラットフォーム固有の API や開発知見"),
        .init(id: "server", title: "Server-Side Swift", description: "Vapor、バックエンド開発、クラウド運用に関する内容"),
        .init(id: "testing", title: "Testing & Quality", description: "ユニットテスト、UI テスト、コード品質の改善"),
        .init(id: "tools", title: "Tools & Productivity", description: "Xcode、デバッグ、開発体験向上に関する内容"),
      ]
    case .en:
      [
        .init(
          id: "swift", title: "Swift Language",
          description: "New features, best practices, and language evolution"),
        .init(
          id: "swiftui", title: "SwiftUI",
          description: "Modern UI development, animations, and architecture"),
        .init(
          id: "platforms", title: "iOS/macOS/visionOS",
          description: "Platform-specific development and APIs"),
        .init(
          id: "server", title: "Server-Side Swift",
          description: "Vapor, backend development, and cloud deployment"),
        .init(
          id: "testing", title: "Testing & Quality",
          description: "Unit testing, UI testing, and code quality"),
        .init(
          id: "tools", title: "Tools & Productivity",
          description: "Xcode, debugging, and developer experience"),
      ]
    }
  }
}
