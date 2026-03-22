import Foundation
import NIOCore
import PostgresNIO
import SharedModels
import Testing

@testable import Server

@Suite("CoInstructorList Postgres Encoding Tests")
struct CoInstructorListPostgresTests {

  @Test("psqlType is .jsonb, not .jsonbArray")
  func psqlTypeIsJSONB() {
    #expect(CoInstructorList.psqlType == .jsonb)
    #expect(CoInstructorList.psqlFormat == .binary)
  }

  @Test("Encode/decode round-trip via PostgresEncodable/PostgresDecodable")
  func postgresRoundTrip() throws {
    let list = CoInstructorList([
      CoInstructor(
        name: "Test User",
        email: "test@example.com",
        githubUsername: "testuser",
        bio: "A test instructor"
      ),
    ])

    // Encode via PostgresEncodable
    var buffer = ByteBuffer()
    let context = PostgresEncodingContext.default
    try list.encode(into: &buffer, context: context)

    // First byte should be JSONB version byte (0x01)
    #expect(buffer.getInteger(at: 0, as: UInt8.self) == 0x01)

    // Decode via PostgresDecodable
    let decodingContext = PostgresDecodingContext.default
    let decoded = try CoInstructorList(
      from: &buffer, type: .jsonb, format: .binary, context: decodingContext
    )
    #expect(decoded == list)
  }
}
