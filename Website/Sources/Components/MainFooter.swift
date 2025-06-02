import Foundation
import Ignite

struct MainFooter: HTML {
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

      Text("© 2016 try! Swift Tokyo")
        .horizontalAlignment(.center)
        .font(.body)
        .fontWeight(.light)
    }
  }
}
