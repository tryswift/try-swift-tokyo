import Testing
import Vapor
import VaporTesting

@Suite("Server Tests")
struct ServerTests {
  @Test("Health check returns OK")
  func healthCheck() async throws {
    let app = try await Application.make(.testing)
    do {
      app.get("health") { _ in ["status": "healthy"] }
      try await app.testing().test(.GET, "health") { response in
        #expect(response.status == .ok)
      }
    } catch {
      try await app.asyncShutdown()
      throw error
    }
    try await app.asyncShutdown()
  }
}
