import Foundation

/// Data Transfer Object for User profile
public struct UserDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let githubID: Int
  public let username: String
  public let role: UserRole
  /// User's display name
  public let displayName: String?
  /// User's email address
  public let email: String?
  /// User's bio/self-introduction
  public let bio: String?
  /// User's personal/portfolio URL
  public let url: String?
  /// User's organization/company
  public let organization: String?
  /// User's avatar/icon URL (from GitHub or custom)
  public let avatarURL: String?

  public let createdAt: Date?
  public let updatedAt: Date?

  public init(
    id: UUID,
    githubID: Int,
    username: String,
    role: UserRole,
    displayName: String? = nil,
    email: String? = nil,
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
    self.email = email
    self.bio = bio
    self.url = url
    self.organization = organization
    self.avatarURL = avatarURL
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

/// Request object for updating user profile
public struct UpdateUserProfileRequest: Codable, Sendable {
  public let displayName: String?
  public let email: String?
  public let bio: String?
  public let url: String?
  public let organization: String?
  public let avatarURL: String?

  public init(
    displayName: String? = nil,
    email: String? = nil,
    bio: String? = nil,
    url: String? = nil,
    organization: String? = nil,
    avatarURL: String? = nil
  ) {
    self.displayName = displayName
    self.email = email
    self.bio = bio
    self.url = url
    self.organization = organization
    self.avatarURL = avatarURL
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
