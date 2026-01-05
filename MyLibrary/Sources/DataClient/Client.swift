import Dependencies
import DependenciesMacros
import Foundation
import SharedModels

@DependencyClient
public struct DataClient: Sendable {
  public var fetchDay1: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchDay2: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchDay3: @Sendable (_ year: ConferenceYear) throws -> Conference
  public var fetchSponsors: @Sendable (_ year: ConferenceYear) throws -> Sponsors
  public var fetchOrganizers: @Sendable (_ year: ConferenceYear) throws -> [Organizer]
  public var fetchSpeakers: @Sendable (_ year: ConferenceYear) throws -> [Speaker]
}

extension DataClient: DependencyKey {
  static public let liveValue: DataClient = .init(
    fetchDay1: { year in
      let data = loadDataFromBundle(fileName: "\(year.rawValue)-day1")
      let response = try jsonDecoder.decode(Conference.self, from: data)
      return response
    },
    fetchDay2: { year in
      let data = loadDataFromBundle(fileName: "\(year.rawValue)-day2")
      let response = try jsonDecoder.decode(Conference.self, from: data)
      return response
    },
    fetchDay3: { year in
      let data = loadDataFromBundle(fileName: "\(year.rawValue)-day3")
      let response = try jsonDecoder.decode(Conference.self, from: data)
      return response
    },
    fetchSponsors: { year in
      let data = loadDataFromBundle(fileName: "\(year.rawValue)-sponsors")
      let response = try jsonDecoder.decode(Sponsors.self, from: data)
      return response
    },
    fetchOrganizers: { year in
      let data = loadDataFromBundle(fileName: "\(year.rawValue)-organizers")
      let response = try jsonDecoder.decode([Organizer].self, from: data)
      return response
    },
    fetchSpeakers: { year in
      let data = loadDataFromBundle(fileName: "\(year.rawValue)-speakers")
      let response = try jsonDecoder.decode([Speaker].self, from: data)
      return response
    }
  )

  static func loadDataFromBundle(fileName: String) -> Data {
    let filePath = Bundle.module.path(forResource: fileName, ofType: "json")!
    let fileURL = URL(fileURLWithPath: filePath)
    let data = try! Data(contentsOf: fileURL)
    return data
  }
}

let jsonDecoder = {
  $0.dateDecodingStrategy = .iso8601
  $0.keyDecodingStrategy = .convertFromSnakeCase
  return $0
}(JSONDecoder())
