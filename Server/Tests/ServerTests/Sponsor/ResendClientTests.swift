import Foundation
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("ResendClient")
struct ResendClientTests {
  @Test("Skips send when RESEND_API_KEY missing in env override")
  func skipsWithoutKey() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }

    let result = await ResendClient.send(
      to: "test@example.com",
      from: "Sponsorship <sponsorship@mail.tryswift.jp>",
      subject: "hi", html: "<p>hi</p>", text: "hi",
      client: app.client, logger: app.logger,
      env: ["RESEND_API_KEY": .some("")]
    )
    #expect(result == .skipped)
  }
}
