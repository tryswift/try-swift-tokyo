import DataClient
import SharedModels
import Testing

@Suite
struct PastEventDecodingTests {
  let dataClient = DataClient.liveValue

  // MARK: - 2017

  @Test
  func decode2017Day1() throws {
    let conference = try dataClient.fetchDay1(.year2017)
    #expect(conference.title == "Day 1")
    #expect(!conference.schedules.isEmpty)
    #expect(conference.schedules.count > 10)
  }

  @Test
  func decode2017Day2() throws {
    let conference = try dataClient.fetchDay2(.year2017)
    #expect(conference.title == "Day 2")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2017Speakers() throws {
    let speakers = try dataClient.fetchSpeakers(.year2017)
    #expect(speakers.count >= 20)
    #expect(speakers.allSatisfy { !$0.name.isEmpty })
    #expect(speakers.allSatisfy { !$0.imageName.isEmpty })
  }

  @Test
  func decode2017Day3Throws() throws {
    #expect(throws: DataClientError.self) {
      _ = try dataClient.fetchDay3(.year2017)
    }
  }

  // MARK: - 2018

  @Test
  func decode2018Day1() throws {
    let conference = try dataClient.fetchDay1(.year2018)
    #expect(conference.title == "Day 1")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2018Day2() throws {
    let conference = try dataClient.fetchDay2(.year2018)
    #expect(conference.title == "Day 2")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2018Speakers() throws {
    let speakers = try dataClient.fetchSpeakers(.year2018)
    #expect(speakers.count >= 25)
    #expect(speakers.allSatisfy { !$0.name.isEmpty })
  }

  // MARK: - 2019

  @Test
  func decode2019Day1() throws {
    let conference = try dataClient.fetchDay1(.year2019)
    #expect(conference.title == "Day 1")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2019Day2() throws {
    let conference = try dataClient.fetchDay2(.year2019)
    #expect(conference.title == "Day 2")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2019Speakers() throws {
    let speakers = try dataClient.fetchSpeakers(.year2019)
    #expect(speakers.count >= 30)
    #expect(speakers.allSatisfy { !$0.name.isEmpty })
  }

  // MARK: - 2020

  @Test
  func decode2020Day1() throws {
    let conference = try dataClient.fetchDay1(.year2020)
    #expect(conference.title == "Day 1")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2020Day2() throws {
    let conference = try dataClient.fetchDay2(.year2020)
    #expect(conference.title == "Day 2")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2020Speakers() throws {
    let speakers = try dataClient.fetchSpeakers(.year2020)
    #expect(speakers.count >= 20)
    #expect(speakers.allSatisfy { !$0.name.isEmpty })
  }

  // MARK: - Existing years still work

  @Test
  func decode2024Day1() throws {
    let conference = try dataClient.fetchDay1(.year2024)
    #expect(conference.title == "Day 1")
    #expect(!conference.schedules.isEmpty)
  }

  @Test
  func decode2024Speakers() throws {
    let speakers = try dataClient.fetchSpeakers(.year2024)
    #expect(!speakers.isEmpty)
  }

  // MARK: - Error handling

  @Test
  func missingResourceReturnsError() throws {
    #expect(throws: DataClientError.self) {
      _ = try dataClient.fetchSponsors(.year2017)
    }
  }

  @Test
  func missingOrganizersReturnsError() throws {
    #expect(throws: DataClientError.self) {
      _ = try dataClient.fetchOrganizers(.year2017)
    }
  }
}
