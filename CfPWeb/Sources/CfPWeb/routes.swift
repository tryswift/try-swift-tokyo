import Vapor

enum CfPWebRoutes {
  static func register(_ app: Application) throws {
    let pageController = PageController()
    try app.register(collection: pageController)

    app.get("health") { _ in
      ["status": "ok", "service": "CfPWeb"]
    }
  }
}
