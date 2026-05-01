import Fluent
import Foundation
import JWT
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("SponsorApplicationFlow")
struct SponsorApplicationFlowTests {
  @Test("Owner can submit application; subsequent withdraw flips status")
  func submitAndWithdraw() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    let conference = try await SponsorTestEnv.conference(app)
    let (org, owner) = try await SponsorTestEnv.organization(app, ownerEmail: "o@example.com")
    _ = try await SponsorTestEnv.plan(
      app, conference: conference, slug: "gold", priceJPY: 1_000_000)

    // Forge a sponsor session cookie
    let payload = SponsorJWTPayload(
      userID: try owner.requireID(),
      orgID: try org.requireID(),
      role: .owner,
      locale: .ja
    )
    let cookieValue = try await app.jwt.keys.sign(payload)
    let cookieHeader = "\(SponsorAuthCookie.name)=\(cookieValue)"

    // Mount auth middleware + portal so cookies work
    let group = app.grouped(SponsorAuthMiddleware(onMissingRedirectTo: nil))
    try group.register(collection: SponsorApplicationController())

    // POST /applications
    try await app.testing().test(
      .POST, "applications",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
        try req.content.encode(
          [
            "planSlug": "gold",
            "billingContactName": "Alice",
            "billingEmail": "billing@example.com",
            "invoicingNotes": "",
            "logoNote": "",
            "acceptedTerms": "true",
          ], as: .urlEncodedForm)
      }
    ) { res in
      #expect(res.status == .seeOther)
    }

    let saved = try await SponsorApplication.query(on: app.db).first()
    #expect(saved?.status == .submitted)
    let appID = try saved!.requireID()

    // POST /applications/<id>/withdraw
    try await app.testing().test(
      .POST, "applications/\(appID.uuidString)/withdraw",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .seeOther)
    }

    let after = try await SponsorApplication.find(appID, on: app.db)
    #expect(after?.status == .withdrawn)
  }
}
