import Vapor

enum CfPWebConfiguration {
  static func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    try CfPWebRoutes.register(app)
  }
}
