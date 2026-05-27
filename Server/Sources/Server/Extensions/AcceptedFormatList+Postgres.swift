import PostgresNIO
import SharedModels

// Explicitly declare AcceptedFormatList as JSONB-encoded for PostgreSQL.
//
// Without this, postgres-kit's ArrayAwareBoxWrappingPostgresEncoder detects the
// inner [TalkDuration] array and encodes it as `jsonb[]` instead of a single
// `jsonb` value, causing a type mismatch with the database column.
//
// By conforming to PostgresEncodable/PostgresDecodable, the "fast path" in
// postgres-kit is used: AcceptedFormatList is encoded directly as JSONB via the
// default implementations provided by postgres-nio for Codable types.

extension AcceptedFormatList: @retroactive PostgresEncodable {}
extension AcceptedFormatList: @retroactive PostgresDecodable {}
