import Foundation

/// Localized string supporting multiple languages
public struct LocalizedString: Codable, Sendable, Equatable {
  public let en: String
  public let ja: String

  public init(en: String, ja: String) {
    self.en = en
    self.ja = ja
  }

  /// Get localized string for the given locale
  public func localized(for locale: String = "en") -> String {
    locale.starts(with: "ja") ? ja : en
  }
}

/// Data Transfer Object for Conference
/// Represents a conference event that accepts CfP submissions
public struct ConferenceDTO: Codable, Sendable, Equatable, Identifiable {
  /// Unique identifier (hash)
  public let id: UUID
  /// URL-friendly path/alias (e.g., "tryswift-tokyo-2026")
  public let path: String
  /// Human-readable display name (e.g., "try! Swift Tokyo 2026")
  public let displayName: String
  /// Conference description with guidelines (markdown, localized)
  public let description: LocalizedString?
  /// Conference year
  public let year: Int
  /// Whether CfP is currently open for this conference
  public let isOpen: Bool
  /// CfP submission deadline
  public let deadline: Date?
  /// Conference start date
  public let startDate: Date?
  /// Conference end date
  public let endDate: Date?
  /// Conference location
  public let location: String?
  /// Conference website URL
  public let websiteURL: String?

  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    path: String,
    displayName: String,
    description: LocalizedString? = nil,
    year: Int,
    isOpen: Bool = true,
    deadline: Date? = nil,
    startDate: Date? = nil,
    endDate: Date? = nil,
    location: String? = nil,
    websiteURL: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.path = path
    self.displayName = displayName
    self.description = description
    self.year = year
    self.isOpen = isOpen
    self.deadline = deadline
    self.startDate = startDate
    self.endDate = endDate
    self.location = location
    self.websiteURL = websiteURL
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// Request object for creating a new conference
public struct CreateConferenceRequest: Codable, Sendable {
  public let path: String
  public let displayName: String
  public let description: LocalizedString?
  public let year: Int
  public let isOpen: Bool
  public let deadline: Date?
  public let startDate: Date?
  public let endDate: Date?
  public let location: String?
  public let websiteURL: String?

  public init(
    path: String,
    displayName: String,
    description: LocalizedString? = nil,
    year: Int,
    isOpen: Bool = true,
    deadline: Date? = nil,
    startDate: Date? = nil,
    endDate: Date? = nil,
    location: String? = nil,
    websiteURL: String? = nil
  ) {
    self.path = path
    self.displayName = displayName
    self.description = description
    self.year = year
    self.isOpen = isOpen
    self.deadline = deadline
    self.startDate = startDate
    self.endDate = endDate
    self.location = location
    self.websiteURL = websiteURL
  }
}

/// Default conference description for try! Swift Tokyo
public enum ConferenceDescriptions {
  public static let trySwiftTokyo = LocalizedString(
    en: """
      ## Talk Guidelines

      - All talks will be held in a **single track**. It is a requirement for adoption to be able to finish speaking within each talk's time limit.
      - All talks include **AI-powered multilingual simultaneous interpretation**.
      - Many people from all over the world come to Japan to participate in this community. Participants prefer **specialized technical talks**.
      - Non-technical talks and emotional talks also have room for adoption, but it is preferable that everyone who comes to the conference can enjoy it.
      - **Introductory content** or content specialized in specific situations is difficult to adopt.
        - Example: General architecture and accessibility adopted by the product will not be adopted unless your expertise is recognized.
      - If you are basing on past appearances, please make all or part of this conference **new content**.
      """,
    ja: """
      ## トークガイドライン

      - すべてのトークは**シングルトラック**で実施します。各講演の規定時間以内で話し切れることが採用条件です。
      - すべてのトークに**AIによる多言語同時通訳**が付きます。
      - 世界各地から参加者が来日します。参加者は**専門性の高い技術トーク**を好みます。
      - 技術的ではないものやエモーショナルなトークにも採用の余地はありますが、来場者全員が楽しめる内容が望ましいです。
      - **入門的な内容**や、特定の状況に特化した内容は採用が難しい傾向です。
        - 例：製品で採用している一般的なアーキテクチャやアクセシビリティは、あなたの専門性が認められない限り採用されません。
      - 過去の登壇を基にする場合は、全体または一部を**新規の内容**にしてください。
      """
  )
}
