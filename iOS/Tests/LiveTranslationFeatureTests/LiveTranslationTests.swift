import ComposableArchitecture
import Testing

@testable import LiveTranslationFeature

@Suite(.serialized)
@MainActor
struct LiveTranslationTests {

  // MARK: - Validate Selected Lang Code

  @Test
  func validateSelectedLangCode_validCode() async {
    let state = LiveTranslation.State()
    // Capture the current code (set by device locale, typically "en" on CI)
    let initialCode = state.selectedLangCode

    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.validateSelectedLangCode(["en", "ja", "ko"]))
    // Assert the valid code was NOT overwritten by the fallback logic
    store.state.$selectedLangCode.withLock { #expect($0 == initialCode) }
  }

  @Test
  func validateSelectedLangCode_invalidCode_fallbackToEn() async {
    @Shared(.selectedLangCode) var selectedLangCode = "xx"
    let state = LiveTranslation.State()

    let store = TestStore(initialState: state) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.requestTranslationLanguage = { _ in }
    }
    store.exhaustivity = .off

    await store.send(.validateSelectedLangCode(["en", "ja", "ko"])) {
      $0.$selectedLangCode.withLock { $0 = "en" }
    }
  }

  @Test
  func validateSelectedLangCode_noEnInList_fallsBackToEn() async {
    @Shared(.selectedLangCode) var selectedLangCode = "zz"
    let state = LiveTranslation.State()

    let store = TestStore(initialState: state) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.requestTranslationLanguage = { _ in }
    }
    store.exhaustivity = .off

    await store.send(.validateSelectedLangCode(["ja", "ko"])) {
      $0.$selectedLangCode.withLock { $0 = "en" }
    }
  }

  // MARK: - Pure State Mutations

  @Test
  func setSelectedLanguageSheet_true() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setSelectedLanguageSheet(true))) {
      $0.isSelectedLanguageSheet = true
    }
  }

  @Test
  func setSelectedLanguageSheet_false() async {
    var state = LiveTranslation.State()
    state.isSelectedLanguageSheet = true
    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setSelectedLanguageSheet(false))) {
      $0.isSelectedLanguageSheet = false
    }
  }

  @Test
  func setShowingLastChat_true() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setShowingLastChat(true))) {
      $0.isShowingLastChat = true
    }
  }

  @Test
  func setShowingLastChat_false() async {
    var state = LiveTranslation.State()
    state.isShowingLastChat = true
    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setShowingLastChat(false))) {
      $0.isShowingLastChat = false
    }
  }

  @Test
  func setSpeechRate() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setSpeechRate(0.8))) {
      $0.speechRate = 0.8
    }
  }

  @Test
  func setShowingSpeedControl_true() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setShowingSpeedControl(true))) {
      $0.isShowingSpeedControl = true
    }
  }

  @Test
  func setShowingSpeedControl_false() async {
    var state = LiveTranslation.State()
    state.isShowingSpeedControl = true
    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.setShowingSpeedControl(false))) {
      $0.isShowingSpeedControl = false
    }
  }

  @Test
  func speechDidFinish_clearsSpeakingItemId() async {
    var state = LiveTranslation.State()
    state.speakingItemId = "item-123"
    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.view(.speechDidFinish)) {
      $0.speakingItemId = nil
    }
  }

  // MARK: - Dependency Mocking

  @Test
  func onAppear_setsRoomNumber() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.buildConfig.liveTranslationRoomNumber = { "ROOM-42" }
      $0.liveTranslationServiceClient.connect = { _, _ in }
      $0.liveTranslationServiceClient.stateStream = { .never }
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear)) {
      $0.roomNumber = "ROOM-42"
    }
  }

  @Test
  func stopSpeaking_clearsSpeakingItemIdAndCallsStop() async {
    let stopCalled = LockIsolated(false)
    var state = LiveTranslation.State()
    state.speakingItemId = "item-456"

    let store = TestStore(initialState: state) {
      LiveTranslation()
    } withDependencies: {
      $0.speechSynthesizer.stop = { @Sendable in
        stopCalled.setValue(true)
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.stopSpeaking)) {
      $0.speakingItemId = nil
    }

    stopCalled.withValue { #expect($0 == true) }
  }

  @Test
  func speakText_setsSpeakingItemIdAndCallsSpeech() async {
    let speakArgs = LockIsolated<(text: String, langCode: String, rate: Float)?>(nil)

    @Shared(.selectedLangCode) var selectedLangCode = "ko"
    var state = LiveTranslation.State()
    state.speechRate = 0.7

    let store = TestStore(initialState: state) {
      LiveTranslation()
    } withDependencies: {
      $0.speechSynthesizer.speak = { @Sendable text, langCode, rate in
        speakArgs.setValue((text, langCode, rate))
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.speakText("Hello world", itemId: "item-789"))) {
      $0.speakingItemId = "item-789"
    }

    // Note: Using \.view (broad match) because Action.View is not @CasePathable,
    // so \.view.speechDidFinish is unavailable. The state assertion below confirms
    // that the received action was indeed .view(.speechDidFinish).
    await store.receive(\.view) {
      $0.speakingItemId = nil
    }

    speakArgs.withValue {
      #expect($0?.text == "Hello world")
      #expect($0?.langCode == "ko")
      #expect($0?.rate == 0.7)
    }
  }

  @Test
  func selectLangCode_updatesCodeAndRequestsTranslation() async {
    @Shared(.selectedLangCode) var selectedLangCode = "en"
    let requestedLang = LockIsolated<String?>(nil)

    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.requestTranslationLanguage = { @Sendable langCode in
        requestedLang.setValue(langCode)
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.selectLangCode("ko"))) {
      $0.$selectedLangCode.withLock { $0 = "ko" }
    }

    requestedLang.withValue { #expect($0 == "ko") }
  }

  // MARK: - Stream Connection

  @Test
  func onAppear_emptyRoomNumber_doesNotConnect() async {
    let connectCalled = LockIsolated(false)

    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.buildConfig.liveTranslationRoomNumber = { "" }
      $0.liveTranslationServiceClient.connect = { _, _ in
        connectCalled.setValue(true)
      }
      $0.liveTranslationServiceClient.stateStream = { .never }
    }
    store.exhaustivity = .off

    await store.send(.view(.onAppear)) {
      $0.roomNumber = ""
    }

    connectCalled.withValue { #expect($0 == false) }
  }

  @Test
  func storeStateUpdated_populatesLastErrorMessage() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(
      .storeStateUpdated(
        StoreState(isConnected: false, lastErrorMessage: "Socket error"))
    ) {
      $0.lastErrorMessage = "Socket error"
    }
  }

  @Test
  func storeStateUpdated_clearsErrorOnConnected() async {
    var state = LiveTranslation.State()
    state.lastErrorMessage = "Previous error"

    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.storeStateUpdated(StoreState(isConnected: true))) {
      $0.isConnected = true
      $0.lastErrorMessage = nil
    }
  }

  @Test
  func disconnectStream_setsNotConnectedAndDisconnects() async {
    let disconnectCalled = LockIsolated(false)
    var state = LiveTranslation.State()
    state.isConnected = true

    let store = TestStore(initialState: state) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.disconnect = { @Sendable in
        disconnectCalled.setValue(true)
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.disconnectStream)) {
      $0.isConnected = false
    }

    disconnectCalled.withValue { #expect($0 == true) }
  }
}
