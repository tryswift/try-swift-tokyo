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

/// Purpose options for scholarship application (checkbox, multiple select)
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
public enum TransportMethod: String, Codable, Sendable, Equatable, CaseIterable {
  case airplane
  case bulletTrain = "bullet_train"
  case train
  case bus

  public var displayName: String {
    switch self {
    case .airplane:
      return "Airplane"
    case .bulletTrain:
      return "Bullet Train (Shinkansen)"
    case .train:
      return "Train"
    case .bus:
      return "Bus"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .airplane:
      return "飛行機"
    case .bulletTrain:
      return "新幹線"
    case .train:
      return "電車"
    case .bus:
      return "バス"
    }
  }
}

/// Accommodation type options
public enum AccommodationType: String, Codable, Sendable, Equatable, CaseIterable {
  case hotel
  case airbnb
  case sharedRoom = "shared_room"

  public var displayName: String {
    switch self {
    case .hotel:
      return "Hotel"
    case .airbnb:
      return "Airbnb / Vacation Rental"
    case .sharedRoom:
      return "Shared Room"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .hotel:
      return "ホテル"
    case .airbnb:
      return "民泊 / Airbnb"
    case .sharedRoom:
      return "相部屋"
    }
  }
}

/// Accommodation reservation status
public enum ReservationStatus: String, Codable, Sendable, Equatable, CaseIterable {
  case reserved
  case notYet = "not_yet"

  public var displayName: String {
    switch self {
    case .reserved:
      return "Reserved"
    case .notYet:
      return "Not yet"
    }
  }

  public var displayNameJa: String {
    switch self {
    case .reserved:
      return "予約済み"
    case .notYet:
      return "これから予約する"
    }
  }
}

/// Travel details stored as JSON alongside a scholarship application
public struct TravelDetails: Codable, Sendable, Equatable {
  public let originCity: String
  public let transportationMethods: [TransportMethod]
  public let estimatedRoundTripCost: Int

  public init(
    originCity: String,
    transportationMethods: [TransportMethod],
    estimatedRoundTripCost: Int
  ) {
    self.originCity = originCity
    self.transportationMethods = transportationMethods
    self.estimatedRoundTripCost = estimatedRoundTripCost
  }
}

/// Accommodation details stored as JSON alongside a scholarship application
public struct AccommodationDetails: Codable, Sendable, Equatable {
  public let accommodationType: AccommodationType
  public let reservationStatus: ReservationStatus
  public let accommodationName: String?
  public let accommodationAddress: String?
  public let checkInDate: String?
  public let checkOutDate: String?
  public let estimatedCost: Int

  public init(
    accommodationType: AccommodationType,
    reservationStatus: ReservationStatus,
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
