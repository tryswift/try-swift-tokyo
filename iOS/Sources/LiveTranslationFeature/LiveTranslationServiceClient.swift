import Dependencies
import DependenciesMacros
import Foundation
@preconcurrency import LiveTranslationSDK_iOS

extension DependencyValues {
  public var liveTranslationServiceClient: LiveTranslationServiceClient {
    get {
      self[LiveTranslationServiceClient.self]
    }
    set {
      self[LiveTranslationServiceClient.self] = newValue
    }
  }
}

@DependencyClient
public struct LiveTranslationServiceClient: Sendable {
  public var langSet: @Sendable (String?) async throws -> LanguageEntity.Response.LangSet
  public var langList: @Sendable () async throws -> [LanguageEntity.Response.LanguageItem]
  public var chatRoomInfo: @Sendable (String) async throws -> ChatRoomEntity.Make.Response
  public var chatConnection:
    @Sendable (String) -> AsyncThrowingStream<RealTimeEntity.ChatStream, any Error> = { _ in .never
    }
  public var requestBatchTranslation:
    @Sendable ([RealTimeEntity.Translation.Request.ContentData]) async -> Void
}

extension LiveTranslationServiceClient: DependencyKey {
  public static let liveValue: Self = {
    let service = LiveTranslationService()
    return Self(
      langSet: { langCode in
        try await service.getLangSet(.init(langCode: langCode ?? LanguageCodeFunctor.deviceCode))
      },
      langList: {
        try await service.getLangList()
      },
      chatRoomInfo: { roomNumber in
        try await service.getChatRoomInfo(.init(interactionKey: roomNumber))
      },
      chatConnection: { roomNumber in
        service.chatConnection(.init(interactionKey: roomNumber))
      },
      requestBatchTranslation: { array in
        await service.requestBatchTranslation(.init(data: array))
      }
    )
  }()
}
