import Ignite

struct MainNavigationBar: HTML {
  let path: (SupportedLanguage) -> String
  let sections: [HomeSectionType]
  let language: SupportedLanguage

  var body: some HTML {
    NavigationBar {
      for section in sections {
        let target: String = {
          let homePath = Home.generatePath(language: language)
          return path(language) == homePath ? "#\(section.htmlId)" : "\(homePath)#\(section.htmlId)"
        }()
        Link(String(section.rawValue, language: language), target: target)
          .role(.light)
      }
      Link(String("FAQ", language: language), target: FAQ(language: language))
        .role(.light)
    } logo: {
      LanguageSelector(path: path, currentLanguage: language)
    }
    .navigationBarStyle(.dark)
    .background(.darkBlue.opacity(0.7))
    .position(.fixedTop)
  }
}
