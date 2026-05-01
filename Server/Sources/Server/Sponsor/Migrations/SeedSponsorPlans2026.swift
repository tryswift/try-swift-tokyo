import Fluent
import Foundation
import SharedModels

struct SeedSponsorPlans2026: AsyncMigration {
  private struct PlanSeed {
    let slug: String
    let sortOrder: Int
    let priceJPY: Int
    let capacity: Int?
    let nameJa: String
    let nameEn: String
    let summaryJa: String
    let summaryEn: String
    let benefitsJa: [String]
    let benefitsEn: [String]
  }

  private static let seeds: [PlanSeed] = [
    PlanSeed(
      slug: "platinum", sortOrder: 10, priceJPY: 2_000_000, capacity: 1,
      nameJa: "Platinum", nameEn: "Platinum",
      summaryJa: "最上位プラン。基調講演前後の枠をご提供。",
      summaryEn: "Top tier with prime placement around keynotes.",
      benefitsJa: ["ロゴ最大級掲載", "ブース", "ランチ枠"],
      benefitsEn: ["Largest logo", "Booth", "Lunch slots"]),
    PlanSeed(
      slug: "gold", sortOrder: 20, priceJPY: 1_000_000, capacity: 3,
      nameJa: "Gold", nameEn: "Gold",
      summaryJa: "ロゴ大、ブース、ランチ。",
      summaryEn: "Large logo, booth, lunch.",
      benefitsJa: ["ロゴ大掲載", "ブース"],
      benefitsEn: ["Large logo", "Booth"]),
    PlanSeed(
      slug: "silver", sortOrder: 30, priceJPY: 500_000, capacity: 8,
      nameJa: "Silver", nameEn: "Silver",
      summaryJa: "ロゴ中、ブース。",
      summaryEn: "Medium logo, booth.",
      benefitsJa: ["ロゴ中掲載"],
      benefitsEn: ["Medium logo"]),
    PlanSeed(
      slug: "bronze", sortOrder: 40, priceJPY: 200_000, capacity: nil,
      nameJa: "Bronze", nameEn: "Bronze",
      summaryJa: "ロゴ掲載。",
      summaryEn: "Logo placement.",
      benefitsJa: ["ロゴ掲載"],
      benefitsEn: ["Logo"]),
    PlanSeed(
      slug: "diversity", sortOrder: 50, priceJPY: 300_000, capacity: nil,
      nameJa: "Diversity & Inclusion", nameEn: "Diversity & Inclusion",
      summaryJa: "D&I 支援。",
      summaryEn: "D&I support.",
      benefitsJa: ["D&I 招待枠"],
      benefitsEn: ["D&I tickets"]),
    PlanSeed(
      slug: "community", sortOrder: 60, priceJPY: 100_000, capacity: nil,
      nameJa: "Community", nameEn: "Community",
      summaryJa: "コミュニティ枠。",
      summaryEn: "Community partner.",
      benefitsJa: ["コミュニティ告知"],
      benefitsEn: ["Community shoutout"]),
  ]

  func prepare(on database: Database) async throws {
    guard
      let conference = try await Conference.query(on: database)
        .filter(\.$path == "tryswift-tokyo-2026")
        .first()
    else {
      database.logger.warning(
        "SeedSponsorPlans2026: Conference 'tryswift-tokyo-2026' not found, skipping")
      return
    }
    let conferenceID = try conference.requireID()

    if !conference.isAcceptingSponsors {
      conference.isAcceptingSponsors = true
      try await conference.save(on: database)
    }

    for seed in Self.seeds {
      let existing = try await SponsorPlan.query(on: database)
        .filter(\.$conference.$id == conferenceID)
        .filter(\.$slug == seed.slug)
        .first()

      let plan: SponsorPlan
      if let existing {
        existing.sortOrder = seed.sortOrder
        existing.priceJPY = seed.priceJPY
        existing.capacity = seed.capacity
        existing.isActive = true
        try await existing.save(on: database)
        plan = existing
      } else {
        plan = SponsorPlan(
          conferenceID: conferenceID, slug: seed.slug,
          sortOrder: seed.sortOrder, priceJPY: seed.priceJPY,
          capacity: seed.capacity)
        try await plan.save(on: database)
      }

      try await upsertLocalization(
        plan: plan, locale: .ja, name: seed.nameJa,
        summary: seed.summaryJa, benefits: seed.benefitsJa, on: database)
      try await upsertLocalization(
        plan: plan, locale: .en, name: seed.nameEn,
        summary: seed.summaryEn, benefits: seed.benefitsEn, on: database)
    }
  }

  func revert(on database: Database) async throws {
    let slugs = Self.seeds.map(\.slug)
    try await SponsorPlan.query(on: database)
      .filter(\.$slug ~~ slugs)
      .delete()
  }

  private func upsertLocalization(
    plan: SponsorPlan, locale: SponsorPortalLocale,
    name: String, summary: String, benefits: [String],
    on database: Database
  ) async throws {
    let planID = try plan.requireID()
    if let existing = try await SponsorPlanLocalization.query(on: database)
      .filter(\.$plan.$id == planID)
      .filter(\.$locale == locale)
      .first()
    {
      existing.name = name
      existing.summary = summary
      existing.benefits = benefits
      try await existing.save(on: database)
    } else {
      let loc = SponsorPlanLocalization(
        planID: planID, locale: locale,
        name: name, summary: summary, benefits: benefits)
      try await loc.save(on: database)
    }
  }
}
