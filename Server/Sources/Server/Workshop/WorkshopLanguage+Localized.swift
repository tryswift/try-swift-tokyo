import SharedModels

extension WorkshopLanguage {
  func localizedName(for language: CfPLanguage) -> String {
    switch (self, language) {
    case (.english, .ja): return "英語"
    case (.english, .en): return "English"
    case (.japanese, .ja): return "日本語"
    case (.japanese, .en): return "Japanese"
    case (.bilingual, .ja): return "バイリンガル"
    case (.bilingual, .en): return "Bilingual"
    case (.other, .ja): return "その他"
    case (.other, .en): return "Other"
    }
  }
}
