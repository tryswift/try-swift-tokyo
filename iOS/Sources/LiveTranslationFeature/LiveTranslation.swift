import AVFoundation
import BuildConfig
import ComposableArchitecture
import DependencyExtra
import Foundation
import LiveTranslationSDK
import SwiftUI

@Reducer
public struct LiveTranslation: Sendable {
  @ObservableState
  public struct State: Sendable, Equatable {
    /// Live Translation Room Number
    var roomNumber: String = ""
    /// Current visible translation items
    var chatList: [ChatItemEntity] = []
    /// Available language list
    var supportLanguages: [LanguageItemEntity] = []
    /// Streaming is connected
    var isConnected: Bool = false
    /// Last error message from the translation service
    var lastErrorMessage: String? = nil
    /// Live Translation Room Title
    var roomTitle: String? = nil
    /// Current language code which user selected
    @Shared(.selectedLangCode) var selectedLangCode: String =
      Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"

    /// selected language sheet
    var isSelectedLanguageSheet: Bool = false
    /// showing last chat
    var isShowingLastChat: Bool = false

    /// Text-to-Speech speed rate (0.0 to 1.0, default 0.5)
    var speechRate: Float = 0.5
    /// Currently speaking item ID
    var speakingItemId: String? = nil
    /// Show speed control
    var isShowingSpeedControl: Bool = false

    /// Auto-read confirmed translations (persisted)
    @Shared(.isAutoReadEnabled) var isAutoReadEnabled: Bool = false
    /// ID of the last auto-read item
    var lastAutoReadItemId: String? = nil
    /// Whether auto-read is currently speaking
    var isAutoReading: Bool = false

    /// Whether the transcript window is currently open (macOS/visionOS)
    var isTranscriptWindowOpen: Bool = false

    /// Number of most recent items to display in transcript mode
    private static let transcriptItemCount = 3

    /// The most recent items for transcript display
    var transcriptItems: [ChatItemEntity] {
      Array(chatList.suffix(Self.transcriptItemCount))
    }

    /// The display name for the currently selected language (read-only to avoid @Shared setter warning)
    var selectedLanguageName: String {
      supportLanguages.first { $0.languageCode == selectedLangCode }?.languageLocal ?? ""
    }

    public init() {}
  }

  public enum Action: BindableAction, ViewAction {
    case binding(BindingAction<State>)
    case storeStateUpdated(StoreState)
    case validateSelectedLangCode([String])
    case autoReadNextItem
    case autoReadDidFinish
    case view(View)

    public enum View {
      case onAppear
      case connectStream
      case disconnectStream
      case selectLangCode(String)
      case setSelectedLanguageSheet(Bool)
      case setShowingLastChat(Bool)
      case speakText(String, itemId: String)
      case stopSpeaking
      case setSpeechRate(Float)
      case setShowingSpeedControl(Bool)
      case speechDidFinish
      case setAutoReadEnabled(Bool)
      case toggleTranscriptWindow
      case transcriptWindowClosed
    }
  }

  @Dependency(\.liveTranslationServiceClient) var liveTranslationServiceClient
  @Dependency(\.buildConfig) var buildConfig
  @Dependency(\.speechSynthesizer) var speechSynthesizer

  private let observationTaskId: String = "observationTask"
  private let autoReadTaskId: String = "autoReadTask"

  public init() {}

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(.onAppear):
        state.roomNumber = buildConfig.liveTranslationRoomNumber()
        guard !state.roomNumber.isEmpty else { return .none }
        return .run { [state] send in
          await liveTranslationServiceClient.connect(
            state.roomNumber, state.selectedLangCode)
          for await storeState in liveTranslationServiceClient.stateStream() {
            await send(.storeStateUpdated(storeState))
          }
        }.cancellable(id: observationTaskId, cancelInFlight: true)

      case .view(.connectStream):
        guard !state.roomNumber.isEmpty else { return .none }
        return .run { [state] send in
          await liveTranslationServiceClient.connect(
            state.roomNumber, state.selectedLangCode)
          for await storeState in liveTranslationServiceClient.stateStream() {
            await send(.storeStateUpdated(storeState))
          }
        }.cancellable(id: observationTaskId, cancelInFlight: true)

      case .view(.disconnectStream):
        state.isConnected = false
        state.isAutoReading = false
        return .merge(
          .cancel(id: observationTaskId),
          .cancel(id: autoReadTaskId),
          .run { _ in
            await liveTranslationServiceClient.disconnect()
            await speechSynthesizer.stop()
          }
        )

