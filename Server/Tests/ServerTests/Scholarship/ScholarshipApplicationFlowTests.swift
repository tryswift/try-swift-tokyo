import Fluent
import FluentSQLiteDriver
import Foundation
import JWT
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("ScholarshipApplicationFlow")
struct ScholarshipApplicationFlowTests {
  @Test("authenticated student can submit then withdraw a scholarship application")
  func submitAndWithdraw() async throws {
    let app = try await makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    // Seed: conference + student
    let conference = Conference(
      path: "tryswift-tokyo-2026", displayName: "try! Swift Tokyo 2026", year: 2026)
    try await conference.save(on: app.db)

    let student = StudentUser(email: "alice@univ.ac.jp", locale: .ja)
    try await student.save(on: app.db)

    // Forge a student session cookie.
    let payload = StudentJWTPayload(userID: try student.requireID(), locale: .ja)
    let cookieValue = try await app.jwt.keys.sign(payload)
    let cookieHeader = "\(StudentAuthCookie.name)=\(cookieValue)"

    // Mount auth middleware + applicant routes so cookies work.
    let group = app.grouped(StudentAuthMiddleware(onMissingRedirectTo: nil))
    try group.register(collection: ScholarshipApplicantController())

    // POST /apply
    try await app.testing().test(
      .POST, "apply",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
        try req.content.encode(
          [
            "email": "alice@univ.ac.jp",
            "name": "Alice",
            "school_and_faculty": "Swift University, CS",
            "current_year": "B3",
            "purposes": "learn_swift",
            "language_preference": "ja",
            "support_type": "ticket_only",
            "agreed_travel_regulations": "true",
            "agreed_application_confirmation": "true",
            "agreed_privacy": "true",
            "agreed_code_of_conduct": "true",
            "_csrf": "test",
          ], as: .urlEncodedForm)
      }
    ) { res in
      #expect(res.status == .seeOther)
    }

    let saved = try await ScholarshipApplication.query(on: app.db).first()
    #expect(saved?.status == .submitted)
    #expect(saved?.email == "alice@univ.ac.jp")
    #expect(saved?.supportType == .ticketOnly)
    let appID = try saved!.requireID()

    // POST /my-application/withdraw
    try await app.testing().test(
      .POST, "my-application/withdraw",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .seeOther)
    }

    let after = try await ScholarshipApplication.find(appID, on: app.db)
    #expect(after?.status == .withdrawn)
  }

  @Test("/api/travel-cost returns the static estimate for a known city")
  func travelCostAPI() async throws {
    let app = try await makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    ScholarshipApplicantController.registerTravelCost(on: app.routes)

    try await app.testing().test(.GET, "api/travel-cost?from=osaka") { res in
      #expect(res.status == .ok)
      let estimate = try res.content.decode(TravelCostCalculator.CostEstimate.self)
      #expect(estimate.city == "Osaka")
      #expect(estimate.bulletTrain == 27_000)
    }

    try await app.testing().test(.GET, "api/travel-cost?from=atlantis") { res in
      #expect(res.status == .notFound)
    }
  }

  // MARK: Helpers

  private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateScholarshipTestSchema())
    try await app.autoMigrate()
    await app.jwt.keys.add(
      hmac: HMACKey(from: "test-secret-do-not-use-in-prod"), digestAlgorithm: .sha256)
    return app
  }
}
