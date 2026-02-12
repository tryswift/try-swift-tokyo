import Fluent
import JWT
import SharedModels
import Vapor

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
  let email: String?
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
    self.email = dto.email
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
  let email: String?
  let bio: String?
  let url: String?
  let organization: String?
  let avatarURL: String?
}

// MARK: - OAuth State Payload (Stateless - survives multi-instance)

/// JWT payload for OAuth state parameter - replaces in-memory session storage
struct OAuthStatePayload: JWTPayload, Equatable {
  /// Unique nonce to prevent replay attacks
  let nonce: String

  /// Expiration (short-lived:  10 minutes)
  let exp: ExpirationClaim

  /// Optional return URL after successful auth
  let returnTo: String?

  /// Issue time
  let iat: IssuedAtClaim

  init(returnTo: String? = nil, expiresIn: TimeInterval = 600) {
    self.nonce = UUID().uuidString
    self.exp = .init(value: Date().addingTimeInterval(expiresIn))
    self.returnTo = returnTo
    self.iat = .init(value: Date())
  }

  func verify(using algorithm: some JWTAlgorithm) async throws {
    try exp.verifyNotExpired()
  }
}

// MARK: - OAuth Errors (Structured + Environment-Aware)

enum OAuthError: AbortError {
  case missingState
  case invalidState(String)
  case expiredState
  case missingCode
  case tokenExchangeFailed(String)
  case userFetchFailed(String)
  case configurationError(String)

  var status: HTTPResponseStatus {
    switch self {
    case .missingState, .invalidState, .expiredState, .missingCode:
      return .badRequest
    case .tokenExchangeFailed, .userFetchFailed, .configurationError:
      return .internalServerError
    }
  }

  var reason: String {
    // In production, return safe generic messages
    let isProduction = Environment.get("APP_ENV") == "production"

    if isProduction {
      switch self {
      case .missingState, .invalidState, .expiredState:
        return "Invalid OAuth state.  Please try signing in again."
      case .missingCode:
        return "Authorization was cancelled or failed. Please try again."
      case .tokenExchangeFailed, .userFetchFailed, .configurationError:
        return "Authentication failed. Please try again later."
      }
    }

    // In development, return detailed errors
    switch self {
    case .missingState:
      return
        "Missing 'state' parameter in OAuth callback.  Ensure the OAuth flow starts from /api/v1/auth/github"
    case .invalidState(let detail):
      return "Invalid OAuth state:  \(detail)"
    case .expiredState:
      return "OAuth state expired. The sign-in link is only valid for 10 minutes."
    case .missingCode:
      return "Missing 'code' parameter in OAuth callback"
    case .tokenExchangeFailed(let detail):
      return "Failed to exchange code for token: \(detail)"
    case .userFetchFailed(let detail):
      return "Failed to fetch GitHub user: \(detail)"
    case .configurationError(let detail):
      return "OAuth configuration error: \(detail)"
    }
  }

  var identifier: String {
    switch self {
    case .missingState: return "oauth_missing_state"
    case .invalidState: return "oauth_invalid_state"
    case .expiredState: return "oauth_expired_state"
    case .missingCode: return "oauth_missing_code"
    case .tokenExchangeFailed: return "oauth_token_failed"
    case .userFetchFailed: return "oauth_user_failed"
    case .configurationError: return "oauth_config_error"
    }
  }
}

/// Controller for authentication endpoints
struct AuthController: RouteCollection {
  /// The frontend URL to redirect to after authentication
  static var frontendURL: String {
    Environment.get("FRONTEND_URL") ?? "https://cfp.tryswift.jp"
  }

  /// The callback URL for GitHub OAuth
  static var callbackURL: String {
    Environment.get("GITHUB_CALLBACK_URL")
      ?? "https://tryswift-cfp-api.fly.dev/api/v1/auth/github/callback"
  }

  func boot(routes: RoutesBuilder) throws {
    let auth = routes.grouped("auth")
    auth.get("github", use: githubLogin)
    auth.get("github", "callback", use: githubCallback)

    let authenticated = auth.grouped(AuthMiddleware())
    authenticated.get("me", use: getCurrentUser)
    authenticated.put("me", use: updateProfile)
  }

  // MARK: - GitHub OAuth Start

