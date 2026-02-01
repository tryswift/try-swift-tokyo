import Foundation
import Testing

@testable import Server

@Suite("SlotType Tests")
struct SlotTypeTests {

  // MARK: - Raw Values

  @Test("Raw values match expected strings")
  func rawValues() {
    #expect(SlotType.talk.rawValue == "talk")
    #expect(SlotType.lightningTalk.rawValue == "lightning_talk")
    #expect(SlotType.breakTime.rawValue == "break")
    #expect(SlotType.lunch.rawValue == "lunch")
    #expect(SlotType.opening.rawValue == "opening")
    #expect(SlotType.closing.rawValue == "closing")
    #expect(SlotType.party.rawValue == "party")
    #expect(SlotType.custom.rawValue == "custom")
  }

  @Test("All cases are present")
  func allCases() {
    #expect(SlotType.allCases.count == 8)
    #expect(
      SlotType.allCases == [
        .talk, .lightningTalk, .breakTime, .lunch, .opening, .closing, .party, .custom,
      ])
  }

  // MARK: - Display Names

  @Test("Display names are correct")
  func displayNames() {
    #expect(SlotType.talk.displayName == "Talk")
    #expect(SlotType.lightningTalk.displayName == "Lightning Talk")
    #expect(SlotType.breakTime.displayName == "Break")
    #expect(SlotType.lunch.displayName == "Lunch")
    #expect(SlotType.opening.displayName == "Opening")
    #expect(SlotType.closing.displayName == "Closing")
    #expect(SlotType.party.displayName == "Party")
    #expect(SlotType.custom.displayName == "Custom")
  }

  // MARK: - Codable

  @Test("Encodes to raw value string")
  func encode() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(SlotType.lightningTalk)
    let string = String(data: data, encoding: .utf8)
    #expect(string == "\"lightning_talk\"")
  }

  @Test("Break type encodes as 'break'")
  func encodeBreak() throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(SlotType.breakTime)
    let string = String(data: data, encoding: .utf8)
    #expect(string == "\"break\"")
  }

  @Test("Decodes from raw value string")
  func decode() throws {
    let decoder = JSONDecoder()
    let data = "\"lightning_talk\"".data(using: .utf8)!
    let slotType = try decoder.decode(SlotType.self, from: data)
    #expect(slotType == .lightningTalk)
  }

  @Test("Decodes break from 'break' string")
  func decodeBreak() throws {
    let decoder = JSONDecoder()
    let data = "\"break\"".data(using: .utf8)!
    let slotType = try decoder.decode(SlotType.self, from: data)
    #expect(slotType == .breakTime)
  }

  @Test("Decoding invalid value throws")
  func decodeInvalid() {
    let decoder = JSONDecoder()
    let data = "\"keynote\"".data(using: .utf8)!
    #expect(throws: DecodingError.self) {
      try decoder.decode(SlotType.self, from: data)
    }
  }

  @Test("Codable round-trip preserves all cases")
  func codableRoundTrip() throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for slotType in SlotType.allCases {
      let data = try encoder.encode(slotType)
      let decoded = try decoder.decode(SlotType.self, from: data)
      #expect(decoded == slotType)
    }
  }

  // MARK: - Init from raw value

  @Test("Init from valid raw value succeeds")
  func initFromRawValue() {
    #expect(SlotType(rawValue: "talk") == .talk)
    #expect(SlotType(rawValue: "lightning_talk") == .lightningTalk)
    #expect(SlotType(rawValue: "break") == .breakTime)
    #expect(SlotType(rawValue: "lunch") == .lunch)
    #expect(SlotType(rawValue: "opening") == .opening)
    #expect(SlotType(rawValue: "closing") == .closing)
    #expect(SlotType(rawValue: "party") == .party)
    #expect(SlotType(rawValue: "custom") == .custom)
  }

  @Test("Init from invalid raw value returns nil")
  func initFromInvalidRawValue() {
    #expect(SlotType(rawValue: "keynote") == nil)
    #expect(SlotType(rawValue: "TALK") == nil)
    #expect(SlotType(rawValue: "") == nil)
    #expect(SlotType(rawValue: "breakTime") == nil)
  }
}
