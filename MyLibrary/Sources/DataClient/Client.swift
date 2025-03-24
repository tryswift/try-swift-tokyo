import Dependencies
import DependenciesMacros
import Foundation
import SharedModels

@DependencyClient
public struct DataClient: Sendable {
  public var fetchDay1: @Sendable () async throws -> Conference
  public var fetchDay2: @Sendable () async throws -> Conference
  public var fetchWorkshop: @Sendable () async throws -> Conference
  public var fetchSponsors: @Sendable () async throws -> Sponsors
  public var fetchOrganizers: @Sendable () async throws -> [Organizer]
  public var fetchSpeakers: @Sendable () async throws -> [Speaker]
}

extension DataClient: DependencyKey {

  static public let liveValue: DataClient = .init(
    fetchDay1: {
      let data = loadDataFromBundle(fileName: "day1")
      let response = try jsonDecoder.decode(Conference.self, from: data)
      return response
    },
    fetchDay2: {
      let data = loadDataFromBundle(fileName: "day2")
      let response = try jsonDecoder.decode(Conference.self, from: data)
      return response
    },
    fetchWorkshop: {
      let data = loadDataFromBundle(fileName: "workshop")
      let response = try jsonDecoder.decode(Conference.self, from: data)
      return response
    },
    fetchSponsors: {
      let data = loadDataFromBundle(fileName: "sponsors")
      let response = try jsonDecoder.decode(Sponsors.self, from: data)
      return response
    },
    fetchOrganizers: {
      let data = loadDataFromBundle(fileName: "organizers")
      let response = try jsonDecoder.decode([Organizer].self, from: data)
      return response
    },
    fetchSpeakers: {
      let data = loadDataFromBundle(fileName: "speakers")
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
