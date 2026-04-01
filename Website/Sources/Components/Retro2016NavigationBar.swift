import Ignite
import SharedModels

struct Retro2016NavigationBar: HTML {
  let language: SupportedLanguage

  private var sections: [HomeSectionType] {
    [.speaker, .timetable, .access]
  }

  var body: some HTML {
    NavigationBar {
      for section in sections {
        let target = "#\(section.htmlId)"
        Link(String(section.rawValue, language: language), target: target)
          .role(.secondary)
      }
      Link(String("FAQ", language: language), target: FAQ(language: language))
        .role(.secondary)
    } logo: {
      LanguageSelector(
        path: { Home.generatePath(for: .year2016, language: $0) },
        currentLanguage: language
      )
    }
    .navigationBarStyle(.light)
    .background(.white.opacity(0.95))
    .position(.fixedTop)
  }
}
