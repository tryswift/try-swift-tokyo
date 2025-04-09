import ComposableArchitecture
import SwiftUI
import Foundation
import LiveTranslationSDK_iOS

@Reducer
public struct LiveTranslation {
  @ObservableState
  public struct State: Equatable {
    var roomNumber: String
    var chatList: [TranslationEntity.CompositeChatItem] = []
    var langSet: LanguageEntity.Response.LangSet? = .none
    var langList: [LanguageEntity.Response.LanguageItem] = []
    var roomInfo: ChatRoomEntity.Make.Response? = .none
    var selectedLangCode: String =
    Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
    
    var isUpdatingChat: Bool = false
    var isUpdatingTR: Bool = false
    var updateChatWaitingQueue: [RealTimeEntity.Chat.Response] = []
    var updateTrWaitingQueue: [RealTimeEntity.Translation.Response] = []
    var latestListType: RealTimeEntity.ListType? = .none
    
    public init(roomNumber: String) {
      self.roomNumber = roomNumber
    }
  }
  
  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case connectChatStream
    case changeLangCode(String)
    case view(View)
    
    case setLangSet(LanguageEntity.Response.LangSet)
    case setLangList([LanguageEntity.Response.LanguageItem])
    case setRoomInfo(ChatRoomEntity.Make.Response)
    
    case handleResponseChat(RealTimeEntity.Chat.Response)
    case handleResponseTranslation(RealTimeEntity.Translation.Response)
    
    public enum View {
      case onAppear
    }
  }
  
  @Dependency(\.liveTranslationServiceClient) var liveTranslationServiceClient
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        return .run { [state] send in
          await withTaskGroup(of: Void.self) { group in
            group.addTask {
              await loadLangSet(send: send)
            }
            group.addTask {
              do {
                let langList = try await liveTranslationServiceClient.langList()
                await send(
                  .setLangList(langList)
                )
              } catch {
                print(error)
              }
            }
            group.addTask {
              do {
                let roomInfo = try await liveTranslationServiceClient.chatRoomInfo(state.roomNumber)
                await send(
                  .setRoomInfo(roomInfo)
                )
              } catch {
                print(error)
              }
            }
          }
        }
      case .connectChatStream:
        return .run { [state] send in
          do {
            let stream = liveTranslationServiceClient.chatConnection(state.roomNumber)
            for try await action in stream {
              switch action {
              case .connect: break
              case .disconnect: break
              case .peerClosed:
                await send(.connectChatStream)
              case .responseChat(let chatItem):
                await send(.handleResponseChat(chatItem))
              case .responseBatchTranslation(let trItem):
                await send(.handleResponseTranslation(trItem))
              default: break
              }
            }
          } catch {
            print(error)
          }
        }
      case .changeLangCode(let newLangCode):
        state.selectedLangCode = newLangCode
        return .run { [state] send in
          await loadLangSet(langCode: newLangCode, send: send)
          await loadTranslation(chatList: state.chatList, newLangCode)
        }
      case .setLangSet(let langSet):
        state.langSet = langSet
        return .none
      case .setLangList(let langList):
        state.langList = langList
        return .none
      case .setRoomInfo(let roomInfo):
        state.roomInfo = roomInfo
        return .none
      case .handleResponseChat(let chatItem):
        return .none
      case .handleResponseTranslation(let trItem):
        return .none
      case .binding:
        return .none
      }
    }
  }
}

extension LiveTranslation {
  private func loadLangSet(langCode: String? = nil, send: Send<Action>) async {
    do {
      let langSet = try await liveTranslationServiceClient.langSet(langCode)
      await send(
        .setLangSet(langSet)
      )
    } catch {
      print(error)
    }
  }
  
  private func loadTranslation(
    chatList: [TranslationEntity.CompositeChatItem], _ dstLangCode: String
  ) async {
    await withTaskGroup(of: Void.self) { group in
      let chunkedArray = chatList.chunked(into: 20)
      for array in chunkedArray {
        group.addTask {
          let mutatedArray = array.map {
            RealTimeEntity.Translation.Request.ContentData(
              chatRoomID: $0.item.chatRoomID,
              chatID: $0.id,
              srcLangCode: $0.item.srcLangCode,
              dstLangCode: dstLangCode,
              timestamp: $0.item.timestamp,
              text: $0.item.textForTR)
          }
          await liveTranslationServiceClient.requestBatchTranslation(mutatedArray)
        }
      }
    }
  }
}

@ViewAction(for: LiveTranslation.self)
public struct LiveTranslationView: View {
  
  @Bindable public var store: StoreOf<LiveTranslation>
  
