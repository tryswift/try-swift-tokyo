@testable import Server
import XCTVapor
import Testing

@Suite("Server Tests")
struct ServerTests {
  @Test("Health check returns OK")
  func healthCheck() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    
    try await app.test(.GET, "/") { response async in
      #expect(response.status == .ok)
    }
  }
}
