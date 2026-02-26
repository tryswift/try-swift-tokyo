import Vapor

/// Service for sending notifications to Slack via Incoming Webhooks
enum SlackNotifier {

  /// Send a notification when a new proposal is submitted
  static func notifyNewProposal(
    title: String,
    speakerName: String,
    talkDuration: String,
    client: Client,
    logger: Logger
  ) async {
    guard let webhookURL = Environment.get("SLACK_WEBHOOK_URL") else {
      logger.debug("SLACK_WEBHOOK_URL not configured, skipping notification")
      return
    }

    let durationText: String
    switch talkDuration {
    case "LT": durationText = "LT (5min)"
    case "workshop": durationText = "Workshop"
    case "invited": durationText = "Invited (20min)"
    default: durationText = "20min"
    }

    let payload = SlackMessage(
      blocks: [
        SlackBlock(
          type: "header",
          text: SlackTextObject(type: "plain_text", text: "📝 新しいCfPプロポーザルが投稿されました")
        ),
        SlackBlock(
          type: "section",
          fields: [
            SlackTextObject(type: "mrkdwn", text: "*タイトル:*\n\(title)"),
            SlackTextObject(type: "mrkdwn", text: "*スピーカー:*\n\(speakerName)"),
            SlackTextObject(type: "mrkdwn", text: "*時間:*\n\(durationText)"),
          ]
        ),
      ]
    )

    do {
      let jsonData = try JSONEncoder().encode(payload)

      let response = try await client.post(URI(string: webhookURL)) { req in
        req.headers.contentType = .json
        req.body = ByteBuffer(data: jsonData)
      }

      if response.status == .ok {
        logger.info("Slack notification sent for proposal: \(title)")
      } else {
        logger.warning(
          "Slack notification failed with status \(response.status.code) for proposal: \(title)")
      }
    } catch {
      logger.warning("Failed to send Slack notification: \(error)")
    }
  }
  /// Send a notification when a new scholarship application is submitted
  static func notifyNewScholarshipApplication(
    name: String,
    school: String,
    supportType: String,
    client: Client,
    logger: Logger
  ) async {
    guard let webhookURL = Environment.get("SLACK_WEBHOOK_URL") else {
      logger.debug("SLACK_WEBHOOK_URL not configured, skipping notification")
      return
    }

    let supportText: String
    switch supportType {
    case "ticket_and_travel": supportText = "チケット＋旅費"
    default: supportText = "チケットのみ"
    }

    let payload = SlackMessage(
      blocks: [
        SlackBlock(
          type: "header",
          text: SlackTextObject(
            type: "plain_text", text: "🎓 新しい学生スカラシップ申請が届きました")
        ),
        SlackBlock(
          type: "section",
          fields: [
            SlackTextObject(type: "mrkdwn", text: "*名前:*\n\(name)"),
            SlackTextObject(type: "mrkdwn", text: "*学校:*\n\(school)"),
            SlackTextObject(type: "mrkdwn", text: "*サポート種別:*\n\(supportText)"),
          ]
        ),
      ]
    )

    do {
      let jsonData = try JSONEncoder().encode(payload)

      let response = try await client.post(URI(string: webhookURL)) { req in
        req.headers.contentType = .json
        req.body = ByteBuffer(data: jsonData)
      }

      if response.status == .ok {
        logger.info("Slack notification sent for scholarship application: \(name)")
      } else {
        logger.warning(
          "Slack notification failed with status \(response.status.code) for scholarship: \(name)")
      }
    } catch {
      logger.warning("Failed to send Slack notification: \(error)")
    }
  }
}

// MARK: - Slack Block Kit Models

private struct SlackMessage: Encodable {
  let blocks: [SlackBlock]
}

private struct SlackBlock: Encodable {
  let type: String
  var text: SlackTextObject?
  var fields: [SlackTextObject]?
}

private struct SlackTextObject: Encodable {
  let type: String
  let text: String
}
