import ComposableArchitecture
import LiveTranslationSDK
import Testing

@testable import LiveTranslationFeature

@Suite
@MainActor
struct LiveTranslationTests {
  @Test
  func validateSelectedLangCode_validCode() async throws {
    @Shared(.selectedLangCode) var selectedLangCode = "ja"
    let state = LiveTranslation.State()

    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    let langList = try makeLangList(["en", "ja", "ko"])
    await store.send(.validateSelectedLangCode(langList))
  }

  @Test
  func validateSelectedLangCode_invalidCode_fallbackToEn() async throws {
    @Shared(.selectedLangCode) var selectedLangCode = "xx"
    let state = LiveTranslation.State()

    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    let langList = try makeLangList(["en", "ja", "ko"])
    await store.send(.validateSelectedLangCode(langList)) {
      $0.$selectedLangCode.withLock { $0 = "en" }
    }
  }
}

private func makeLangList(_ codes: [String]) throws -> [LanguageItemEntity] {
  try codes.enumerated().map { index, code in
    let json = """
      {"langId":\(index),"languageCode":"\(code)","languageLocal":"\(code)"}
      """
    return try JSONDecoder().decode(
      LanguageItemEntity.self,
      from: Data(json.utf8)
    )
  }
}
