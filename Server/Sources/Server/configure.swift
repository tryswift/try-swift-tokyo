import Vapor
import Fluent
import FluentPostgresDriver
import JWT
import NIOSSL

enum AppConfiguration {
  /// Configure the Vapor application
  static func configure(_ app: Application) async throws {
    // MARK: - Database Configuration

    // Configure PostgreSQL with connection pool settings
    if let databaseURL = Environment.get("DATABASE_URL") {
      // Production: Use DATABASE_URL with connection pool
      var tlsConfig: TLSConfiguration = .makeClientConfiguration()
      tlsConfig.certificateVerification = .none

      let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)

      var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
      postgresConfig.coreConfiguration.tls = .require(nioSSLContext)

      app.databases.use(
        .postgres(
          configuration: postgresConfig,
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
            database: Environment.get("DB_NAME") ?? "tryswift_cfp",
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
    app.migrations.add(CreateProposal())

    // Auto-migrate in development
    if app.environment == .development {
      try await app.autoMigrate()
    }

    // MARK: - JWT Configuration

    // Get JWT secret from environment
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
      fatalError("JWT_SECRET environment variable is required")
    }

    // Configure JWT with HS256 algorithm
    await app.jwt.keys.add(hmac: HMACKey(from: jwtSecret), digestAlgorithm: .sha256)

    // MARK: - Middleware

    // Enable CORS for iOS client
    let corsConfiguration = CORSMiddleware.Configuration(
      allowedOrigin: .all,
      allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
      allowedHeaders: [.accept, .authorization, .contentType, .origin]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

    // MARK: - Routes

    try AppRoutes.register(app)
  }
}
