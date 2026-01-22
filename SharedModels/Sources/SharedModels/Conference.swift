import Foundation

public struct Conference: Codable, Equatable, Hashable, Sendable {
  public var title: String
  public var date: Date
  public var schedules: [Schedule]

  public init(id: Int, title: String, date: Date, schedules: [Schedule]) {
    self.title = title
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
  public var summary: String?
  public var speakers: [Speaker]?
  public var place: String?
  public var description: String?
  public var requirements: String?

  public init(
    title: String, speakers: [Speaker]?, place: String?, description: String?,
    requirements: String?
  ) {
    self.title = title
    self.speakers = speakers
    self.place = place
    self.description = description
    self.requirements = requirements
  }
}
