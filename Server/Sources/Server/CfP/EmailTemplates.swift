/// Email type for speaker notifications
enum EmailType: String, CaseIterable, Sendable {
  case acceptance
  case rejection
}

/// Bilingual email templates for speaker notifications
enum EmailTemplates {

  /// Escape HTML special characters to prevent XSS
  private static func escapeHTML(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }

  // MARK: - Acceptance Email

  enum Acceptance {
    static func subject(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "[try! Swift Tokyo 2026] Your Proposal Has Been Accepted!"
      case .ja: return "[try! Swift Tokyo 2026] プロポーザルが採択されました！"
      }
    }

    static func body(_ lang: CfPLanguage, speakerName: String, proposalTitle: String) -> String {
      let name = escapeHTML(speakerName)
      let title = escapeHTML(proposalTitle)
      switch lang {
      case .en:
        return """
          <html><body style="font-family: sans-serif; line-height: 1.6; color: #333;">
          <p>Dear \(name),</p>
          <p>Congratulations! We are thrilled to inform you that your proposal \
          &ldquo;<strong>\(title)</strong>&rdquo; has been accepted \
          for try! Swift Tokyo 2026!</p>
          <p>We will follow up with more details about the schedule, speaker benefits, \
          and logistics soon.</p>
          <p>Thank you for your contribution to the Swift community!</p>
          <p>Best regards,<br>try! Swift Tokyo Organizing Team</p>
          </body></html>
          """
      case .ja:
        return """
          <html><body style="font-family: sans-serif; line-height: 1.6; color: #333;">
          <p>\(name) 様</p>
          <p>おめでとうございます！「<strong>\(title)</strong>」が \
          try! Swift Tokyo 2026 に採択されましたことをお知らせいたします！</p>
          <p>スケジュール、スピーカー特典、ロジスティクスの詳細については、\
          後日改めてご連絡いたします。</p>
          <p>Swift コミュニティへのご貢献に感謝いたします！</p>
          <p>try! Swift Tokyo 運営チーム</p>
          </body></html>
          """
      }
    }
  }

  // MARK: - Rejection Email

  enum Rejection {
    static func subject(_ lang: CfPLanguage) -> String {
      switch lang {
      case .en: return "[try! Swift Tokyo 2026] CfP Review Result"
      case .ja: return "[try! Swift Tokyo 2026] CfP 選考結果のお知らせ"
      }
    }

    static func body(_ lang: CfPLanguage, speakerName: String, proposalTitle: String) -> String {
      let name = escapeHTML(speakerName)
      let title = escapeHTML(proposalTitle)
      switch lang {
      case .en:
        return """
          <html><body style="font-family: sans-serif; line-height: 1.6; color: #333;">
          <p>Dear \(name),</p>
          <p>Thank you for submitting your proposal &ldquo;<strong>\(title)</strong>&rdquo; \
          to try! Swift Tokyo 2026.</p>
          <p>After careful review by our selection committee, we regret to inform you \
          that your proposal was not selected for this year&rsquo;s conference.</p>
          <p>We received many outstanding proposals and the selection was extremely competitive. \
          We encourage you to apply again for future events.</p>
          <p>We hope to see you at the conference!</p>
          <p>Best regards,<br>try! Swift Tokyo Organizing Team</p>
          </body></html>
          """
      case .ja:
        return """
          <html><body style="font-family: sans-serif; line-height: 1.6; color: #333;">
          <p>\(name) 様</p>
          <p>try! Swift Tokyo 2026 へのプロポーザル「<strong>\(title)</strong>」の\
          ご応募ありがとうございました。</p>
          <p>選考委員会による慎重な審査の結果、誠に残念ながら今回は採択に至らなかったことを\
          お知らせいたします。</p>
          <p>多数の素晴らしいプロポーザルをいただき、大変競争の激しい選考となりました。\
          今後のイベントへのご応募をお待ちしております。</p>
          <p>カンファレンスでお会いできることを楽しみにしております！</p>
          <p>try! Swift Tokyo 運営チーム</p>
          </body></html>
          """
      }
    }
  }

  // MARK: - Preview Helper

  static func preview(
    type: EmailType,
    language: CfPLanguage,
    speakerName: String = "Speaker Name",
    proposalTitle: String = "Proposal Title"
  ) -> (subject: String, body: String) {
    switch type {
    case .acceptance:
      return (
        Acceptance.subject(language),
        Acceptance.body(language, speakerName: speakerName, proposalTitle: proposalTitle)
      )
    case .rejection:
      return (
        Rejection.subject(language),
        Rejection.body(language, speakerName: speakerName, proposalTitle: proposalTitle)
      )
    }
  }
}
