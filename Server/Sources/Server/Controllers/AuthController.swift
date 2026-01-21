import Vapor
import Fluent
import JWT
import SharedModels

/// Vapor Content wrapper for AuthResponse
struct AuthResponseContent: Content {
  let token: String
  let user: UserDTOContent
  
  init(from response: AuthResponse) {
    self.token = response.token
    self.user = UserDTOContent(from: response.user)
  }
}

/// Vapor Content wrapper for UserDTO
struct UserDTOContent: Content {
  let id: UUID
  let githubID: Int
  let username: String
  let role: String
  let displayName: String?
  let bio: String?
  let url: String?
  let organization: String?
  let avatarURL: String?
  let createdAt: Date?
  let updatedAt: Date?
  
  init(from dto: UserDTO) {
    self.id = dto.id
    self.githubID = dto.githubID
    self.username = dto.username
    self.role = dto.role.rawValue
    self.displayName = dto.displayName
    self.bio = dto.bio
    self.url = dto.url
    self.organization = dto.organization
    self.avatarURL = dto.avatarURL
    self.createdAt = dto.createdAt
    self.updatedAt = dto.updatedAt
  }
}

/// Vapor Content wrapper for UpdateUserProfileRequest
struct UpdateUserProfileRequestContent: Content {
  let displayName: String?
  let bio: String?
  let url: String?
  let organization: String?
  let avatarURL: String?
}

/// Controller for authentication endpoints
struct AuthController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let auth = routes.grouped("auth")
    auth.get("github", use: githubLogin)
    auth.get("github", "callback", use: githubCallback)
    
    let authenticated = auth.grouped(AuthMiddleware())
    authenticated.get("me", use: getCurrentUser)
    authenticated.put("me", use: updateProfile)
  }
  
  /// Redirect to GitHub OAuth login page
  @Sendable
  func githubLogin(req: Request) async throws -> Response {
    let config = try GitHubOAuth.Config()
    let callbackURL = Environment.get("GITHUB_CALLBACK_URL") ?? "http://localhost:8080/auth/github/callback"
    
    let githubAuthURL = "https://github.com/login/oauth/authorize"
    let scope = "read:org"
    let url = "\(githubAuthURL)?client_id=\(config.clientID)&redirect_uri=\(callbackURL)&scope=\(scope)"
    
    return req.redirect(to: url)
  }
  
  /// Handle GitHub OAuth callback
  @Sendable
  func githubCallback(req: Request) async throws -> AuthResponseContent {
    // Get authorization code from query params
    guard let code = req.query[String.self, at: "code"] else {
      throw Abort(.badRequest, reason: "Missing authorization code")
    }
    
    let config = try GitHubOAuth.Config()
    
    // Exchange code for access token
    let accessToken = try await GitHubOAuth.exchangeCodeForToken(
      code: code,
      config: config,
      client: req.client
    )
    
    // Get user info from GitHub
    let githubUser = try await GitHubOAuth.getUser(
      accessToken: accessToken,
      client: req.client
    )
    
    // Check if user is a member of the tryswift/tokyo team
    let isTeamMember = try await GitHubOAuth.isTeamMember(
      accessToken: accessToken,
      username: githubUser.login,
      organization: config.organizationName,
      teamSlug: config.teamSlug,
      client: req.client
    )
    
    // Determine user role based on team membership
    let role: UserRole = isTeamMember ? .admin : .speaker
    
    // Find or create user
    let user: User
    if let existingUser = try await User.query(on: req.db)
      .filter(\.$githubID == githubUser.id)
      .first() {
      // Update existing user
      existingUser.username = githubUser.login
      existingUser.role = role
      existingUser.avatarURL = githubUser.avatarUrl
      try await existingUser.save(on: req.db)
      user = existingUser
    } else {
      // Create new user
      user = User(
        githubID: githubUser.id,
        username: githubUser.login,
        role: role,
        avatarURL: githubUser.avatarUrl
      )
      try await user.save(on: req.db)
    }
    
    // Generate JWT token
    guard let userID = user.id else {
      throw Abort(.internalServerError, reason: "User ID is missing")
    }
    
    let payload = UserJWTPayload(
      userID: userID,
      role: user.role,
      username: user.username
    )
    
    let token = try await req.jwt.sign(payload)
    let userDTO = try user.toDTO()
    
    return AuthResponseContent(from: AuthResponse(token: token, user: userDTO))
  }
  
  /// Get current authenticated user
  @Sendable
  func getCurrentUser(req: Request) async throws -> UserDTOContent {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)
    
    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }
    
    guard let user = try await User.find(userID, on: req.db) else {
      throw Abort(.notFound, reason: "User not found")
    }
    
    return UserDTOContent(from: try user.toDTO())
  }
  
  /// Update current user's profile
  /// PUT /auth/me
  @Sendable
  func updateProfile(req: Request) async throws -> UserDTOContent {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)
    
    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }
    
    guard let user = try await User.find(userID, on: req.db) else {
      throw Abort(.notFound, reason: "User not found")
    }
    
    let request = try req.content.decode(UpdateUserProfileRequestContent.self)
    
    // Update user profile fields
    if let displayName = request.displayName {
      user.displayName = displayName
    }
    if let bio = request.bio {
      user.bio = bio
    }
    if let url = request.url {
      user.url = url
    }
    if let organization = request.organization {
      user.organization = organization
    }
    if let avatarURL = request.avatarURL {
      user.avatarURL = avatarURL
    }
    
    try await user.save(on: req.db)
    
    return UserDTOContent(from: try user.toDTO())
  }
}
