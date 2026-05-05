import Foundation
import SharedModels
import Testing

@testable import Server

@Suite("SponsorEmailTemplates")
struct SponsorEmailTemplatesTests {
  @Test("magic-link subject is locale-specific")
  func magicLinkSubject() {
    let url = URL(string: "https://sponsor.tryswift.jp/auth/verify?token=x")!
    let ja = SponsorEmailTemplates.render(
      .magicLink(verifyURL: url, ttlMinutes: 30),
      locale: .ja, recipientName: nil)
    let en = SponsorEmailTemplates.render(
      .magicLink(verifyURL: url, ttlMinutes: 30),
      locale: .en, recipientName: nil)
    #expect(ja.subject.contains("ログイン"))
    #expect(en.subject.lowercased().contains("login"))
  }

  @Test("application-approved includes plan name and recipient")
  func approvedShowsPlan() {
    let url = URL(string: "https://sponsor.tryswift.jp/applications/abc")!
    let m = SponsorEmailTemplates.render(
      .applicationApproved(planName: "Gold", nextStepsURL: url),
      locale: .en, recipientName: "Pat")
    #expect(m.textBody.contains("Gold"))
    #expect(m.textBody.contains("Pat"))
  }
}
