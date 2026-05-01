import Foundation
import Vapor

enum ResendClient {
  enum SendResult: Equatable, Sendable {
    case sent(messageID: String)
    case skipped
    case failed(status: UInt)
  }

  /// Send an email through the Resend HTTP API. Returns `.skipped` when no API key is configured.
  static func send(
    to: String,
    from: String,
    subject: String,
    html: String,
    text: String,
    client: Client,
    logger: Logger,
    env: [String: String?] = [:]
  ) async -> SendResult {
    let apiKey: String?
    if let override = env["RESEND_API_KEY"] {
      apiKey = override
    } else {
      apiKey = Environment.get("RESEND_API_KEY")
    }
    guard let apiKey, !apiKey.isEmpty else {
      logger.debug("RESEND_API_KEY not set, skipping email")
      return .skipped
    }

    struct Payload: Encodable {
      let from: String
      let to: [String]
      let subject: String
      let html: String
      let text: String
    }
    struct ResendResponse: Decodable { let id: String }

    let payload = Payload(from: from, to: [to], subject: subject, html: html, text: text)
    do {
      let response = try await client.post(URI(string: "https://api.resend.com/emails")) { req in
        req.headers.bearerAuthorization = .init(token: apiKey)
        req.headers.contentType = .json
        try req.content.encode(payload, as: .json)
      }
      if response.status.code >= 200 && response.status.code < 300 {
        let decoded = try response.content.decode(ResendResponse.self)
        logger.info("Resend OK", metadata: ["to": .string(to), "id": .string(decoded.id)])
        return .sent(messageID: decoded.id)
      }
      logger.warning(
        "Resend non-2xx",
        metadata: ["to": .string(to), "status": .stringConvertible(response.status.code)])
      return .failed(status: response.status.code)
    } catch {
      logger.warning(
        "Resend send error",
        metadata: ["error": .string(String(describing: error))])
      return .failed(status: 0)
    }
  }
}
