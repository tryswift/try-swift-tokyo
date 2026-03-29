import Fluent
import SQLKit
import Vapor

struct FavoriteToggleRequest: Content {
  let proposalId: UUID
  let deviceId: String
}

struct FavoriteToggleResponse: Content {
  let isFavorite: Bool
  let count: Int
}

struct FavoriteItem: Content {
  let proposalId: UUID
}

struct FavoriteCountItem: Content {
  let proposalId: UUID
  let count: Int
}

struct FavoritesController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let favorites = routes.grouped("favorites")

    favorites.get(use: getFavorites)
    favorites.put(use: toggleFavorite)

    let favoriteCounts = routes.grouped("favorite-counts")
    favoriteCounts.get(use: getFavoriteCounts)
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

  /// GET /api/v1/favorite-counts
  @Sendable
  func getFavoriteCounts(req: Request) async throws -> [FavoriteCountItem] {
    guard let sql = req.db as? any SQLDatabase else {
      throw Abort(.internalServerError, reason: "SQL database required")
    }

    struct CountRow: Decodable {
      let proposalId: UUID
      let count: Int

      enum CodingKeys: String, CodingKey {
        case proposalId = "proposal_id"
        case count
      }
    }

    let rows = try await sql.raw(
      "SELECT proposal_id, COUNT(*) AS count FROM \(raw: Favorite.schema) GROUP BY proposal_id"
    ).all(decoding: CountRow.self)

    return rows.map { FavoriteCountItem(proposalId: $0.proposalId, count: $0.count) }
  }

  /// PUT /api/v1/favorites
  @Sendable
  func toggleFavorite(req: Request) async throws -> FavoriteToggleResponse {
    let body = try req.content.decode(FavoriteToggleRequest.self)

    guard !body.deviceId.isEmpty else {
      throw Abort(.badRequest, reason: "deviceId is required")
    }

    // Verify proposal exists
    guard (try await Proposal.find(body.proposalId, on: req.db)) != nil else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    let isFavorite: Bool

    // Check if favorite already exists
    if let existing = try await Favorite.query(on: req.db)
      .filter(\.$proposal.$id == body.proposalId)
      .filter(\.$deviceID == body.deviceId)
      .first()
    {
      // Remove favorite
      try await existing.delete(on: req.db)
      isFavorite = false
    } else {
      // Add favorite — handle concurrent insert race on unique constraint
      let favorite = Favorite(proposalID: body.proposalId, deviceID: body.deviceId)
      do {
        try await favorite.save(on: req.db)
        isFavorite = true
      } catch let error as DatabaseError where error.isConstraintFailure {
        // Another request inserted concurrently — treat as already favorited
        isFavorite = true
      }
    }

    // Get updated count
    let count = try await Favorite.query(on: req.db)
      .filter(\.$proposal.$id == body.proposalId)
      .count()

    return FavoriteToggleResponse(isFavorite: isFavorite, count: count)
  }
}
