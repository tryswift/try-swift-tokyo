import Fluent
import FluentSQLiteDriver
import Foundation
import JWT
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("ScholarshipAPIFlow")
struct ScholarshipApplicationFlowTests {
  @Test("authenticated student can submit then withdraw a scholarship application")
  func submitAndWithdraw() async throws {
    let app = try await makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    let conference = Conference(
      path: "tryswift-tokyo-2026", displayName: "try! Swift Tokyo 2026", year: 2026)
    try await conference.save(on: app.db)

    let student = StudentUser(email: "alice@univ.ac.jp", locale: .ja)
    try await student.save(on: app.db)

    let payload = StudentJWTPayload(userID: try student.requireID(), locale: .ja)
    let cookieValue = try await app.jwt.keys.sign(payload)
    let cookieHeader = "\(StudentAuthCookie.name)=\(cookieValue)"

    // Mount the API controller under /api/v1/scholarship like routes.swift does.
    try app.grouped("api", "v1", "scholarship")
      .register(collection: ScholarshipAPIController())

    try await app.testing().test(
      .POST, "api/v1/scholarship/apply",
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

    try await app.testing().test(
      .POST, "api/v1/scholarship/me/application/withdraw",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .seeOther)
    }

    let after = try await ScholarshipApplication.query(on: app.db).first()
    #expect(after?.status == .withdrawn)
  }

  @Test("/api/v1/scholarship/api/travel-cost returns the static estimate for a known city")
  func travelCostAPI() async throws {
    let app = try await makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    try app.grouped("api", "v1", "scholarship")
      .register(collection: ScholarshipAPIController())

    try await app.testing().test(.GET, "api/v1/scholarship/api/travel-cost?from=osaka") { res in
      #expect(res.status == .ok)
      let estimate = try res.content.decode(TravelCostCalculator.CostEstimate.self)
      #expect(estimate.city == "Osaka")
      #expect(estimate.bulletTrain == 27_000)
    }

    try await app.testing().test(.GET, "api/v1/scholarship/api/travel-cost?from=atlantis") { res in
      #expect(res.status == .notFound)
    }
  }

  @Test("/api/v1/scholarship/me returns 401 without cookie, 200 with cookie")
  func meEndpoint() async throws {
    let app = try await makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    let student = StudentUser(email: "carol@cs.tokyo.ac.jp", locale: .en)
    try await student.save(on: app.db)
    let payload = StudentJWTPayload(userID: try student.requireID(), locale: .en)
    let cookieValue = try await app.jwt.keys.sign(payload)
    let cookieHeader = "\(StudentAuthCookie.name)=\(cookieValue)"

    try app.grouped("api", "v1", "scholarship")
      .register(collection: ScholarshipAPIController())

    try await app.testing().test(.GET, "api/v1/scholarship/me") { res in
      #expect(res.status == .unauthorized)
    }

    try await app.testing().test(
      .GET, "api/v1/scholarship/me",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: cookieHeader)
      }
    ) { res in
      #expect(res.status == .ok)
      let json = try res.content.decode(MeResponse.self)
      #expect(json.email == "carol@cs.tokyo.ac.jp")
      #expect(json.isOrganizer == false)
    }
  }

  // Mirrors the inline `MeResponse` in ScholarshipAPIController; redefined here
  // since the controller's struct is private.
  private struct MeResponse: Codable {
    let id: UUID
    let email: String
    let displayName: String?
    let isOrganizer: Bool
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
