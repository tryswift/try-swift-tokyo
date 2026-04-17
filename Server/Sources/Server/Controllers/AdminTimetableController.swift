import Fluent
import Vapor

struct OptionalPayloadField<T: Codable & Sendable>: Codable, Sendable {
  let value: T?

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.value = container.decodeNil() ? nil : try container.decode(T.self)
  }
}

struct CreateScheduleSlotRequestContent: Content {
  var conferenceId: UUID
  var proposalId: UUID?
  var day: Int
  var startTime: String
  var endTime: String?
  var slotType: String
  var customTitle: String?
  var customTitleJa: String?
  var place: String?
  var placeJa: String?
}

struct UpdateScheduleSlotRequestContent: Content {
  var proposalId: OptionalPayloadField<UUID>?
  var day: Int?
  var startTime: String?
  var endTime: OptionalPayloadField<String>?
  var slotType: String?
  var customTitle: OptionalPayloadField<String>?
  var customTitleJa: OptionalPayloadField<String>?
  var descriptionText: OptionalPayloadField<String>?
  var descriptionTextJa: OptionalPayloadField<String>?
  var place: OptionalPayloadField<String>?
  var placeJa: OptionalPayloadField<String>?
}

struct ReorderScheduleSlotRequestContent: Content {
  var id: UUID
  var sortOrder: Int
}

