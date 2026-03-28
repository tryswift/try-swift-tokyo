import Fluent
import Vapor

struct FavoriteToggleRequest: Content {
  let proposalId: UUID
  let deviceId: String
}

struct FavoriteToggleResponse: Content {
  let isFavorite: Bool
}

struct FavoriteItem: Content {
  let proposalId: UUID
}

struct FavoritesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let favorites = routes.grouped("favorites")

    favorites.get(use: getFavorites)
    favorites.put(use: toggleFavorite)
  }

  /// GET /api/v1/favorites?deviceId=xxx
  @Sendable
  func getFavorites(req: Request) async throws -> [FavoriteItem] {
    guard let deviceId = req.query[String.self, at: "deviceId"], !deviceId.isEmpty else {
      throw Abort(.badRequest, reason: "deviceId query parameter is required")
    }

    let favorites = try await Favorite.query(on: req.db)
      .filter(\.$deviceID == deviceId)
      .all()

    return favorites.map { FavoriteItem(proposalId: $0.$proposal.id) }
  }

  /// PUT /api/v1/favorites
  @Sendable
  func toggleFavorite(req: Request) async throws -> FavoriteToggleResponse {
    let body = try req.content.decode(FavoriteToggleRequest.self)

    guard !body.deviceId.isEmpty else {
      throw Abort(.badRequest, reason: "deviceId is required")
    }

    // Verify proposal exists
    guard let _ = try await Proposal.find(body.proposalId, on: req.db) else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    // Check if favorite already exists
    if let existing = try await Favorite.query(on: req.db)
      .filter(\.$proposal.$id == body.proposalId)
      .filter(\.$deviceID == body.deviceId)
      .first()
    {
      // Remove favorite
      try await existing.delete(on: req.db)
      return FavoriteToggleResponse(isFavorite: false)
    } else {
      // Add favorite
      let favorite = Favorite(proposalID: body.proposalId, deviceID: body.deviceId)
      try await favorite.save(on: req.db)
      return FavoriteToggleResponse(isFavorite: true)
    }
  }
}
