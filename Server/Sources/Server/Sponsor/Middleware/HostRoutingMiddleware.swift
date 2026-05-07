import Vapor

struct HostRoutingMiddleware: AsyncMiddleware {
  let sponsorHost: String

  init(sponsorHost: String? = nil) {
    self.sponsorHost =
      sponsorHost
      ?? Environment.get("SPONSOR_HOST")
      ?? "sponsor.tryswift.jp"
  }

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    if let host = request.headers.first(name: .host)?.lowercased() {
      let bareHost = host.split(separator: ":").first.map(String.init) ?? host
      if bareHost == sponsorHost.lowercased() {
        request.storage[SponsorHostStorageKey.self] = true
      }
    }
    return try await next.respond(to: request)
  }
}

private struct SponsorHostStorageKey: StorageKey { typealias Value = Bool }

extension Request {
  var isSponsorHost: Bool { storage[SponsorHostStorageKey.self] == true }
}
