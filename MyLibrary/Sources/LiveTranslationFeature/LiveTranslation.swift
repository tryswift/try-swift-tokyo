import ComposableArchitecture
import SwiftUI
import Foundation
import LiveTranslationSDK_iOS

@Reducer
public struct LiveTranslation {
  @ObservableState
  public struct State: Equatable {
    /// Live Translation Room Number
    var roomNumber: String
    /// Current visible translation items
    var chatList: [TranslationEntity.CompositeChatItem] = []
    /// Current language set
    var langSet: LanguageEntity.Response.LangSet? = .none
    /// Available language list
    var langList: [LanguageEntity.Response.LanguageItem] = []
    /// Live Translation Room Info
    var roomInfo: ChatRoomEntity.Make.Response? = .none
    /// Current language code which user selected
    var selectedLangCode: String =
    Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
    
    /// While updating chat
    var isUpdatingChat: Bool = false
    /// While updating translation response
    var isUpdatingTR: Bool = false
    /// Chat updating request queue
    var updateChatWaitingQueue: [RealTimeEntity.Chat.Response] = []
    /// Translation response request queue
    var updateTrWaitingQueue: [RealTimeEntity.Translation.Response] = []
    /// Latest item's list type
    var latestListType: RealTimeEntity.ListType? = .none
    
    /// Streaming is connected
    var isConnected: Bool = false
    /// The task of connecting stream
    var chatStreamTask: Task<Void, Never>? = nil
    
    /// selected language sheet
    var isSelectedLanguageSheet: Bool = false
    /// showing last chat
    var isShowingLastChat: Bool = false
    
    public init(roomNumber: String) {
      self.roomNumber = roomNumber
    }
  }
  
  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case connectChatStream
    case disconnectChatStream
    case changeLangCode(String)
    case view(View)
    
    case handleResponseChat(RealTimeEntity.Chat.Response)
    case handleResponseTranslation(RealTimeEntity.Translation.Response)
    
