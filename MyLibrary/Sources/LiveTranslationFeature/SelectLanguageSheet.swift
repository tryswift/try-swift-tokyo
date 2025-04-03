#if canImport(LiveTranslationSDK_iOS)
  import LiveTranslationSDK_iOS
  import SwiftUI

  struct SelectLanguageSheet: View {
    let languageList: [LanguageEntity.Response.LanguageItem]
    let langSet: LanguageEntity.Response.LangSet?
    let selectedLanguageAction: (String) -> Void

    @State var languageListWithTitle: [LanguageWithTitle] = []

    var body: some View {
      ScrollView {
        LazyVStack {
          ForEach(languageListWithTitle) { lang in
            Button(action: { selectedLanguageAction(lang.langCode) }) {
              Text(lang.langTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .contentShape(.rect)
            }
          }
        }
      }
      .task {
        self.languageListWithTitle = await makeLanguageWithTitleList()
      }
    }
  }

  extension SelectLanguageSheet {
    fileprivate func makeLanguageWithTitleList() async -> [LanguageWithTitle] {
      await withCheckedContinuation { continuation in
        let newList: [LanguageWithTitle] = languageList.reduce([]) { current, next in
          guard let title = langSet?.langCodingKey(next.langCode) else { return current }
          return current + [.init(langCode: next.langCode, langTitle: title)]
        }

        continuation.resume(returning: newList)
      }
    }
  }

  extension SelectLanguageSheet {
    struct LanguageWithTitle: Equatable, Identifiable {
      var id: String { langCode }
      let langCode: String
      let langTitle: String

      init(langCode: String, langTitle: String) {
        self.langCode = langCode
        self.langTitle = langTitle
      }
    }
  }
#endif
