import Dependencies
import DependenciesMacros
import Foundation
import SharedModels

public enum DataClientError: Error, Equatable {
  case resourceNotFound(String)
}

@DependencyClient
public struct DataClient: Sendable {
  public var fetchDay1: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchDay2: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchDay3: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchWorkshop: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchSponsors: @Sendable (_ year: ConferenceYear) throws -> Sponsors
  public var fetchOrganizers: @Sendable (_ year: ConferenceYear) throws -> [Organizer]
  public var fetchSpeakers: @Sendable (_ year: ConferenceYear) throws -> [Speaker]
}

extension DataClient: DependencyKey {
  static public let liveValue: DataClient = .init(
    fetchDay1: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-day1")
      return try jsonDecoder.decode(Conference.self, from: data)
    },
    fetchDay2: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-day2")
      return try jsonDecoder.decode(Conference.self, from: data)
    },
    fetchDay3: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-day3")
      return try jsonDecoder.decode(Conference.self, from: data)
    },
    fetchWorkshop: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-workshop")
      return try jsonDecoder.decode(Conference.self, from: data)
    },
    fetchSponsors: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-sponsors")
      return try jsonDecoder.decode(Sponsors.self, from: data)
    },
    fetchOrganizers: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-organizers")
      return try jsonDecoder.decode([Organizer].self, from: data)
    },
    fetchSpeakers: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-speakers")
      return try jsonDecoder.decode([Speaker].self, from: data)
    }
  )

  static func loadDataFromBundle(fileName: String) throws -> Data {
    guard let filePath = Bundle.module.path(forResource: fileName, ofType: "json") else {
      throw DataClientError.resourceNotFound(fileName)
    }
    let fileURL = URL(fileURLWithPath: filePath)
    return try Data(contentsOf: fileURL)
  }
}

let jsonDecoder = {
  $0.dateDecodingStrategy = .iso8601
  $0.keyDecodingStrategy = .convertFromSnakeCase
  return $0
}(JSONDecoder())
