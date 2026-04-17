import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = try await Application.make(env)
do {
  try await CfPWebConfiguration.configure(app)
  try await app.execute()
  try await app.asyncShutdown()
} catch {
  app.logger.report(error: error)
  try await app.asyncShutdown()
  throw error
}
