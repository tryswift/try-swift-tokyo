import Fluent
import Foundation

/// Seeds the try! Swift Tokyo 2026 conference with CfP open
struct SeedTrySwiftTokyo2026: AsyncMigration {
  func prepare(on database: Database) async throws {
    // Check if the conference already exists
    let existingConference = try await Conference.query(on: database)
      .filter(\.$path == "tryswift-tokyo-2026")
      .first()

    if existingConference != nil {
      // Conference already exists, skip seeding
      return
    }

    let conference = Conference(
      path: "tryswift-tokyo-2026",
      displayName: "try! Swift Tokyo 2026",
      descriptionEn: """
        ## Talk Guidelines

        - All talks will be held in a **single track**. It is a requirement for adoption to be able to finish speaking within each talk's time limit.
        - All talks include **AI-powered multilingual simultaneous interpretation**.
        - Many people from all over the world come to Japan to participate in this community. Participants prefer **specialized technical talks**.
        - Non-technical talks and emotional talks also have room for adoption, but it is preferable that everyone who comes to the conference can enjoy it.
        - **Introductory content** or content specialized in specific situations is difficult to adopt.
          - Example: General architecture and accessibility adopted by the product will not be adopted unless your expertise is recognized.
        - If you are basing on past appearances, please make all or part of this conference **new content**.
        """,
      descriptionJa: """
        ## トークガイドライン

        - すべてのトークは**シングルトラック**で実施します。各講演の規定時間以内で話し切れることが採用条件です。
        - すべてのトークに**AIによる多言語同時通訳**が付きます。
        - 世界各地から参加者が来日します。参加者は**専門性の高い技術トーク**を好みます。
        - 技術的ではないものやエモーショナルなトークにも採用の余地はありますが、来場者全員が楽しめる内容が望ましいです。
        - **入門的な内容**や、特定の状況に特化した内容は採用が難しい傾向です。
          - 例：製品で採用している一般的なアーキテクチャやアクセシビリティは、あなたの専門性が認められない限り採用されません。
        - 過去の登壇を基にする場合は、全体または一部を**新規の内容**にしてください。
        """,
      year: 2026,
      isOpen: true,
      deadline: ISO8601DateFormatter().date(from: "2026-02-01T23:59:59Z"),
      startDate: ISO8601DateFormatter().date(from: "2026-04-12T00:00:00+09:00"),
      endDate: ISO8601DateFormatter().date(from: "2026-04-14T23:59:59+09:00"),
      location: "Tokyo, Japan",
      websiteURL: "https://tryswift.jp"
    )

    try await conference.save(on: database)
  }

  func revert(on database: Database) async throws {
    try await Conference.query(on: database)
      .filter(\.$path == "tryswift-tokyo-2026")
      .delete()
  }
}
