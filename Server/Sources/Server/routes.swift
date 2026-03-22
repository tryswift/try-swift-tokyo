import Vapor

/// Controls which routes are registered based on the deployment target.
/// - `cfp`: CfP routes only (cfp.tryswift.jp)
/// - `student`: Scholarship routes only (student.tryswift.jp)
/// - `auth`: Auth service only (auth.tryswift.jp)
/// - `all`: Everything (local development)
enum AppMode: String {
  case cfp
  case student
  case auth
  case all

  static var current: AppMode {
    AppMode(rawValue: Environment.get("APP_MODE") ?? "all") ?? .all
  }
}

enum AppRoutes {
  /// Register all routes for the application
  static func register(_ app: Application) throws {
    let mode = AppMode.current

    // Serve static files for CfP (images, CSS, JS)
    // FileMiddleware maps request paths directly to filesystem paths
    // e.g., /cfp/images/riko.png -> Public/cfp/images/riko.png
    let cfpPublicDirectory = app.directory.workingDirectory + "Public/"
    app.middleware.use(
      FileMiddleware(
        publicDirectory: cfpPublicDirectory,
        defaultFile: nil,
        directoryAction: .none,
        advancedETagComparison: true
      )
    )

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

    // Auth routes — registered on auth app and in local dev (all)
    if mode == .auth || mode == .all {
      try api.register(collection: AuthController())
    }

    // CfP-specific routes
    if mode == .cfp || mode == .all {
      try api.register(collection: ConferenceController())
      try api.register(collection: ProposalController())
      try app.register(collection: CfPRoutes())
    }

    // Scholarship-specific routes
    if mode == .student || mode == .all {
      try app.register(collection: ScholarshipRoutes())
    }
  }
}
