import Vapor

/// Client for Luma (lu.ma) public API
enum LumaClient {

  private static let baseURL = "https://public-api.luma.com/v1"

  /// Check if an email has a ticket for the given event
  static func getGuest(
    email: String,
    eventID: String? = nil,
    client: Client,
    logger: Logger
  ) async throws -> LumaGuest? {
    guard let apiKey = Environment.get("LUMA_API_KEY") else {
      logger.warning("LUMA_API_KEY not configured")
      throw Abort(.internalServerError, reason: "Luma API not configured")
    }

    let lumaEventID: String
    if let explicitEventID = eventID {
      lumaEventID = explicitEventID
    } else if let configuredEventID = Environment.get("LUMA_EVENT_ID") {
      lumaEventID = configuredEventID
    } else {
      logger.error("LUMA_EVENT_ID not configured and no eventID provided")
      throw Abort(.internalServerError, reason: "Luma event ID not configured")
    }
    var components = URLComponents(string: "\(baseURL)/event/get-guest")!
    components.queryItems = [
      URLQueryItem(name: "event_id", value: lumaEventID),
      URLQueryItem(name: "id", value: email),
    ]
    // URLComponents leaves + unencoded (valid per RFC 3986), but many servers
    // interpret + as space per x-www-form-urlencoded. Encode it explicitly.
    components.percentEncodedQuery = components.percentEncodedQuery?
      .replacingOccurrences(of: "+", with: "%2B")
    let url = components.string!

    let response = try await client.get(URI(string: url)) { req in
      req.headers.add(name: "x-luma-api-key", value: apiKey)
    }

    guard response.status == .ok else {
      if response.status == .notFound {
        return nil
      }
      let body = response.body.map { String(buffer: $0) } ?? "no body"
      let truncatedBody = body.count > 1000 ? String(body.prefix(1000)) + "… (truncated)" : body
      logger.error(
        "Luma get-guest returned status \(response.status.code) for email: \(email) - \(truncatedBody)"
      )
      throw Abort(.badGateway, reason: "Luma API returned \(response.status.code)")
    }

    return try response.content.decode(LumaGetGuestResponse.self).guest
  }

  /// Create a new event on Luma
  static func createEvent(
    name: String,
    descriptionMd: String,
    startAt: String,
    endAt: String,
    timezone: String = "Asia/Tokyo",
    client: Client,
    logger: Logger
  ) async throws -> LumaEventResponse {
    guard let apiKey = Environment.get("LUMA_API_KEY") else {
      throw Abort(.internalServerError, reason: "Luma API not configured")
    }

    let payload = LumaCreateEventRequest(
      name: name,
      description_md: descriptionMd,
      start_at: startAt,
      end_at: endAt,
      timezone: timezone
    )

    let response = try await client.post(URI(string: "\(baseURL)/event/create")) { req in
      req.headers.add(name: "x-luma-api-key", value: apiKey)
      req.headers.contentType = .json
      try req.content.encode(payload)
    }

    guard response.status == .ok || response.status == .created else {
      let body = response.body.map { String(buffer: $0) } ?? "no body"
      logger.error("Luma create-event failed: \(response.status.code) - \(body)")
      throw Abort(.badGateway, reason: "Failed to create Luma event")
    }

    return try response.content.decode(LumaEventResponse.self)
  }

  /// Add a guest to a Luma event (sends them a ticket)
  static func addGuestToEvent(
    eventID: String,
    email: String,
    name: String,
    client: Client,
    logger: Logger
  ) async throws -> LumaAddGuestResponse {
    guard let apiKey = Environment.get("LUMA_API_KEY") else {
      throw Abort(.internalServerError, reason: "Luma API not configured")
    }

    let payload = LumaAddGuestRequest(
      event_id: eventID,
      email: email,
      name: name
    )

    let response = try await client.post(URI(string: "\(baseURL)/event/add-guest")) { req in
      req.headers.add(name: "x-luma-api-key", value: apiKey)
      req.headers.contentType = .json
      try req.content.encode(payload)
    }

    guard response.status == .ok || response.status == .created else {
      let body = response.body.map { String(buffer: $0) } ?? "no body"
      logger.error("Luma add-guest failed: \(response.status.code) - \(body)")
      throw Abort(.badGateway, reason: "Failed to add guest to Luma event")
    }

    return try response.content.decode(LumaAddGuestResponse.self)
  }
}

// MARK: - Luma API Models

/// Wrapper for GET /event/get-guest response
private struct LumaGetGuestResponse: Content, Sendable {
  let guest: LumaGuest
}

struct LumaGuest: Content, Sendable {
  let id: String?
  let user_email: String?
  let user_name: String?
  let user_first_name: String?
  let user_last_name: String?
  let approval_status: String?

  /// Check if guest has an approved ticket
  var hasTicket: Bool {
    approval_status == "approved"
  }

  var displayName: String {
    if let name = user_name, !name.isEmpty { return name }
    return [user_first_name, user_last_name].compactMap { $0 }.joined(separator: " ")
  }
}

struct LumaCreateEventRequest: Content, Sendable {
  let name: String
  let description_md: String
  let start_at: String
  let end_at: String
  let timezone: String
}

struct LumaEventResponse: Content, Sendable {
  let id: String
  let name: String?
  let url: String?
}

struct LumaAddGuestRequest: Content, Sendable {
  let event_id: String
  let email: String
  let name: String
}

struct LumaAddGuestResponse: Content, Sendable {
  let id: String?
  let email: String?
}
