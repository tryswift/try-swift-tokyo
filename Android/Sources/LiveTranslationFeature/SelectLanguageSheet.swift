import SwiftUI

struct SelectLanguageSheet: View {
  let languages: [LanguageItem]
  let onSelect: (String, String) -> Void

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(languages) { lang in
            Button(action: { onSelect(lang.langCode, lang.langTitle) }) {
              Text(lang.langTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
        }
        .padding()
      }
      .navigationTitle("Select Language")
      #if os(iOS) || SKIP
      .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
      #endif
    }
  }
}
