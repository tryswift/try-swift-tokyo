/// Localized strings for CfP pages
enum CfPStrings {
  // MARK: - Navigation
  enum Navigation {
    static func home(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Home"
      case .ja: return "ホーム"
      }
    }

    static func guidelines(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Guidelines"
      case .ja: return "ガイドライン"
      }
    }

    static func submit(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit"
      case .ja: return "応募する"
      }
    }

    static func myProposals(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "My Proposals"
      case .ja: return "応募履歴"
      }
    }

    static func signOut(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign Out"
      case .ja: return "ログアウト"
      }
    }

    static func loginWithGitHub(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Login with GitHub"
      case .ja: return "GitHubでログイン"
      }
    }
  }

  // MARK: - Home Page
  enum Home {
    static func heroSubtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "try! Swift Tokyo 2026"
      case .ja: return "try! Swift Tokyo 2026"
      }
    }

    static func heroTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Call for Proposals"
      case .ja: return "スピーカー募集"
      }
    }

    static func heroDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Share your Swift expertise with developers from around the world. Submit your talk proposal for try! Swift Tokyo 2026!"
      case .ja:
        return "あなたのSwiftの知識を世界中の開発者と共有しませんか？try! Swift Tokyo 2026でのトーク応募をお待ちしています！"
      }
    }

    static func submitYourProposal(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit Your Proposal"
      case .ja: return "応募する"
      }
    }

    static func viewGuidelines(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "View Guidelines"
      case .ja: return "ガイドラインを見る"
      }
    }

    static func myProposals(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "My Proposals"
      case .ja: return "応募履歴"
      }
    }

    static func allProposals(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "All Proposals"
      case .ja: return "全応募一覧"
      }
    }

    static func importantDates(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Important Dates"
      case .ja: return "重要な日程"
      }
    }

    static func cfpOpens(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "CfP Opens"
      case .ja: return "募集開始"
      }
    }

    static func cfpOpensDate(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "January 15, 2026"
      case .ja: return "2026年1月15日"
      }
    }

    static func submissionDeadline(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submission Deadline"
      case .ja: return "応募締切"
      }
    }

    static func submissionDeadlineDate(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "February 1, 2026"
      case .ja: return "2026年2月1日"
      }
    }

    static func notifications(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Notifications"
      case .ja: return "選考結果通知"
      }
    }

    static func notificationsDate(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "February 8, 2026"
      case .ja: return "2026年2月8日"
      }
    }

    static func conference(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Conference"
      case .ja: return "カンファレンス"
      }
    }

    static func conferenceDate(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "April 12-14, 2026"
      case .ja: return "2026年4月12日〜14日"
      }
    }

    static func talkFormats(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Talk Formats"
      case .ja: return "トークの形式"
      }
    }

    static func regularTalk(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Regular Talk"
      case .ja: return "レギュラートーク"
      }
    }

    static func regularTalkDuration(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "20 minutes"
      case .ja: return "20分"
      }
    }

    static func regularTalkDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Deep dive into a specific topic with detailed examples and live demos. Perfect for sharing comprehensive knowledge about Swift development."
      case .ja:
        return
          "特定のトピックを詳細な例やライブデモとともに深く掘り下げます。Swift開発に関する包括的な知識を共有するのに最適です。"
      }
    }

    static func lightningTalk(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Lightning Talk"
      case .ja: return "ライトニングトーク"
      }
    }

    static func lightningTalkDuration(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "5 minutes"
      case .ja: return "5分"
      }
    }

    static func lightningTalkDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Quick, focused presentation on a single idea, tip, or tool. Great for first-time speakers or sharing quick wins!"
      case .ja:
        return "1つのアイデア、Tips、ツールに焦点を当てた短いプレゼンテーション。初めてのスピーカーや、ちょっとしたTipsの共有に最適です！"
      }
    }

    static func topicsTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Topics We're Looking For"
      case .ja: return "募集トピック"
      }
    }

    static func topicSwiftLanguage(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Swift Language"
      case .ja: return "Swift言語"
      }
    }

    static func topicSwiftLanguageDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "New features, best practices, and language evolution"
      case .ja: return "新機能、ベストプラクティス、言語の進化"
      }
    }

    static func topicSwiftUI(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "SwiftUI"
      case .ja: return "SwiftUI"
      }
    }

    static func topicSwiftUIDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Modern UI development, animations, and architecture"
      case .ja: return "モダンなUI開発、アニメーション、アーキテクチャ"
      }
    }

    static func topicPlatforms(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "iOS/macOS/visionOS"
      case .ja: return "iOS/macOS/visionOS"
      }
    }

    static func topicPlatformsDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Platform-specific development and APIs"
      case .ja: return "プラットフォーム固有の開発とAPI"
      }
    }

    static func topicServerSide(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Server-Side Swift"
      case .ja: return "サーバーサイドSwift"
      }
    }

    static func topicServerSideDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Vapor, backend development, and cloud deployment"
      case .ja: return "Vapor、バックエンド開発、クラウドデプロイメント"
      }
    }

    static func topicTesting(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Testing & Quality"
      case .ja: return "テストと品質"
      }
    }

    static func topicTestingDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Unit testing, UI testing, and code quality"
      case .ja: return "ユニットテスト、UIテスト、コード品質"
      }
    }

    static func topicTools(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Tools & Productivity"
      case .ja: return "ツールと生産性"
      }
    }

    static func topicToolsDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Xcode, debugging, and developer experience"
      case .ja: return "Xcode、デバッグ、開発者体験"
      }
    }

    static func ctaTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Ready to Share Your Knowledge?"
      case .ja: return "あなたの知識を共有しませんか？"
      }
    }

    static func ctaDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "We welcome speakers of all experience levels. First-time speakers are encouraged to apply!"
      case .ja: return "経験レベルを問わず、すべてのスピーカーを歓迎します。初めての方もぜひご応募ください！"
      }
    }
  }

  // MARK: - Guidelines Page
  enum Guidelines {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submission Guidelines"
      case .ja: return "応募ガイドライン"
      }
    }

    static func subtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Everything you need to know about submitting a talk proposal for try! Swift Tokyo 2026."
      case .ja: return "try! Swift Tokyo 2026へのトーク応募に必要なすべての情報をご紹介します。"
      }
    }

    static func whatWereLookingFor(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "What We're Looking For"
      case .ja: return "求めるトーク"
      }
    }

    static func lookingForItem1(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Original content that hasn't been presented at other major conferences"
      case .ja: return "他の主要カンファレンスで発表されていないオリジナルコンテンツ"
      }
    }

    static func lookingForItem2(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Practical knowledge that attendees can apply in their work"
      case .ja: return "参加者が仕事で活用できる実践的な知識"
      }
    }

    static func lookingForItem3(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Clear learning outcomes for the audience"
      case .ja: return "明確な学習成果"
      }
    }

    static func lookingForItem4(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Well-structured presentations with demos when applicable"
      case .ja: return "適切な場合にはデモを含む、よく構成されたプレゼンテーション"
      }
    }

    static func lookingForItem5(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Topics relevant to the Swift community"
      case .ja: return "Swiftコミュニティに関連するトピック"
      }
    }

    static func talkFormats(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Talk Formats"
      case .ja: return "トークの形式"
      }
    }

    static func regularTalkTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Regular Talk (20 minutes)"
      case .ja: return "レギュラートーク（20分）"
      }
    }

    static func regularTalkDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "A comprehensive session covering a topic in depth. Include time for context, examples, and key takeaways. Live coding and demos are welcome!"
      case .ja:
        return
          "トピックを深く掘り下げる包括的なセッション。背景、例、重要なポイントを含めてください。ライブコーディングやデモも歓迎します！"
      }
    }

    static func lightningTalkTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Lightning Talk (5 minutes)"
      case .ja: return "ライトニングトーク（5分）"
      }
    }

    static func lightningTalkDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "A focused, fast-paced presentation covering a single concept, tool, or tip. Perfect for sharing quick wins or introducing new ideas."
      case .ja:
        return
          "単一のコンセプト、ツール、またはTipsを扱う、集中した短いプレゼンテーション。ちょっとしたTipsの共有や新しいアイデアの紹介に最適です。"
      }
    }

    static func proposalRequirements(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Proposal Requirements"
      case .ja: return "応募要件"
      }
    }

    static func reqTitleLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Title"
      case .ja: return "タイトル"
      }
    }

    static func reqTitleDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "A clear, descriptive title that accurately represents your talk content."
      case .ja: return "トークの内容を正確に表す、明確で説明的なタイトル。"
      }
    }

    static func reqAbstractLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Abstract"
      case .ja: return "概要"
      }
    }

    static func reqAbstractDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "A 2-3 sentence summary that will be shown publicly if your talk is accepted. This should explain what attendees will learn."
      case .ja:
        return "トークが採択された場合に公開される2〜3文の要約。参加者が何を学べるかを説明してください。"
      }
    }

    static func reqTalkDetailsLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Talk Details"
      case .ja: return "トークの詳細"
      }
    }

    static func reqTalkDetailsDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "A detailed description of your talk for reviewers. Include your outline, key points, and any demos you plan to show. This helps us understand your vision."
      case .ja:
        return
          "レビュアー向けのトークの詳細な説明。アウトライン、主要なポイント、予定しているデモを含めてください。これにより、あなたのビジョンを理解できます。"
      }
    }

    static func reqSpeakerBioLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Speaker Bio"
      case .ja: return "スピーカー紹介"
      }
    }

    static func reqSpeakerBioDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Tell us about yourself! Your background, experience, and what makes you excited about this topic."
      case .ja: return "自己紹介をお願いします！あなたの経歴、経験、このトピックに対する情熱について教えてください。"
      }
    }

    static func reqNotesLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Notes (Optional)"
      case .ja: return "備考（任意）"
      }
    }

    static func reqNotesDesc(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "Any additional information for organizers, such as accessibility needs, scheduling constraints, or whether you've given this talk before."
      case .ja:
        return
          "運営者への追加情報（アクセシビリティの要件、スケジュールの制約、このトークを以前に行ったことがあるかなど）。"
      }
    }

    static func selectionCriteria(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Selection Criteria"
      case .ja: return "選考基準"
      }
    }

    static func selectionCriteriaIntro(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Our review committee evaluates proposals based on:"
      case .ja: return "選考委員会は以下の基準で応募を評価します："
      }
    }

    static func criteriaItem1(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Relevance to the Swift community"
      case .ja: return "Swiftコミュニティへの関連性"
      }
    }

    static func criteriaItem2(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Originality and uniqueness of content"
      case .ja: return "コンテンツの独自性とユニークさ"
      }
    }

    static func criteriaItem3(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Clarity of proposal and learning outcomes"
      case .ja: return "応募内容と学習成果の明確さ"
      }
    }

    static func criteriaItem4(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Speaker's expertise and presentation ability"
      case .ja: return "スピーカーの専門知識とプレゼンテーション能力"
      }
    }

    static func criteriaItem5(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Diversity of topics across the conference program"
      case .ja: return "カンファレンスプログラム全体のトピックの多様性"
      }
    }

    static func tipsTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Tips for a Great Proposal"
      case .ja: return "良い応募のためのヒント"
      }
    }

    static func tipItem1(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Be specific about what attendees will learn"
      case .ja: return "参加者が何を学べるかを具体的に"
      }
    }

    static func tipItem2(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Include a clear outline or structure"
      case .ja: return "明確なアウトラインや構成を含める"
      }
    }

    static func tipItem3(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Mention any demos or live coding"
      case .ja: return "デモやライブコーディングがあれば記載する"
      }
    }

    static func tipItem4(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Show your passion for the topic"
      case .ja: return "トピックへの情熱を示す"
      }
    }

    static func tipItem5(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Proofread your submission carefully"
      case .ja: return "応募内容を注意深く校正する"
      }
    }

    static func tipItem6(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Don't be afraid to submit multiple proposals!"
      case .ja: return "複数の応募を躊躇しないでください！"
      }
    }

    static func speakerBenefits(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Speaker Benefits"
      case .ja: return "スピーカー特典"
      }
    }

    static func benefitItem1(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Free conference ticket"
      case .ja: return "カンファレンスチケット無料"
      }
    }

    static func benefitItem2(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Speaker dinner with other speakers and organizers"
      case .ja: return "他のスピーカーや運営者とのスピーカーディナー"
      }
    }

    static func benefitItem3(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Travel support available for international speakers"
      case .ja: return "海外スピーカーへの渡航サポートあり"
      }
    }

    static func benefitItem4(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Professional video recording of your talk"
      case .ja: return "トークのプロによる動画撮影"
      }
    }

    static func benefitItem5(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Networking opportunities with Swift developers worldwide"
      case .ja: return "世界中のSwift開発者とのネットワーキング機会"
      }
    }
  }

  // MARK: - Submit Page
  enum Submit {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit Your Proposal"
      case .ja: return "トークを応募する"
      }
    }

    static func subtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Share your Swift expertise with developers from around the world."
      case .ja: return "あなたのSwiftの知識を世界中の開発者と共有しましょう。"
      }
    }

    static func cfpNotOpen(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Call for Proposals Not Open"
      case .ja: return "スピーカー募集は終了しています"
      }
    }

    static func cfpNotOpenDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return
          "The Call for Proposals is not currently open. Please check back later for the next conference."
      case .ja: return "現在、スピーカー募集は行っていません。次回のカンファレンスをお待ちください。"
      }
    }

    static func backToHome(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Back to Home"
      case .ja: return "ホームに戻る"
      }
    }

    static func proposalSubmitted(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Proposal Submitted!"
      case .ja: return "応募完了！"
      }
    }

    static func proposalSubmittedDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Your proposal has been submitted successfully. Good luck!"
      case .ja: return "応募が正常に送信されました。幸運を祈ります！"
      }
    }

    static func viewMyProposals(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "View My Proposals"
      case .ja: return "応募履歴を見る"
      }
    }

    static func submitAnother(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit Another"
      case .ja: return "別の応募をする"
      }
    }

    static func signInRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign In Required"
      case .ja: return "ログインが必要です"
      }
    }

    static func signInDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return "Connect your GitHub account to submit proposals and track your submissions."
      case .ja: return "GitHubアカウントを連携して、応募の送信と履歴の確認を行いましょう。"
      }
    }

    static func signInWithGitHub(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign in with GitHub"
      case .ja: return "GitHubでログイン"
      }
    }

    static func formTitleLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Title *"
      case .ja: return "タイトル *"
      }
    }

    static func formTitlePlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Enter your talk title"
      case .ja: return "トークのタイトルを入力"
      }
    }

    static func formAbstractLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Abstract *"
      case .ja: return "概要 *"
      }
    }

    static func formAbstractPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "A brief summary of your talk (2-3 sentences)"
      case .ja: return "トークの簡単な要約（2〜3文）"
      }
    }

    static func formAbstractHint(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "This will be shown to the audience if your talk is accepted."
      case .ja: return "トークが採択された場合、聴衆に公開されます。"
      }
    }

    static func formTalkDetailsLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Talk Details *"
      case .ja: return "トークの詳細 *"
      }
    }

    static func formTalkDetailsPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Detailed description for reviewers"
      case .ja: return "レビュアー向けの詳細な説明"
      }
    }

    static func formTalkDetailsHint(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en:
        return "Include outline, key points, and what attendees will learn. For reviewers only."
      case .ja: return "アウトライン、主要なポイント、参加者が学べることを含めてください。レビュアー専用です。"
      }
    }

    static func formDurationLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Talk Duration *"
      case .ja: return "トークの長さ *"
      }
    }

    static func formDurationPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Choose duration..."
      case .ja: return "長さを選択..."
      }
    }

    static func formDurationRegular(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Regular Talk (20 minutes)"
      case .ja: return "レギュラートーク（20分）"
      }
    }

    static func formDurationLightning(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Lightning Talk (5 minutes)"
      case .ja: return "ライトニングトーク（5分）"
      }
    }

    static func formBioLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Speaker Bio *"
      case .ja: return "スピーカー紹介 *"
      }
    }

    static func formBioPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Tell us about yourself"
      case .ja: return "自己紹介をお願いします"
      }
    }

    static func formIconUrlLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Profile Picture URL (Optional)"
      case .ja: return "プロフィール画像URL（任意）"
      }
    }

    static func formNotesLabel(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Notes for Organizers (Optional)"
      case .ja: return "運営者への備考（任意）"
      }
    }

    static func formNotesPlaceholder(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Any special requirements or additional information"
      case .ja: return "特別な要件や追加情報があれば"
      }
    }

    static func submitProposal(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit Proposal"
      case .ja: return "応募を送信"
      }
    }
  }

  // MARK: - My Proposals Page
  enum MyProposals {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "My Proposals"
      case .ja: return "応募履歴"
      }
    }

    static func subtitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "View and manage your submitted talk proposals."
      case .ja: return "送信したトーク応募の確認と管理。"
      }
    }

    static func organizer(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Organizer"
      case .ja: return "運営者"
      }
    }

    static func speaker(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Speaker"
      case .ja: return "スピーカー"
      }
    }

    static func logout(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Logout"
      case .ja: return "ログアウト"
      }
    }

    static func yourSubmissions(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Your Submissions"
      case .ja: return "あなたの応募"
      }
    }

    static func noProposalsYet(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "No proposals yet"
      case .ja: return "まだ応募がありません"
      }
    }

    static func submitFirstProposal(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit your first proposal to see it here."
      case .ja: return "最初の応募を送信するとここに表示されます。"
      }
    }

    static func submitAProposal(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit a Proposal"
      case .ja: return "応募する"
      }
    }

    static func submitAnotherProposal(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit Another Proposal"
      case .ja: return "別の応募をする"
      }
    }

    static func signInRequired(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign In Required"
      case .ja: return "ログインが必要です"
      }
    }

    static func signInDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Please sign in to view your proposals."
      case .ja: return "応募履歴を見るにはログインしてください。"
      }
    }
  }

  // MARK: - Login Page
  enum Login {
    static func title(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Login"
      case .ja: return "ログイン"
      }
    }

    static func loginFailed(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Login failed: "
      case .ja: return "ログイン失敗: "
      }
    }

    static func welcomeUser(_ lang: CfPLanguage, username: String) -> String {
      switch lang {
      case .en: return "Welcome, \(username)!"
      case .ja: return "ようこそ、\(username)さん！"
      }
    }

    static func welcomeDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "You are now signed in. You can submit and manage your talk proposals."
      case .ja: return "ログインしました。トークの応募と管理ができます。"
      }
    }

    static func submitAProposal(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Submit a Proposal"
      case .ja: return "応募する"
      }
    }

    static func myProposals(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "My Proposals"
      case .ja: return "応募履歴"
      }
    }

    static func logout(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Logout"
      case .ja: return "ログアウト"
      }
    }

    static func signInTitle(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign in to try! Swift CfP"
      case .ja: return "try! Swift CfPにログイン"
      }
    }

    static func signInDescription(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Connect your GitHub account to submit and manage your talk proposals."
      case .ja: return "GitHubアカウントを連携して、トークの応募と管理を行いましょう。"
      }
    }

    static func signInWithGitHub(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Sign in with GitHub"
      case .ja: return "GitHubでログイン"
      }
    }

    static func termsNotice(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "By signing in, you agree to our terms of service and privacy policy."
      case .ja: return "ログインすると、利用規約とプライバシーポリシーに同意したことになります。"
      }
    }
  }

  // MARK: - Footer
  enum Footer {
    static func mainWebsite(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Main Website"
      case .ja: return "メインサイト"
      }
    }

    static func codeOfConduct(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Code of Conduct"
      case .ja: return "行動規範"
      }
    }

    static func privacyPolicy(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "Privacy Policy"
      case .ja: return "プライバシーポリシー"
      }
    }
  }
}