struct AdminTimetableController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let admin = routes.grouped("admin")
      .grouped(AuthMiddleware())
      .grouped(OrganizerMiddleware())
    let timetable = admin.grouped("timetable")

    timetable.get("slots", use: getSlots)
    timetable.post("slots", use: createSlot)
    timetable.put("slots", ":slotID", use: updateSlot)
    timetable.delete("slots", ":slotID", use: deleteSlot)
    timetable.post("reorder", use: reorderSlots)
    timetable.get("export", use: exportAll)
    timetable.get("export", ":day", use: exportDay)
  }

  @Sendable
  func getSlots(req: Request) async throws -> [ScheduleSlotDTO] {
    _ = try await AdminAPIService.requireAdmin(req)

    let conference: Conference
    if let conferencePath = req.query[String.self, at: "conference"] {
      guard
        let found = try await Conference.query(on: req.db)
          .filter(\.$path == conferencePath)
          .first()
      else {
        throw Abort(.notFound, reason: "Conference not found")
      }
      conference = found
    } else {
      guard
        let found = try await Conference.query(on: req.db)
          .sort(\.$year, .descending)
          .first()
      else {
        throw Abort(.notFound, reason: "No conference found")
      }
      conference = found
    }

    guard let conferenceID = conference.id else {
      throw Abort(.internalServerError, reason: "Conference ID missing")
    }

    let slots = try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == conferenceID)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }
      .sort(\.$day)
      .sort(\.$sortOrder)
      .all()

    return try slots.map { try ScheduleSlotDTO(slot: $0) }
  }

  @Sendable
  func createSlot(req: Request) async throws -> ScheduleSlotDTO {
    _ = try await AdminAPIService.requireAdmin(req)
    let body = try req.content.decode(CreateScheduleSlotRequestContent.self)

    guard let slotType = SlotType(rawValue: body.slotType) else {
      throw Abort(.badRequest, reason: "Invalid slot type")
    }
    guard let startTime = AdminAPIService.parseISO8601(body.startTime) else {
      throw Abort(.badRequest, reason: "Invalid start time format")
    }
    let endTime = try body.endTime.map { raw in
      guard let value = AdminAPIService.parseISO8601(raw) else {
        throw Abort(.badRequest, reason: "Invalid end time format")
      }
      return value
    }

    let maxOrder =
      try await ScheduleSlot.query(on: req.db)
      .filter(\.$conference.$id == body.conferenceId)
      .filter(\.$day == body.day)
      .sort(\.$sortOrder, .descending)
      .first()?.sortOrder ?? -1

    let slot = ScheduleSlot(
      conferenceID: body.conferenceId,
      proposalID: body.proposalId,
      day: body.day,
      startTime: startTime,
      endTime: endTime,
      slotType: slotType,
      customTitle: body.customTitle,
      customTitleJa: body.customTitleJa,
      place: body.place,
      placeJa: body.placeJa,
      sortOrder: maxOrder + 1
    )

    try await slot.save(on: req.db)

    let savedQuery = ScheduleSlot.query(on: req.db)
      .filter(\.$id == slot.id!)
      .with(\.$proposal) { proposal in
        proposal.with(\.$speaker)
        proposal.with(\.$conference)
      }

    guard let saved = try await savedQuery.first() else {
      throw Abort(.internalServerError, reason: "Failed to reload slot")
    }

    return try ScheduleSlotDTO(slot: saved)
  }

  @Sendable
  func updateSlot(req: Request) async throws -> HTTPStatus {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let slotID = req.parameters.get("slotID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid slot ID")
    }
    guard let slot = try await ScheduleSlot.find(slotID, on: req.db) else {
      throw Abort(.notFound, reason: "Slot not found")
    }

    let body = try req.content.decode(UpdateScheduleSlotRequestContent.self)
    if let proposalId = body.proposalId { slot.$proposal.id = proposalId.value }
    if let day = body.day { slot.day = day }
    if let startTime = body.startTime {
      guard let value = AdminAPIService.parseISO8601(startTime) else {
        throw Abort(.badRequest, reason: "Invalid start time format")
      }
      slot.startTime = value
    }
    if let endTime = body.endTime {
      slot.endTime = try endTime.value.map { raw in
        guard let value = AdminAPIService.parseISO8601(raw) else {
          throw Abort(.badRequest, reason: "Invalid end time format")
        }
        return value
      }
    }
    if let slotType = body.slotType {
      guard let value = SlotType(rawValue: slotType) else {
        throw Abort(.badRequest, reason: "Invalid slot type")
      }
      slot.slotType = value
    }
    if let customTitle = body.customTitle { slot.customTitle = customTitle.value }
    if let customTitleJa = body.customTitleJa { slot.customTitleJa = customTitleJa.value }
    if let descriptionText = body.descriptionText { slot.descriptionText = descriptionText.value }
    if let descriptionTextJa = body.descriptionTextJa { slot.descriptionTextJa = descriptionTextJa.value }
    if let place = body.place { slot.place = place.value }
    if let placeJa = body.placeJa { slot.placeJa = placeJa.value }

    try await slot.save(on: req.db)
    return .ok
  }

  @Sendable
  func deleteSlot(req: Request) async throws -> HTTPStatus {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let slotID = req.parameters.get("slotID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid slot ID")
    }
    guard let slot = try await ScheduleSlot.find(slotID, on: req.db) else {
      throw Abort(.notFound, reason: "Slot not found")
    }
    try await slot.delete(on: req.db)
    return .noContent
  }

  @Sendable
  func reorderSlots(req: Request) async throws -> HTTPStatus {
    _ = try await AdminAPIService.requireAdmin(req)
    let items = try req.content.decode([ReorderScheduleSlotRequestContent].self)
    for item in items {
      if let slot = try await ScheduleSlot.find(item.id, on: req.db) {
        slot.sortOrder = item.sortOrder
        try await slot.save(on: req.db)
      }
    }
    return .ok
  }

  @Sendable
  func exportDay(req: Request) async throws -> Response {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let day = req.parameters.get("day", as: Int.self) else {
      throw Abort(.badRequest, reason: "Invalid day parameter")
    }
    guard
      let conference = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .first(),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "No conference found")
    }
    let json = try await AdminAPIService.buildTimetableJSON(
      req: req, conference: conference, conferenceID: conferenceID, day: day)
    return try AdminAPIService.encodeJSONAttachment(
      json, filename: "\(conference.year)-day\(day).json")
  }

  @Sendable
  func exportAll(req: Request) async throws -> Response {
    _ = try await AdminAPIService.requireAdmin(req)
    guard
      let conference = try await Conference.query(on: req.db)
        .sort(\.$year, .descending)
        .first(),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "No conference found")
    }
    let days = AdminAPIService.computeConferenceDays(conference: conference)
    var allDays: [TimetableExportConference] = []
    for dayInfo in days {
      let json = try await AdminAPIService.buildTimetableJSON(
        req: req, conference: conference, conferenceID: conferenceID, day: dayInfo.dayNumber)
      allDays.append(json)
    }
    return try AdminAPIService.encodeJSONAttachment(allDays, filename: "timetable-all.json")
  }
}
