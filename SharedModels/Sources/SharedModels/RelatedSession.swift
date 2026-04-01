import Foundation

public struct RelatedSession: Equatable, Hashable, Identifiable, Sendable {
  public var id: String { "\(year.rawValue)-\(session.title)-\(speakerName ?? "")" }
  public var year: ConferenceYear
  public var session: Session
  public var speakerImageName: String?
  public var speakerName: String?
  public var isSameSpeaker: Bool

  public init(
    year: ConferenceYear,
    session: Session,
    speakerImageName: String? = nil,
    speakerName: String? = nil,
    isSameSpeaker: Bool
  ) {
    self.year = year
    self.session = session
    self.speakerImageName = speakerImageName
    self.speakerName = speakerName
    self.isSameSpeaker = isSameSpeaker
  }
}
