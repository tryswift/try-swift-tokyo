import Foundation
import Testing

@testable import SharedModels

@Suite("ProposalStatus Tests")
struct ProposalStatusTests {

  // MARK: - Raw Values

  @Test("Raw values match expected strings")
  func rawValues() {
    #expect(ProposalStatus.submitted.rawValue == "submitted")
    #expect(ProposalStatus.accepted.rawValue == "accepted")
    #expect(ProposalStatus.rejected.rawValue == "rejected")
    #expect(ProposalStatus.withdrawn.rawValue == "withdrawn")
  }

  @Test("All cases are present")
  func allCases() {
    #expect(ProposalStatus.allCases.count == 4)
    #expect(
      ProposalStatus.allCases == [.submitted, .accepted, .rejected, .withdrawn])
  }

  // MARK: - Display Names

  @Test("Display names are correct")
  func displayNames() {
    #expect(ProposalStatus.submitted.displayName == "Submitted")
    #expect(ProposalStatus.accepted.displayName == "Accepted")
    #expect(ProposalStatus.rejected.displayName == "Rejected")
    #expect(ProposalStatus.withdrawn.displayName == "Withdrawn")
  }

  // MARK: - Badge Classes

  @Test("Badge classes map to correct Bootstrap classes")
  func badgeClasses() {
    #expect(ProposalStatus.submitted.badgeClass == "bg-secondary")
    #expect(ProposalStatus.accepted.badgeClass == "bg-success")
    #expect(ProposalStatus.rejected.badgeClass == "bg-danger")
    #expect(ProposalStatus.withdrawn.badgeClass == "bg-warning text-dark")
  }

  // MARK: - Codable

  @Test("Encodes to raw value string")
  func encode() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(ProposalStatus.accepted)
    let string = String(data: data, encoding: .utf8)
    #expect(string == "\"accepted\"")
  }

  @Test("Decodes from raw value string")
  func decode() throws {
    let decoder = JSONDecoder()
    let data = "\"rejected\"".data(using: .utf8)!
    let status = try decoder.decode(ProposalStatus.self, from: data)
    #expect(status == .rejected)
  }

  @Test("Decoding invalid value throws")
  func decodeInvalid() {
    let decoder = JSONDecoder()
    let data = "\"invalid\"".data(using: .utf8)!
    #expect(throws: DecodingError.self) {
      try decoder.decode(ProposalStatus.self, from: data)
    }
  }

  @Test("Codable round-trip preserves all cases")
  func codableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for status in ProposalStatus.allCases {
      let data = try encoder.encode(status)
      let decoded = try decoder.decode(ProposalStatus.self, from: data)
      #expect(decoded == status)
    }
  }

  // MARK: - Init from raw value

  @Test("Init from valid raw value succeeds")
  func initFromRawValue() {
    #expect(ProposalStatus(rawValue: "submitted") == .submitted)
    #expect(ProposalStatus(rawValue: "accepted") == .accepted)
    #expect(ProposalStatus(rawValue: "rejected") == .rejected)
    #expect(ProposalStatus(rawValue: "withdrawn") == .withdrawn)
  }

  @Test("Init from invalid raw value returns nil")
  func initFromInvalidRawValue() {
    #expect(ProposalStatus(rawValue: "pending") == nil)
    #expect(ProposalStatus(rawValue: "ACCEPTED") == nil)
    #expect(ProposalStatus(rawValue: "") == nil)
  }
}
