import Foundation
import Testing

@testable import Server

@Suite("Speaker Export JSON Tests")
struct SpeakerExportTests {

  @Test("SpeakerExportDTO encodes with snake_case keys")
  func speakerSnakeCaseKeys() throws {
    let speaker = SpeakerExportDTO(
      name: "John Doe",
      imageName: "john_doe",
      bio: "Swift enthusiast",
      bioJa: "Swiftエンジニア",
      jobTitle: "Senior Engineer",
      jobTitleJa: "シニアエンジニア",
      links: []
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let data = try encoder.encode(speaker)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("\"image_name\""))
    #expect(jsonString.contains("\"bio_ja\""))
    #expect(jsonString.contains("\"job_title\""))
    #expect(jsonString.contains("\"job_title_ja\""))
    #expect(!jsonString.contains("\"imageName\""))
    #expect(!jsonString.contains("\"bioJa\""))
    #expect(!jsonString.contains("\"jobTitle\""))
    #expect(!jsonString.contains("\"jobTitleJa\""))
  }

  @Test("SpeakerExportDTO round-trip preserves data")
  func speakerRoundTrip() throws {
    let speaker = SpeakerExportDTO(
      name: "Jane Smith",
      imageName: "jane_smith",
      bio: "iOS developer",
      bioJa: "iOSデベロッパー",
      jobTitle: "Lead Engineer at Company",
      jobTitleJa: "株式会社○○ リードエンジニア",
      links: [
        SpeakerExportLink(url: "https://github.com/janesmith", name: "@janesmith")
      ]
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(speaker)
    let decoded = try decoder.decode(SpeakerExportDTO.self, from: data)

    #expect(decoded.name == "Jane Smith")
    #expect(decoded.imageName == "jane_smith")
    #expect(decoded.bio == "iOS developer")
    #expect(decoded.bioJa == "iOSデベロッパー")
    #expect(decoded.jobTitle == "Lead Engineer at Company")
    #expect(decoded.jobTitleJa == "株式会社○○ リードエンジニア")
    #expect(decoded.links.count == 1)
    #expect(decoded.links[0].name == "@janesmith")
    #expect(decoded.links[0].url == "https://github.com/janesmith")
  }

  @Test("SpeakerExportDTO with nil optional fields")
  func speakerNilOptionals() throws {
    let speaker = SpeakerExportDTO(
      name: "Bob",
      imageName: "bob",
      bio: nil,
      bioJa: nil,
      jobTitle: nil,
      jobTitleJa: nil,
      links: []
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(speaker)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    #expect(json["name"] as? String == "Bob")
    #expect(json["bio"] == nil || json["bio"] is NSNull)
    #expect(json["links"] as? [[String: Any]] != nil)
  }

  @Test("SpeakerExportLink round-trip preserves data")
  func linkRoundTrip() throws {
    let link = SpeakerExportLink(url: "https://github.com/example", name: "@example")

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(link)
    let decoded = try decoder.decode(SpeakerExportLink.self, from: data)

    #expect(decoded.url == "https://github.com/example")
    #expect(decoded.name == "@example")
  }

  @Test("Speaker array encodes matching 2026-speakers.json format")
  func speakerArrayMatchesFormat() throws {
    let speakers = [
      SpeakerExportDTO(
        name: "Alice",
        imageName: "alice",
        bio: "Swift developer",
        bioJa: "Swiftデベロッパー",
        jobTitle: "Engineer",
        jobTitleJa: "エンジニア",
        links: [
          SpeakerExportLink(url: "https://github.com/alice", name: "@alice")
        ]
      ),
      SpeakerExportDTO(
        name: "Bob Chen",
        imageName: "bob_chen",
        bio: "Kotlin multiplatform expert",
        bioJa: nil,
        jobTitle: nil,
        jobTitleJa: nil,
        links: []
      ),
    ]

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(speakers)
    let jsonArray = try JSONSerialization.jsonObject(with: data) as! [[String: Any]]

    #expect(jsonArray.count == 2)
    #expect(jsonArray[0]["name"] as? String == "Alice")
    #expect(jsonArray[0]["image_name"] as? String == "alice")
    #expect(jsonArray[0]["job_title"] as? String == "Engineer")
    #expect(jsonArray[0]["job_title_ja"] as? String == "エンジニア")

    let links = jsonArray[0]["links"] as! [[String: Any]]
    #expect(links.count == 1)
    #expect(links[0]["url"] as? String == "https://github.com/alice")

    #expect(jsonArray[1]["name"] as? String == "Bob Chen")
    #expect(jsonArray[1]["image_name"] as? String == "bob_chen")
  }
}
