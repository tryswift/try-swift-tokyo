import Vapor

enum AppRoutes {
  /// Register all routes for the application
  static func register(_ app: Application) throws {
    // Serve static files for CfP (images, CSS, JS)
    // FileMiddleware maps request paths directly to filesystem paths
    // e.g., /images/riko.png -> Public/images/riko.png
    let cfpPublicDirectory = app.directory.workingDirectory + "Public/"
    app.middleware.use(
      FileMiddleware(
        publicDirectory: cfpPublicDirectory,
        defaultFile: nil,
        directoryAction: .none,
        advancedETagComparison: true
      )
    )

    // Root endpoint - handled by CfPRoutes for production
    // Status endpoint for monitoring
    app.get("status") { req in
      return ["status": "ok", "service": "trySwiftCfP"]
    }

    // Health check endpoint for Fly.io
    app.get("health") { req in
      return ["status": "healthy", "service": "trySwiftCfP"]
    }

    // API version prefix
    let api = app.grouped("api", "v1")

    // Register API controllers
    try api.register(collection: AuthController())
    try api.register(collection: ConferenceController())
    try api.register(collection: ProposalController())

    // Register CfP SSR pages
    try app.register(collection: CfPRoutes())
  }
}
