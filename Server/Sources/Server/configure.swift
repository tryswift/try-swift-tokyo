import Fluent
import FluentPostgresDriver
import JWT
import Vapor

enum AppConfiguration {
  /// Configure the Vapor application
  static func configure(_ app: Application) async throws {
    // MARK: - Database Configuration

    // Configure PostgreSQL with connection pool settings
    if let databaseURL = Environment.get("DATABASE_URL") {
      // Production: Use DATABASE_URL with connection pool
      try app.databases.use(
        .postgres(
          url: databaseURL,
          maxConnectionsPerEventLoop: 4,
          connectionPoolTimeout: .seconds(30)
        ),
        as: .psql
      )
    } else {
      // Development: Use individual environment variables
      app.databases.use(
        .postgres(
          configuration: SQLPostgresConfiguration(
            hostname: Environment.get("DB_HOST") ?? "localhost",
            port: Environment.get("DB_PORT").flatMap(Int.init) ?? 5432,
            username: Environment.get("DB_USER") ?? "postgres",
            password: Environment.get("DB_PASSWORD") ?? "postgres",
            database: Environment.get("DB_NAME") ?? "tryswift_api",
            tls: .disable
          ),
          maxConnectionsPerEventLoop: 4,
          connectionPoolTimeout: .seconds(30)
        ),
        as: .psql
      )
    }

    // MARK: - Migrations

    app.migrations.add(CreateUser())
    app.migrations.add(CreateConference())
    // Conference's is_accepting_sponsors column must exist before SeedTrySwiftTokyo2026
    // saves a Conference row (the model now has a non-optional `isAcceptingSponsors` field).
    app.migrations.add(AddIsAcceptingSponsorsToConference())
    app.migrations.add(CreateProposal())
    // Add is_published before the seed so fresh databases have the column
    // when SeedTrySwiftTokyo2026 saves through the Conference model. Existing
    // databases apply this on their next startup if it is still pending,
    // following Fluent's registered migration order.
    app.migrations.add(AddConferenceIsPublished())
    app.migrations.add(SeedTrySwiftTokyo2026())
    app.migrations.add(AddUserEmail())
    app.migrations.add(AddProposalSpeakerInfo())
    app.migrations.add(AddPaperCallImportUser())
    app.migrations.add(AddProposalPaperCallFields())
    app.migrations.add(AddProposalStatus())
    app.migrations.add(CreateScheduleSlot())
    app.migrations.add(AddScheduleSlotIndexes())
    app.migrations.add(AddProposalGitHubUsername())
    app.migrations.add(AddProposalWorkshopFields())
    app.migrations.add(CreateWorkshopRegistration())
    app.migrations.add(CreateWorkshopApplication())
    app.migrations.add(AddProposalJapaneseFields())
    app.migrations.add(AddProposalSpeakerDetails())
    app.migrations.add(AddProposalWorkshopDetailsJA())
    app.migrations.add(CreateFeedback())
    app.migrations.add(CreateFavorite())
    app.migrations.add(AddFavoriteIndexes())
    app.migrations.add(AddFeedbackIndexes())
    app.migrations.add(CreateSponsorOrganization())
    app.migrations.add(CreateSponsorUser())
    app.migrations.add(CreateSponsorMembership())
    app.migrations.add(CreateSponsorPlan())
    app.migrations.add(CreateSponsorPlanLocalization())
    app.migrations.add(CreateSponsorInquiry())
    app.migrations.add(CreateSponsorApplication())
    app.migrations.add(CreateMagicLinkToken())
    app.migrations.add(CreateSponsorInvitation())
    app.migrations.add(SeedSponsorPlans2026())

    // Auto-migrate on startup (safe for production as Fluent tracks completed migrations)
    try await app.autoMigrate()

    // MARK: - JWT Configuration

    // Get JWT secret from environment
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
      fatalError("JWT_SECRET environment variable is required")
    }

    // Configure JWT with HS256 algorithm
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    // MARK: - Request Body Size Configuration

    // Increase max body size for CSV file uploads (default is 16KB)
    // Set to 10MB to support large PaperCall.io CSV exports
    app.routes.defaultMaxBodySize = "10mb"

    // MARK: - Middleware

    // Enable CORS for frontend and iOS client
    // Allow tryswift.jp properties and localhost for development.
    let corsConfiguration = CORSMiddleware.Configuration(
      allowedOrigin: .originBased,
      allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
      allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith],
      allowCredentials: true
    )
    // Insert CORS at the very front of the middleware chain so it sits *outside*
    // the auto-registered ErrorMiddleware. Without this, abort errors (401/403/404)
    // bypass CORSMiddleware's response decoration and the browser misreports the
    // failure as a CORS error rather than the underlying status.
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)

    // Identify sponsor.tryswift.jp host so SponsorHostOnlyMiddleware can gate routes.
    app.middleware.use(HostRoutingMiddleware())

    // Serve static files from Public directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // MARK: - Routes

    try AppRoutes.register(app)
  }
}
