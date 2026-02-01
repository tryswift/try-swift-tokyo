import Foundation
import Testing

@testable import SharedModels

@Suite("TalkDuration Tests")
struct TalkDurationTests {

  // MARK: - Raw Values

  @Test("Raw values match expected strings")
  func rawValues() {
    #expect(TalkDuration.regular.rawValue == "20min")
    #expect(TalkDuration.lightning.rawValue == "LT")
    #expect(TalkDuration.invited.rawValue == "invited")
  }

  @Test("All cases are present")
  func allCases() {
    #expect(TalkDuration.allCases.count == 3)
    #expect(TalkDuration.allCases == [.regular, .lightning, .invited])
  }

  // MARK: - Display Names

  @Test("Display names are correct")
  func displayNames() {
    #expect(TalkDuration.regular.displayName == "20 minutes")
    #expect(TalkDuration.lightning.displayName == "Lightning Talk (5 min)")
    #expect(TalkDuration.invited.displayName == "Invited Talk (20 min)")
  }

  // MARK: - isInvitedOnly

  @Test("Only invited duration is invited-only")
  func isInvitedOnly() {
    #expect(TalkDuration.regular.isInvitedOnly == false)
    #expect(TalkDuration.lightning.isInvitedOnly == false)
    #expect(TalkDuration.invited.isInvitedOnly == true)
  }

  // MARK: - Codable

  @Test("Encodes to raw value string")
  func encode() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(TalkDuration.regular)
    let string = String(data: data, encoding: .utf8)
    #expect(string == "\"20min\"")
  }

  @Test("Decodes from raw value string")
  func decode() throws {
    let decoder = JSONDecoder()
    let data = "\"LT\"".data(using: .utf8)!
    let duration = try decoder.decode(TalkDuration.self, from: data)
    #expect(duration == .lightning)
  }

  @Test("Decoding invalid value throws")
  func decodeInvalid() {
    let decoder = JSONDecoder()
    let data = "\"30min\"".data(using: .utf8)!
    #expect(throws: DecodingError.self) {
      try decoder.decode(TalkDuration.self, from: data)
    }
  }

  @Test("Codable round-trip preserves all cases")
  func codableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for duration in TalkDuration.allCases {
      let data = try encoder.encode(duration)
      let decoded = try decoder.decode(TalkDuration.self, from: data)
      #expect(decoded == duration)
    }
  }

  // MARK: - Init from raw value

  @Test("Init from valid raw value succeeds")
  func initFromRawValue() {
    #expect(TalkDuration(rawValue: "20min") == .regular)
    #expect(TalkDuration(rawValue: "LT") == .lightning)
    #expect(TalkDuration(rawValue: "invited") == .invited)
  }

  @Test("Init from invalid raw value returns nil")
  func initFromInvalidRawValue() {
    #expect(TalkDuration(rawValue: "30min") == nil)
    #expect(TalkDuration(rawValue: "lt") == nil)
    #expect(TalkDuration(rawValue: "") == nil)
  }
}
