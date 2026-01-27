import Vapor

enum AppRoutes {
  /// Register all routes for the application
  static func register(_ app: Application) throws {
    // Root endpoint
    app.get { req in
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
