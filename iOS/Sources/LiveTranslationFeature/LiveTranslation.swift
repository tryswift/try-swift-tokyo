import AVFoundation
import BuildConfig
import ComposableArchitecture
import DependencyExtra
import Foundation
import SwiftUI
import LiveTranslationSDK

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
    }
  }

  @Dependency(\.liveTranslationServiceClient) var liveTranslationServiceClient
  @Dependency(\.buildConfig) var buildConfig
  @Dependency(\.speechSynthesizer) var speechSynthesizer

  private let observationTaskId: String = "observationTask"

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
        return .merge(
          .cancel(id: observationTaskId),
          .run { _ in
            await liveTranslationServiceClient.disconnect()
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
        return .run { [state] send in
          await speechSynthesizer.speak(text, state.selectedLangCode, state.speechRate)
          await send(.view(.speechDidFinish))
        }

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
        return .none

      case .storeStateUpdated(let storeState):
        let previousLanguages = state.supportLanguages
        state.chatList = storeState.chatList
        state.supportLanguages = storeState.supportLanguages
        state.isConnected = storeState.isConnected
        state.roomTitle = storeState.roomTitle
        state.lastErrorMessage = storeState.isConnected ? nil : storeState.lastErrorMessage
        if storeState.supportLanguages != previousLanguages
          && !storeState.supportLanguages.isEmpty
        {
          return .send(.validateSelectedLangCode(storeState.supportLanguages.map(\.languageCode)))
        }
        return .none

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
      .safeAreaInset(edge: .bottom) {
        if store.isShowingSpeedControl {
          speedControlView
        }
      }
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
              openWindow(id: "transcript")
            } label: {
              Image(systemName: "rectangle.on.rectangle")
            }
            .accessibilityLabel(Text("Open transcript window", bundle: .module))
          }
        #endif
        ToolbarItem(placement: .primaryAction) {
          HStack {
            Button {
              send(.setShowingSpeedControl(!store.isShowingSpeedControl))
            } label: {
              Image(systemName: "speedometer")
            }
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
    VStack(spacing: 8) {
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
    .background(.regularMaterial)
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
        .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 16))
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
            .glassEffectIfAvailable(.regular, in: .rect(cornerRadius: 20))
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
