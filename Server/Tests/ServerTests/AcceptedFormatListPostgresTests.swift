import Foundation
import NIOCore
import PostgresNIO
import SharedModels
import Testing

@testable import Server

@Suite("AcceptedFormatList Postgres Encoding Tests")
struct AcceptedFormatListPostgresTests {

  @Test("psqlType is .jsonb, not .jsonbArray")
  func psqlTypeIsJSONB() {
    // Guards the reason the wrapper exists: without the PostgresEncodable/
    // Decodable conformances, postgres-kit would encode the inner array as
    // `jsonb[]`. SQLite-backed integration tests cannot catch this.
    #expect(AcceptedFormatList.psqlType == .jsonb)
    #expect(AcceptedFormatList.psqlFormat == .binary)
  }

  @Test("Encode/decode round-trip via PostgresEncodable/PostgresDecodable")
  func postgresRoundTrip() throws {
    let list = AcceptedFormatList([.regular, .lightning, .workshop])

    // Encode via PostgresEncodable
    var buffer = ByteBuffer()
    let context = PostgresEncodingContext.default
    try list.encode(into: &buffer, context: context)

    // First byte should be JSONB version byte (0x01)
    #expect(buffer.getInteger(at: 0, as: UInt8.self) == 0x01)

    // Decode via PostgresDecodable
    let decodingContext = PostgresDecodingContext.default
    let decoded = try AcceptedFormatList(
      from: &buffer, type: .jsonb, format: .binary, context: decodingContext
    )
    #expect(decoded == list)
  }
}