  public init(store: StoreOf<LiveTranslation>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationStack {
      VStack {
        ScrollViewReader { proxy in
          ScrollView {
            
          }
        }
      }
    }
  }
}

extension [TranslationEntity.CompositeChatItem] {
  fileprivate func merge(item: RealTimeEntity.Chat.Response, dstLangCode: String) async
    -> [TranslationEntity.CompositeChatItem]
  {
    await withCheckedContinuation { continuation in
      switch item.contentData.listType {
      case .append:
        var mutableSelf = self
        for newItem in item.contentData.chatList {
          if let lastIdx = mutableSelf.lastIndex(where: { $0.id == newItem.id }) {
            mutableSelf.remove(at: lastIdx)
          }

          guard !(newItem.textForTR.isEmpty || newItem.text.isEmpty) else { continue }
          mutableSelf.append(
            .init(item: newItem, trItem: .none, ttsData: .none, dstLangCode: dstLangCode))
        }

        return continuation.resume(returning: mutableSelf.suffix(100))

      case .realtime:
        var mutableSelf = self
        for newItem in item.contentData.chatList {
          if let lastIdx = mutableSelf.lastIndex(where: { $0.id == newItem.id }) {
            mutableSelf.remove(at: lastIdx)
          }

          mutableSelf.append(
            .init(item: newItem, trItem: .none, ttsData: .none, dstLangCode: dstLangCode))
        }
        return continuation.resume(returning: mutableSelf)

      case .renew:
        let newArr: [TranslationEntity.CompositeChatItem] = item.contentData.chatList.reduce([]) {
          current, next in
          guard !next.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return current
          }
          let first = self.first(where: { $0.item.id == next.id })
          let new: TranslationEntity.CompositeChatItem = .init(
            item: next, trItem: first?.trItem, ttsData: first?.ttsData, dstLangCode: dstLangCode)

          return current + [new]
        }

        return continuation.resume(returning: newArr.suffix(100))

      case .update:
        let newArr = item.contentData.chatList.reduce(self) { current, next in
          // If the update target is included in the current chat list (when modifying a chat with non-empty value)
          if let idx = current.firstIndex(where: { $0.item.chatID == next.chatID }) {
            var variableCurrent = current

            // If modified to empty value, delete the chat from the chat list
            if next.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              variableCurrent.remove(at: idx)
              return variableCurrent
            } else {
              variableCurrent[idx] = .init(
                item: next,
                trItem: variableCurrent[idx].trItem,
                ttsData: .none,
                dstLangCode: dstLangCode)
              return variableCurrent
            }
            // If the update target is not included in the current chat list (when modifying an empty chat)
          } else if let willAppendIndex = current.firstIndex(where: {
            $0.item.timestamp > next.timestamp
          }) {
            guard !next.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
              return current
            }
            var variableCurrent = current
            variableCurrent.insert(
              .init(item: next, trItem: .none, ttsData: .none, dstLangCode: dstLangCode),
              at: willAppendIndex)
            return variableCurrent
          } else {
            return current
          }
        }

        return continuation.resume(returning: newArr.suffix(100))

      default:
        return continuation.resume(returning: self)
      }
    }
  }

  fileprivate func updateTranslation(item: RealTimeEntity.Translation.Response) async
    -> [TranslationEntity.CompositeChatItem]
  {
    await withCheckedContinuation { continuation in
      guard
        let firstIndex = self.firstIndex(where: {
          $0.id == item.contentData.chatList.first?.chatID
        }
        )
      else {
        return continuation.resume(returning: self)
      }

      let range = firstIndex..<(firstIndex + item.contentData.chatList.count)
      var mutatedArray: [TranslationEntity.CompositeChatItem] = []

      for index in range {
        guard let trItem = item.contentData.chatList[safe: mutatedArray.count] else { break }
        guard let newItem = self[safe: index]?.setTranslation(trItem: trItem) else { break }

        mutatedArray.append(newItem)
      }

      var mutateSelf = self
      mutateSelf.replaceSubrange(range, with: mutatedArray)

      return continuation.resume(returning: mutateSelf)
    }
  }
}

extension TranslationEntity.CompositeChatItem {
  fileprivate func setTranslation(trItem: TranslationEntity.TR.Response) -> Self {
    .init(
      item: item,
      trItem: trItem,
      ttsData: .none,
      dstLangCode: trItem.dstLangCode)
  }
}

extension Collection {
  fileprivate subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

extension Array {
  fileprivate func chunked(into size: Int) -> [[Element]] {
    guard size > .zero else { return [self] }
    return stride(from: 0, to: count, by: size).map { startIndex in
      let endIndex = index(startIndex, offsetBy: size, limitedBy: count) ?? endIndex
      return Array(self[startIndex..<endIndex])
    }
  }
}
