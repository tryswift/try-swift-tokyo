import Fluent
import JWT
import Vapor

struct FeedbackSubmission: Content {
  let proposalId: UUID
  let comment: String
  let deviceId: String
}

struct FeedbackResponse: Content {
  let id: UUID
  let comment: String
  let createdAt: Date?
}

struct FeedbackForTalk: Content {
  let proposalId: UUID
  let proposalTitle: String
  let feedbacks: [FeedbackResponse]
}

struct FeedbackController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let feedback = routes.grouped("feedback")

    // Public: submit anonymous feedback
    feedback.post(use: submitFeedback)

    // Authenticated: speaker views their feedback
    let authenticated = feedback.grouped(AuthMiddleware())
    authenticated.get("my-talks", use: getMyTalksFeedback)
  }

  /// POST /api/v1/feedback
  @Sendable
  func submitFeedback(req: Request) async throws -> HTTPStatus {
    let submission = try req.content.decode(FeedbackSubmission.self)

    guard !submission.deviceId.isEmpty else {
      throw Abort(.badRequest, reason: "deviceId is required")
    }

    let comment = submission.comment.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !comment.isEmpty else {
      throw Abort(.badRequest, reason: "Comment cannot be empty")
    }
    guard comment.count <= 2000 else {
      throw Abort(.badRequest, reason: "Comment must be 2000 characters or fewer")
    }

    // Verify proposal exists
    guard (try await Proposal.find(submission.proposalId, on: req.db)) != nil else {
      throw Abort(.notFound, reason: "Proposal not found")
    }

    // Rate limit: max 3 feedback per device per proposal
    let existingCount = try await Feedback.query(on: req.db)
      .filter(\.$proposal.$id == submission.proposalId)
      .filter(\.$deviceID == submission.deviceId)
      .count()
    guard existingCount < 3 else {
      throw Abort(.tooManyRequests, reason: "Feedback limit reached for this talk")
    }

    let feedback = Feedback(
      proposalID: submission.proposalId,
      comment: comment,
      deviceID: submission.deviceId
    )
    try await feedback.save(on: req.db)

    return .created
  }

  /// GET /api/v1/feedback/my-talks
  @Sendable
  func getMyTalksFeedback(req: Request) async throws -> [FeedbackForTalk] {
    let payload = try await req.jwt.verify(as: UserJWTPayload.self)
    guard let userID = payload.userID else {
      throw Abort(.unauthorized)
    }

    let proposals = try await Proposal.query(on: req.db)
      .filter(\.$speaker.$id == userID)
      .all()

    let proposalIDs = proposals.compactMap(\.id)
    guard !proposalIDs.isEmpty else { return [] }

    // Batch fetch all feedbacks in one query
    let allFeedbacks = try await Feedback.query(on: req.db)
      .filter(\.$proposal.$id ~~ proposalIDs)
      .sort(\.$createdAt, .descending)
      .all()

    let feedbacksByProposal = Dictionary(grouping: allFeedbacks) { $0.$proposal.id }

    var result: [FeedbackForTalk] = []
    for proposal in proposals {
      guard let proposalID = proposal.id,
        let feedbacks = feedbacksByProposal[proposalID],
        !feedbacks.isEmpty
      else { continue }

      result.append(
        FeedbackForTalk(
          proposalId: proposalID,
          proposalTitle: proposal.title,
          feedbacks: feedbacks.compactMap { fb in
            guard let id = fb.id else { return nil }
            return FeedbackResponse(id: id, comment: fb.comment, createdAt: fb.createdAt)
          }
        ))
    }

    return result
  }
}
