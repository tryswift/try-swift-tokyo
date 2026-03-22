import PostgresNIO
import SharedModels

// Explicitly declare CoInstructorList as JSONB-encoded for PostgreSQL.
//
// Without this, postgres-kit's ArrayAwareBoxWrappingPostgresEncoder detects
// the inner [CoInstructor] array and encodes it as `jsonb[]` instead of a
// single `jsonb` value, causing a type mismatch with the database column.
//
// By conforming to PostgresEncodable/PostgresDecodable, the "fast path"
// in postgres-kit is used: CoInstructorList is encoded directly as JSONB
// via the default implementations provided by postgres-nio for Codable types.

extension CoInstructorList: @retroactive PostgresEncodable {}
extension CoInstructorList: @retroactive PostgresDecodable {}
