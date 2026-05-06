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

    // /api/v1 must NOT be reachable from sponsor.tryswift.jp or student.tryswift.jp.
    // Those portals serve SSR HTML only; the JSON API is exposed only on the
    // configured API host (api.tryswift.jp).
    let api = app.grouped(NotSponsorHostMiddleware())
      .grouped(NotStudentHostMiddleware())
      .grouped("api", "v1")

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

    // Student scholarship portal routes (host-filtered to student.tryswift.jp)
    try app.register(collection: ScholarshipRoutes())
  }
}
