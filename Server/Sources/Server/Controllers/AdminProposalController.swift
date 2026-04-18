import Fluent
import SharedModels
import Vapor

struct AdminUserLookupResponse: Content {
  let name: String?
  let email: String?
  let bio: String?
  let avatarURL: String?
}

struct AdminProposalRequestContent: Content {
  let conferenceId: UUID
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
  let githubUsername: String?
  let notes: String?
  let titleJA: String?
  let abstractJA: String?
  let workshopDetails: WorkshopDetails?
  let workshopDetailsJA: WorkshopDetailsJA?
  let coInstructors: [CoInstructor]?

  func decodedTalkDuration() throws -> TalkDuration {
    guard let duration = TalkDuration(rawValue: talkDuration) else {
      throw Abort(
        .badRequest, reason: "Invalid talk duration. Use '20min', 'LT', 'workshop', or 'invited'")
    }
    return duration
  }

  func validate() throws -> TalkDuration {
    let duration = try decodedTalkDuration()
    guard !title.isEmpty else { throw Abort(.badRequest, reason: "Title is required") }
    guard !abstract.isEmpty else { throw Abort(.badRequest, reason: "Abstract is required") }
    guard !talkDetail.isEmpty else { throw Abort(.badRequest, reason: "Talk detail is required") }
    guard !speakerName.isEmpty else { throw Abort(.badRequest, reason: "Speaker name is required") }
    guard !speakerEmail.isEmpty else {
      throw Abort(.badRequest, reason: "Speaker email is required")
    }
    guard !bio.isEmpty else { throw Abort(.badRequest, reason: "Bio is required") }
    if duration.isWorkshop, workshopDetails == nil {
      throw Abort(.badRequest, reason: "Workshop details are required for workshop talks")
    }
    return duration
  }
}

struct ProposalStatusChangeRequestContent: Content {
  let status: String

  func decodedStatus() throws -> ProposalStatus {
    guard let status = ProposalStatus(rawValue: status) else {
      throw Abort(.badRequest, reason: "Invalid proposal status")
    }
    return status
  }
}

