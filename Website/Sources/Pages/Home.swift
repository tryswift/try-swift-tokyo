import DataClient
import Dependencies
import Foundation
import Ignite
import SharedModels

struct Home: StaticPage {
  let year: ConferenceYear
  let language: SupportedLanguage
  var title = ""

  var path: String {
    Home.generatePath(for: year, language: language)
  }

  var description: String {
    String(
      "Developers from all over the world will gather for tips and tricks and the latest examples of development using Swift. The event will be held for three days from April 12 - 14, 2026, with the aim of sharing our Swift knowledge and skills and collaborating with each other!",
      language: language
    )
  }

  @Dependency(DataClient.self) var dataClient

  var body: some HTML {
    Script(file: URL(string: "https://embed.lu.ma/checkout-button.js")!).id("luma-checkout")

    MainNavigationBar(
      path: Home.generatePath(for:language:),
      sections: HomeSectionType.navigationItems(for: year),
      year: year,
      language: language
    )

    ForEach(HomeSectionType.allCases.filter { $0.isAvailable(for: year) }) { sectionType in
      sectionType.generateContents(for: year, language: language, dataClient: dataClient)
    }
  }

  static func generatePath(for year: ConferenceYear, language: SupportedLanguage) -> String {
    var pathComponents = [String]()
    if year != .latest {
      pathComponents.append(String(year.rawValue))
    }
    if language != .ja {
      pathComponents.append(language.rawValue)
    }
    return "/" + pathComponents.joined(separator: "/")
  }
}
