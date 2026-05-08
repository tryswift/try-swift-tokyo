import Foundation
import SharedModels

enum ScholarshipEmailKind: Sendable {
  case magicLink(verifyURL: URL, ttlMinutes: Int)
  case applicationReceived(conferenceName: String)
  case applicationApproved(conferenceName: String, approvedAmountYen: Int)
  case applicationRejected(conferenceName: String, reason: String?)
}

enum ScholarshipEmailTemplates {
  static func render(
    _ kind: ScholarshipEmailKind,
    locale: ScholarshipPortalLocale,
    recipientName: String?
  ) -> EmailMessage {
    let greeting = greeting(for: recipientName, locale: locale)
    switch kind {
    case .magicLink(let url, let ttl):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】学生スカラシップ ログインリンク",
          body:
            "\(greeting)\n\n以下のリンクから\(ttl)分以内にログインしてください。\n\(url.absoluteString)\n\n— try! Swift Tokyo Scholarship Team"
        )
        : message(
          "[try! Swift Tokyo] Scholarship login link",
          body:
            "\(greeting)\n\nUse the link below within \(ttl) minutes to log in.\n\(url.absoluteString)\n\n— try! Swift Tokyo Scholarship Team"
        )

    case .applicationReceived(let conferenceName):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(conferenceName) スカラシップ申請を受け付けました",
          body:
            "\(greeting)\n\n\(conferenceName) の学生スカラシップ申請を受け付けました。\nオーガナイザーが内容を確認のうえ、改めてご連絡いたします。"
        )
        : message(
          "[try! Swift Tokyo] Application received: \(conferenceName)",
          body:
            "\(greeting)\n\nWe received your scholarship application for \(conferenceName). The organizers will review it and get back to you."
        )

    case .applicationApproved(let conferenceName, let amount):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(conferenceName) スカラシップ申請が承認されました",
          body:
            "\(greeting)\n\n\(conferenceName) のスカラシップ申請が承認されました。\n承認額: ¥\(amount)\n\n後ほどオーガナイザーより手続きについてご連絡します。"
        )
        : message(
          "[try! Swift Tokyo] Approved: \(conferenceName) scholarship",
          body:
            "\(greeting)\n\nYour \(conferenceName) scholarship application has been approved.\nApproved amount: ¥\(amount)\n\nThe organizers will follow up with the next steps."
        )

    case .applicationRejected(let conferenceName, let reason):
      let reasonText = reason?.isEmpty == false ? reason! : nil
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(conferenceName) スカラシップ申請について",
          body:
            "\(greeting)\n\n\(conferenceName) のスカラシップ申請について、今回はお見送りとさせていただきました。\(reasonText.map { "\n理由: \($0)" } ?? "")\n\nまたの機会をお待ちしております。"
        )
        : message(
          "[try! Swift Tokyo] About your \(conferenceName) scholarship application",
          body:
            "\(greeting)\n\nUnfortunately we were unable to approve your \(conferenceName) scholarship application this time.\(reasonText.map { "\nReason: \($0)" } ?? "")\n\nWe appreciate your interest."
        )
    }
  }

  private static func greeting(for name: String?, locale: ScholarshipPortalLocale) -> String {
    let n = name?.isEmpty == false ? name! : (locale == .ja ? "申請者" : "there")
    return locale == .ja ? "\(n) 様" : "Hi \(n),"
  }

  private static func message(_ subject: String, body: String) -> EmailMessage {
    let html = "<pre style=\"font-family: ui-monospace, monospace\">\(escapeHTML(body))</pre>"
    return EmailMessage(subject: subject, htmlBody: html, textBody: body)
  }

  private static func escapeHTML(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }
}
