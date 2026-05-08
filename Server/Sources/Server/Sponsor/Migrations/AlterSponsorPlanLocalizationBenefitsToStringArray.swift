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
    // The SeedSponsorPlans2026 migration could not insert any rows yet, so
    // the table is empty in practice. Still emit a USING expression so the
    // ALTER works even if rows somehow exist.
    try await sql.raw(
      """
      ALTER TABLE sponsor_plan_localizations
      ALTER COLUMN benefits TYPE text[]
      USING (
        CASE
          WHEN benefits IS NULL THEN ARRAY[]::text[]
          ELSE ARRAY(SELECT jsonb_array_elements_text(benefits))
        END
      )
      """
    ).run()
  }

  func revert(on database: Database) async throws {
    guard let sql = database as? SQLDatabase, sql.dialect.name == "postgresql" else { return }
    try await sql.raw(
      """
      ALTER TABLE sponsor_plan_localizations
      ALTER COLUMN benefits TYPE jsonb
      USING to_jsonb(benefits)
      """
    ).run()
  }
}
