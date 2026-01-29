import Fluent
import SharedModels

/// Migration to create a system user for PaperCall imports
/// This user is used as the speaker_id for proposals imported from PaperCall.io
/// since those proposals don't have associated GitHub accounts
struct AddPaperCallImportUser: AsyncMigration {
  /// Fixed UUID for the PaperCall import system user
  static let paperCallUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

  func prepare(on database: Database) async throws {
    let user = User(
      id: Self.paperCallUserID,
      githubID: 0,
      username: "papercall-import",
      role: .speaker,
      displayName: "PaperCall Import",
      email: nil,
      bio: "System user for PaperCall imported proposals"
    )
    try await user.save(on: database)
  }

  func revert(on database: Database) async throws {
    try await User.query(on: database)
      .filter(\.$id == Self.paperCallUserID)
      .delete()
  }
}
