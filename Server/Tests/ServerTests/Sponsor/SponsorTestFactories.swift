import Fluent
import FluentSQLiteDriver
import Foundation
import JWT
import Vapor
import VaporTesting

import enum SharedModels.SponsorPortalLocale

@testable import Server

enum SponsorTestEnv {
  static func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateSponsorTestSchema())
    try await app.autoMigrate()
    await app.jwt.keys.add(
      hmac: HMACKey(from: "test-secret-do-not-use-in-prod"), digestAlgorithm: .sha256)
    return app
  }

  @discardableResult
  static func conference(
    _ app: Application,
    path: String = "tryswift-tokyo-2026",
    isAcceptingSponsors: Bool = true
  ) async throws -> Conference {
    let c = Conference(path: path, displayName: "try! Swift Tokyo 2026", year: 2026)
    c.isAcceptingSponsors = isAcceptingSponsors
    try await c.save(on: app.db)
    return c
  }

  @discardableResult
  static func sponsorUser(
    _ app: Application, email: String,
    locale: SponsorPortalLocale = .ja
  ) async throws -> SponsorUser {
    let u = SponsorUser(email: email, displayName: nil, locale: locale)
    try await u.save(on: app.db)
    return u
  }

  @discardableResult
  static func organization(
    _ app: Application, ownerEmail: String
  ) async throws -> (SponsorOrganization, SponsorUser) {
    let owner = try await sponsorUser(app, email: ownerEmail)
    let org = SponsorOrganization(legalName: "Acme Inc.", displayName: "Acme")
    try await org.save(on: app.db)
    let mem = SponsorMembership(
      organizationID: try org.requireID(),
      userID: try owner.requireID(),
      role: .owner)
    try await mem.save(on: app.db)
    return (org, owner)
  }

  @discardableResult
  static func plan(
    _ app: Application, conference: Conference, slug: String,
    priceJPY: Int = 1_000_000
  ) async throws -> SponsorPlan {
    let p = SponsorPlan(
      conferenceID: try conference.requireID(), slug: slug,
      sortOrder: 10, priceJPY: priceJPY)
    try await p.save(on: app.db)
    let l1 = SponsorPlanLocalization(
      planID: try p.requireID(), locale: .ja,
      name: slug.capitalized, summary: "test plan", benefits: ["b1"])
    try await l1.save(on: app.db)
    let l2 = SponsorPlanLocalization(
      planID: try p.requireID(), locale: .en,
      name: slug.capitalized, summary: "test plan", benefits: ["b1"])
    try await l2.save(on: app.db)
    return p
  }
}
