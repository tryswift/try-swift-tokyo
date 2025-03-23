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
        Text(String(sectionType.title, language: language))
          .horizontalAlignment(.center)
          .font(.title2)
          .fontWeight(.bold)
          .foregroundStyle(.bootstrapPurple)
          .margin(.top, .px(80))
          .margin(.bottom, .px(16))

        let description = String(sectionType.description, language: language)
        Text(markdown: description)
          .horizontalAlignment(description.displayedCharacterCount() > 100 ? .leading : .center)
          .font(.body)
          .foregroundStyle(.dimGray)
      }
    }
  }
}

private extension String {
  func displayedCharacterCount() -> Int {
    guard let data = self.data(using: .utf8) else {
      return .zero
    }
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
      .documentType: NSAttributedString.DocumentType.html,
      .characterEncoding: String.Encoding.utf8.rawValue
    ]
    let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil)

    return attributedString?.string.count ?? .zero
  }
}
