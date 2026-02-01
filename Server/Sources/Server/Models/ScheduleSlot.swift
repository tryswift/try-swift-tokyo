import Fluent
import Vapor

/// Schedule slot type for timetable entries
enum SlotType: String, Codable, Sendable, CaseIterable {
  case talk
  case lightningTalk = "lightning_talk"
  case breakTime = "break"
  case lunch
  case opening
  case closing
  case party
  case custom

  var displayName: String {
    switch self {
    case .talk: return "Talk"
    case .lightningTalk: return "Lightning Talk"
    case .breakTime: return "Break"
    case .lunch: return "Lunch"
    case .opening: return "Opening"
    case .closing: return "Closing"
    case .party: return "Party"
    case .custom: return "Custom"
    }
  }
}

/// Schedule slot model for timetable entries
final class ScheduleSlot: Model, Content, @unchecked Sendable {
  static let schema = "schedule_slots"

  @ID(key: .id)
  var id: UUID?

  /// Reference to the conference
  @Parent(key: "conference_id")
  var conference: Conference

  /// Reference to the proposal (nullable for non-talk slots)
  @OptionalParent(key: "proposal_id")
  var proposal: Proposal?

  /// Day number (1, 2, 3, etc.)
  @Field(key: "day")
  var day: Int

  /// Start time
  @Field(key: "start_time")
  var startTime: Date

  /// End time (optional)
  @OptionalField(key: "end_time")
  var endTime: Date?

  /// Slot type
  @Field(key: "slot_type")
  var slotType: SlotType

  /// Custom title (for non-talk slots like "Lunch Break")
  @OptionalField(key: "custom_title")
  var customTitle: String?

  /// Custom title in Japanese
  @OptionalField(key: "custom_title_ja")
  var customTitleJa: String?

  /// Description (for non-talk slots)
  @OptionalField(key: "description_text")
  var descriptionText: String?

  /// Description in Japanese
  @OptionalField(key: "description_text_ja")
  var descriptionTextJa: String?

  /// Venue/room name
  @OptionalField(key: "place")
  var place: String?

  /// Venue/room name in Japanese
  @OptionalField(key: "place_ja")
  var placeJa: String?

  /// Sort order for ordering within a day
  @Field(key: "sort_order")
  var sortOrder: Int

  /// Timestamps
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() {}

  init(
    id: UUID? = nil,
    conferenceID: UUID,
    proposalID: UUID? = nil,
    day: Int,
    startTime: Date,
    endTime: Date? = nil,
    slotType: SlotType,
    customTitle: String? = nil,
    customTitleJa: String? = nil,
    descriptionText: String? = nil,
    descriptionTextJa: String? = nil,
    place: String? = nil,
    placeJa: String? = nil,
    sortOrder: Int
  ) {
    self.id = id
    self.$conference.id = conferenceID
    if let proposalID {
      self.$proposal.id = proposalID
    }
    self.day = day
    self.startTime = startTime
    self.endTime = endTime
    self.slotType = slotType
    self.customTitle = customTitle
    self.customTitleJa = customTitleJa
    self.descriptionText = descriptionText
    self.descriptionTextJa = descriptionTextJa
    self.place = place
    self.placeJa = placeJa
    self.sortOrder = sortOrder
  }
}
