import Vapor

enum ScholarshipSlackNotifier {
  static func notifyNewApplication(
    name: String,
    school: String,
    supportType: String,
    client: Client,
    logger: Logger
  ) async {
    await post(
      text:
        ":mortar_board: 新しい学生スカラシップ申請\n*氏名:* \(name)\n*学校:* \(school)\n*支援タイプ:* \(supportType)",
      client: client,
      logger: logger
    )
  }

  static func notifyDecision(
    name: String,
    school: String,
    decision: String,
    approvedAmount: Int? = nil,
    client: Client,
    logger: Logger
  ) async {
    let amountLine = approvedAmount.map { "\n*承認額:* ¥\($0)" } ?? ""
    await post(
      text: ":white_check_mark: \(decision)\n*氏名:* \(name)\n*学校:* \(school)\(amountLine)",
      client: client,
      logger: logger
    )
  }

  private static func post(text: String, client: Client, logger: Logger) async {
    guard
      let url = Environment.get("SCHOLARSHIP_SLACK_WEBHOOK_URL")
        ?? Environment.get("SLACK_WEBHOOK_URL"),
      !url.isEmpty
    else {
      logger.debug("Scholarship Slack webhook not configured, skipping")
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
          "Scholarship Slack non-OK",
          metadata: ["status": .stringConvertible(response.status.code)]
        )
      }
    } catch {
      logger.warning("Scholarship Slack send error: \(error)")
    }
  }
}
