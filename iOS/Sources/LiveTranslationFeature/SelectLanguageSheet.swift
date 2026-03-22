import DependencyExtra
import LiveTranslationSDK
import SwiftUI

struct SelectLanguageSheet: View {
  let languageList: [LanguageItemEntity]
  let selectedLanguageAction: (LanguageItemEntity) -> Void

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(languageList) { langItem in
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