  /// Redirect to GitHub OAuth login page
  /// GET /api/v1/auth/github? returnTo=<optional-url>
  @Sendable
  func githubLogin(req: Request) async throws -> Response {
    let config: GitHubOAuth.Config
    do {
      config = try GitHubOAuth.Config()
    } catch {
      req.logger.error("GitHub OAuth not configured: \(error)")
      throw OAuthError.configurationError("GITHUB_CLIENT_ID or GITHUB_CLIENT_SECRET not set")
    }

    // Get optional returnTo parameter
    let returnTo = try? req.query.get(String.self, at: "returnTo")

    // Validate returnTo URL if provided (prevent open redirect)
    if let returnTo = returnTo, !isValidReturnURL(returnTo) {
      req.logger.warning("Invalid returnTo URL rejected: \(returnTo)")
      throw Abort(.badRequest, reason: "Invalid returnTo URL")
    }

    // Generate signed state token (STATELESS - survives Fly.io restarts/multi-instance!)
    let statePayload = OAuthStatePayload(returnTo: returnTo)
    let stateToken = try await req.jwt.sign(statePayload)

    req.logger.info(
      "Starting GitHub OAuth",
      metadata: [
        "returnTo": .string(returnTo ?? "default"),
        "stateNonce": .string(statePayload.nonce),
      ])

    // Build GitHub authorization URL with proper encoding
    var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
    components.queryItems = [
      URLQueryItem(name: "client_id", value: config.clientID),
      URLQueryItem(name: "redirect_uri", value: Self.callbackURL),
      URLQueryItem(name: "scope", value: "read:user read:org"),
      URLQueryItem(name: "state", value: stateToken),
    ]

    guard let authURL = components.url?.absoluteString else {
      throw OAuthError.configurationError("Failed to build authorization URL")
    }

    return req.redirect(to: authURL)
  }

  // MARK: - GitHub OAuth Callback

  /// Handle GitHub OAuth callback
  /// GET /api/v1/auth/github/callback?code=...&state=...
  @Sendable
  func githubCallback(req: Request) async throws -> Response {
    // 1. Validate state parameter exists
    guard let stateToken = req.query[String.self, at: "state"] else {
      req.logger.warning(
        "OAuth callback missing state parameter",
        metadata: [
          "query": .string(req.url.query ?? "none"),
          "referer": .string(req.headers.first(name: .referer) ?? "none"),
        ])
      throw OAuthError.missingState
    }

    // 2.Validate and decode state token
    let statePayload: OAuthStatePayload
    do {
      statePayload = try await req.jwt.verify(stateToken, as: OAuthStatePayload.self)
    } catch let error as JWTError {
      req.logger.warning("OAuth state validation failed: \(error)")
      if case .claimVerificationFailure = error.errorType {
        throw OAuthError.expiredState
      } else {
        throw OAuthError.invalidState(String(describing: error))
      }
    } catch {
      req.logger.warning("OAuth state decode failed: \(error)")
      throw OAuthError.invalidState("Could not decode state token")
    }

    req.logger.info(
      "OAuth state validated",
      metadata: [
        "nonce": .string(statePayload.nonce),
        "returnTo": .string(statePayload.returnTo ?? "default"),
      ])

    // 3. Validate authorization code exists
    guard let code = req.query[String.self, at: "code"] else {
      // Check for error from GitHub
      if let error = req.query[String.self, at: "error"] {
        let description = req.query[String.self, at: "error_description"] ?? "Unknown error"
        req.logger.warning("GitHub returned error: \(error) - \(description)")
        return req.redirect(to: "\(Self.frontendURL)/login-page?error=\(error)")
      }
      throw OAuthError.missingCode
    }

    req.logger.info("GitHub callback received with code")

    let config: GitHubOAuth.Config
    do {
      config = try GitHubOAuth.Config()
    } catch {
      req.logger.error("GitHub OAuth not configured: \(error)")
      throw OAuthError.configurationError("Missing GitHub OAuth credentials")
    }

    // 4. Exchange code for access token
    let accessToken: String
    do {
      accessToken = try await GitHubOAuth.exchangeCodeForToken(
        code: code,
        config: config,
        redirectURI: Self.callbackURL,
        client: req.client
      )
      req.logger.info("Access token obtained successfully")
    } catch {
      req.logger.error("Token exchange failed: \(error)")
      throw OAuthError.tokenExchangeFailed(String(describing: error))
    }

    // 5. Get user info from GitHub
    let githubUser: GitHubOAuth.GitHubUser
    do {
      githubUser = try await GitHubOAuth.getUser(
        accessToken: accessToken,
        client: req.client
      )
      req.logger.info("GitHub user obtained:  \(githubUser.login)")
    } catch {
      req.logger.error("Failed to get GitHub user: \(error)")
      throw OAuthError.userFetchFailed(String(describing: error))
    }

    // 6. Check if user is a member of the tryswift/tokyo team (admin)
    var isAdminTeamMember = false
    do {
      isAdminTeamMember = try await GitHubOAuth.isTeamMember(
        accessToken: accessToken,
        username: githubUser.login,
        organization: config.organizationName,
        teamSlug: config.teamSlug,
        client: req.client
      )
      req.logger.info("Admin team membership check: \(isAdminTeamMember)")
    } catch {
      req.logger.warning("Admin team membership check failed: \(error)")
    }

    // 6b. Check if user is a member of the invited speaker team
    var isInvitedSpeakerTeamMember = false
    if !isAdminTeamMember {
      do {
        isInvitedSpeakerTeamMember = try await GitHubOAuth.isTeamMember(
          accessToken: accessToken,
          username: githubUser.login,
          organization: config.organizationName,
          teamSlug: config.invitedSpeakerTeamSlug,
          client: req.client
        )
        req.logger.info("Invited speaker team membership check: \(isInvitedSpeakerTeamMember)")
      } catch {
        req.logger.warning("Invited speaker team membership check failed: \(error)")
      }
    }

    // 7. Determine user role based on team membership
    let role: UserRole
    if isAdminTeamMember {
      role = .admin
    } else if isInvitedSpeakerTeamMember {
      role = .invitedSpeaker
    } else {
      role = .speaker
    }

    // 8. Find or create user
    let user: User
    if let existingUser = try await User.query(on: req.db)
      .filter(\.$githubID == githubUser.id)
      .first()
    {
      existingUser.username = githubUser.login
      existingUser.role = role
      existingUser.avatarURL = githubUser.avatarUrl
      // Update email from GitHub if not already set
      if existingUser.email == nil, let email = githubUser.email {
        existingUser.email = email
      }
      // Update displayName from GitHub if not already set
      if existingUser.displayName == nil, let name = githubUser.name {
        existingUser.displayName = name
      }
      try await existingUser.save(on: req.db)
      user = existingUser
    } else {
      user = User(
        githubID: githubUser.id,
        username: githubUser.login,
        role: role,
        displayName: githubUser.name,
        email: githubUser.email,
        avatarURL: githubUser.avatarUrl
      )
      try await user.save(on: req.db)
      req.logger.info("Created new user: \(user.username)")
    }

    // 8b. Re-associate proposals that reference this GitHub username
    //     but are still pointing to the PaperCall import user (best-effort).
    if let userID = user.id {
      do {
        try await Proposal.query(on: req.db)
          .group(.or) { group in
            group.filter(\.$paperCallUsername == user.username)
            group.filter(\.$githubUsername == user.username)
          }
          .filter(\.$speaker.$id == AddPaperCallImportUser.paperCallUserID)
          .set(\.$speaker.$id, to: userID)
          .update()
      } catch {
        req.logger.warning(
          "Failed to re-associate proposals for user \(user.username): \(error)")
      }
    }

    // 9. Generate JWT token
    guard let userID = user.id else {
      return req.redirect(to: "\(Self.frontendURL)/login-page?error=user_creation_failed")
    }

    let payload = UserJWTPayload(
      userID: userID,
      role: user.role,
      username: user.username
    )

    let token = try await req.jwt.sign(payload)

    // 10. Set secure HTTP-only cookie and redirect to frontend
    // Use returnTo from state if provided, otherwise default to login page
    let returnTo = statePayload.returnTo ?? "/login"

    req.logger.info(
      "OAuth flow completed, redirecting",
      metadata: [
        "username": .string(user.username),
        "role": .string(role.rawValue),
        "returnTo": .string(returnTo),
      ])

    // Create response with redirect and set HTTP-only cookie
    // Since CfP pages are now served from the same Vapor server, we can set cookies directly
    let response = Response(status: .seeOther)
    response.headers.replaceOrAdd(name: .location, value: returnTo)

    // Set HTTP-only cookie for authentication
    response.cookies["cfp_token"] = HTTPCookies.Value(
      string: token,
      expires: Date().addingTimeInterval(86400 * 7),  // 7 days
      maxAge: 86400 * 7,
      path: "/",
      isSecure: Environment.get("APP_ENV") == "production",
      isHTTPOnly: true,
      sameSite: .lax
    )

    // Also set username cookie (not HTTP-only, for display purposes)
    response.cookies["cfp_username"] = HTTPCookies.Value(
      string: user.username,
      expires: Date().addingTimeInterval(86400 * 7),
      maxAge: 86400 * 7,
      path: "/",
      isSecure: Environment.get("APP_ENV") == "production",
      isHTTPOnly: false,
      sameSite: .lax
    )

    return response
  }

