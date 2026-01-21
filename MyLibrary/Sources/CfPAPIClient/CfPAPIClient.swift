import Foundation
import SharedModels

/// CfP API Client for communicating with the trySwift CfP Server
public struct CfPAPIClient: Sendable {
  public var baseURL: URL
  public var token: String?
  
  public init(baseURL: URL, token: String? = nil) {
    self.baseURL = baseURL
    self.token = token
  }
  
  /// Create a client with authentication token
  public func authenticated(with token: String) -> CfPAPIClient {
    CfPAPIClient(baseURL: baseURL, token: token)
  }
  
  // MARK: - Auth
  
  /// Get the GitHub OAuth login URL
  public var githubLoginURL: URL {
    baseURL.appendingPathComponent("api/v1/auth/github")
  }
  
  /// Get the current authenticated user
  public func getCurrentUser() async throws -> UserDTO {
    try await request(.get, path: "api/v1/auth/me")
  }
  
  /// Update the current user's profile
  public func updateProfile(_ request: UpdateUserProfileRequest) async throws -> UserDTO {
    try await self.request(.put, path: "api/v1/auth/me", body: request)
  }
  
  // MARK: - Conferences
  
  /// Get all conferences
  public func getConferences() async throws -> [ConferenceDTO] {
    try await request(.get, path: "api/v1/conferences")
  }
  
  /// Get open conferences (accepting proposals)
  public func getOpenConferences() async throws -> [ConferenceDTO] {
    try await request(.get, path: "api/v1/conferences/open")
  }
  
  /// Get a conference by path
  public func getConference(path: String) async throws -> ConferenceDTO {
    try await request(.get, path: "api/v1/conferences/\(path)")
  }
  
  /// Create a new conference (admin only)
  public func createConference(_ conference: CreateConferenceRequest) async throws -> ConferenceDTO {
    try await request(.post, path: "api/v1/conferences", body: conference)
  }
  
  // MARK: - Proposals
  
  /// Submit a new proposal
  public func submitProposal(_ proposal: CreateProposalRequest) async throws -> ProposalDTO {
    try await request(.post, path: "api/v1/proposals", body: proposal)
  }
  
  /// Get my proposals
  public func getMyProposals() async throws -> [ProposalDTO] {
    try await request(.get, path: "api/v1/proposals/mine")
  }
  
  /// Get my proposals for a specific conference
  public func getMyProposals(conferencePath: String) async throws -> [ProposalDTO] {
    try await request(.get, path: "api/v1/proposals/mine/\(conferencePath)")
  }
  
  /// Get all proposals (admin only)
  public func getAllProposals() async throws -> [ProposalDTO] {
    try await request(.get, path: "api/v1/proposals")
  }
  
  /// Get proposals for a specific conference (admin only)
  public func getProposals(conferencePath: String) async throws -> [ProposalDTO] {
    try await request(.get, path: "api/v1/proposals/conference/\(conferencePath)")
  }
  
  /// Get a specific proposal (admin only)
  public func getProposal(id: UUID) async throws -> ProposalDTO {
    try await request(.get, path: "api/v1/proposals/\(id.uuidString)")
  }
  
  // MARK: - Private
  
  private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
  }
  
  private func request<T: Decodable>(_ method: HTTPMethod, path: String) async throws -> T {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response, data: data)
    
    return try JSONDecoder.api.decode(T.self, from: data)
  }
  
  private func request<T: Decodable, B: Encodable>(_ method: HTTPMethod, path: String, body: B) async throws -> T {
    let url = baseURL.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = try JSONEncoder.api.encode(body)
    
    if let token {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response, data: data)
    
    return try JSONDecoder.api.decode(T.self, from: data)
  }
  
  private func validateResponse(_ response: URLResponse, data: Data) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw CfPAPIError.invalidResponse
    }
    
    switch httpResponse.statusCode {
    case 200..<300:
      return
    case 401:
      throw CfPAPIError.unauthorized
    case 403:
      throw CfPAPIError.forbidden
    case 404:
      throw CfPAPIError.notFound
    case 400..<500:
      let message = try? JSONDecoder().decode(ErrorResponse.self, from: data)
      throw CfPAPIError.clientError(httpResponse.statusCode, message?.reason ?? "Unknown error")
    case 500..<600:
      throw CfPAPIError.serverError(httpResponse.statusCode)
    default:
      throw CfPAPIError.unknown(httpResponse.statusCode)
    }
  }
}

// MARK: - Error Types

public enum CfPAPIError: Error, LocalizedError, Sendable {
  case invalidResponse
  case unauthorized
  case forbidden
  case notFound
  case clientError(Int, String)
  case serverError(Int)
  case unknown(Int)
  
  public var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid response from server"
    case .unauthorized:
      return "Please sign in to continue"
    case .forbidden:
      return "You don't have permission to access this resource"
    case .notFound:
      return "Resource not found"
    case .clientError(_, let message):
      return message
    case .serverError(let code):
      return "Server error (\(code))"
    case .unknown(let code):
      return "Unknown error (\(code))"
    }
  }
}

private struct ErrorResponse: Decodable {
  let reason: String
}

// MARK: - JSON Coders

extension JSONDecoder {
  static let api: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()
}

extension JSONEncoder {
  static let api: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()
}
