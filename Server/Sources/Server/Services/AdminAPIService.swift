import DataClient
import Fluent
import JWT
import SharedModels
import Vapor

enum AdminAPIService {
  struct DayInfo: Sendable {
    let dayNumber: Int
    let label: String
    let date: Date?
  }

  static func requireAdmin(_ req: Request) async throws -> UserJWTPayload {
    let payload = try await req.requireAuthenticatedUserPayload()
    guard payload.role.isAdmin else {
      throw Abort(.forbidden, reason: "Admin access required")
    }
    return payload
  }

  static func resolveSpeakerID(
    githubUsername rawUsername: String?,
    on db: Database
  ) async throws -> UUID {
    let username = rawUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    if !username.isEmpty,
      let user = try await User.query(on: db)
        .filter(\.$username == username)
        .first(),
      let userID = user.id
    {
      return userID
    }

    guard
      let importUser = try await User.find(
        AddPaperCallImportUser.paperCallUserID, on: db)
    else {
      throw Abort(
        .internalServerError,
        reason: "Import user not configured. Run migrations first.")
    }
    guard let importUserID = importUser.id else {
      throw Abort(.internalServerError, reason: "Import user ID missing")
    }
    return importUserID
  }

  static func parseISO8601(_ string: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return fractional.date(from: string) ?? plain.date(from: string)
  }

  static func computeConferenceDays(conference: Conference) -> [DayInfo] {
    guard let startDate = conference.startDate, let endDate = conference.endDate else {
      return [DayInfo(dayNumber: 1, label: "Day 1", date: nil)]
    }

    var days: [DayInfo] = []
    let calendar = Calendar.current
    var current = startDate
    var dayNum = 1
    let dayLabels = ["Workshop", "Day 1", "Day 2"]

    while current <= endDate {
      let label = dayNum <= dayLabels.count ? dayLabels[dayNum - 1] : "Day \(dayNum)"
      days.append(DayInfo(dayNumber: dayNum, label: label, date: current))
      dayNum += 1
      guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }

    return days
  }

  static func encodeJSONAttachment<T: Encodable>(_ value: T, filename: String) throws -> Response {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .custom { date, encoder in
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime]
      formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")!
      var container = encoder.singleValueContainer()
      try container.encode(formatter.string(from: date))
    }

    let data = try encoder.encode(value)
    var headers = HTTPHeaders()
    headers.contentType = .json
    headers.add(name: .contentDisposition, value: "attachment; filename=\"\(filename)\"")
    return Response(status: .ok, headers: headers, body: .init(data: data))
  }

  static func buildTimetableJSON(
    req: Request,
    conference: Conference,
    conferenceID: UUID,
    day: Int
  ) async throws -> TimetableExportConference {
    let slots = try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .filter(\.$day == day)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }
      .sort(\.$sortOrder)
      .all()

    let conferenceYear = ConferenceYear(rawValue: conference.year)
    let knownSpeakers: [Speaker] = await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        let speakers = conferenceYear.flatMap { try? DataClient.liveValue.fetchSpeakers($0) } ?? []
        continuation.resume(returning: speakers)
      }
    }
    let speakerMap = Dictionary(
      knownSpeakers.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

    var schedulesByTime: [(time: Date, slots: [ScheduleSlot])] = []
    var currentTime: Date?
    var currentSlots: [ScheduleSlot] = []

    for slot in slots {
      if slot.startTime != currentTime {
        if let time = currentTime, !currentSlots.isEmpty {
          schedulesByTime.append((time: time, slots: currentSlots))
        }
        currentTime = slot.startTime
        currentSlots = [slot]
      } else {
        currentSlots.append(slot)
      }
    }
    if let time = currentTime, !currentSlots.isEmpty {
      schedulesByTime.append((time: time, slots: currentSlots))
    }

    let schedules = schedulesByTime.map { group -> TimetableExportSchedule in
      let sessions = group.slots.map { slot -> TimetableExportSession in
        if let proposal = slot.proposal {
          let matched = speakerMap[proposal.speakerName]
          let fallbackImageName = proposal.speakerName.lowercased().replacingOccurrences(
            of: " ", with: "_")
          return TimetableExportSession(
            proposalId: proposal.id?.uuidString,
            title: proposal.title,
            titleJa: proposal.titleJA,
            summary: String(proposal.abstract.prefix(200)),
            summaryJa: proposal.abstractJA.map { String($0.prefix(200)) },
            speakers: [
              TimetableExportSpeaker(
                name: proposal.speakerName,
                imageName: matched?.imageName ?? fallbackImageName,
                bio: proposal.bio,
                bioJa: proposal.bioJa ?? matched?.bioJa,
                jobTitle: proposal.jobTitle ?? matched?.jobTitle,
                jobTitleJa: proposal.jobTitleJa ?? matched?.jobTitleJa,
                links: matched?.links?.map {
                  TimetableExportLink(name: $0.name, url: $0.url.absoluteString)
                } ?? []
              )
            ],
            place: slot.place,
            placeJa: slot.placeJa,
            description: proposal.abstract,
            descriptionJa: proposal.abstractJA
          )
        } else {
          return TimetableExportSession(
            proposalId: nil,
            title: slot.customTitle ?? slot.slotType.displayName,
            titleJa: slot.customTitleJa,
            summary: nil,
            summaryJa: nil,
            speakers: nil,
            place: slot.place,
            placeJa: slot.placeJa,
            description: slot.descriptionText,
            descriptionJa: slot.descriptionTextJa
          )
        }
      }
      return TimetableExportSchedule(time: group.time, sessions: sessions)
    }

    let dayDate: Date
    if let startDate = conference.startDate {
      dayDate = Calendar.current.date(byAdding: .day, value: day - 1, to: startDate) ?? startDate
    } else {
      dayDate = Date()
    }

    let dayLabels = ["Workshop", "Day 1", "Day 2"]
    let dayLabel = day <= dayLabels.count ? dayLabels[day - 1] : "Day \(day)"

    return TimetableExportConference(
      id: day,
      title: dayLabel,
      titleJa: nil,
      date: dayDate,
      schedules: schedules
    )
  }
}
