import DataClient
import Dependencies
import Foundation
import Ignite
import SharedModels

struct Home: StaticPage {
  let language: SupportedLanguage
  var title = ""

  var path: String {
    Home.generatePath(language: language)
  }

  var description: String {
    String(
        "Developers from all over the world will gather for tips and tricks and the latest examples of development using Swift. The event will be held for three days from April 9 - 11, 2025, with the aim of sharing our Swift knowledge and skills and collaborating with each other!",
        language: language
    )
  }

  @Dependency(DataClient.self) var dataClient

  var body: some HTML {
    MainNavigationBar(
      path: Home.generatePath(language:),
      sections: HomeSectionType.navigationItems,
      language: language
    )

    ForEach(HomeSectionType.allCases) { sectionType in
      sectionType.generateContents(language: language, dataClient: dataClient)
    }
  }

  static func generatePath(language: SupportedLanguage) -> String {
    switch language {
    case .ja: "/"
    case .en: "/en"
    }
  }
}
