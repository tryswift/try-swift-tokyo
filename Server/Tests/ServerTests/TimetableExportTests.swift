import Foundation
import Testing

@testable import Server

@Suite("Timetable Export JSON Tests")
struct TimetableExportTests {

  // MARK: - TimetableExportConference

  @Test("Conference encodes with snake_case keys")
  func conferenceSnakeCaseKeys() throws {
    let conference = TimetableExportConference(
      id: 1,
      title: "Day 1",
      titleJa: "1日目",
      date: Date(timeIntervalSince1970: 0),
      schedules: []
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(conference)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("\"title_ja\""))
    #expect(!jsonString.contains("\"titleJa\""))
  }

  @Test("Conference encodes id as integer")
  func conferenceIdIsInteger() throws {
    let conference = TimetableExportConference(
      id: 2,
      title: "Day 2",
      titleJa: nil,
      date: Date(timeIntervalSince1970: 0),
      schedules: []
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(conference)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    #expect(json["id"] as? Int == 2)
  }

  @Test("Conference round-trip preserves data")
  func conferenceRoundTrip() throws {
    let date = Date(timeIntervalSince1970: 1_717_200_000)
    let conference = TimetableExportConference(
      id: 1,
      title: "Workshop",
      titleJa: "ワークショップ",
      date: date,
      schedules: []
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let data = try encoder.encode(conference)
    let decoded = try decoder.decode(TimetableExportConference.self, from: data)

    #expect(decoded.id == 1)
    #expect(decoded.title == "Workshop")
    #expect(decoded.titleJa == "ワークショップ")
    #expect(decoded.schedules.isEmpty)
  }

  // MARK: - TimetableExportSchedule

  @Test("Schedule encodes time as date")
  func scheduleEncodesTime() throws {
    let schedule = TimetableExportSchedule(
      time: Date(timeIntervalSince1970: 1_717_200_000),
      sessions: []
    )

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(schedule)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("\"time\""))
    #expect(jsonString.contains("2024-06-01"))
  }

  // MARK: - TimetableExportSession

  @Test("Session encodes all fields")
  func sessionEncodesAllFields() throws {
    let session = TimetableExportSession(
      title: "Swift Concurrency Deep Dive",
      titleJa: "Swift並行処理の深掘り",
      summary: "A deep dive into async/await",
      summaryJa: "async/awaitの深掘り",
      speakers: [
        TimetableExportSpeaker(
          name: "John Doe",
          imageName: "john_doe",
          bio: "Swift enthusiast",
          bioJa: "Swiftエンジニア",
          links: [
            TimetableExportLink(name: "Twitter", url: "https://twitter.com/johndoe")
          ]
        )
      ],
      place: "Hall A",
      placeJa: "ホールA",
      description: "Full description",
      descriptionJa: "完全な説明"
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let data = try encoder.encode(session)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("\"title_ja\""))
    #expect(jsonString.contains("\"summary_ja\""))
    #expect(jsonString.contains("\"place_ja\""))
    #expect(jsonString.contains("\"description_ja\""))
    #expect(jsonString.contains("\"image_name\""))
    #expect(jsonString.contains("\"bio_ja\""))
  }

  @Test("Session with nil speakers encodes as null")
  func sessionNilSpeakers() throws {
    let session = TimetableExportSession(
      title: "Lunch Break",
      titleJa: "昼休み",
      summary: nil,
      summaryJa: nil,
      speakers: nil,
      place: nil,
      placeJa: nil,
      description: nil,
      descriptionJa: nil
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(session)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    // nil Optional encodes as JSON null
    #expect(json["speakers"] == nil || json["speakers"] is NSNull)
  }

  // MARK: - TimetableExportSpeaker

  @Test("Speaker encodes with image_name in snake_case")
  func speakerImageNameSnakeCase() throws {
    let speaker = TimetableExportSpeaker(
      name: "Jane Smith",
      imageName: "jane_smith",
      bio: "iOS developer",
      bioJa: "iOSデベロッパー",
      links: []
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let data = try encoder.encode(speaker)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("\"image_name\""))
    #expect(jsonString.contains("\"bio_ja\""))
  }

  // MARK: - TimetableExportLink

  @Test("Link round-trip preserves data")
  func linkRoundTrip() throws {
    let link = TimetableExportLink(name: "GitHub", url: "https://github.com/example")

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(link)
    let decoded = try decoder.decode(TimetableExportLink.self, from: data)

    #expect(decoded.name == "GitHub")
    #expect(decoded.url == "https://github.com/example")
  }

  // MARK: - Full Structure

  @Test("Full timetable structure matches DataClient schema")
  func fullStructureMatchesDataClientSchema() throws {
    let conference = TimetableExportConference(
      id: 2,
      title: "Day 1",
      titleJa: nil,
      date: Date(timeIntervalSince1970: 1_717_200_000),
      schedules: [
        TimetableExportSchedule(
          time: Date(timeIntervalSince1970: 1_717_218_000),
          sessions: [
            TimetableExportSession(
              title: "Opening",
              titleJa: "オープニング",
              summary: nil,
              summaryJa: nil,
              speakers: nil,
              place: "Main Hall",
              placeJa: "メインホール",
              description: nil,
              descriptionJa: nil
            )
          ]
        ),
        TimetableExportSchedule(
          time: Date(timeIntervalSince1970: 1_717_221_600),
          sessions: [
            TimetableExportSession(
              title: "Keynote: Future of Swift",
              titleJa: nil,
              summary: "A look at what's coming",
              summaryJa: nil,
              speakers: [
                TimetableExportSpeaker(
                  name: "Tim Apple",
                  imageName: "tim_apple",
                  bio: "CEO",
                  bioJa: nil,
                  links: [
                    TimetableExportLink(name: "Website", url: "https://example.com")
                  ]
                )
              ],
              place: "Main Hall",
              placeJa: "メインホール",
              description: "Full keynote description",
              descriptionJa: nil
            )
          ]
        ),
      ]
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(conference)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    // Verify top-level structure
    #expect(json["id"] as? Int == 2)
    #expect(json["title"] as? String == "Day 1")
    #expect(json["date"] != nil)

    // Verify schedules array
    let schedules = json["schedules"] as! [[String: Any]]
    #expect(schedules.count == 2)

    // Verify sessions within schedules
    let firstSessions = schedules[0]["sessions"] as! [[String: Any]]
    #expect(firstSessions.count == 1)
    #expect(firstSessions[0]["title"] as? String == "Opening")
    // nil Optional speakers: key may be absent or null
    let openingSpeakers = firstSessions[0]["speakers"]
    #expect(openingSpeakers == nil || openingSpeakers is NSNull)

    let secondSessions = schedules[1]["sessions"] as! [[String: Any]]
    #expect(secondSessions.count == 1)

    let speakers = secondSessions[0]["speakers"] as! [[String: Any]]
    #expect(speakers.count == 1)
    #expect(speakers[0]["name"] as? String == "Tim Apple")
    #expect(speakers[0]["image_name"] as? String == "tim_apple")

    let links = speakers[0]["links"] as! [[String: Any]]
    #expect(links.count == 1)
    #expect(links[0]["name"] as? String == "Website")
  }

  // MARK: - JST Date Encoding

  @Test("Custom JST date encoding produces correct timezone")
  func jstDateEncoding() throws {
    let conference = TimetableExportConference(
      id: 1,
      title: "Day 1",
      titleJa: nil,
      date: Date(timeIntervalSince1970: 1_717_200_000),
      schedules: []
    )

    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .custom { date, encoder in
      let jstFormatter = ISO8601DateFormatter()
      jstFormatter.formatOptions = [.withInternetDateTime]
      jstFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")!
      var container = encoder.singleValueContainer()
      try container.encode(jstFormatter.string(from: date))
    }

    let data = try encoder.encode(conference)
    let jsonString = String(data: data, encoding: .utf8)!

    #expect(jsonString.contains("+09:00"))
  }
}
