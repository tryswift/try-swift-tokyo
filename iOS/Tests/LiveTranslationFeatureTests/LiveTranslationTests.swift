import ComposableArchitecture
import LiveTranslationSDK_iOS
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

    let langList = makeLangList(["en", "ja", "ko"])
    await store.send(.validateSelectedLangCode(langList))
  }

  @Test
  func validateSelectedLangCode_invalidCode_fallbackToEn() async {
    @Shared(.selectedLangCode) var selectedLangCode = "xx"
    let state = LiveTranslation.State()

    let store = TestStore(initialState: state) {
      LiveTranslation()
    }
    store.exhaustivity = .off

    let langList = makeLangList(["en", "ja", "ko"])
    await store.send(.validateSelectedLangCode(langList)) {
      $0.$selectedLangCode.withLock { $0 = "en" }
    }
  }
}

private func makeLangList(_ codes: [String]) -> [LanguageEntity.Response.LanguageItem] {
  codes.enumerated().compactMap { index, code in
    let json = """
      {"langID":\(index),"language":"\(code)","langCode":"\(code)","langORG":"\(code)","langLocal":"\(code)","isSupportLangSet":true}
      """
    return try? JSONDecoder().decode(
      LanguageEntity.Response.LanguageItem.self,
      from: Data(json.utf8)
    )
  }
}
