import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = try await Application.make(env)

do {
  try await AppConfiguration.configure(app)
  try AppRoutes.register(app)
} catch {
  app.logger.report(error: error)
  try? await app.asyncShutdown()
  throw error
}

try await app.execute()
