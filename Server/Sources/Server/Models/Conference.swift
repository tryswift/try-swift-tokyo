import Fluent
import SharedModels
import Vapor

/// Conference model for CfP
final class Conference: Model, Content, @unchecked Sendable {
  static let schema = "conferences"

  @ID(key: .id)
  var id: UUID?

  /// URL-friendly path/alias (e.g., "tryswift-tokyo-2026")
  @Field(key: "path")
  var path: String

  /// Human-readable display name (e.g., "try! Swift Tokyo 2026")
  @Field(key: "display_name")
  var displayName: String

  /// Description in English (markdown)
  @OptionalField(key: "description_en")
  var descriptionEn: String?

  /// Description in Japanese (markdown)
  @OptionalField(key: "description_ja")
  var descriptionJa: String?

  /// Conference year
  @Field(key: "year")
  var year: Int

  /// Whether CfP is currently open
  @Field(key: "is_open")
  var isOpen: Bool

  /// CfP submission deadline
  @OptionalField(key: "deadline")
  var deadline: Date?

  /// Conference start date
  @OptionalField(key: "start_date")
  var startDate: Date?

  /// Conference end date
  @OptionalField(key: "end_date")
  var endDate: Date?

  /// Conference location
  @OptionalField(key: "location")
  var location: String?

  /// Conference website URL
  @OptionalField(key: "website_url")
  var websiteURL: String?

  /// Proposals for this conference
  @Children(for: \.$conference)
  var proposals: [Proposal]

  /// Timestamps
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    path: String,
    displayName: String,
    descriptionEn: String? = nil,
    descriptionJa: String? = nil,
    year: Int,
    isOpen: Bool = true,
    deadline: Date? = nil,
    startDate: Date? = nil,
    endDate: Date? = nil,
    location: String? = nil,
    websiteURL: String? = nil
  ) {
    self.id = id
    self.path = path
    self.displayName = displayName
    self.descriptionEn = descriptionEn
    self.descriptionJa = descriptionJa
    self.year = year
    self.isOpen = isOpen
    self.deadline = deadline
    self.startDate = startDate
    self.endDate = endDate
    self.location = location
    self.websiteURL = websiteURL
  }

  /// Get localized description
  var description: LocalizedString? {
    guard let en = descriptionEn, let ja = descriptionJa else {
      if let en = descriptionEn {
        return LocalizedString(en: en, ja: en)
      }
      if let ja = descriptionJa {
        return LocalizedString(en: ja, ja: ja)
      }
      return nil
    }
    return LocalizedString(en: en, ja: ja)
  }

  /// Convert to DTO for API responses
  func toDTO() throws -> ConferenceDTO {
    guard let id = id else {
      throw Abort(.internalServerError, reason: "Conference ID is missing")
    }
    return ConferenceDTO(
      id: id,
      path: path,
      displayName: displayName,
      description: description,
      year: year,
      isOpen: isOpen,
      deadline: deadline,
      startDate: startDate,
      endDate: endDate,
      location: location,
      websiteURL: websiteURL,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }

  /// Convert to public info for SSR pages
  func toPublicInfo() -> ConferencePublicInfo {
    ConferencePublicInfo(
      displayName: displayName,
      deadline: deadline
    )
  }
}

/// Public conference info for SSR pages
struct ConferencePublicInfo: Sendable {
  let displayName: String
  let deadline: Date?
}
