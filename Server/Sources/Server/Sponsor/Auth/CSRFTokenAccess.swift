import Vapor

extension Request {
  /// Current CSRF token from the `csrf_token` cookie.
  /// `CSRFMiddleware` ensures this is populated on GET responses; pages embed it
  /// in form `_csrf` fields so the middleware can validate POSTs.
  var csrfToken: String {
    cookies["csrf_token"]?.string ?? ""
  }
}