  // MARK:  - Helper Methods

  /// Get cookie domain based on frontend URL
  private static func getCookieDomain() -> String? {
    guard let frontendURL = URL(string: Self.frontendURL),
      let host = frontendURL.host
    else {
      return nil
    }

    // For tryswift.jp domains, use .tryswift.jp to allow subdomains
    if host.hasSuffix("tryswift.jp") {
      return ".tryswift.jp"
    }

    // For fly.dev domains, use the specific subdomain
    if host.hasSuffix(".fly.dev") {
      return host
    }

    // For localhost, don't set domain
    if host == "localhost" {
      return nil
    }

    return host
  }

  /// Validate that returnTo URL is allowed (prevent open redirect)
  private func isValidReturnURL(_ urlString: String) -> Bool {
    // Allow relative paths (same-origin redirects are safe)
    if urlString.hasPrefix("/") && !urlString.hasPrefix("//") {
      return true
    }

    guard let url = URL(string: urlString),
      let host = url.host?.lowercased()
    else {
      return false
    }

    let allowedHosts = [
      "tryswift-cfp-website.fly.dev",
      "tryswift.jp",
      "cfp.tryswift.jp",
      "localhost",
    ]

    return allowedHosts.contains { host == $0 || host.hasSuffix(".\($0)") }
  }

  // MARK: - Authenticated Endpoints

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

    if let displayName = request.displayName {
      user.displayName = displayName
    }
    if let email = request.email {
      user.email = email
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
