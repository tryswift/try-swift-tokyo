import Foundation
import Vapor

/// DTO for schedule slots used in timetable editor API
struct ScheduleSlotDTO: Content, Sendable {
  let id: UUID?
  let conferenceId: UUID
  let proposalId: UUID?
  let proposalTitle: String?
  let speakerName: String?
  let speakerIconURL: String?
  let talkDuration: String?
  let day: Int
  let startTime: Date
  let endTime: Date?
  let slotType: String
  let customTitle: String?
  let customTitleJa: String?
  let place: String?
  let placeJa: String?
  let sortOrder: Int

  init(slot: ScheduleSlot) throws {
    self.id = slot.id
    self.conferenceId = slot.$conference.id
    self.proposalId = slot.$proposal.id
    self.proposalTitle = slot.proposal?.title
    self.speakerName = slot.proposal?.speakerName
    self.speakerIconURL = slot.proposal?.iconURL
    self.talkDuration = slot.proposal?.talkDuration.rawValue
    self.day = slot.day
    self.startTime = slot.startTime
    self.endTime = slot.endTime
    self.slotType = slot.slotType.rawValue
    self.customTitle = slot.customTitle
    self.customTitleJa = slot.customTitleJa
    self.place = slot.place
    self.placeJa = slot.placeJa
    self.sortOrder = slot.sortOrder
  }
}

/// Export format matching DataClient Conference JSON structure
struct TimetableExportConference: Codable, Sendable {
  let id: Int
  let title: String
  let titleJa: String?
  let date: Date
  let schedules: [TimetableExportSchedule]
}

struct TimetableExportSchedule: Codable, Sendable {
  let time: Date
  let sessions: [TimetableExportSession]
}

struct TimetableExportSession: Codable, Sendable {
  let title: String
  let titleJa: String?
  let summary: String?
  let summaryJa: String?
  let speakers: [TimetableExportSpeaker]?
  let place: String?
  let placeJa: String?
  let description: String?
  let descriptionJa: String?
}

struct TimetableExportSpeaker: Codable, Sendable {
  let name: String
  let imageName: String
  let bio: String?
  let bioJa: String?
  let links: [TimetableExportLink]
}

struct TimetableExportLink: Codable, Sendable {
  let name: String
  let url: String
}
