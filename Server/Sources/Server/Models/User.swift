import Fluent
import Vapor
import SharedModels

/// User model for CfP system
/// Stores GitHub authentication data and role information
final class User: Model, Content, @unchecked Sendable {
  static let schema = "users"
  
  @ID(key: .id)
  var id: UUID?
  
  /// GitHub user ID (unique identifier from GitHub)
  @Field(key: "github_id")
  var githubID: Int
  
  /// GitHub username
  @Field(key: "username")
  var username: String
  
  /// User role (admin/speaker)
  @Field(key: "role")
  var role: UserRole
  
  /// User's display name
  @OptionalField(key: "display_name")
  var displayName: String?
  
  /// User's bio/self-introduction
  @OptionalField(key: "bio")
  var bio: String?
  
  /// User's personal/portfolio URL
  @OptionalField(key: "url")
  var url: String?
  
  /// User's organization/company
  @OptionalField(key: "organization")
  var organization: String?
  
  /// GitHub avatar URL
  @OptionalField(key: "avatar_url")
  var avatarURL: String?
  
  /// Timestamps
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?
  
  /// User's proposals
  @Children(for: \.$speaker)
  var proposals: [Proposal]
  
  init() {}
  
  init(
    id: UUID? = nil,
    githubID: Int,
    username: String,
    role: UserRole,
    displayName: String? = nil,
    bio: String? = nil,
    url: String? = nil,
    organization: String? = nil,
    avatarURL: String? = nil
  ) {
    self.id = id
    self.githubID = githubID
    self.username = username
    self.role = role
    self.displayName = displayName
    self.bio = bio
    self.url = url
    self.organization = organization
    self.avatarURL = avatarURL
  }
  
  /// Convert to DTO for API responses
  func toDTO() throws -> UserDTO {
    guard let id = id else {
      throw Abort(.internalServerError, reason: "User ID is missing")
    }
    return UserDTO(
      id: id,
      githubID: githubID,
      username: username,
      role: role,
      displayName: displayName,
      bio: bio,
      url: url,
      organization: organization,
      avatarURL: avatarURL,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
