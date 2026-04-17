import Fluent
import JWT
import SharedModels
import Vapor

extension Request {
  private func authenticatedToken() -> String? {
    if let cookieToken = cookies["auth_token"]?.string, !cookieToken.isEmpty {
      return cookieToken
    }
    if let authHeader = headers.bearerAuthorization?.token, !authHeader.isEmpty {
      return authHeader
    }
    return nil
  }

  /// Try to authenticate the current user payload from cookie or bearer token.
  func authenticatedUserPayload() async throws -> UserJWTPayload? {
    if let existing = auth.get(UserJWTPayload.self) {
      return existing
    }

    guard let token = authenticatedToken() else {
      return nil
    }

    let payload = try await jwt.verify(token, as: UserJWTPayload.self)
    auth.login(payload)
    return payload
  }

  /// Require an authenticated user payload from cookie or bearer token.
  func requireAuthenticatedUserPayload() async throws -> UserJWTPayload {
    guard let payload = try await authenticatedUserPayload() else {
      throw Abort(.unauthorized, reason: "Authentication required")
    }
    return payload
  }

  /// Try to authenticate the current user from cookie or bearer token
  func authenticatedUser() async throws -> UserDTO? {
    guard let payload = try await authenticatedUserPayload() else {
      return nil
    }
    guard let userID = payload.userID else { return nil }
    guard let user = try await User.find(userID, on: db) else { return nil }
    return try user.toDTO()
  }
}
