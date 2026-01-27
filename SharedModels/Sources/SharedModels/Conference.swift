import Foundation

public struct Conference: Codable, Equatable, Hashable, Sendable {
  public var title: String
  public var titleJa: String?
  public var date: Date
  public var schedules: [Schedule]

  public init(id: Int, title: String, titleJa: String? = nil, date: Date, schedules: [Schedule]) {
    self.title = title
    self.titleJa = titleJa
    self.date = date
    self.schedules = schedules
  }
}

public struct Schedule: Codable, Equatable, Hashable, Sendable {
  public var time: Date
  public var sessions: [Session]

  public init(time: Date, sessions: [Session]) {
    self.time = time
    self.sessions = sessions
  }
}

public struct Session: Codable, Equatable, Hashable, Sendable {
  public var title: String
  public var titleJa: String?
  public var summary: String?
  public var summaryJa: String?
  public var speakers: [Speaker]?
  public var place: String?
  public var placeJa: String?
  public var description: String?
  public var descriptionJa: String?
  public var requirements: String?
  public var requirementsJa: String?

  public init(
    title: String,
    titleJa: String? = nil,
    summary: String? = nil,
    summaryJa: String? = nil,
    speakers: [Speaker]?,
    place: String?,
    placeJa: String? = nil,
    description: String?,
    descriptionJa: String? = nil,
    requirements: String?,
    requirementsJa: String? = nil
  ) {
    self.title = title
    self.titleJa = titleJa
    self.summary = summary
    self.summaryJa = summaryJa
    self.speakers = speakers
    self.place = place
    self.placeJa = placeJa
    self.description = description
    self.descriptionJa = descriptionJa
    self.requirements = requirements
    self.requirementsJa = requirementsJa
  }
}
