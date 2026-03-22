import Foundation

public struct VideoMetadata: Codable, Equatable, Hashable, Sendable {
  public var sessionTitle: String
  public var youtubeVideoId: String
  public var duration: TimeInterval?
  public var chapters: [Chapter]?
  public var transcript: [TranscriptEntry]?
  public var resources: [VideoResource]?
  public var summary: String?
  public var codeResources: [CodeResource]?

  public init(
    sessionTitle: String,
    youtubeVideoId: String,
    duration: TimeInterval? = nil,
    chapters: [Chapter]? = nil,
    transcript: [TranscriptEntry]? = nil,
    resources: [VideoResource]? = nil,
    summary: String? = nil,
    codeResources: [CodeResource]? = nil
  ) {
    self.sessionTitle = sessionTitle
    self.youtubeVideoId = youtubeVideoId
    self.duration = duration
    self.chapters = chapters
    self.transcript = transcript
    self.resources = resources
    self.summary = summary
    self.codeResources = codeResources
  }
}

public struct Chapter: Codable, Equatable, Hashable, Sendable {
  public var title: String
  public var startTime: TimeInterval

  public init(title: String, startTime: TimeInterval) {
    self.title = title
    self.startTime = startTime
  }
}

public struct TranscriptEntry: Codable, Equatable, Hashable, Sendable, Identifiable {
  public var id: Int
  public var startTime: TimeInterval
  public var endTime: TimeInterval
  public var text: String

  public init(id: Int, startTime: TimeInterval, endTime: TimeInterval, text: String) {
    self.id = id
    self.startTime = startTime
    self.endTime = endTime
    self.text = text
  }
}

public struct VideoResource: Codable, Equatable, Hashable, Sendable {
  public var title: String
  public var url: URL

  public init(title: String, url: URL) {
    self.title = title
    self.url = url
  }
}

public struct CodeResource: Codable, Equatable, Hashable, Sendable {
  public var title: String
  public var url: URL
  public var kind: Kind?

  public enum Kind: String, Codable, Equatable, Hashable, Sendable {
    case github
    case gist
    case playground
    case other
  }

  public init(title: String, url: URL, kind: Kind? = nil) {
    self.title = title
    self.url = url
    self.kind = kind
  }
}
