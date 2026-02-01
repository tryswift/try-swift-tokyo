import Foundation
import Testing

@testable import SharedModels

@Suite("ProposalDTO Status Field Tests")
struct ProposalDTOStatusTests {

  private func makeSampleDTO(status: ProposalStatus = .submitted) -> ProposalDTO {
    ProposalDTO(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      conferenceId: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
      conferencePath: "tryswift-tokyo-2026",
      conferenceDisplayName: "try! Swift Tokyo 2026",
      title: "Test Talk",
      abstract: "A test abstract",
      talkDetail: "Some details",
      talkDuration: .regular,
      speakerName: "Test Speaker",
      speakerEmail: "test@example.com",
      bio: "A test bio",
      speakerID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
      speakerUsername: "testuser",
      status: status
    )
  }

  // MARK: - Default Status

  @Test("Default status is submitted")
  func defaultStatus() {
    let dto = ProposalDTO(
      id: UUID(),
      conferenceId: UUID(),
      conferencePath: "test",
      conferenceDisplayName: "Test",
      title: "Title",
      abstract: "Abstract",
      talkDetail: "Detail",
      talkDuration: .regular,
      speakerName: "Name",
      speakerEmail: "email@test.com",
      bio: "Bio",
      speakerID: UUID(),
      speakerUsername: "user"
    )
    #expect(dto.status == .submitted)
  }

  // MARK: - Status Preserved in DTO

  @Test("Status is preserved when set explicitly")
  func statusPreserved() {
    for status in ProposalStatus.allCases {
      let dto = makeSampleDTO(status: status)
      #expect(dto.status == status)
    }
  }

  // MARK: - Codable Round-Trip with Status

  @Test("JSON round-trip preserves status for all cases")
  func jsonRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for status in ProposalStatus.allCases {
      let dto = makeSampleDTO(status: status)
      let data = try encoder.encode(dto)
      let decoded = try decoder.decode(ProposalDTO.self, from: data)
      #expect(decoded.status == status)
      #expect(decoded.id == dto.id)
      #expect(decoded.title == dto.title)
    }
  }

  @Test("JSON encodes status as raw value string")
  func jsonContainsStatusRawValue() throws {
    let dto = makeSampleDTO(status: .accepted)
    let data = try JSONEncoder().encode(dto)
    let jsonString = String(data: data, encoding: .utf8)!
    #expect(jsonString.contains("\"accepted\""))
  }

  @Test("JSON decodes status from raw value string")
  func jsonDecodesStatus() throws {
    let dto = makeSampleDTO(status: .rejected)
    let data = try JSONEncoder().encode(dto)
    let decoded = try JSONDecoder().decode(ProposalDTO.self, from: data)
    #expect(decoded.status == .rejected)
  }

  // MARK: - Equatable

  @Test("DTOs with different status are not equal")
  func differentStatusNotEqual() {
    let submitted = makeSampleDTO(status: .submitted)
    let accepted = makeSampleDTO(status: .accepted)
    #expect(submitted != accepted)
  }

  @Test("DTOs with same status are equal")
  func sameStatusEqual() {
    let dto1 = makeSampleDTO(status: .accepted)
    let dto2 = makeSampleDTO(status: .accepted)
    #expect(dto1 == dto2)
  }
}
