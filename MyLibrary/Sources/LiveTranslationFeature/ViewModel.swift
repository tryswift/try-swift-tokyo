import Foundation
import LiveTranslationSDK_iOS

@Observable
@MainActor
public final class ViewModel {
  public init(roomNumber: String) {
    self.roomNumber = roomNumber
  }

  var roomNumber: String
  var chatList: [TranslationEntity.CompositeChatItem] = []
  var langSet: LanguageEntity.Response.LangSet? = .none
  var langList: [LanguageEntity.Response.LanguageItem] = []
  var roomInfo: ChatRoomEntity.Make.Response? = .none
  var selectedLangCode: String =
    Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"

  let service: LiveTranslationService = .init()

  var isUpdatingChat: Bool = false
  var isUpdatingTR: Bool = false
  var updateChatWaitingQueue: [RealTimeEntity.Chat.Response] = []
  var updateTrWaitingQueue: [RealTimeEntity.Translation.Response] = []
  var latestListType: RealTimeEntity.ListType? = .none
}

extension ViewModel {
  public func send(_ inputAction: InputAction) {
    switch inputAction {
    case .onAppearedPage:
      Task {
        await withTaskGroup(of: Void.self) { [weak self] group in
          group.addTask { await self?.loadLangSet() }
          group.addTask { await self?.loadChatRoomInfo(self?.roomNumber) }
          group.addTask { await self?.loadLangList() }
        }
      }
    case .connectChatStream:
      Task {
        await connectChatStream(roomNumber)
      }
    case .changeLangCode(let newLangCode):
      selectedLangCode = newLangCode
      Task {
        await loadLangSet(langCode: newLangCode)
        await loadTranslation(chatList: chatList, newLangCode)
      }
    }
  }
}

extension ViewModel {
  private func loadLangSet(langCode: String = LanguageCodeFunctor.deviceCode) async {
    do {
      let langSet = try await service.getLangSet(.init(langCode: langCode))
      self.langSet = langSet
    } catch {
      print(error.displayMessage)
    }
  }

  private func loadLangList() async {
    do {
      let langList = try await service.getLangList()
      self.langList = langList
    } catch {
      print(error.displayMessage)
    }
  }

  private func loadChatRoomInfo(_ roomNumber: String?) async {
    do {
      guard let roomNumber else { return assert(true, "roomNumber is required") }
      let roomInfo = try await service.getChatRoomInfo(.init(interactionKey: roomNumber))
      self.roomInfo = roomInfo
    } catch {
      print(error.displayMessage)
    }
  }

  private func connectChatStream(_ roomNumber: String) async {
    do {
      let stream = service.chatConnection(.init(interactionKey: roomNumber))
      for try await action in stream {
        switch action {
        case .connect: break
        case .disconnect: break
        case .peerClosed:
          send(.connectChatStream)
        case .responseChat(let chatItem):
          await handleResponseChat(chatItem)
        case .responseBatchTranslation(let trItem):
          await handleResponseTranslation(trItem)
        default: break
        }
      }
    } catch {
      print(error.serialized().displayMessage)
    }
  }

  package func loadTranslation(
    chatList: [TranslationEntity.CompositeChatItem], _ dstLangCode: String
  ) async {
    await withTaskGroup(of: Void.self) { [weak self] group in
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
          do {
            try await self?.service.requestBatchTranslation(.init(data: mutatedArray))
          } catch {
            print(error.serialized().displayMessage)
          }
        }
      }
    }
  }
}

extension ViewModel {
  fileprivate func handleResponseChat(_ chatItem: RealTimeEntity.Chat.Response) async {
    guard !isUpdatingChat else {
      updateChatWaitingQueue.append(chatItem)
      return
    }

    self.isUpdatingChat = true
    self.latestListType = chatItem.contentData.listType
    let newChatList = await self.chatList.merge(item: chatItem, dstLangCode: selectedLangCode)

    self.chatList = newChatList
    self.isUpdatingChat = false

    switch chatItem.contentData.listType {
    case .update:
      let updateTargetList = chatItem.contentData.chatList.reduce(
        [TranslationEntity.CompositeChatItem]()
      ) { current, next in
        guard let firstIndex = newChatList.firstIndex(where: { $0.id == next.id }) else {
          return current
        }
        return current + [newChatList[firstIndex]]
      }
      await loadTranslation(chatList: updateTargetList, selectedLangCode)

    case .append:
      guard let lastItem = newChatList.last else { return }
      await loadTranslation(chatList: [lastItem], selectedLangCode)

    case .realtime: break
    default: await loadTranslation(chatList: chatList, selectedLangCode)
    }

    await checkUpdateChatWaitingQueue()
  }

  private func checkUpdateChatWaitingQueue() async {
    guard let task = updateChatWaitingQueue.first else { return }
    updateChatWaitingQueue.removeFirst()
    await handleResponseChat(task)
  }

  private func handleResponseTranslation(_ trItem: RealTimeEntity.Translation.Response) async {
    guard !isUpdatingTR else {
      updateTrWaitingQueue.append(trItem)
      return
    }

    self.isUpdatingTR = true
    self.latestListType = trItem.contentData.listType

    let newChatList = await self.chatList.updateTranslation(item: trItem)

    self.chatList = newChatList
    self.isUpdatingTR = false

    await checkUpdateTRWaitingQueue()
  }

  private func checkUpdateTRWaitingQueue() async {
    guard let task = updateTrWaitingQueue.first else { return }
    updateTrWaitingQueue.removeFirst()
    await handleResponseTranslation(task)
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
        let firstIndex = self.firstIndex(where: { $0.id == item.contentData.chatList.first?.chatID }
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

extension ViewModel {
  public enum InputAction {
    case onAppearedPage
    case connectChatStream
    case changeLangCode(String)
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
  func chunked(into size: Int) -> [[Element]] {
    guard size > .zero else { return [self] }
    return stride(from: 0, to: count, by: size).map { startIndex in
      let endIndex = index(startIndex, offsetBy: size, limitedBy: count) ?? endIndex
      return Array(self[startIndex..<endIndex])
    }
  }
}