    public enum View {
      case onAppear
      case connectStream
      case selectLangCode(String)
      case setSelectedLanguageSheet(Bool)
      case setShowingLastChat(Bool)
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
                  .set(\.langList, langList)
                )
              } catch {
                print(error)
              }
            }
            group.addTask {
              do {
                let roomInfo = try await liveTranslationServiceClient.chatRoomInfo(state.roomNumber)
                await send(
                  .set(\.roomInfo, roomInfo)
                )
              } catch {
                print(error)
              }
            }
          }
          await send(.connectChatStream)
        }
      case .view(.connectStream):
        return .run { send in
          await send(.connectChatStream)
        }
      case .view(.selectLangCode(let langCode)):
        return .run { send in
          await send(.changeLangCode(langCode))
        }
      case .view(.setSelectedLanguageSheet(let flag)):
        state.isSelectedLanguageSheet = flag
        return .none
      case .view(.setShowingLastChat(let flag)):
        state.isShowingLastChat = flag
        return .none
      case .connectChatStream:
        return .run { [state] send in
          let task = Task {
            do {
              let stream = liveTranslationServiceClient.chatConnection(state.roomNumber)
              for try await action in stream {
                switch action {
                case .connect:
                  await send(.set(\.isConnected, true))
                  break
                case .disconnect:
                  await send(.set(\.isConnected, false))
                  break
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
          await send(
            .set(
              \.chatStreamTask,
               task
            )
          )
        }
      case .disconnectChatStream:
        state.chatStreamTask?.cancel()
        return .none
      case .changeLangCode(let newLangCode):
        state.selectedLangCode = newLangCode
        return .run { [state] send in
          await loadLangSet(langCode: newLangCode, send: send)
          await loadTranslation(chatList: state.chatList, newLangCode)
        }
      case .handleResponseChat(let chatItem):
        return .run { [state] send in
          await handleResponseChat(chatItem, state: state, send: send)
        }
      case .handleResponseTranslation(let trItem):
        return .run { [state] send in
          await handleResponseTranslation(trItem, state: state, send: send)
        }
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
        .set(\.langSet, langSet)
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
  
  /// Handle chat item response
  private func handleResponseChat(_ chatItem: RealTimeEntity.Chat.Response, state: State, send: Send<Action>) async {
    guard !state.isUpdatingChat else {
      await send(
        .set(\.updateChatWaitingQueue, state.updateChatWaitingQueue + [chatItem])
      )
      return
    }
    // NOTE: Updating chat list
    await send(.set(\.isUpdatingChat, true))
    await send(.set(\.latestListType, chatItem.contentData.listType))
    let newChatList = await state.chatList.merge(item: chatItem, dstLangCode: state.selectedLangCode)
    await send(.set(\.chatList, newChatList))
    await send(.set(\.isUpdatingChat, false))
    
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
      await loadTranslation(chatList: updateTargetList, state.selectedLangCode)
      
    case .append:
      guard let lastItem = newChatList.last else { return }
      await loadTranslation(chatList: [lastItem], state.selectedLangCode)
      
    case .realtime: break
      
    default:
      await loadTranslation(chatList: state.chatList, state.selectedLangCode)
    }
    
    await checkUpdateChatWaitingQueue(state: state, send: send)
  }
  
  /// Check chat item wating queue
  private func checkUpdateChatWaitingQueue(state: State, send: Send<Action>) async {
    guard let task = state.updateChatWaitingQueue.first else { return }
    await send(.set(\.updateChatWaitingQueue, state.updateChatWaitingQueue.dropFirst().map { $0 }))
    await handleResponseChat(task, state: state, send: send)
  }
  
  /// Handle translation item response
  private func handleResponseTranslation(_ trItem: RealTimeEntity.Translation.Response, state: State, send: Send<Action>) async {
    guard !state.isUpdatingTR else {
      await send(.set(\.updateTrWaitingQueue, state.updateTrWaitingQueue + [trItem]))
      return
    }
    
    await send(.set(\.isUpdatingTR, true))
    await send(.set(\.latestListType, trItem.contentData.listType))
    let newChatList = await state.chatList.updateTranslation(item: trItem)
    await send(.set(\.chatList, newChatList))
    await send(.set(\.isUpdatingTR, false))
    
    await checkUpdateTRWaitingQueue(state: state, send: send)
  }
  
  /// Check translation item waiting queue
  private func checkUpdateTRWaitingQueue(state: State, send: Send<Action>) async {
    guard let task = state.updateTrWaitingQueue.first else { return }
    await send(.set(\.updateTrWaitingQueue, state.updateTrWaitingQueue.dropFirst().map { $0 }))
    await handleResponseTranslation(task, state: state, send: send)
  }
}

@ViewAction(for: LiveTranslation.self)
public struct LiveTranslationView: View {
  
  @Bindable public var store: StoreOf<LiveTranslation>
  
  private let scrollContentBottomID: String = "atBottom"
  
  public init(store: StoreOf<LiveTranslation>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationStack {
      VStack {
        ScrollViewReader { proxy in
          ScrollView {
            if store.roomNumber.isEmpty {
              ContentUnavailableView("Room is unavailable", systemImage: "text.page.slash.fill")
              Spacer()
            } else if store.chatList.isEmpty {
              ContentUnavailableView("Not started yet", systemImage: "text.page.slash.fill")
              Spacer()
            } else {
              translationContents
            }
            
            flittoLogo
              .id(scrollContentBottomID)
              .padding(.bottom, 16)
          }
          .onChange(of: store.chatList.last) { old, new in
            guard old != .none else {
              proxy.scrollTo(scrollContentBottomID, anchor: .bottom)
              return
            }
            
            guard store.isShowingLastChat else { return }
            
            withAnimation(.interactiveSpring) {
              proxy.scrollTo(scrollContentBottomID, anchor: .center)
            }
          }
        }
      }
      .task {
        send(.onAppear)
      }
      .navigationTitle(Text("Live translation", bundle: .module))
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            send(.setSelectedLanguageSheet(!store.isSelectedLanguageSheet))
          } label: {
            let selectedLanguage =
            store.langSet?.langCodingKey(store.selectedLangCode) ?? ""
            Text(selectedLanguage)
            Image(systemName: "globe")
          }
          .sheet(isPresented: $store.isSelectedLanguageSheet) {
            SelectLanguageSheet(
              languageList: store.langList,
              langSet: store.langSet,
              selectedLanguageAction: { langCode in
                send(.selectLangCode(langCode))
                send(.setSelectedLanguageSheet(false))
              }
            )
            .presentationDetents([.medium, .large])
          }
        }
      }
    }
  }
  
  @ViewBuilder
  var translationContents: some View {
    LazyVStack {
      ForEach(store.chatList) { item in
        Text(item.trItem?.content ?? item.item.text)
          .frame(maxWidth: .infinity, alignment: .leading)
          .multilineTextAlignment(.leading)
          .padding()
          .onAppear {
            guard item == store.chatList.last else { return }
            send(.setShowingLastChat(true))
          }
          .onDisappear {
            guard item == store.chatList.last else { return }
            send(.setShowingLastChat(false))
          }
      }
    }
  }
  
  @ViewBuilder
  var flittoLogo: some View {
    HStack {
      Spacer()
      Text("Powered by", bundle: .module)
        .font(.caption)
        .foregroundStyle(Color(.secondaryLabel))
      Image(.flitto)
        .resizable()
        .offset(x: -10)
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: 30)
      Spacer()
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

#Preview {
  LiveTranslationView(store: .init(initialState: .init(roomNumber: "490294")) {
    LiveTranslation()
  })
}
