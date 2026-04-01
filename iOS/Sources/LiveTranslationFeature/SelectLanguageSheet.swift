import DependencyExtra
import LiveTranslationSDK
import SwiftUI

struct SelectLanguageSheet: View {
  let languageList: [LanguageItemEntity]
  let selectedLanguageAction: (LanguageItemEntity) -> Void

  private var sortedLanguages: [LanguageItemEntity] {
    let priorityCodes = ["ja", "en"]
    let priority = priorityCodes.flatMap { code in
      languageList.filter { $0.languageCode == code }
    }
    let rest = languageList.filter { !priorityCodes.contains($0.languageCode) }
    return priority + rest
  }

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(sortedLanguages) { langItem in
          Button(action: { selectedLanguageAction(langItem) }) {
            Text(langItem.languageLocal)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
              .contentShape(.rect)
          }
          .glassEffectIfAvailable(.regular.interactive(), in: .rect(cornerRadius: 12))
        }
      }
      .padding()
    }
  }
}
