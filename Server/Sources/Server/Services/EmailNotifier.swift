import Vapor

/// Service for sending emails via an HTTP email API (e.g. Resend)
enum EmailNotifier {

  /// Result of an email send attempt
  struct SendResult: Sendable {
    let success: Bool
    let recipientEmail: String
    let error: String?
  }

  /// Send an acceptance email to a speaker
  static func sendAcceptanceEmail(
    speakerName: String,
    speakerEmail: String,
    proposalTitle: String,
    language: CfPLanguage,
    client: Client,
    logger: Logger
  ) async -> SendResult {
    let subject = EmailTemplates.Acceptance.subject(language)
    let html = EmailTemplates.Acceptance.body(
      language, speakerName: speakerName, proposalTitle: proposalTitle)
    return await sendEmail(
      to: speakerEmail, subject: subject, html: html, client: client, logger: logger)
  }

  /// Send a rejection email to a speaker
  static func sendRejectionEmail(
    speakerName: String,
    speakerEmail: String,
    proposalTitle: String,
    language: CfPLanguage,
    client: Client,
    logger: Logger
  ) async -> SendResult {
    let subject = EmailTemplates.Rejection.subject(language)
    let html = EmailTemplates.Rejection.body(
      language, speakerName: speakerName, proposalTitle: proposalTitle)
    return await sendEmail(
      to: speakerEmail, subject: subject, html: html, client: client, logger: logger)
  }

  /// Send bulk emails to proposals matching a given type
  static func sendBulkEmails(
    proposals: [(speakerName: String, speakerEmail: String, proposalTitle: String)],
    emailType: EmailType,
    language: CfPLanguage,
    client: Client,
    logger: Logger
  ) async -> [SendResult] {
    var results: [SendResult] = []
    for proposal in proposals {
      let result: SendResult
      switch emailType {
      case .acceptance:
        result = await sendAcceptanceEmail(
          speakerName: proposal.speakerName,
          speakerEmail: proposal.speakerEmail,
          proposalTitle: proposal.proposalTitle,
          language: language,
          client: client,
          logger: logger
        )
      case .rejection:
        result = await sendRejectionEmail(
          speakerName: proposal.speakerName,
          speakerEmail: proposal.speakerEmail,
          proposalTitle: proposal.proposalTitle,
          language: language,
          client: client,
          logger: logger
        )
      }
      results.append(result)
      // Small delay between sends to avoid rate limiting
      try? await Task.sleep(for: .milliseconds(100))
    }
    return results
  }

  // MARK: - Private

  private static func sendEmail(
    to email: String,
    subject: String,
    html: String,
    client: Client,
    logger: Logger
  ) async -> SendResult {
    guard let apiKey = Environment.get("EMAIL_API_KEY") else {
      logger.debug("EMAIL_API_KEY not configured, skipping email")
      return SendResult(
        success: false, recipientEmail: email, error: "EMAIL_API_KEY not configured")
    }
    guard let fromAddress = Environment.get("EMAIL_FROM_ADDRESS") else {
      logger.debug("EMAIL_FROM_ADDRESS not configured, skipping email")
      return SendResult(
        success: false, recipientEmail: email, error: "EMAIL_FROM_ADDRESS not configured")
    }

    let apiURL = Environment.get("EMAIL_API_URL") ?? "https://api.resend.com/emails"

    let payload = EmailRequest(
      from: "try! Swift Tokyo <\(fromAddress)>",
      to: [email],
      subject: subject,
      html: html
    )

    do {
      let jsonData = try JSONEncoder().encode(payload)

      let response = try await client.post(URI(string: apiURL)) { req in
        req.headers.contentType = .json
        req.headers.bearerAuthorization = BearerAuthorization(token: apiKey)
        req.body = ByteBuffer(data: jsonData)
      }

      if response.status == .ok || response.status == .created {
        logger.info("Email sent to \(email): \(subject)")
        return SendResult(success: true, recipientEmail: email, error: nil)
      } else {
        let bodyStr = response.body.map { String(buffer: $0) } ?? "no body"
        logger.warning("Email API responded \(response.status.code) for \(email): \(bodyStr)")
        return SendResult(
          success: false, recipientEmail: email,
          error: "API returned \(response.status.code)")
      }
    } catch {
      logger.warning("Failed to send email to \(email): \(error)")
      return SendResult(
        success: false, recipientEmail: email, error: error.localizedDescription)
    }
  }
}

// MARK: - API Request Model

private struct EmailRequest: Encodable {
  let from: String
  let to: [String]
  let subject: String
  let html: String
}
