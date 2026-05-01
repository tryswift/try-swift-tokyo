import Crypto
import Fluent
import Foundation
import Testing
import Vapor

@testable import Server

@Suite("MagicLinkService")
struct MagicLinkServiceTests {
  @Test("issue stores SHA256 hash, not the raw token")
  func issueStoresHash() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let user = try await SponsorTestEnv.sponsorUser(app, email: "owner@example.com")

    let issued = try await MagicLinkService.issue(
      for: user, on: app.db,
      ttl: .seconds(60), now: { Date() })
    #expect(issued.rawToken.count >= 32)

    let stored = try await MagicLinkToken.query(on: app.db).first()
    #expect(stored != nil)
    #expect(stored?.tokenHash != issued.rawToken)
    #expect(stored?.tokenHash == MagicLinkService.hash(issued.rawToken))
  }

  @Test("verify returns user for valid token, nil for expired or used")
  func verifyHonorsExpiryAndSingleUse() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let user = try await SponsorTestEnv.sponsorUser(app, email: "u@example.com")

    let clockBase = Date()
    let clockFuture = clockBase.addingTimeInterval(120)

    let issued = try await MagicLinkService.issue(
      for: user, on: app.db,
      ttl: .seconds(60), now: { clockBase })

    let firstResult = try await MagicLinkService.verify(
      rawToken: issued.rawToken,
      on: app.db, now: { clockBase })
    #expect(firstResult?.id == user.id)

    let replay = try await MagicLinkService.verify(
      rawToken: issued.rawToken,
      on: app.db, now: { clockBase })
    #expect(replay == nil, "Replay must be rejected")

    let second = try await MagicLinkService.issue(
      for: user, on: app.db,
      ttl: .seconds(60), now: { clockBase })
    let expired = try await MagicLinkService.verify(
      rawToken: second.rawToken,
      on: app.db, now: { clockFuture })
    #expect(expired == nil, "Expired must be rejected")
  }

  @Test("verify rejects unknown / tampered tokens")
  func tamperedRejected() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.sponsorUser(app, email: "u@example.com")
    let result = try await MagicLinkService.verify(
      rawToken: "not-a-real-token",
      on: app.db, now: { Date() })
    #expect(result == nil)
  }
}
