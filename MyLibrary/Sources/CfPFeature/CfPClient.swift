import CfPAPIClient
import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

/// API Client for CfP operations (TCA Dependency wrapper)
@DependencyClient
public struct CfPClient: Sendable {
  public var login: @Sendable () async throws -> AuthResponse
  public var getCurrentUser: @Sendable () async throws -> UserDTO
  public var getMyProposals: @Sendable () async throws -> [ProposalDTO]
  public var getOpenConferences: @Sendable () async throws -> [ConferenceDTO]
  public var createProposal: @Sendable (CreateProposalRequest) async throws -> ProposalDTO
  public var updateProposal: @Sendable (UUID, UpdateProposalRequest) async throws -> ProposalDTO
  public var deleteProposal: @Sendable (UUID) async throws -> Void
  
  public init(
    login: @escaping @Sendable () async throws -> AuthResponse = { throw CfPError.notImplemented },
    getCurrentUser: @escaping @Sendable () async throws -> UserDTO = { throw CfPError.notImplemented },
    getMyProposals: @escaping @Sendable () async throws -> [ProposalDTO] = { throw CfPError.notImplemented },
    getOpenConferences: @escaping @Sendable () async throws -> [ConferenceDTO] = { throw CfPError.notImplemented },
    createProposal: @escaping @Sendable (CreateProposalRequest) async throws -> ProposalDTO = { _ in throw CfPError.notImplemented },
    updateProposal: @escaping @Sendable (UUID, UpdateProposalRequest) async throws -> ProposalDTO = { _, _ in throw CfPError.notImplemented },
    deleteProposal: @escaping @Sendable (UUID) async throws -> Void = { _ in throw CfPError.notImplemented }
  ) {
    self.login = login
    self.getCurrentUser = getCurrentUser
    self.getMyProposals = getMyProposals
    self.getOpenConferences = getOpenConferences
    self.createProposal = createProposal
    self.updateProposal = updateProposal
    self.deleteProposal = deleteProposal
  }
}

public enum CfPError: Error, LocalizedError {
  case notImplemented
  case unauthorized
  case networkError(String)
  case serverError(String)
  
  public var errorDescription: String? {
    switch self {
    case .notImplemented:
      return "Feature not implemented"
    case .unauthorized:
      return "Please login to continue"
    case .networkError(let message):
      return "Network error: \(message)"
    case .serverError(let message):
      return "Server error: \(message)"
    }
  }
}

extension CfPClient: DependencyKey {
  public static var liveValue: CfPClient {
    let apiClient = CfPAPIClient(baseURL: URL(string: "https://cfp-api.tryswift.jp")!)
    
    return CfPClient(
      login: {
        // OAuth flow is handled externally, this returns mock for now
        // Real implementation would use ASWebAuthenticationSession
        throw CfPError.notImplemented
      },
      getCurrentUser: {
        try await apiClient.getCurrentUser()
      },
      getMyProposals: {
        try await apiClient.getMyProposals()
      },
      getOpenConferences: {
        try await apiClient.getOpenConferences()
      },
      createProposal: { request in
        try await apiClient.submitProposal(request)
      },
      updateProposal: { _, _ in
        throw CfPError.notImplemented
      },
      deleteProposal: { _ in
        throw CfPError.notImplemented
      }
    )
  }
  
  public static let testValue = CfPClient()
  
  public static let previewValue = CfPClient(
    login: {
      AuthResponse(
        token: "preview-token",
        user: UserDTO(
          id: UUID(),
          githubID: 12345,
          username: "preview_user",
          role: .speaker,
          avatarURL: nil
        )
      )
    },
    getCurrentUser: {
      UserDTO(
        id: UUID(),
        githubID: 12345,
        username: "preview_user",
        role: .speaker,
        avatarURL: nil
      )
    },
    getMyProposals: {
      [
        ProposalDTO(
          id: UUID(),
          title: "Building SwiftUI Apps with TCA",
          abstract: "Learn how to build scalable iOS apps using The Composable Architecture.",
          talkDetail: "This talk covers the fundamentals of TCA...",
          talkDuration: .regular,
          bio: "iOS Developer with 10 years of experience",
          iconURL: nil,
          notes: nil,
          speakerID: UUID(),
          speakerUsername: "preview_user",
          conferenceId: UUID(),
          conferencePath: "tryswift-tokyo-2026",
          conferenceDisplayName: "try! Swift Tokyo 2026",
          createdAt: Date(),
          updatedAt: nil
        )
      ]
    },
    getOpenConferences: {
      [
        ConferenceDTO(
          id: UUID(),
          path: "tryswift-tokyo-2026",
          displayName: "try! Swift Tokyo 2026",
          description: LocalizedString(
            en: "Submit your proposal for try! Swift Tokyo 2026!",
            ja: "try! Swift Tokyo 2026のプロポーザルを応募してください！"
          ),
          year: 2026,
          isOpen: true,
          deadline: Date().addingTimeInterval(60 * 60 * 24 * 30),
          startDate: Date().addingTimeInterval(60 * 60 * 24 * 90),
          endDate: Date().addingTimeInterval(60 * 60 * 24 * 92),
          createdAt: Date(),
          updatedAt: nil
        )
      ]
    },
    createProposal: { request in
      ProposalDTO(
        id: UUID(),
        conferenceId: UUID(),
        conferencePath: request.conferencePath,
        conferenceDisplayName: "try! Swift Tokyo 2026",
        title: request.title,
        abstract: request.abstract,
        talkDetail: request.talkDetail,
        talkDuration: request.talkDuration,
        bio: request.bio,
        iconURL: request.iconURL,
        notes: request.notes,
        speakerID: UUID(),
        speakerUsername: "preview_user",
        conferenceId: UUID(),
        conferencePath: request.conferencePath,
        conferenceDisplayName: "try! Swift Tokyo 2026",
        createdAt: Date(),
        updatedAt: nil
      )
    },
    updateProposal: { _, _ in
      ProposalDTO(
        id: UUID(),
        title: "Updated Proposal",
        abstract: "Updated abstract",
        talkDetail: "Updated detail",
        talkDuration: .regular,
        bio: "Updated bio",
        iconURL: nil,
        notes: nil,
        speakerID: UUID(),
        speakerUsername: "preview_user",
        conferenceId: UUID(),
        conferencePath: "tryswift-tokyo-2026",
        conferenceDisplayName: "try! Swift Tokyo 2026",
        createdAt: Date(),
        updatedAt: Date()
      )
    },
    deleteProposal: { _ in }
  )
}

extension DependencyValues {
  public var cfpClient: CfPClient {
    get { self[CfPClient.self] }
    set { self[CfPClient.self] = newValue }
  }
}