struct AdminProposalController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let admin = routes.grouped("admin")
      .grouped(AuthMiddleware())
      .grouped(OrganizerMiddleware())

    let proposals = admin.grouped("proposals")
    proposals.get(use: getAll)
    proposals.get(":proposalID", use: getOne)
    proposals.post(use: create)
    proposals.put(":proposalID", use: update)
    proposals.delete(":proposalID", use: delete)
    proposals.post(":proposalID", "status", use: changeStatus)
    proposals.get("export", use: exportCSV)
    proposals.get("speakers-export", use: exportSpeakers)
    proposals.post("import", use: importProposals)

    admin.get("users", "lookup", ":username", use: lookupUser)
  }

  @Sendable
  func getAll(req: Request) async throws -> [ProposalDTOContent] {
    _ = try await AdminAPIService.requireAdmin(req)

    let conferencePath = req.query[String.self, at: "conference"]
    let query = Proposal.query(on: req.db)
      .with(\.$speaker)
      .with(\.$conference)
      .sort(\.$createdAt, .descending)

    if let conferencePath,
      let conference = try await Conference.query(on: req.db)
        .filter(\.$path == conferencePath)
        .first(),
      let conferenceID = conference.id
    {
      query.filter(\.$conference.$id == conferenceID)
    }

    let proposals = try await query.all()
    return try proposals.map { proposal in
      ProposalDTOContent(
        from: try proposal.toDTO(
          speakerUsername: proposal.paperCallUsername ?? proposal.speaker.username,
          conference: proposal.conference
        ))
    }
  }

  @Sendable
  func getOne(req: Request) async throws -> ProposalDTOContent {
    _ = try await AdminAPIService.requireAdmin(req)
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
        speakerUsername: proposal.paperCallUsername ?? proposal.speaker.username,
        conference: proposal.conference
      ))
  }

  @Sendable
  func create(req: Request) async throws -> ProposalDTOContent {
    _ = try await AdminAPIService.requireAdmin(req)
    let request = try req.content.decode(AdminProposalRequestContent.self)
    let talkDuration = try request.validate()

    guard try await Conference.find(request.conferenceId, on: req.db) != nil else {
      throw Abort(.notFound, reason: "Conference not found")
    }
    let speakerID = try await AdminAPIService.resolveSpeakerID(
      githubUsername: request.githubUsername, on: req.db)

    let proposal = Proposal(
      conferenceID: request.conferenceId,
      title: request.title,
      abstract: request.abstract,
      talkDetail: request.talkDetail,
      talkDuration: talkDuration,
      speakerName: request.speakerName,
      speakerEmail: request.speakerEmail,
      bio: request.bio,
      bioJa: request.bioJa?.isEmpty == true ? nil : request.bioJa,
      jobTitle: request.jobTitle?.isEmpty == true ? nil : request.jobTitle,
      jobTitleJa: request.jobTitleJa?.isEmpty == true ? nil : request.jobTitleJa,
      iconURL: request.iconURL?.isEmpty == true ? nil : request.iconURL,
      notes: request.notes?.isEmpty == true ? nil : request.notes,
      speakerID: speakerID,
      titleJA: request.titleJA?.isEmpty == true ? nil : request.titleJA,
      abstractJA: request.abstractJA?.isEmpty == true ? nil : request.abstractJA,
      workshopDetails: talkDuration.isWorkshop ? request.workshopDetails : nil,
      coInstructors: talkDuration.isWorkshop ? request.coInstructors : nil
    )
    proposal.workshopDetailsJA = talkDuration.isWorkshop ? request.workshopDetailsJA : nil
    let githubUsername =
      request.githubUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !githubUsername.isEmpty {
      proposal.paperCallUsername = githubUsername
      proposal.githubUsername = githubUsername
    }

    try await proposal.save(on: req.db)
    guard
      let saved = try await Proposal.query(on: req.db)
        .filter(\.$id == proposal.id!)
        .with(\.$speaker)
        .with(\.$conference)
        .first()
    else {
      throw Abort(.internalServerError, reason: "Failed to reload proposal")
    }
    return ProposalDTOContent(
      from: try saved.toDTO(
        speakerUsername: saved.paperCallUsername ?? saved.speaker.username,
        conference: saved.conference
      ))
  }

  @Sendable
  func update(req: Request) async throws -> ProposalDTOContent {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }
    guard
      let proposal = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .with(\.$conference)
        .first()
    else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    let request = try req.content.decode(AdminProposalRequestContent.self)
    let talkDuration = try request.validate()
    guard try await Conference.find(request.conferenceId, on: req.db) != nil else {
      throw Abort(.notFound, reason: "Conference not found")
    }

    let githubUsername =
      request.githubUsername?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let speakerID = try await AdminAPIService.resolveSpeakerID(
      githubUsername: request.githubUsername, on: req.db)

    proposal.$conference.id = request.conferenceId
    proposal.$speaker.id = speakerID
    proposal.title = request.title
    proposal.abstract = request.abstract
    proposal.talkDetail = request.talkDetail
    proposal.talkDuration = talkDuration
    proposal.speakerName = request.speakerName
    proposal.speakerEmail = request.speakerEmail
    proposal.bio = request.bio
    proposal.bioJa = request.bioJa?.isEmpty == true ? nil : request.bioJa
    proposal.jobTitle = request.jobTitle?.isEmpty == true ? nil : request.jobTitle
    proposal.jobTitleJa = request.jobTitleJa?.isEmpty == true ? nil : request.jobTitleJa
    proposal.iconURL = request.iconURL?.isEmpty == true ? nil : request.iconURL
    proposal.notes = request.notes?.isEmpty == true ? nil : request.notes
    proposal.titleJA = request.titleJA?.isEmpty == true ? nil : request.titleJA
    proposal.abstractJA = request.abstractJA?.isEmpty == true ? nil : request.abstractJA
    proposal.paperCallUsername = githubUsername.isEmpty ? nil : githubUsername
    proposal.githubUsername = githubUsername.isEmpty ? nil : githubUsername
    proposal.workshopDetails = talkDuration.isWorkshop ? request.workshopDetails : nil
    proposal.workshopDetailsJA = talkDuration.isWorkshop ? request.workshopDetailsJA : nil
    proposal.coInstructors =
      talkDuration.isWorkshop ? request.coInstructors.map(CoInstructorList.init) : nil

    try await proposal.save(on: req.db)
    guard
      let saved = try await Proposal.query(on: req.db)
        .filter(\.$id == proposalID)
        .with(\.$speaker)
        .with(\.$conference)
        .first()
    else {
      throw Abort(.internalServerError, reason: "Failed to reload proposal")
    }
    return ProposalDTOContent(
      from: try saved.toDTO(
        speakerUsername: saved.paperCallUsername ?? saved.speaker.username,
        conference: saved.conference
      ))
  }

  @Sendable
  func delete(req: Request) async throws -> HTTPStatus {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }
    guard let proposal = try await Proposal.find(proposalID, on: req.db) else {
      throw Abort(.notFound, reason: "Proposal not found")
    }
    try await proposal.delete(on: req.db)
    return .noContent
  }

  @Sendable
  func changeStatus(req: Request) async throws -> HTTPStatus {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let proposalID = req.parameters.get("proposalID", as: UUID.self) else {
      throw Abort(.badRequest, reason: "Invalid proposal ID")
    }
    guard let proposal = try await Proposal.find(proposalID, on: req.db) else {
      throw Abort(.notFound, reason: "Proposal not found")
    }
    let request = try req.content.decode(ProposalStatusChangeRequestContent.self)
    proposal.status = try request.decodedStatus()
    try await proposal.save(on: req.db)
    return .ok
  }

  @Sendable
  func lookupUser(req: Request) async throws -> AdminUserLookupResponse {
    _ = try await AdminAPIService.requireAdmin(req)
    guard let username = req.parameters.get("username") else {
      throw Abort(.badRequest, reason: "Username is required")
    }
    guard
      let user = try await User.query(on: req.db)
        .filter(\.$username == username)
        .first()
    else {
      throw Abort(.notFound)
    }
    return AdminUserLookupResponse(
      name: user.displayName,
      email: user.email,
      bio: user.bio,
      avatarURL: user.avatarURL
    )
  }

  @Sendable
  func exportCSV(req: Request) async throws -> Response {
    _ = try await AdminAPIService.requireAdmin(req)

    let conferencePath = req.query[String.self, at: "conference"]
    let query = Proposal.query(on: req.db)
      .with(\.$speaker)
      .with(\.$conference)
      .sort(\.$createdAt, .descending)

    if let conferencePath,
      let conference = try await Conference.query(on: req.db)
        .filter(\.$path == conferencePath)
        .first(),
      let conferenceID = conference.id
    {
      query.filter(\.$conference.$id == conferenceID)
    }

    let proposals = try await query.all()
    var csv =
      "ID,Title,Title (JA),Abstract,Abstract (JA),Talk Details,Type,Status,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At,Co-Instructors\n"
    let formatter = ISO8601DateFormatter()

    for proposal in proposals {
      let coInstructorSummary =
        proposal.coInstructors?.items.map {
          "\($0.name) <\($0.email)> @\($0.githubUsername)"
        }.joined(separator: "; ") ?? ""
      let row = [
        proposal.id?.uuidString ?? "",
        escapeCSV(proposal.title),
        escapeCSV(proposal.titleJA ?? ""),
        escapeCSV(proposal.abstract),
        escapeCSV(proposal.abstractJA ?? ""),
        escapeCSV(proposal.talkDetail),
        proposal.talkDuration.rawValue,
        proposal.status.rawValue,
        escapeCSV(proposal.speakerName),
        escapeCSV(proposal.speakerEmail),
        escapeCSV(
          proposal.githubUsername ?? proposal.paperCallUsername ?? proposal.speaker.username),
        escapeCSV(proposal.bio),
        escapeCSV(proposal.iconURL ?? ""),
        escapeCSV(proposal.notes ?? ""),
        escapeCSV(proposal.conference.displayName),
        proposal.createdAt.map(formatter.string(from:)) ?? "",
        escapeCSV(coInstructorSummary),
      ]
      csv += row.joined(separator: ",") + "\n"
    }

    var headers = HTTPHeaders()
    headers.contentType = .plainText
    headers.add(
      name: .contentDisposition,
      value: "attachment; filename=\"proposals.csv\"")
    return Response(status: .ok, headers: headers, body: .init(string: csv))
  }

  private func escapeCSV(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  @Sendable
  func exportSpeakers(req: Request) async throws -> Response {
    _ = try await AdminAPIService.requireAdmin(req)

    let conference: Conference
    if let conferencePath = req.query[String.self, at: "conference"] {
      guard
        let found = try await Conference.query(on: req.db)
          .filter(\.$path == conferencePath)
          .first()
      else {
        throw Abort(.notFound, reason: "Conference not found")
      }
      conference = found
    } else {
      guard
        let found = try await Conference.query(on: req.db)
          .sort(\.$year, .descending)
          .first()
      else {
        throw Abort(.notFound, reason: "No conferences available")
      }
      conference = found
    }

    guard let conferenceID = conference.id else {
      throw Abort(.internalServerError, reason: "Conference has no ID")
    }

    let proposals = try await Proposal.query(on: req.db)
      .filter(\.$status == .accepted)
      .filter(\.$conference.$id == conferenceID)
      .sort(\.$speakerName, .ascending)
      .all()

    let speakers = proposals.map { proposal -> SpeakerExportDTO in
      let imageName = proposal.speakerName.lowercased().replacingOccurrences(of: " ", with: "_")
      var links: [TimetableExportLink] = []
      if let githubUsername = proposal.githubUsername, !githubUsername.isEmpty {
        links.append(
          TimetableExportLink(
            name: "@\(githubUsername)", url: "https://github.com/\(githubUsername)")
        )
      }
      return SpeakerExportDTO(
        name: proposal.speakerName,
        imageName: imageName,
        bio: proposal.bio,
        bioJa: proposal.bioJa,
        jobTitle: proposal.jobTitle,
        jobTitleJa: proposal.jobTitleJa,
        links: links
      )
    }

    return try AdminAPIService.encodeJSONAttachment(
      speakers, filename: "\(conference.year)-speakers.json")
  }

  @Sendable
  func importProposals(req: Request) async throws -> HTTPStatus {
    _ = try await AdminAPIService.requireAdmin(req)

    struct ImportRequest: Content {
      var csvFile: File
      var conferenceId: UUID
      var skipDuplicates: Bool?
      var githubUsername: String?
    }

    let request = try req.content.decode(ImportRequest.self)
    let filename = request.csvFile.filename.lowercased()
    guard filename.hasSuffix(".csv") || filename.hasSuffix(".json") else {
      throw Abort(.badRequest, reason: "Please upload a CSV or JSON file")
    }
    let fileContent = String(buffer: request.csvFile.data)
    guard let conference = try await Conference.find(request.conferenceId, on: req.db),
      let conferenceID = conference.id
    else {
      throw Abort(.notFound, reason: "Conference not found")
    }

    let speakerID = try await AdminAPIService.resolveSpeakerID(
      githubUsername: request.githubUsername, on: req.db)
    let skipDuplicates = request.skipDuplicates ?? false

    if filename.hasSuffix(".json") {
      let parsedProposals = try PaperCallJSONParser.parse(fileContent)
      for parsed in parsedProposals {
        if skipDuplicates {
          let existing = try await Proposal.query(on: req.db)
            .filter(\.$speakerEmail == parsed.speakerEmail)
            .filter(\.$title == parsed.title)
            .filter(\.$conference.$id == conferenceID)
            .first()
          if existing != nil { continue }
        }
        let proposal = Proposal(
          conferenceID: conferenceID,
          title: parsed.title,
          abstract: parsed.abstract,
          talkDetail: parsed.talkDetails,
          talkDuration: TalkDuration.fromPaperCall(parsed.duration),
          speakerName: parsed.speakerName,
          speakerEmail: parsed.speakerEmail,
          bio: parsed.bio,
          iconURL: parsed.iconURL,
          notes: parsed.notes,
          speakerID: speakerID
        )
        proposal.paperCallUsername = parsed.speakerUsername.isEmpty ? nil : parsed.speakerUsername
        try await proposal.save(on: req.db)
      }
    } else {
      let parsedProposals = try SpeakersCSVParser.parse(fileContent)
      for parsed in parsedProposals {
        if skipDuplicates {
          let existing = try await Proposal.query(on: req.db)
            .filter(\.$speakerEmail == parsed.email)
            .filter(\.$title == parsed.title)
            .filter(\.$conference.$id == conferenceID)
            .first()
          if existing != nil { continue }
        }
        let proposal = Proposal(
          conferenceID: conferenceID,
          title: parsed.title,
          abstract: parsed.summary,
          talkDetail: parsed.talkDetail,
          talkDuration: .regular,
          speakerName: parsed.name,
          speakerEmail: parsed.email,
          bio: parsed.bio,
          iconURL: SpeakersCSVParser.githubAvatarURL(from: parsed.github),
          notes: SpeakersCSVParser.buildNotes(from: parsed),
          speakerID: speakerID
        )
        let githubUsername = SpeakersCSVParser.extractGitHubUsername(from: parsed.github)
        proposal.githubUsername = githubUsername.isEmpty ? nil : githubUsername
        proposal.paperCallUsername = githubUsername.isEmpty ? nil : githubUsername
        try await proposal.save(on: req.db)
      }
    }

    return .created
  }
}
