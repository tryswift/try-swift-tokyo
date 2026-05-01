import Fluent
import Foundation
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("SponsorInquiryFlow")
struct SponsorInquiryFlowTests {
  @Test("POST /inquiry creates SponsorUser + MagicLinkToken and redirects to thanks")
  func inquiryHappyPath() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    try app.register(collection: SponsorPublicController())

    try await app.testing().test(
      .POST, "inquiry",
      beforeRequest: { req in
        try req.content.encode(
          SponsorInquiryFormPayload(
            companyName: "Acme",
            contactName: "Alice",
            email: "alice@example.com",
            message: "interested in Gold",
            desiredPlanSlug: "gold"
          ))
      }
    ) { res in
      #expect(res.status == .seeOther)
      #expect(res.headers.first(name: .location) == "/inquiry/thanks")
    }

    let inquiry = try await SponsorInquiry.query(on: app.db).first()
    #expect(inquiry?.companyName == "Acme")
    let user = try await SponsorUser.query(on: app.db).first()
    #expect(user?.email == "alice@example.com")
    let tokens = try await MagicLinkToken.query(on: app.db).all()
    #expect(tokens.count == 1)
  }
}
