import Vapor

enum SponsorSlackNotifier {
  static func notifyInquiry(
    companyName: String,
    planSlug: String?,
    client: Client,
    logger: Logger
  ) async {
    await post(
      text:
        ":mailbox: 新しいスポンサーお問い合わせ\n*会社:* \(companyName)\n*希望プラン:* \(planSlug ?? "未指定")",
      client: client,
      logger: logger
    )
  }

  static func notifyApplicationSubmitted(
    orgName: String,
    planName: String,
    client: Client,
    logger: Logger
  ) async {
    await post(
      text: ":hourglass_flowing_sand: 新しい申込\n*会社:* \(orgName)\n*プラン:* \(planName)",
      client: client,
      logger: logger
    )
  }

  static func notifyDecision(
    orgName: String,
    planName: String,
    decision: String,
    client: Client,
    logger: Logger
  ) async {
    await post(
      text: ":white_check_mark: \(decision)\n*会社:* \(orgName)\n*プラン:* \(planName)",
      client: client,
      logger: logger
    )
  }

  private static func post(text: String, client: Client, logger: Logger) async {
    guard
      let url = Environment.get("SPONSOR_SLACK_WEBHOOK_URL")
        ?? Environment.get("SLACK_WEBHOOK_URL"),
      !url.isEmpty
    else {
      logger.debug("Sponsor Slack webhook not configured, skipping")
      return
    }
    struct Payload: Encodable { let text: String }
    do {
      let response = try await client.post(URI(string: url)) { req in
        req.headers.contentType = .json
        try req.content.encode(Payload(text: text), as: .json)
      }
      if response.status != .ok {
        logger.warning(
          "Sponsor Slack non-OK",
          metadata: ["status": .stringConvertible(response.status.code)]
        )
      }
    } catch {
      logger.warning("Sponsor Slack send error: \(error)")
    }
  }
}
