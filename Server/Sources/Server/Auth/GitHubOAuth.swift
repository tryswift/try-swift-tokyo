import Vapor

/// GitHub OAuth configuration and API client
struct GitHubOAuth {
  /// GitHub OAuth configuration from environment
  struct Config {
    let clientID: String
    let clientSecret: String
    let organizationName: String
    let teamSlug: String

    init() throws {
      guard let clientID = Environment.get("GITHUB_CLIENT_ID") else {
        throw Abort(.internalServerError, reason: "GITHUB_CLIENT_ID not configured")
      }
      guard let clientSecret = Environment.get("GITHUB_CLIENT_SECRET") else {
        throw Abort(.internalServerError, reason: "GITHUB_CLIENT_SECRET not configured")
      }
      self.clientID = clientID
      self.clientSecret = clientSecret
      self.organizationName = Environment.get("GITHUB_ORG_NAME") ?? "tryswift"
      self.teamSlug = Environment.get("GITHUB_TEAM_SLUG") ?? "tokyo"
    }
  }

  /// GitHub access token response
  struct AccessTokenResponse: Content {
    let accessToken: String
    let tokenType: String
    let scope: String

    enum CodingKeys: String, CodingKey {
      case accessToken = "access_token"
      case tokenType = "token_type"
      case scope
    }
  }

  /// GitHub user response
  struct GitHubUser: Content {
    let id: Int
    let login: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
      case id
      case login
      case avatarUrl = "avatar_url"
    }
  }

  /// GitHub error response from OAuth
  struct GitHubErrorResponse: Content {
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
      case error
      case errorDescription = "error_description"
    }
  }

  /// Exchange authorization code for access token
  static func exchangeCodeForToken(
    code: String,
    config: Config,
    client: Client
  ) async throws -> String {
    let response = try await client.post("https://github.com/login/oauth/access_token") { req in
      try req.content.encode([
        "client_id": config.clientID,
        "client_secret": config.clientSecret,
        "code": code
      ])
      req.headers.add(name: .accept, value: "application/json")
    }

    // Check for error response
    if let errorResponse = try? response.content.decode(GitHubErrorResponse.self),
       let error = errorResponse.error {
      throw Abort(.badRequest, reason: "GitHub OAuth error: \(error) - \(errorResponse.errorDescription ?? "no description")")
    }

    let tokenResponse = try response.content.decode(AccessTokenResponse.self)

    if tokenResponse.accessToken.isEmpty {
      throw Abort(.internalServerError, reason: "Received empty access token from GitHub")
    }

    return tokenResponse.accessToken
  }

  /// Get authenticated user info from GitHub
  static func getUser(accessToken: String, client: Client) async throws -> GitHubUser {
    let response = try await client.get("https://api.github.com/user") { req in
      req.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
      req.headers.add(name: .accept, value: "application/vnd.github.v3+json")
      req.headers.add(name: "User-Agent", value: "trySwiftCfP")
    }

    return try response.content.decode(GitHubUser.self)
  }

  /// Check if user is a member of the specified team
  /// Uses: GET /orgs/{org}/teams/{team_slug}/memberships/{username}
  /// Returns 200 with state="active" if member, 404 if not
  static func isTeamMember(
    accessToken: String,
    username: String,
    organization: String,
    teamSlug: String,
    client: Client
  ) async throws -> Bool {
    // Check team membership using the authenticated user's token
    // Requires read:org scope
    let response = try await client.get(
      "https://api.github.com/orgs/\(organization)/teams/\(teamSlug)/memberships/\(username)"
    ) { req in
      req.headers.bearerAuthorization = BearerAuthorization(token: accessToken)
      req.headers.add(name: .accept, value: "application/vnd.github.v3+json")
      req.headers.add(name: "User-Agent", value: "trySwiftCfP")
    }

    // 200 = membership found, check if active
    guard response.status == .ok else {
      return false
    }

    // Decode membership response to check state
    struct TeamMembership: Content {
      let state: String
      let role: String
    }

    do {
      let membership = try response.content.decode(TeamMembership.self)
      return membership.state == "active"
    } catch {
      return false
    }
  }
}
