import Vapor

/// GitHub OAuth helper for token exchange and user fetching
enum GitHubOAuth {

  /// OAuth configuration from environment variables
  struct Config {
    let clientID: String
    let clientSecret: String
    let organizationName: String
    let teamSlug: String

    init() throws {
      guard let clientID = Environment.get("GITHUB_CLIENT_ID") else {
        throw ConfigError.missingClientID
      }
      guard let clientSecret = Environment.get("GITHUB_CLIENT_SECRET") else {
        throw ConfigError.missingClientSecret
      }

      self.clientID = clientID
      self.clientSecret = clientSecret
      self.organizationName = Environment.get("GITHUB_ORG") ?? "tryswift"
      self.teamSlug = Environment.get("GITHUB_TEAM") ?? "tokyo"
    }

    enum ConfigError: Error, CustomStringConvertible {
      case missingClientID
      case missingClientSecret

      var description: String {
        switch self {
        case .missingClientID:
          return "GITHUB_CLIENT_ID environment variable is not set"
        case .missingClientSecret:
          return "GITHUB_CLIENT_SECRET environment variable is not set"
        }
      }
    }
  }

  /// GitHub user response
  struct GitHubUser: Content {
    let id: Int
    let login: String
    let avatarUrl: String?
    let name: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
      case id, login, name, email
      case avatarUrl = "avatar_url"
    }
  }

  /// Token exchange request body
  private struct TokenRequest: Content {
    let client_id: String
    let client_secret: String
    let code: String
    let redirect_uri: String
  }

  /// Token exchange response
  private struct TokenResponse: Content {
    let access_token: String?
    let token_type: String?
    let scope: String?
    let error: String?
    let error_description: String?
  }

  /// Exchange authorization code for access token
  /// - Parameters:
  ///   - code: The authorization code from GitHub callback
  ///   - config:  OAuth configuration
  ///   - redirectURI: The redirect URI (must match the one used in authorization)
  ///   - client: HTTP client
  /// - Returns: Access token string
  static func exchangeCodeForToken(
    code: String,
    config: Config,
    redirectURI: String,
    client: Client
  ) async throws -> String {

    let response = try await client.post("https://github.com/login/oauth/access_token") { req in
      req.headers.add(name: .accept, value: "application/json")
      req.headers.add(name: .contentType, value: "application/json")

      try req.content.encode(
        TokenRequest(
          client_id: config.clientID,
          client_secret: config.clientSecret,
          code: code,
          redirect_uri: redirectURI
        ))
    }

    guard response.status == .ok else {
      let body = response.body.map { String(buffer: $0) } ?? "empty"
      throw TokenError.httpError(status: response.status, body: body)
    }

    let tokenResponse = try response.content.decode(TokenResponse.self)

    // GitHub returns 200 even for errors, check the response body
    if let error = tokenResponse.error {
      let description = tokenResponse.error_description ?? "No description"
      throw TokenError.githubError(error: error, description: description)
    }

    guard let accessToken = tokenResponse.access_token else {
      throw TokenError.missingToken
    }

    return accessToken
  }

  /// Fetch GitHub user profile
  static func getUser(accessToken: String, client: Client) async throws -> GitHubUser {
    let response = try await client.get("https://api.github.com/user") { req in
      req.headers.add(name: .authorization, value: "Bearer \(accessToken)")
      req.headers.add(name: .accept, value: "application/vnd.github+json")
      req.headers.add(name: "X-GitHub-Api-Version", value: "2022-11-28")
      req.headers.add(name: .userAgent, value: "try-swift-tokyo-cfp")
    }

    guard response.status == .ok else {
      let body = response.body.map { String(buffer: $0) } ?? "empty"
      throw UserError.httpError(status: response.status, body: body)
    }

    return try response.content.decode(GitHubUser.self)
  }

  /// Check if user is a member of a specific team
  static func isTeamMember(
    accessToken: String,
    username: String,
    organization: String,
    teamSlug: String,
    client: Client
  ) async throws -> Bool {
    let url =
      "https://api.github.com/orgs/\(organization)/teams/\(teamSlug)/memberships/\(username)"

    let response = try await client.get(URI(string: url)) { req in
      req.headers.add(name: .authorization, value: "Bearer \(accessToken)")
      req.headers.add(name: .accept, value: "application/vnd.github+json")
      req.headers.add(name: "X-GitHub-Api-Version", value: "2022-11-28")
      req.headers.add(name: .userAgent, value: "try-swift-tokyo-cfp")
    }

    // 200 = member, 404 = not a member
    return response.status == .ok
  }

  // MARK: - Errors

  enum TokenError: Error, CustomStringConvertible {
    case httpError(status: HTTPStatus, body: String)
    case githubError(error: String, description: String)
    case missingToken

    var description: String {
      switch self {
      case .httpError(let status, let body):
        return "HTTP \(status.code): \(body)"
      case .githubError(let error, let description):
        return "GitHub error '\(error)': \(description)"
      case .missingToken:
        return "No access_token in response"
      }
    }
  }

  enum UserError: Error, CustomStringConvertible {
    case httpError(status: HTTPStatus, body: String)

    var description: String {
      switch self {
      case .httpError(let status, let body):
        return "HTTP \(status.code): \(body)"
      }
    }
  }
}