      case .view(.selectLangCode(let langCode)):
        state.$selectedLangCode.withLock { $0 = langCode }
        return .run { _ in
          await liveTranslationServiceClient.requestTranslationLanguage(langCode)
        }

      case .view(.setSelectedLanguageSheet(let flag)):
        state.isSelectedLanguageSheet = flag
        return .none

      case .view(.setShowingLastChat(let flag)):
        state.isShowingLastChat = flag
        return .none

      case .view(.speakText(let text, let itemId)):
        state.speakingItemId = itemId
        state.isAutoReading = false
        return .merge(
          .cancel(id: autoReadTaskId),
          .run { [state] send in
            await speechSynthesizer.speak(text, state.selectedLangCode, state.speechRate)
            await send(.view(.speechDidFinish))
          }
        )

      case .view(.stopSpeaking):
        state.speakingItemId = nil
        return .run { _ in
          await speechSynthesizer.stop()
        }

      case .view(.setSpeechRate(let rate)):
        state.speechRate = rate
        return .none

      case .view(.setShowingSpeedControl(let flag)):
        state.isShowingSpeedControl = flag
        return .none

      case .view(.speechDidFinish):
        state.speakingItemId = nil
        if state.isAutoReadEnabled {
          return .send(.autoReadNextItem)
        }
        return .none

      case .storeStateUpdated(let storeState):
        let previousLanguages = state.supportLanguages
        state.chatList = storeState.chatList
        state.supportLanguages = storeState.supportLanguages
        state.isConnected = storeState.isConnected
        state.roomTitle = storeState.roomTitle
        state.lastErrorMessage = storeState.isConnected ? nil : storeState.lastErrorMessage
        var effects: [Effect<Action>] = []
        if storeState.supportLanguages != previousLanguages
          && !storeState.supportLanguages.isEmpty
        {
          effects.append(
            .send(.validateSelectedLangCode(storeState.supportLanguages.map(\.languageCode))))
        }
        if state.isAutoReadEnabled {
          effects.append(.send(.autoReadNextItem))
        }
        return effects.isEmpty ? .none : .concatenate(effects)

      case .validateSelectedLangCode(let langCodes):
        let currentCode = state.selectedLangCode
        let isValid = langCodes.contains(currentCode)
        if !isValid {
          let deviceCode =
            Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
          let fallbackCode =
            langCodes.contains(deviceCode) ? deviceCode : "en"
          state.$selectedLangCode.withLock { $0 = fallbackCode }
          return .run { _ in
            await liveTranslationServiceClient.requestTranslationLanguage(fallbackCode)
          }
        }
        return .none

      case .view(.setAutoReadEnabled(let enabled)):
        state.$isAutoReadEnabled.withLock { $0 = enabled }
        if !enabled {
          let wasAutoReading = state.isAutoReading
          state.isAutoReading = false
          if wasAutoReading {
            return .merge(
              .cancel(id: autoReadTaskId),
              .run { _ in await speechSynthesizer.stop() }
            )
          }
          return .cancel(id: autoReadTaskId)
        }
        return .send(.autoReadNextItem)

      case .autoReadNextItem:
        guard state.isAutoReadEnabled else { return .none }
        guard state.speakingItemId == nil else { return .none }
        guard !state.isAutoReading else { return .none }

        let unreadItems: [ChatItemEntity]
        if let lastId = state.lastAutoReadItemId,
          let lastIndex = state.chatList.firstIndex(where: { $0.id == lastId })
        {
          unreadItems = Array(
            state.chatList.suffix(from: state.chatList.index(after: lastIndex))
          ).filter { !$0.isRealTime }
        } else {
          // First time: only read the latest confirmed item
          unreadItems = Array(state.chatList.suffix(1).filter { !$0.isRealTime })
        }

        guard let nextItem = unreadItems.first else { return .none }

        state.isAutoReading = true
        state.lastAutoReadItemId = nextItem.id
        let text = nextItem.textForTr.isEmpty ? nextItem.text : nextItem.textForTr
        let langCode = state.selectedLangCode
        let rate = state.speechRate

        return .run { send in
          await speechSynthesizer.speak(text, langCode, rate)
          await send(.autoReadDidFinish)
        }.cancellable(id: autoReadTaskId, cancelInFlight: false)

