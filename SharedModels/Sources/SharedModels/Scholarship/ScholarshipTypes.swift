import Foundation

/// Support type for scholarship application
public enum ScholarshipSupportType: String, Codable, Sendable, Equatable, CaseIterable {
  case ticketOnly = "ticket_only"
  case ticketAndTravel = "ticket_and_travel"

  public var displayName: String {
    switch self {
    case .ticketOnly:
      return "Ticket Only"
    case .ticketAndTravel:
      return "Ticket + Accommodation/Transportation"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .ticketOnly:
      return "参加チケットのみ"
    case .ticketAndTravel:
      return "参加チケット＋宿泊費・交通費"
    }
  }
}

/// Purpose options for scholarship application (multi-select)
public enum ScholarshipPurpose: String, Codable, Sendable, Equatable, CaseIterable {
  case learnSwift = "learn_swift"
  case schoolCourses = "school_courses"
  case learnFromOtherLanguages = "learn_from_other_languages"
  case beginnerOpportunity = "beginner_opportunity"
  case networking = "networking"

  public var displayName: String {
    switch self {
    case .learnSwift:
      return "Want to learn more Swift"
    case .schoolCourses:
      return "Using Swift in school courses/activities"
    case .learnFromOtherLanguages:
      return "Want to learn Swift from other languages"
    case .beginnerOpportunity:
      return "Learning opportunity for programming beginners"
    case .networking:
      return "Networking with engineers worldwide"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .learnSwift:
      return "日頃Swiftを使っていて、もっと勉強したい"
    case .schoolCourses:
      return "学校の授業や課外活動でSwiftを使用している"
    case .learnFromOtherLanguages:
      return "他言語を使用しており、Swiftを学びたい"
    case .beginnerOpportunity:
      return "プログラミング初心者向けの学習機会として"
    case .networking:
      return "世界中のエンジニアとの交流"
    }
  }
}

/// Transportation method options
public enum ScholarshipTransportMethod: String, Codable, Sendable, Equatable, CaseIterable {
  case airplane
  case bulletTrain = "bullet_train"
  case train
  case bus

  public var displayName: String {
    switch self {
    case .airplane: return "Airplane"
    case .bulletTrain: return "Bullet Train (Shinkansen)"
    case .train: return "Train"
    case .bus: return "Bus"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .airplane: return "飛行機"
    case .bulletTrain: return "新幹線"
    case .train: return "電車"
    case .bus: return "バス"
    }
  }
}

/// Accommodation type options
public enum ScholarshipAccommodationType: String, Codable, Sendable, Equatable, CaseIterable {
  case hotel
  case airbnb
  case sharedRoom = "shared_room"

  public var displayName: String {
    switch self {
    case .hotel: return "Hotel"
    case .airbnb: return "Airbnb / Vacation Rental"
    case .sharedRoom: return "Shared Room"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .hotel: return "ホテル"
    case .airbnb: return "民泊 / Airbnb"
    case .sharedRoom: return "相部屋"
    }
  }
}

/// Accommodation reservation status
public enum ScholarshipReservationStatus: String, Codable, Sendable, Equatable, CaseIterable {
  case reserved
  case notYet = "not_yet"

  public var displayName: String {
    switch self {
    case .reserved: return "Reserved"
    case .notYet: return "Not yet"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .reserved: return "予約済み"
    case .notYet: return "これから予約する"
    }
  }
}

/// Travel details stored as JSON alongside a scholarship application
public struct ScholarshipTravelDetails: Codable, Sendable, Equatable {
  public let originCity: String
  public let transportationMethods: [ScholarshipTransportMethod]
  public let estimatedRoundTripCost: Int

  public init(
    originCity: String,
    transportationMethods: [ScholarshipTransportMethod],
    estimatedRoundTripCost: Int
  ) {
    self.originCity = originCity
    self.transportationMethods = transportationMethods
    self.estimatedRoundTripCost = estimatedRoundTripCost
  }
}

/// Accommodation details stored as JSON alongside a scholarship application
public struct ScholarshipAccommodationDetails: Codable, Sendable, Equatable {
  public let accommodationType: ScholarshipAccommodationType
  public let reservationStatus: ScholarshipReservationStatus
  public let accommodationName: String?
  public let accommodationAddress: String?
  public let checkInDate: String?
  public let checkOutDate: String?
  public let estimatedCost: Int

  public init(
    accommodationType: ScholarshipAccommodationType,
    reservationStatus: ScholarshipReservationStatus,
    accommodationName: String? = nil,
    accommodationAddress: String? = nil,
    checkInDate: String? = nil,
    checkOutDate: String? = nil,
    estimatedCost: Int
  ) {
    self.accommodationType = accommodationType
    self.reservationStatus = reservationStatus
    self.accommodationName = accommodationName
    self.accommodationAddress = accommodationAddress
    self.checkInDate = checkInDate
    self.checkOutDate = checkOutDate
    self.estimatedCost = estimatedCost
  }
}

/// Wrapper for `[String]` to encode/decode as a single JSON array value
/// (avoids Fluent treating bare `[String]` as PostgreSQL `jsonb[]`)
public struct ScholarshipPurposeList: Codable, Sendable, Equatable {
  public var items: [String]

  public init(_ items: [String]) {
    self.items = items
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.items = try container.decode([String].self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(items)
  }
}
