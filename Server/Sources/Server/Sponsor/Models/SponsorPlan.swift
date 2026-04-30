import Fluent
import SharedModels
import Vapor

final class SponsorPlan: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_plans"

  @ID(key: .id) var id: UUID?
  @Parent(key: "conference_id") var conference: Conference
  @Field(key: "slug") var slug: String
  @Field(key: "sort_order") var sortOrder: Int
  @Field(key: "price_jpy") var priceJPY: Int
  @OptionalField(key: "capacity") var capacity: Int?
  @OptionalField(key: "deadline_at") var deadlineAt: Date?
  @Field(key: "is_active") var isActive: Bool
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  @Children(for: \.$plan) var localizations: [SponsorPlanLocalization]

  init() {}

  init(
    id: UUID? = nil, conferenceID: UUID, slug: String, sortOrder: Int,
    priceJPY: Int, capacity: Int? = nil, deadlineAt: Date? = nil,
    isActive: Bool = true
  ) {
    self.id = id
    self.$conference.id = conferenceID
    self.slug = slug
    self.sortOrder = sortOrder
    self.priceJPY = priceJPY
    self.capacity = capacity
    self.deadlineAt = deadlineAt
    self.isActive = isActive
  }

  func toDTO() throws -> SponsorPlanDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorPlan missing id") }
    return SponsorPlanDTO(
      id: id, conferenceID: $conference.id, slug: slug, sortOrder: sortOrder,
      priceJPY: priceJPY, capacity: capacity, deadlineAt: deadlineAt,
      isActive: isActive,
      localizations: localizations.map { $0.toDTO() }
    )
  }
}
