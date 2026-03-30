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

  /// Returns the index of the currently-live schedule slot, if any.
  /// End time is inferred from the next slot's start time.
  /// The last slot uses `lastSlotDuration` (default: 60 minutes).
  public func liveScheduleIndex(
    at now: Date,
    lastSlotDuration: TimeInterval = 3600
  ) -> Int? {
    for (index, schedule) in schedules.enumerated() {
      let endTime: Date
      if index + 1 < schedules.count {
        endTime = schedules[index + 1].time
      } else {
        endTime = schedule.time.addingTimeInterval(lastSlotDuration)
      }
      if now >= schedule.time && now < endTime {
        return index
      }
    }
    return nil
  }
}

public struct Schedule: Codable, Equatable, Hashable, Sendable {
  public var time: Date
  public var endTime: Date?
  public var sessions: [Session]

  public init(time: Date, endTime: Date? = nil, sessions: [Session]) {
    self.time = time
    self.endTime = endTime
    self.sessions = sessions
  }
}

public struct Session: Codable, Equatable, Hashable, Sendable {
  public var proposalId: String?
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
  public var sponsor: String?
  public var youtubeVideoId: String?

  public init(
    proposalId: String? = nil,
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
    requirementsJa: String? = nil,
    sponsor: String? = nil,
    youtubeVideoId: String? = nil,
  ) {
    self.proposalId = proposalId
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
    self.sponsor = sponsor
    self.youtubeVideoId = youtubeVideoId
  }
}
