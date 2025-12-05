import Foundation
import Ignite
import SharedModels

struct MainFooter: HTML {
  let year: ConferenceYear
  let language: SupportedLanguage

  var body: some HTML {
    Column {
      Text {
        Link(String("Code of Conduct", language: language), target: CodeOfConduct(language: language))
          .role(.light)
          .margin(.trailing, .small)
        Link(String("Privacy Policy", language: language), target: PrivacyPolicy(language: language))
          .role(.light)
      }
      .horizontalAlignment(.center)
      .font(.body)
      .fontWeight(.semibold)

      Text {
        InlineForEach(ConferenceYear.allCases.filter { $0 != year }) { year in
          Link(
            String("\(year.rawValue)", language: language),
            target: Home(year: year, language: language)
          )
          .role(.light)
          .margin(.trailing, year == ConferenceYear.allCases.last ? .none : .small)
        }
      }
      .horizontalAlignment(.center)
      .font(.body)
      .fontWeight(.semibold)
      .padding(.bottom, .large)

      Text("© 2016 try! Swift Tokyo")
        .horizontalAlignment(.center)
        .font(.body)
        .fontWeight(.light)
        .border(.white, width: 1, edges: .top)
    }
  }
}
