import Fluent
import JWT
import SharedModels
import Vapor

/// Vapor Content wrapper for ProposalDTO
struct ProposalDTOContent: Content {
  let id: UUID
  let conferenceId: UUID
  let conferencePath: String
  let conferenceDisplayName: String
  let title: String
  let abstract: String
  let talkDetail: String
  let talkDuration: String
  let speakerName: String
  let speakerEmail: String
  let bio: String
  let bioJa: String?
  let jobTitle: String?
  let jobTitleJa: String?
  let iconURL: String?
  let notes: String?
  let speakerID: UUID
  let speakerUsername: String
  let githubUsername: String?
  let status: String
  let createdAt: Date?
  let updatedAt: Date?
  let titleJA: String?
  let abstractJA: String?
  let workshopDetails: WorkshopDetails?
  let workshopDetailsJA: WorkshopDetailsJA?
  let coInstructors: [CoInstructor]?

  init(from dto: ProposalDTO) {
    self.id = dto.id
    self.conferenceId = dto.conferenceId
    self.conferencePath = dto.conferencePath
    self.conferenceDisplayName = dto.conferenceDisplayName
    self.title = dto.title
    self.abstract = dto.abstract
    self.talkDetail = dto.talkDetail
    self.talkDuration = dto.talkDuration.rawValue
    self.speakerName = dto.speakerName
    self.speakerEmail = dto.speakerEmail
    self.bio = dto.bio
    self.bioJa = dto.bioJa
    self.jobTitle = dto.jobTitle
    self.jobTitleJa = dto.jobTitleJa
    self.iconURL = dto.iconURL
    self.notes = dto.notes
    self.speakerID = dto.speakerID
    self.speakerUsername = dto.speakerUsername
    self.githubUsername = dto.githubUsername
    self.status = dto.status.rawValue
    self.createdAt = dto.createdAt
    self.updatedAt = dto.updatedAt
    self.titleJA = dto.titleJA
    self.abstractJA = dto.abstractJA
    self.workshopDetails = dto.workshopDetails
    self.workshopDetailsJA = dto.workshopDetailsJA
    self.coInstructors = dto.coInstructors
  }
}

/// Vapor Content wrapper for CreateProposalRequest
struct CreateProposalRequestContent: Content {
  let conferencePath: String?
  let title: String
  let abstract: String
  let talkDetail: String
  let talkDuration: String
  let speakerName: String
  let speakerEmail: String
  let bio: String
  let bioJa: String?
  let jobTitle: String?
  let jobTitleJa: String?
  let iconURL: String?
  let notes: String?
  let workshopDetails: WorkshopDetails?
  let coInstructors: [CoInstructor]?

  func toRequest(defaultConferencePath: String, userRole: UserRole) throws -> CreateProposalRequest
  {
    guard let duration = TalkDuration(rawValue: talkDuration) else {
      throw Abort(
        .badRequest, reason: "Invalid talk duration. Use '20min', 'LT', 'workshop', or 'invited'")
    }

    // Validate that only invited speakers can submit invited talks
    if duration.isInvitedOnly && !userRole.isInvitedSpeaker {
      throw Abort(.forbidden, reason: "Only invited speakers can submit invited talks")
    }

    return CreateProposalRequest(
      conferencePath: conferencePath ?? defaultConferencePath,
      title: title,
      abstract: abstract,
      talkDetail: talkDetail,
      talkDuration: duration,
      speakerName: speakerName,
      speakerEmail: speakerEmail,
      bio: bio,
      bioJa: bioJa,
      jobTitle: jobTitle,
      jobTitleJa: jobTitleJa,
      iconURL: iconURL,
      notes: notes,
      workshopDetails: workshopDetails,
      coInstructors: coInstructors
    )
  }
}

