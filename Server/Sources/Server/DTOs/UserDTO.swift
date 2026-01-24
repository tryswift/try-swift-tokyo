import Foundation
import SharedModels

/// Data Transfer Object for User profile (Server-side copy)
/// This mirrors the SharedModels.UserDTO for API responses
public struct UserDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let githubID: Int
  public let username: String
  public let role: UserRole
  public let displayName: String?
  public let bio: String?
  public let url: String?
  public let organization: String?
  public let avatarURL: String?
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    githubID: Int,
    username: String,
    role: UserRole,
    displayName: String? = nil,
    bio: String? = nil,
    url: String? = nil,
    organization: String? = nil,
    avatarURL: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
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
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// Auth response containing JWT token and user info
public struct AuthResponse: Codable, Sendable {
  public let token: String
  public let user: UserDTO

  public init(token: String, user: UserDTO) {
    self.token = token
    self.user = user
  }
}
