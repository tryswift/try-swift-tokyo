import Foundation
import SharedModels

enum SponsorEmailKind: Sendable {
  case magicLink(verifyURL: URL, ttlMinutes: Int)
  case inquiryReceived(materialsURL: URL)
  case memberInvite(orgName: String, inviterName: String, acceptURL: URL)
  case applicationReceived(planName: String)
  case applicationApproved(planName: String, nextStepsURL: URL)
  case applicationRejected(planName: String, reason: String)
}

struct EmailMessage: Sendable {
  let subject: String
  let htmlBody: String
  let textBody: String
}

enum SponsorEmailTemplates {
  static func render(
    _ kind: SponsorEmailKind,
    locale: SponsorPortalLocale,
    recipientName: String?
  ) -> EmailMessage {
    let greeting = greeting(for: recipientName, locale: locale)
    switch kind {
    case .magicLink(let url, let ttl):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】スポンサーポータル ログインリンク",
          body:
            "\(greeting)\n\n以下のリンクから\(ttl)分以内にログインしてください。\n\(url.absoluteString)\n\n— try! Swift Tokyo Sponsorship Team"
        )
        : message(
          "[try! Swift Tokyo] Sponsor portal login link",
          body:
            "\(greeting)\n\nUse the link below within \(ttl) minutes to log in.\n\(url.absoluteString)\n\n— try! Swift Tokyo Sponsorship Team"
        )

    case .inquiryReceived(let materialsURL):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】資料をお届けします",
          body:
            "\(greeting)\n\nスポンサー資料をご請求いただきありがとうございます。以下より資料をご確認ください。\n\(materialsURL.absoluteString)\n\nご検討よろしくお願いいたします。"
        )
        : message(
          "[try! Swift Tokyo] Sponsor materials",
          body:
            "\(greeting)\n\nThank you for requesting our sponsor pack. Materials are available here:\n\(materialsURL.absoluteString)"
        )

    case .memberInvite(let orgName, let inviterName, let acceptURL):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(orgName) への参加招待",
          body:
            "\(greeting)\n\n\(inviterName) さんから \(orgName) へ招待されました。以下より参加してください。\n\(acceptURL.absoluteString)"
        )
        : message(
          "[try! Swift Tokyo] You've been invited to \(orgName)",
          body:
            "\(greeting)\n\n\(inviterName) invited you to join \(orgName). Accept here:\n\(acceptURL.absoluteString)"
        )

    case .applicationReceived(let planName):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(planName) プラン申込を受け付けました",
          body:
            "\(greeting)\n\n\(planName) プランの申込を受け付けました。Organizer の確認後、改めてご連絡いたします。"
        )
        : message(
          "[try! Swift Tokyo] Application received: \(planName)",
          body:
            "\(greeting)\n\nWe received your \(planName) sponsorship application. We'll get back to you after Organizer review."
        )

    case .applicationApproved(let planName, let nextStepsURL):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(planName) プラン申込が承認されました",
          body:
            "\(greeting)\n\n\(planName) プランの申込が承認されました。次のステップ:\n\(nextStepsURL.absoluteString)"
        )
        : message(
          "[try! Swift Tokyo] Approved: \(planName)",
          body:
            "\(greeting)\n\nYour \(planName) sponsorship has been approved! Next steps:\n\(nextStepsURL.absoluteString)"
        )

    case .applicationRejected(let planName, let reason):
      return locale == .ja
        ? message(
          "【try! Swift Tokyo】\(planName) プラン申込について",
          body:
            "\(greeting)\n\n\(planName) プランの申込について、今回はお見送りとさせていただきました。\n理由: \(reason)\n\nまたの機会をお待ちしております。"
        )
        : message(
          "[try! Swift Tokyo] About your \(planName) application",
          body:
            "\(greeting)\n\nUnfortunately we were unable to confirm your \(planName) application this time.\nReason: \(reason)\n\nWe appreciate your interest."
        )
    }
  }

  private static func greeting(for name: String?, locale: SponsorPortalLocale) -> String {
    let n = name?.isEmpty == false ? name! : (locale == .ja ? "ご担当者" : "there")
    return locale == .ja ? "\(n) 様" : "Hi \(n),"
  }

  private static func message(_ subject: String, body: String) -> EmailMessage {
    let html =
      "<pre style=\"font-family: ui-monospace, monospace\">\(escapeHTML(body))</pre>"
    return EmailMessage(subject: subject, htmlBody: html, textBody: body)
  }

  private static func escapeHTML(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }
}
