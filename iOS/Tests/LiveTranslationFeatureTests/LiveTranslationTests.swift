import ComposableArchitecture
import Testing

@testable import LiveTranslationFeature

@Suite
@MainActor
struct LiveTranslationTests {

  // MARK: - Existing: Validate Selected Lang Code

  @Test
  func validateSelectedLangCode_validCode() async {
    @Shared(.selectedLangCode) var selectedLangCode = "ja"
    let state = LiveTranslation.State()

    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    await store.send(.validateSelectedLangCode(["en", "ja", "ko"]))
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
    }
    store.exhaustivity = .off

    let langList = makeLangList(["ja", "ko"])
    await store.send(.validateSelectedLangCode(langList)) {
      $0.$selectedLangCode.withLock { $0 = "en" }
    }
  }

  // MARK: - Group 1: Pure State Mutations

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

  // MARK: - Group 2: Dependency Mocking

  @Test
  func onAppear_setsRoomNumber() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.buildConfig.liveTranslationRoomNumber = { "ROOM-42" }
      $0.liveTranslationServiceClient.langSet = { @Sendable _ in
        throw CancellationError()
      }
      $0.liveTranslationServiceClient.langList = { @Sendable in
        throw CancellationError()
      }
      $0.liveTranslationServiceClient.chatRoomInfo = { @Sendable _ in
        throw CancellationError()
      }
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
  func selectLangCode_sendsChangeLangCode() async {
    @Shared(.selectedLangCode) var selectedLangCode = "en"

    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.langSet = { @Sendable _ in
        throw CancellationError()
      }
      $0.liveTranslationServiceClient.requestBatchTranslation = { @Sendable _ in }
    }
    store.exhaustivity = .off

    await store.send(.view(.selectLangCode("ko")))
    await store.receive(\.changeLangCode) {
      $0.$selectedLangCode.withLock { $0 = "ko" }
    }
  }

  @Test
  func changeLangCode_updatesSelectedLangCode() async {
    @Shared(.selectedLangCode) var selectedLangCode = "en"
    let langSetCalled = LockIsolated<String?>(nil)

    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.langSet = { @Sendable langCode in
        langSetCalled.setValue(langCode)
        throw CancellationError()
      }
      $0.liveTranslationServiceClient.requestBatchTranslation = { @Sendable _ in }
    }
    store.exhaustivity = .off

    await store.send(.changeLangCode("ko")) {
      $0.$selectedLangCode.withLock { $0 = "ko" }
    }

    langSetCalled.withValue {
      #expect($0 == "ko")
    }
  }

  // MARK: - Group 3: Stream Connection

  @Test
  func disconnectStream_cancelsConnectTask() async {
    let store = TestStore(initialState: LiveTranslation.State()) {
      LiveTranslation()
    } withDependencies: {
      $0.liveTranslationServiceClient.chatConnection = { @Sendable _ in
        AsyncThrowingStream { continuation in
          continuation.onTermination = { _ in }
        }
      }
    }
    store.exhaustivity = .off

    await store.send(.view(.connectStream))
    await store.send(.view(.disconnectStream))
  }
}
