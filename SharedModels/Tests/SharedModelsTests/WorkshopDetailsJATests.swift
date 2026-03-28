import Foundation
import Testing

@testable import SharedModels

@Suite("WorkshopDetailsJA Codable Tests")
struct WorkshopDetailsJATests {

  @Test("Round-trip encode/decode retains all field values")
  func roundTrip() throws {
    let original = WorkshopDetailsJA(
      keyTakeaways: "学べること",
      prerequisites: "Swiftの基本知識",
      agendaSchedule: "10:00-12:00 ハンズオン",
      participantRequirements: "MacBook",
      requiredSoftware: "Xcode 16",
      networkRequirements: "Wi-Fi必須"
    )

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(WorkshopDetailsJA.self, from: data)

    #expect(decoded == original)
    #expect(decoded.keyTakeaways == "学べること")
    #expect(decoded.prerequisites == "Swiftの基本知識")
    #expect(decoded.agendaSchedule == "10:00-12:00 ハンズオン")
    #expect(decoded.participantRequirements == "MacBook")
    #expect(decoded.requiredSoftware == "Xcode 16")
    #expect(decoded.networkRequirements == "Wi-Fi必須")
  }

  @Test("Decode from empty JSON object succeeds with all fields nil")
  func decodeEmptyObject() throws {
    let json = Data("{}".utf8)
    let decoded = try JSONDecoder().decode(WorkshopDetailsJA.self, from: json)

    #expect(decoded.keyTakeaways == nil)
    #expect(decoded.prerequisites == nil)
    #expect(decoded.agendaSchedule == nil)
    #expect(decoded.participantRequirements == nil)
    #expect(decoded.requiredSoftware == nil)
    #expect(decoded.networkRequirements == nil)
  }

  @Test("Decode with partial fields succeeds")
  func decodePartialFields() throws {
    let json = Data(
      """
      {"keyTakeaways": "テスト", "agendaSchedule": "スケジュール"}
      """.utf8)
    let decoded = try JSONDecoder().decode(WorkshopDetailsJA.self, from: json)

    #expect(decoded.keyTakeaways == "テスト")
    #expect(decoded.prerequisites == nil)
    #expect(decoded.agendaSchedule == "スケジュール")
    #expect(decoded.participantRequirements == nil)
  }
}

@Suite("ProposalDTO workshopDetailsJA Backward Compatibility Tests")
struct ProposalDTOWorkshopDetailsJATests {

  private func makeSampleDTO(
    workshopDetailsJA: WorkshopDetailsJA? = nil
  ) -> ProposalDTO {
    ProposalDTO(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      conferenceId: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
      conferencePath: "tryswift-tokyo-2026",
      conferenceDisplayName: "try! Swift Tokyo 2026",
      title: "Test Workshop",
      abstract: "A test abstract",
      talkDetail: "Some details",
      talkDuration: .workshop,
      speakerName: "Test Speaker",
      speakerEmail: "test@example.com",
      bio: "A test bio",
      speakerID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
      speakerUsername: "testuser",
      workshopDetailsJA: workshopDetailsJA
    )
  }

  @Test("Round-trip preserves workshopDetailsJA values")
  func roundTrip() throws {
    let detailsJA = WorkshopDetailsJA(
      keyTakeaways: "学べること",
      prerequisites: "前提知識",
      agendaSchedule: "スケジュール",
      participantRequirements: "持ち物",
      requiredSoftware: "ソフトウェア",
      networkRequirements: "ネットワーク"
    )
    let dto = makeSampleDTO(workshopDetailsJA: detailsJA)

    let data = try JSONEncoder().encode(dto)
    let decoded = try JSONDecoder().decode(ProposalDTO.self, from: data)

    #expect(decoded.workshopDetailsJA == detailsJA)
    #expect(decoded.workshopDetailsJA?.keyTakeaways == "学べること")
  }

  @Test("Round-trip preserves nil workshopDetailsJA")
  func roundTripNil() throws {
    let dto = makeSampleDTO(workshopDetailsJA: nil)

    let data = try JSONEncoder().encode(dto)
    let decoded = try JSONDecoder().decode(ProposalDTO.self, from: data)

    #expect(decoded.workshopDetailsJA == nil)
  }

  @Test("Decode from older payload missing workshopDetailsJA key succeeds")
  func backwardCompatibility() throws {
    // Encode a DTO, then remove the workshopDetailsJA key to simulate an older payload
    let dto = makeSampleDTO(workshopDetailsJA: nil)
    let data = try JSONEncoder().encode(dto)

    var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    json.removeValue(forKey: "workshopDetailsJA")

    let modifiedData = try JSONSerialization.data(withJSONObject: json)
    let decoded = try JSONDecoder().decode(ProposalDTO.self, from: modifiedData)

    #expect(decoded.workshopDetailsJA == nil)
    #expect(decoded.title == "Test Workshop")
  }
}