      case .autoReadDidFinish:
        state.isAutoReading = false
        return .send(.autoReadNextItem)

      case .view(.toggleTranscriptWindow):
        state.isTranscriptWindowOpen.toggle()
        return .none

      case .view(.transcriptWindowClosed):
        state.isTranscriptWindowOpen = false
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
  @Environment(\.scenePhase) var scenePhase
  #if os(macOS) || os(visionOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
  #endif

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
              FlittoLogoView()
            } else if store.chatList.isEmpty {
              if let errorMessage = store.lastErrorMessage {
                ContentUnavailableView {
                  Label(
                    String(localized: "Connection error", bundle: .module),
                    systemImage: "exclamationmark.triangle.fill"
                  )
                } description: {
                  Text(errorMessage)
                }
              } else {
                ContentUnavailableView("Not started yet", systemImage: "text.page.slash.fill")
              }
              Spacer()
              FlittoLogoView()
            } else {
              translationContents
              Color.clear
                .id(scrollContentBottomID)
                .frame(height: 1)
            }
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
          .onChange(of: scenePhase) {
            switch scenePhase {
            case .inactive: break
            case .active:
              send(.connectStream)
            case .background:
              send(.disconnectStream)
            @unknown default: break
            }
          }
        }
      }
      .task {
        send(.onAppear)
      }
      .navigationTitle(Text("Live translation", bundle: .module))
      #if !os(macOS) && !os(visionOS)
        .sheet(isPresented: $store.isShowingSpeedControl) {
          speedControlView
          .presentationDetents([.height(180)])
          .presentationDragIndicator(.visible)
        }
      #endif
      .toolbar {
        if !store.isConnected {
          ToolbarItem(placement: .navigation) {
            Button {
              send(.connectStream)
            } label: {
              Image(systemName: "arrow.trianglehead.2.clockwise")
            }
          }
        }
        #if os(macOS) || os(visionOS)
          ToolbarItem(placement: .primaryAction) {
            Button {
              if store.isTranscriptWindowOpen {
                dismissWindow(id: "transcript")
              } else {
                openWindow(id: "transcript")
              }
              send(.toggleTranscriptWindow)
            } label: {
              Image(
                systemName: store.isTranscriptWindowOpen
                  ? "rectangle.on.rectangle.slash" : "rectangle.on.rectangle")
            }
            .accessibilityLabel(
              Text(
                store.isTranscriptWindowOpen
                  ? "Close transcript window" : "Open transcript window",
                bundle: .module
              )
            )
          }
        #endif
        ToolbarItem(placement: .primaryAction) {
          HStack {
            Button {
              send(.setShowingSpeedControl(!store.isShowingSpeedControl))
            } label: {
              Image(systemName: "speedometer")
            }
            #if os(macOS) || os(visionOS)
              .popover(isPresented: $store.isShowingSpeedControl) {
                speedControlView
                .frame(width: 280)
              }
            #endif
          }
        }
        ToolbarSpacer(placement: .primaryAction)
        ToolbarItem(placement: .primaryAction) {
          Button {
            send(.setSelectedLanguageSheet(!store.isSelectedLanguageSheet))
          } label: {
            Text(store.selectedLanguageName)
            Image(systemName: "globe")
          }
          #if os(macOS)
            .popover(isPresented: $store.isSelectedLanguageSheet) {
              SelectLanguageSheet(
                languageList: store.supportLanguages,
                selectedLanguageAction: { langItem in
                  send(.selectLangCode(langItem.languageCode))
                  send(.setSelectedLanguageSheet(false))
                }
              )
              .frame(width: 280, height: 400)
            }
          #endif
        }
      }
    }
    #if !os(macOS)
      .sheet(isPresented: $store.isSelectedLanguageSheet) {
        SelectLanguageSheet(
          languageList: store.supportLanguages,
          selectedLanguageAction: { langItem in
            send(.selectLangCode(langItem.languageCode))
            send(.setSelectedLanguageSheet(false))
          }
        )
        .presentationDetents([.medium, .large])
      }
    #endif
  }

  @ViewBuilder
  var speedControlView: some View {
    VStack(spacing: 12) {
      Toggle(
        isOn: Binding(
          get: { store.isAutoReadEnabled },
          set: { send(.setAutoReadEnabled($0)) }
        )
      ) {
        Label {
          Text("Auto-Read", bundle: .module)
        } icon: {
          Image(systemName: "headphones")
        }
        .font(.subheadline)
      }

      Divider()

      HStack {
        Text("Speech Speed", bundle: .module)
          .font(.subheadline)
        Spacer()
        Text(speedLabel)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Slider(
        value: Binding(
          get: { store.speechRate },
          set: { send(.setSpeechRate($0)) }
        ),
        in: 0.1...1.0,
        step: 0.1
      )
    }
    .padding()
  }

  private var speedLabel: String {
    let rate = store.speechRate
    if rate <= 0.3 {
      return String(localized: "Slow", bundle: .module)
    } else if rate <= 0.6 {
      return String(localized: "Normal", bundle: .module)
    } else {
      return String(localized: "Fast", bundle: .module)
    }
  }

  @ViewBuilder
  var translationContents: some View {
    LazyVStack(spacing: 12) {
      ForEach(store.chatList) { item in
        HStack(alignment: .top, spacing: 8) {
          Text(item.textForTr.isEmpty ? item.text : item.textForTr)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .foregroundStyle(item.isRealTime ? .secondary : .primary)
          Button {
            let text = item.textForTr.isEmpty ? item.text : item.textForTr
            if store.speakingItemId == item.id {
              send(.stopSpeaking)
            } else {
              send(.speakText(text, itemId: item.id))
            }
          } label: {
            Image(
              systemName: store.speakingItemId == item.id ? "stop.circle.fill" : "speaker.wave.2"
            )
            .foregroundStyle(store.speakingItemId == item.id ? .red : .accentColor)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(
            store.speakingItemId == item.id
              ? Text("Stop speaking", bundle: .module)
              : Text("Speak text", bundle: .module)
          )
        }
        .padding()
        .glassEffectContainerIfAvailable()
        .glassEffectIfAvailable(item.isRealTime ? .clear : .regular, in: .rect(cornerRadius: 16))
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
    .padding(.horizontal)
    .glassEffectContainerIfAvailable()
  }

}

// MARK: - Shared Flitto Logo

struct FlittoLogoView: View {
  var body: some View {
    HStack {
      Spacer()
      Text("Powered by", bundle: .module)
        .font(.caption)
        .foregroundStyle(.secondary)
      Image(.flitto)
        .resizable()
        .offset(x: -10)
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: 30)
        .accessibilityIgnoresInvertColors()
      Spacer()
    }
    .padding(.vertical, 8)
    .glassEffectIfAvailable(.clear, in: .capsule)
    .padding(.horizontal)
  }
}

extension SharedKey where Self == AppStorageKey<String> {
  static var selectedLangCode: Self {
    appStorage("selectedLangCode")
  }
}

extension SharedKey where Self == AppStorageKey<Bool> {
  static var isAutoReadEnabled: Self {
    appStorage("isAutoReadEnabled")
  }
}

// MARK: - Transcript Window View

public struct TranscriptWindowView: View {

  @Bindable var store: StoreOf<LiveTranslation>
  @Environment(\.scenePhase) private var scenePhase

  public init(store: StoreOf<LiveTranslation>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 16) {
      Spacer()
      if store.chatList.isEmpty {
        ContentUnavailableView(
          String(localized: "Not started yet", bundle: .module),
          systemImage: "text.page.slash.fill"
        )
      } else {
        ForEach(store.transcriptItems) { item in
          Text(item.textForTr.isEmpty ? item.text : item.textForTr)
            #if os(visionOS)
              .font(.system(size: 36, weight: .medium))
            #else
              .font(.system(size: 28, weight: .medium))
            #endif
            .multilineTextAlignment(.center)
            .foregroundStyle(item.isRealTime ? .secondary : .primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .glassEffectIfAvailable(
              item.isRealTime ? .clear : .regular, in: .rect(cornerRadius: 20))
        }
        .animation(.easeInOut(duration: 0.3), value: store.chatList.last?.id)
      }
      Spacer()
      FlittoLogoView()
    }
    .padding()
    .glassEffectContainerIfAvailable()
    .task {
      store.send(.view(.onAppear))
    }
    .onDisappear {
      store.send(.view(.transcriptWindowClosed))
    }
    .onChange(of: scenePhase) {
      switch scenePhase {
      case .active:
        store.send(.view(.connectStream))
      case .background:
        store.send(.view(.disconnectStream))
      default: break
      }
    }
  }
}

#Preview {
  LiveTranslationView(
    store: .init(initialState: .init()) {
      LiveTranslation()
    })
}
