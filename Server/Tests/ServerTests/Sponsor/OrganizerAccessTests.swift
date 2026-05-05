import Fluent
import Foundation
import JWT
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("OrganizerAccess")
struct OrganizerAccessTests {
  @Test("admin role accesses /admin/sponsors successfully")
  func adminAllowed() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    let admin = User(githubID: 100, username: "admin1", role: .admin)
    try await admin.save(on: app.db)

    let payload = UserJWTPayload(
      userID: try admin.requireID(), role: .admin, username: admin.username)
    let token = try await app.jwt.keys.sign(payload)

    let group = app.grouped(OrganizerOnlyMiddleware())
    try group.register(collection: OrganizerSponsorController())

    try await app.testing().test(
      .GET, "admin/sponsors",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: "auth_token=\(token)")
      }
    ) { res in
      #expect(res.status == .ok)
    }
  }

  @Test("speaker role gets 403")
  func speakerForbidden() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    let speaker = User(githubID: 200, username: "speaker1", role: .speaker)
    try await speaker.save(on: app.db)

    let payload = UserJWTPayload(
      userID: try speaker.requireID(), role: .speaker, username: speaker.username)
    let token = try await app.jwt.keys.sign(payload)

    let group = app.grouped(OrganizerOnlyMiddleware())
    try group.register(collection: OrganizerSponsorController())

    try await app.testing().test(
      .GET, "admin/sponsors",
      beforeRequest: { req in
        req.headers.replaceOrAdd(name: .cookie, value: "auth_token=\(token)")
      }
    ) { res in
      #expect(res.status == .forbidden)
    }
  }

  @Test("missing cookie redirects to organizer login")
  func unauthenticatedRedirects() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.conference(app)

    let group = app.grouped(OrganizerOnlyMiddleware())
    try group.register(collection: OrganizerSponsorController())

    try await app.testing().test(.GET, "admin/sponsors") { res in
      #expect(res.status == .seeOther)
    }
  }
}
