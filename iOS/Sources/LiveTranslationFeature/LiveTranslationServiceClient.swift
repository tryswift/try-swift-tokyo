import Dependencies
import DependenciesMacros
import Foundation
import LiveTranslationSDK
import Observation

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

public struct StoreState: Equatable, Sendable {
  public var isConnected: Bool
  public var chatList: [ChatItemEntity]
  public var supportLanguages: [LanguageItemEntity]
  public var dstLangCode: String?
  public var roomTitle: String?
  public var lastErrorMessage: String?

  public init(
    isConnected: Bool = false,
    chatList: [ChatItemEntity] = [],
    supportLanguages: [LanguageItemEntity] = [],
    dstLangCode: String? = nil,
    roomTitle: String? = nil,
    lastErrorMessage: String? = nil
  ) {
    self.isConnected = isConnected
    self.chatList = chatList
    self.supportLanguages = supportLanguages
    self.dstLangCode = dstLangCode
    self.roomTitle = roomTitle
    self.lastErrorMessage = lastErrorMessage
  }
}

@DependencyClient
public struct LiveTranslationServiceClient: Sendable {
  public var connect: @Sendable (_ interactionKey: String, _ dstLangCode: String?) async -> Void
  public var disconnect: @Sendable () async -> Void
  public var requestTranslationLanguage: @Sendable (_ langCode: String) async -> Void
  public var stateStream: @Sendable () -> AsyncStream<StoreState> = { .never }
}

extension LiveTranslationServiceClient: DependencyKey {
  public static let liveValue: Self = {
    final class Ref: @unchecked Sendable {
      @MainActor var store: ChatAudienceStore?
    }
    let ref = Ref()

    return Self(
      connect: { interactionKey, dstLangCode in
        await MainActor.run {
          if ref.store == nil {
            ref.store = ChatAudienceStore()
          }
          ref.store?.connect(interactionKey: interactionKey, dstLangCode: dstLangCode)
        }
      },
      disconnect: {
        await MainActor.run {
          ref.store?.disconnect()
        }
      },
      requestTranslationLanguage: { langCode in
        await MainActor.run {
          ref.store?.requestTranslationLanguage(langCode)
        }
      },
      stateStream: {
        AsyncStream { continuation in
          let task = Task { @MainActor in
            guard let store = ref.store else {
              continuation.finish()
              return
            }

            func snapshot() -> StoreState {
              MainActor.assumeIsolated {
                StoreState(
                  isConnected: store.isConnected,
                  chatList: store.chatList,
                  supportLanguages: store.supportLanguages,
                  dstLangCode: store.dstLangCode,
                  roomTitle: store.roomTitle,
                  lastErrorMessage: store.lastErrorMessage
                )
              }
            }

            continuation.yield(snapshot())

            while !Task.isCancelled {
              await withCheckedContinuation { resume in
                withObservationTracking {
                  MainActor.assumeIsolated {
                    _ = store.isConnected
                    _ = store.chatList
                    _ = store.supportLanguages
                    _ = store.dstLangCode
                    _ = store.roomTitle
                    _ = store.lastErrorMessage
                  }
                } onChange: {
                  resume.resume()
                }
              }
              continuation.yield(snapshot())
            }
            continuation.finish()
          }
          continuation.onTermination = { _ in
            task.cancel()
          }
        }
      }
    )
  }()
}
