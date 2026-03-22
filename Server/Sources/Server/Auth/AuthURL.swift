import Vapor

/// Builds auth URLs that work across subdomains.
///
/// In production, `AUTH_BASE_URL` points to `https://auth.tryswift.jp`
/// and `FRONTEND_URL` is set to each app's own origin (e.g. `https://student.tryswift.jp`).
/// In local dev, both are empty so links remain relative.
enum AuthURL: Sendable {
  /// Base URL for auth service (e.g. "https://auth.tryswift.jp", empty for local dev)
  static let base: String = Environment.get("AUTH_BASE_URL") ?? ""
  /// This app's base URL (e.g. "https://student.tryswift.jp", empty for local dev)
  private static let frontendBase: String = Environment.get("FRONTEND_URL") ?? ""

  /// Build a GitHub login URL with `returnTo` pointing back to this app.
  static func login(returnTo path: String) -> String {
    let returnTo = frontendBase.isEmpty ? path : "\(frontendBase)\(path)"
    return "\(base)/api/v1/auth/github?returnTo=\(returnTo)"
  }
}
