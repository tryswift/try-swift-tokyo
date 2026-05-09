import Fluent
import SQLKit

/// Convert `sponsor_plan_localizations.benefits` from `jsonb` to `text[]`.
///
/// `CreateSponsorPlanLocalization` originally created the column as `.json`
/// (jsonb in Postgres), but the model writes it as `[String]`, which Fluent
/// serialises as a Postgres text array. Production startup fails with
/// `column "benefits" is of type jsonb but expression is of type text[]` while
/// running `SeedSponsorPlans2026`. New environments will get `.array(of: .string)`
/// directly from the updated `CreateSponsorPlanLocalization`; this migration
/// brings already-migrated databases in line.
struct AlterSponsorPlanLocalizationBenefitsToStringArray: AsyncMigration {
  func prepare(on database: Database) async throws {
    // Postgres-only ALTER. On SQLite (used in tests) this migration is a
    // no-op because CreateSponsorPlanLocalization already creates the
    // column as `.array(of: .string)` after this PR; SQLite stores arrays
    // as JSON strings regardless of the declared type.
    guard let sql = database as? SQLDatabase, sql.dialect.name == "postgresql" else { return }
    // The original ALTER attempted `USING (... ARRAY(SELECT jsonb_array_elements_text(benefits)) ...)`,
    // but Postgres rejects that with "cannot use subquery in transform expression"
    // (sqlState 0A000): subqueries are not allowed inside an `ALTER COLUMN ... USING`
    // expression. We work around it by dropping the column and re-adding it as
    // `text[]`. SeedSponsorPlans2026 has never finished on production, so the
    // table is empty there; SQLite tests skip this migration entirely via the
    // dialect guard above.
    try await sql.raw("ALTER TABLE sponsor_plan_localizations DROP COLUMN benefits").run()
    try await sql.raw(
      """
      ALTER TABLE sponsor_plan_localizations
      ADD COLUMN benefits text[] NOT NULL DEFAULT ARRAY[]::text[]
      """
    ).run()
    try await sql.raw(
      "ALTER TABLE sponsor_plan_localizations ALTER COLUMN benefits DROP DEFAULT"
    ).run()
  }

  func revert(on database: Database) async throws {
    guard let sql = database as? SQLDatabase, sql.dialect.name == "postgresql" else { return }
    try await sql.raw("ALTER TABLE sponsor_plan_localizations DROP COLUMN benefits").run()
    try await sql.raw(
      "ALTER TABLE sponsor_plan_localizations ADD COLUMN benefits jsonb NOT NULL DEFAULT '[]'::jsonb"
    ).run()
    try await sql.raw(
      "ALTER TABLE sponsor_plan_localizations ALTER COLUMN benefits DROP DEFAULT"
    ).run()
  }
}
