import JWT
import SharedModels
import Vapor

extension Request {
  /// Get authenticated user from cookie or authorization header
  func authenticatedUser() async throws -> UserDTO? {
    let token: String?
    if let cookieToken = cookies["cfp_token"]?.string, !cookieToken.isEmpty {
      token = cookieToken
    } else if let authHeader = headers.bearerAuthorization?.token {
      token = authHeader
    } else {
      return nil
    }

    guard let token else { return nil }

    let payload = try await jwt.verify(token, as: UserJWTPayload.self)
    guard let userID = payload.userID else { return nil }
    guard let user = try await User.find(userID, on: db) else { return nil }

    return try user.toDTO()
  }

  /// Get CSRF token from cookie
  var csrfToken: String {
    cookies["csrf_token"]?.string ?? ""
  }
}
