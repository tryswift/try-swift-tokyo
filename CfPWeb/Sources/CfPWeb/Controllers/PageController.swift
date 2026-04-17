import Vapor
import VaporElementary

struct PageController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: home)
    routes.get("guidelines", use: guidelines)
    routes.get("login", use: login)
    routes.get("login-page", use: login)
    routes.get("profile", use: profile)
    routes.get("submit", use: submit)
    routes.get("submit-page", use: submit)
    routes.get("workshops", use: workshops)
    routes.get("workshops", "apply", use: workshops)
    routes.get("workshops", "status", use: workshops)
    routes.get("my-proposals", use: myProposals)
    routes.get("my-proposals-page", use: myProposals)
    routes.get("my-proposals", ":proposalID", use: myProposals)
    routes.get("my-proposals", ":proposalID", "edit", use: myProposals)
    routes.get("feedback", use: feedback)
    routes.get("organizer", use: organizer)

    routes.get("organizer", "proposals", use: organizer)
    routes.get("organizer", "proposals", "new", use: organizer)
    routes.get("organizer", "proposals", "import", use: organizer)
    routes.get("organizer", "proposals", ":proposalID", use: organizer)
    routes.get("organizer", "proposals", ":proposalID", "edit", use: organizer)
    routes.get("organizer", "timetable", use: organizer)
    routes.get("organizer", "workshops", use: organizer)
    routes.get("organizer", "workshops", "applications", use: organizer)
    routes.get("organizer", "workshops", "results", use: organizer)

    let ja = routes.grouped("ja")
    ja.get(use: home)
    ja.get("guidelines", use: guidelines)
    ja.get("login", use: login)
    ja.get("submit", use: submit)
    ja.get("workshops", use: workshops)
    ja.get("workshops", "apply", use: workshops)
    ja.get("workshops", "status", use: workshops)
    ja.get("feedback", use: feedback)
    ja.get("profile", use: profile)
    ja.get("my-proposals", use: myProposals)
    ja.get("my-proposals", ":proposalID", use: myProposals)
    ja.get("my-proposals", ":proposalID", "edit", use: myProposals)

    let jaOrganizer = ja.grouped("organizer")
    jaOrganizer.get("proposals", use: organizer)
    jaOrganizer.get("proposals", "new", use: organizer)
    jaOrganizer.get("proposals", "import", use: organizer)
    jaOrganizer.get("proposals", ":proposalID", use: organizer)
    jaOrganizer.get("proposals", ":proposalID", "edit", use: organizer)
    jaOrganizer.get("timetable", use: organizer)
    jaOrganizer.get("workshops", use: organizer)
    jaOrganizer.get("workshops", "applications", use: organizer)
    jaOrganizer.get("workshops", "results", use: organizer)

    let cfp = routes.grouped("cfp")
    cfp.get(use: redirectFromLegacyPrefix)
    cfp.get("**", use: redirectFromLegacyPrefix)
  }

  @Sendable
  func home(req: Request) async throws -> Response {
    try await render(req, page: .home)
  }

  @Sendable
  func guidelines(req: Request) async throws -> Response {
    try await render(req, page: .guidelines)
  }

  @Sendable
  func login(req: Request) async throws -> Response {
    try await render(req, page: .login)
  }

  @Sendable
  func profile(req: Request) async throws -> Response {
    try await render(req, page: .profile)
  }

  @Sendable
  func submit(req: Request) async throws -> Response {
    try await render(req, page: .submit)
  }

  @Sendable
  func workshops(req: Request) async throws -> Response {
    try await render(req, page: .workshops)
  }

  @Sendable
  func myProposals(req: Request) async throws -> Response {
    try await render(req, page: .myProposals)
  }

  @Sendable
  func feedback(req: Request) async throws -> Response {
    try await render(req, page: .feedback)
  }

  @Sendable
  func organizer(req: Request) async throws -> Response {
    try await render(req, page: .organizer)
  }

  @Sendable
  func redirectFromLegacyPrefix(req: Request) async throws -> Response {
    let path = req.url.path.replacingOccurrences(of: "/cfp", with: "")
    let target = path.isEmpty ? "/" : path
    return req.redirect(to: target, redirectType: .permanent)
  }

  private func render(_ req: Request, page: CfPPage) async throws -> Response {
    let html = HTMLResponse {
      AppLayout(page: page)
    }
    return try await html.encodeResponse(for: req)
  }
}
