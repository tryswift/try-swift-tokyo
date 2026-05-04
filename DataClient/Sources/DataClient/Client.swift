import Foundation
import SharedModels

#if !SKIP
  import Dependencies
  import DependenciesMacros
#endif

public enum DataClientError: Error, Equatable {
  case resourceNotFound(String)
}

#if !SKIP
  @DependencyClient
  public struct DataClient: Sendable {
    public var fetchDay1: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchDay2: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchDay3: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchWorkshop: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchSponsors: @Sendable (_ year: ConferenceYear) throws -> Sponsors
    public var fetchOrganizers: @Sendable (_ year: ConferenceYear) throws -> [Organizer]
    public var fetchSpeakers: @Sendable (_ year: ConferenceYear) throws -> [Speaker]
    public var fetchVideos: @Sendable (_ year: ConferenceYear) throws -> [VideoMetadata]
  }

  extension DataClient: DependencyKey {
    static public let liveValue: DataClient = .live
  }
#else
  public struct DataClient: Sendable {
    public var fetchDay1: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchDay2: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchDay3: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchWorkshop: @Sendable (_ year: ConferenceYear) throws -> Conference
    public var fetchSponsors: @Sendable (_ year: ConferenceYear) throws -> Sponsors
    public var fetchOrganizers: @Sendable (_ year: ConferenceYear) throws -> [Organizer]
    public var fetchSpeakers: @Sendable (_ year: ConferenceYear) throws -> [Speaker]
    public var fetchVideos: @Sendable (_ year: ConferenceYear) throws -> [VideoMetadata]

    public init(
      fetchDay1: @escaping @Sendable (_ year: ConferenceYear) throws -> Conference,
      fetchDay2: @escaping @Sendable (_ year: ConferenceYear) throws -> Conference,
      fetchDay3: @escaping @Sendable (_ year: ConferenceYear) throws -> Conference,
      fetchWorkshop: @escaping @Sendable (_ year: ConferenceYear) throws -> Conference,
      fetchSponsors: @escaping @Sendable (_ year: ConferenceYear) throws -> Sponsors,
      fetchOrganizers: @escaping @Sendable (_ year: ConferenceYear) throws -> [Organizer],
      fetchSpeakers: @escaping @Sendable (_ year: ConferenceYear) throws -> [Speaker],
      fetchVideos: @escaping @Sendable (_ year: ConferenceYear) throws -> [VideoMetadata]
    ) {
      self.fetchDay1 = fetchDay1
      self.fetchDay2 = fetchDay2
      self.fetchDay3 = fetchDay3
      self.fetchWorkshop = fetchWorkshop
      self.fetchSponsors = fetchSponsors
      self.fetchOrganizers = fetchOrganizers
      self.fetchSpeakers = fetchSpeakers
      self.fetchVideos = fetchVideos
    }
  }
#endif

extension DataClient {
  public static let live = DataClient(
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
    },
    fetchVideos: { year in
      let data = try loadDataFromBundle(fileName: "\(year.rawValue)-videos")
      return try jsonDecoder.decode([VideoMetadata].self, from: data)
    }
  )
}

func loadDataFromBundle(fileName: String) throws -> Data {
  guard let filePath = Bundle.module.path(forResource: fileName, ofType: "json") else {
    throw DataClientError.resourceNotFound(fileName)
  }
  let fileURL = URL(fileURLWithPath: filePath)
  return try Data(contentsOf: fileURL)
}

let jsonDecoder: JSONDecoder = {
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
  decoder.keyDecodingStrategy = JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase
  return decoder
}()
