import ComposableArchitecture
import Testing

@testable import LiveTranslationFeature

@Suite
@MainActor
struct LiveTranslationTests {
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
}
