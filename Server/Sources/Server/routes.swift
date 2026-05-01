import Vapor

enum AppRoutes {
  /// Register all routes for the application
  static func register(_ app: Application) throws {
    // Status endpoint for monitoring
    app.get("status") { req in
      return ["status": "ok", "service": "trySwiftAPI"]
    }

    // Health check endpoint for Fly.io
    app.get("health") { req in
      return ["status": "healthy", "service": "trySwiftAPI"]
    }

    // API version prefix
    let api = app.grouped("api", "v1")

    // Register API controllers
    try api.register(collection: AuthController())
    try api.register(collection: ConferenceController())
    try api.register(collection: ProposalController())
    try api.register(collection: AdminProposalController())
    try api.register(collection: AdminTimetableController())
    try api.register(collection: WorkshopController())
    try api.register(collection: AdminWorkshopController())
    try api.register(collection: FeedbackController())
    try api.register(collection: FavoritesController())

    // Sponsor portal routes (host-filtered to sponsor.tryswift.jp)
    try app.register(collection: SponsorRoutes())
  }
}
