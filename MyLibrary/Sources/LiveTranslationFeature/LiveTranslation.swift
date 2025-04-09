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
    
    public enum View {
      case onAppear
    }
  }
  
  public init() {}
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        return .run { send in
          await withTaskGroup(of: Void.self) { group in
            group.addTask {
//              TODO: loadLangSet
            }
            group.addTask {
//              TODO: loadLangList
            }
            group.addTask {
//              TODO: loadChatRoomInfo
            }
          }
        }
      case .connectChatStream:
        return .none
      case .changeLangCode(let newLangCode):
        return .none
      case .binding:
        return .none
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
