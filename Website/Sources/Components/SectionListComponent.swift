import Foundation
import Ignite

protocol SectionDefinition: RawRepresentable, CaseIterable where RawValue == String {
  var title: String { get }
  var description: String { get }
}

extension SectionDefinition {
  var title: String {
    rawValue
  }
}

struct SectionListComponent: HTML {
  let title: String
  let dataSource: [any SectionDefinition]
  let language: SupportedLanguage

  var body: some HTML {
    Text(title)
      .horizontalAlignment(.center)
      .font(.title1)
      .fontWeight(.bold)
      .foregroundStyle(.bootstrapPurple)

    ForEach(dataSource) { sectionType in
      Section {
        if !sectionType.title.isEmpty {
          Text(String(sectionType.title, language: language))
            .horizontalAlignment(.center)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.bootstrapPurple)
            .margin(.top, .px(80))
            .margin(.bottom, .px(16))
        }

        let description = String(sectionType.description, language: language)
        Text(markdown: description)
          .horizontalAlignment(description.displayedCharacterCount() > 100 ? .leading : .center)
          .font(.body)
          .foregroundStyle(.dimGray)
      }
    }
  }
}

extension String {
  fileprivate func displayedCharacterCount() -> Int {
    // Strip HTML tags to get approximate displayed character count
    // This is a simple regex-based approach that works on Linux
    let htmlTagPattern = "<[^>]+>"
    let strippedString = self.replacingOccurrences(
      of: htmlTagPattern,
      with: "",
      options: .regularExpression
    )
    return strippedString.count
  }
}
