import Vapor
import Fluent
import JWT
import SharedModels

/// Vapor Content wrapper for LocalizedString
struct LocalizedStringContent: Content {
  let en: String
  let ja: String
  
  init(from ls: LocalizedString) {
    self.en = ls.en
    self.ja = ls.ja
  }
}

/// Vapor Content wrapper for ConferenceDTO
struct ConferenceDTOContent: Content {
  let id: UUID
  let path: String
  let displayName: String
  let description: LocalizedStringContent?
  let year: Int
  let isOpen: Bool
  let deadline: Date?
  let startDate: Date?
  let endDate: Date?
  let location: String?
  let websiteURL: String?
  let createdAt: Date?
  let updatedAt: Date?
  
  init(from dto: ConferenceDTO) {
    self.id = dto.id
    self.path = dto.path
    self.displayName = dto.displayName
    self.description = dto.description.map { LocalizedStringContent(from: $0) }
    self.year = dto.year
    self.isOpen = dto.isOpen
    self.deadline = dto.deadline
    self.startDate = dto.startDate
    self.endDate = dto.endDate
    self.location = dto.location
    self.websiteURL = dto.websiteURL
    self.createdAt = dto.createdAt
    self.updatedAt = dto.updatedAt
  }
}

/// Vapor Content wrapper for CreateConferenceRequest
struct CreateConferenceRequestContent: Content {
  let path: String
  let displayName: String
  let descriptionEn: String?
  let descriptionJa: String?
  let year: Int
  let isOpen: Bool?
  let deadline: Date?
  let startDate: Date?
  let endDate: Date?
  let location: String?
  let websiteURL: String?
}

/// Controller for conference endpoints
struct ConferenceController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let conferences = routes.grouped("conferences")
    
    // Public routes
    conferences.get(use: getAllConferences)
    conferences.get("open", use: getOpenConferences)
    conferences.get(":path", use: getConference)
    
    // Admin-only routes (Organizer access)
    let adminOnly = conferences.grouped(AuthMiddleware()).grouped(OrganizerMiddleware())
    adminOnly.post(use: createConference)
    adminOnly.put(":path", use: updateConference)
    adminOnly.delete(":path", use: deleteConference)
  }
  
  /// Get all conferences
  /// GET /conferences
  @Sendable
  func getAllConferences(req: Request) async throws -> [ConferenceDTOContent] {
    let conferences = try await Conference.query(on: req.db)
      .sort(\.$year, .descending)
      .all()
    
    return try conferences.map { conference in
      ConferenceDTOContent(from: try conference.toDTO())
    }
  }
  
  /// Get open conferences (CfP is active)
  /// GET /conferences/open
  @Sendable
  func getOpenConferences(req: Request) async throws -> [ConferenceDTOContent] {
    let conferences = try await Conference.query(on: req.db)
      .filter(\.$isOpen == true)
      .sort(\.$year, .descending)
      .all()
    
    return try conferences.map { conference in
      ConferenceDTOContent(from: try conference.toDTO())
    }
  }
  
  /// Get a specific conference by path
  /// GET /conferences/:path
  @Sendable
  func getConference(req: Request) async throws -> ConferenceDTOContent {
    guard let path = req.parameters.get("path") else {
      throw Abort(.badRequest, reason: "Conference path is required")
    }
    
    guard let conference = try await Conference.query(on: req.db)
      .filter(\.$path == path)
      .first() else {
      throw Abort(.notFound, reason: "Conference not found")
    }
    
    return ConferenceDTOContent(from: try conference.toDTO())
  }
  
  /// Create a new conference (admin only)
  /// POST /conferences
  @Sendable
  func createConference(req: Request) async throws -> ConferenceDTOContent {
    let request = try req.content.decode(CreateConferenceRequestContent.self)
    
    // Check if path already exists
    let existing = try await Conference.query(on: req.db)
      .filter(\.$path == request.path)
      .first()
    
    if existing != nil {
      throw Abort(.conflict, reason: "Conference with path '\(request.path)' already exists")
    }
    
    let conference = Conference(
      path: request.path,
      displayName: request.displayName,
      descriptionEn: request.descriptionEn,
      descriptionJa: request.descriptionJa,
      year: request.year,
      isOpen: request.isOpen ?? true,
      deadline: request.deadline,
      startDate: request.startDate,
      endDate: request.endDate,
      location: request.location,
      websiteURL: request.websiteURL
    )
    
    try await conference.save(on: req.db)
    
    return ConferenceDTOContent(from: try conference.toDTO())
  }
  
  /// Update a conference (admin only)
  /// PUT /conferences/:path
  @Sendable
  func updateConference(req: Request) async throws -> ConferenceDTOContent {
    guard let path = req.parameters.get("path") else {
      throw Abort(.badRequest, reason: "Conference path is required")
    }
    
    guard let conference = try await Conference.query(on: req.db)
      .filter(\.$path == path)
      .first() else {
      throw Abort(.notFound, reason: "Conference not found")
    }
    
    let request = try req.content.decode(CreateConferenceRequestContent.self)
    
    conference.path = request.path
    conference.displayName = request.displayName
    conference.descriptionEn = request.descriptionEn
    conference.descriptionJa = request.descriptionJa
    conference.year = request.year
    conference.isOpen = request.isOpen ?? conference.isOpen
    conference.deadline = request.deadline
    conference.startDate = request.startDate
    conference.endDate = request.endDate
    conference.location = request.location
    conference.websiteURL = request.websiteURL
    
    try await conference.save(on: req.db)
    
    return ConferenceDTOContent(from: try conference.toDTO())
  }
  
  /// Delete a conference (admin only)
  /// DELETE /conferences/:path
  @Sendable
  func deleteConference(req: Request) async throws -> HTTPStatus {
    guard let path = req.parameters.get("path") else {
      throw Abort(.badRequest, reason: "Conference path is required")
    }
    
    guard let conference = try await Conference.query(on: req.db)
      .filter(\.$path == path)
      .first() else {
      throw Abort(.notFound, reason: "Conference not found")
    }
    
    try await conference.delete(on: req.db)
    
    return .noContent
  }
}