/// Vapor Content wrapper for updating an existing proposal.
struct UpdateProposalRequestContent: Content {
  let title: String?
  let abstract: String?
  let talkDetail: String?
  let talkDuration: String?
  let githubUsername: String?
  let speakerName: String?
  let speakerEmail: String?
  let bio: String?
  let bioJa: String?
  let jobTitle: String?
  let jobTitleJa: String?
  let iconURL: String?
  let notes: String?
  let workshopDetails: WorkshopDetails?
  let coInstructors: [CoInstructor]?

  func validate(for role: UserRole) throws -> TalkDuration? {
    guard let talkDuration else { return nil }
    guard let duration = TalkDuration(rawValue: talkDuration) else {
      throw Abort(
        .badRequest, reason: "Invalid talk duration. Use '20min', 'LT', 'workshop', or 'invited'")
    }
    if duration.isInvitedOnly && !role.isInvitedSpeaker {
      throw Abort(.forbidden, reason: "Only invited speakers can submit invited talks")
    }
    return duration
  }
}

/// Controller for proposal endpoints
struct ProposalController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let proposals = routes.grouped("proposals")

    // Authenticated routes
    let authenticated = proposals.grouped(AuthMiddleware())
    authenticated.post(use: createProposal)
    authenticated.get("mine", use: getMyProposals)
    authenticated.get("mine", ":conferencePath", use: getMyProposalsByConference)
    authenticated.put(":proposalID", use: updateOwnProposal)
    authenticated.post(":proposalID", "withdraw", use: withdrawOwnProposal)

    // Admin-only routes (Organizer access)
    let adminOnly = proposals.grouped(AuthMiddleware()).grouped(OrganizerMiddleware())
    adminOnly.get(use: getAllProposals)
    adminOnly.get("conference", ":conferencePath", use: getProposalsByConference)
    adminOnly.get(":proposalID", use: getProposal)
    adminOnly.delete(":proposalID", use: deleteProposal)
  }

  /// Create a new proposal (authenticated users)
  /// POST /proposals
  @Sendable
  func createProposal(req: Request) async throws -> ProposalDTOContent {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)

    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }

    let contentRequest = try req.content.decode(CreateProposalRequestContent.self)

    // Find the current open conference or use the specified one
    let conferencePath = contentRequest.conferencePath
    let conference: Conference

    if let path = conferencePath {
      guard
        let found = try await Conference.query(on: req.db)
          .filter(\.$path == path)
          .first()
      else {
        throw Abort(.notFound, reason: "Conference not found: \(path)")
      }
      conference = found
    } else {
      // Get the current open conference
      guard
        let current = try await Conference.query(on: req.db)
          .filter(\.$isOpen == true)
          .sort(\.$year, .descending)
          .first()
      else {
        throw Abort(
          .badRequest,
          reason:
            "The Call for Proposals is not currently open. Please check back later for the next conference."
        )
      }
      conference = current
    }

    guard conference.isOpen else {
      throw Abort(.badRequest, reason: "Submissions are closed for \(conference.displayName)")
    }

    guard let conferenceID = conference.id else {
      throw Abort(.internalServerError, reason: "Conference ID is missing")
    }

    let createRequest = try contentRequest.toRequest(
      defaultConferencePath: conference.path,
      userRole: payload.role
    )

    // Validate input
    guard !createRequest.title.isEmpty else {
      throw Abort(.badRequest, reason: "Title is required")
    }
    guard !createRequest.abstract.isEmpty else {
      throw Abort(.badRequest, reason: "Abstract is required")
    }
    guard !createRequest.talkDetail.isEmpty else {
      throw Abort(.badRequest, reason: "Talk detail is required")
    }
    guard !createRequest.speakerName.isEmpty else {
      throw Abort(.badRequest, reason: "Speaker name is required")
    }
    guard !createRequest.speakerEmail.isEmpty else {
      throw Abort(.badRequest, reason: "Speaker email is required")
    }
    guard !createRequest.bio.isEmpty else {
      throw Abort(.badRequest, reason: "Bio is required")
    }

    // Create proposal
    let proposal = Proposal(
      conferenceID: conferenceID,
      title: createRequest.title,
      abstract: createRequest.abstract,
      talkDetail: createRequest.talkDetail,
      talkDuration: createRequest.talkDuration,
      speakerName: createRequest.speakerName,
      speakerEmail: createRequest.speakerEmail,
      bio: createRequest.bio,
      bioJa: createRequest.bioJa,
      jobTitle: createRequest.jobTitle,
      jobTitleJa: createRequest.jobTitleJa,
      iconURL: createRequest.iconURL,
      notes: createRequest.notes,
      speakerID: userID
    )

    try await proposal.save(on: req.db)

    // Notify organizers via Slack
    await SlackNotifier.notifyNewProposal(
      title: createRequest.title,
      speakerName: createRequest.speakerName,
      talkDuration: createRequest.talkDuration.rawValue,
      client: req.client,
      logger: req.logger
    )

    return ProposalDTOContent(
      from: try proposal.toDTO(speakerUsername: payload.username, conference: conference))
  }

  /// Get all proposals (admin only)
  /// GET /proposals
  @Sendable
  func getAllProposals(req: Request) async throws -> [ProposalDTOContent] {
    let proposals = try await Proposal.query(on: req.db)
      .with(\.$speaker)
      .with(\.$conference)
      .all()

    return try proposals.map { proposal in
      ProposalDTOContent(
        from: try proposal.toDTO(
          speakerUsername: proposal.speaker.username, conference: proposal.conference))
    }
  }

  /// Get proposals by conference (admin only)
  /// GET /proposals/conference/:conferencePath
  @Sendable
  func getProposalsByConference(req: Request) async throws -> [ProposalDTOContent] {
    guard let conferencePath = req.parameters.get("conferencePath") else {
      throw Abort(.badRequest, reason: "Conference path is required")
    }

    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$path == conferencePath)
        .first()
    else {
      throw Abort(.notFound, reason: "Conference not found")
    }

    let proposals = try await Proposal.query(on: req.db)
      .filter(\.$conference.$id == conference.id!)
      .with(\.$speaker)
      .with(\.$conference)
      .all()

    return try proposals.map { proposal in
      ProposalDTOContent(
        from: try proposal.toDTO(
          speakerUsername: proposal.speaker.username, conference: proposal.conference))
    }
  }

  /// Get proposals submitted by the current user
  /// GET /proposals/mine
  @Sendable
  func getMyProposals(req: Request) async throws -> [ProposalDTOContent] {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)

    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }

    let proposals = try await Proposal.query(on: req.db)
      .filter(\.$speaker.$id == userID)
      .with(\.$conference)
      .all()

    return try proposals.map { proposal in
      ProposalDTOContent(
        from: try proposal.toDTO(speakerUsername: payload.username, conference: proposal.conference)
      )
    }
  }

  /// Get proposals submitted by the current user for a specific conference
  /// GET /proposals/mine/:conferencePath
  @Sendable
  func getMyProposalsByConference(req: Request) async throws -> [ProposalDTOContent] {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)

    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }

    guard let conferencePath = req.parameters.get("conferencePath") else {
      throw Abort(.badRequest, reason: "Conference path is required")
    }

    guard
      let conference = try await Conference.query(on: req.db)
        .filter(\.$path == conferencePath)
        .first()
    else {
      throw Abort(.notFound, reason: "Conference not found")
    }

    let proposals = try await Proposal.query(on: req.db)
      .filter(\.$speaker.$id == userID)
      .filter(\.$conference.$id == conference.id!)
      .with(\.$conference)
      .all()

    return try proposals.map { proposal in
      ProposalDTOContent(
        from: try proposal.toDTO(speakerUsername: payload.username, conference: proposal.conference)
      )
    }
  }

  /// Update a proposal owned by the current user.
  /// PUT /proposals/:proposalID
  @Sendable
  func updateOwnProposal(req: Request) async throws -> ProposalDTOContent {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)
    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }
    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .filter(\.$speaker.$id == userID)
        .with(\.$conference)
        .first()
    else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    let request = try req.content.decode(UpdateProposalRequestContent.self)
    let talkDuration = try request.validate(for: payload.role)

    if let githubUsername = request.githubUsername?.trimmingCharacters(in: .whitespacesAndNewlines) {
      guard !githubUsername.isEmpty else {
        throw Abort(.badRequest, reason: "GitHub ID is required")
      }
      proposal.githubUsername = githubUsername
    }
    if let title = request.title {
      guard !title.isEmpty else { throw Abort(.badRequest, reason: "Title is required") }
      proposal.title = title
    }
    if let abstract = request.abstract {
      guard !abstract.isEmpty else { throw Abort(.badRequest, reason: "Abstract is required") }
      proposal.abstract = abstract
    }
    if let talkDetail = request.talkDetail {
      guard !talkDetail.isEmpty else { throw Abort(.badRequest, reason: "Talk detail is required") }
      proposal.talkDetail = talkDetail
    }
    if let talkDuration {
      proposal.talkDuration = talkDuration
    }
    if let speakerName = request.speakerName {
      guard !speakerName.isEmpty else { throw Abort(.badRequest, reason: "Speaker name is required") }
      proposal.speakerName = speakerName
    }
    if let speakerEmail = request.speakerEmail {
      guard !speakerEmail.isEmpty else {
        throw Abort(.badRequest, reason: "Speaker email is required")
      }
      proposal.speakerEmail = speakerEmail
    }
    if let bio = request.bio {
      guard !bio.isEmpty else { throw Abort(.badRequest, reason: "Bio is required") }
      proposal.bio = bio
    }

    if let bioJa = request.bioJa {
      proposal.bioJa = bioJa.isEmpty ? nil : bioJa
    }
    if let jobTitle = request.jobTitle {
      proposal.jobTitle = jobTitle.isEmpty ? nil : jobTitle
    }
    if let jobTitleJa = request.jobTitleJa {
      proposal.jobTitleJa = jobTitleJa.isEmpty ? nil : jobTitleJa
    }
    if let iconURL = request.iconURL {
      guard !iconURL.isEmpty else { throw Abort(.badRequest, reason: "Icon URL is required") }
      proposal.iconURL = iconURL
    }
    if let notes = request.notes {
      proposal.notes = notes.isEmpty ? nil : notes
    }

    if proposal.talkDuration.isWorkshop {
      proposal.workshopDetails = request.workshopDetails
      proposal.coInstructors = request.coInstructors.map(CoInstructorList.init)
    } else {
      proposal.workshopDetails = nil
      proposal.coInstructors = nil
    }

    try await proposal.save(on: req.db)

    return ProposalDTOContent(
      from: try proposal.toDTO(speakerUsername: payload.username, conference: proposal.conference)
    )
  }

  /// Withdraw a proposal owned by the current user.
  /// POST /proposals/:proposalID/withdraw
  @Sendable
  func withdrawOwnProposal(req: Request) async throws -> HTTPStatus {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)
    guard let userID = payload.userID else {
      throw Abort(.unauthorized, reason: "Invalid token")
    }
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }
    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .filter(\.$speaker.$id == userID)
        .first()
    else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    proposal.status = .withdrawn
    try await proposal.save(on: req.db)
    return .ok
  }

  /// Get a specific proposal (admin only)
  /// GET /proposals/:proposalID
  @Sendable
  func getProposal(req: Request) async throws -> ProposalDTOContent {
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }

    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .with(\.$speaker)
        .with(\.$conference)
        .first()
    else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    return ProposalDTOContent(
      from: try proposal.toDTO(
        speakerUsername: proposal.speaker.username, conference: proposal.conference))
  }

  /// Delete a proposal (admin only)
  /// DELETE /proposals/:proposalID
  @Sendable
  func deleteProposal(req: Request) async throws -> HTTPStatus {
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }

    guard let proposal = try await Proposal.find(proposalID, on: req.db) else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    try await proposal.delete(on: req.db)

    return .noContent
  }
}
