import Foundation
import Ignite
import SharedModels

struct SponsorComponent: HTML {
  private let sponsor: Sponsor
  private let size: CGSize
  private let language: SupportedLanguage
  private let image: any InlineElement

  init(sponsor: Sponsor, size: CGSize, language: SupportedLanguage) {
    self.sponsor = sponsor
    self.size = size
    self.language = language

    self.image = Image(sponsor.imageFilename, description: sponsor.name ?? "sponsor logo")
      .resizable()
      .frame(maxWidth: Int(size.width), maxHeight: Int(size.height))
      .frame(width: .percent(.init(100)))
  }

  var body: some HTML {
    if let target = sponsor.getLocalizedLink(language: language)?.absoluteString {
      Link(image, target: target)
        .target(.newWindow)
    } else {
      image
    }
  }
}

extension Sponsor {
  fileprivate func getLocalizedLink(language: SupportedLanguage) -> URL? {
    switch language {
    case .ja: japaneseLink ?? link
    case .en: link
    }
  }

  fileprivate var imageFilename: String {
    // Extract filename from namespace path (e.g., "Sponsor/2026/2026_RevenueCat" -> "2026_RevenueCat")
    // or keep as-is if no namespace (for backward compatibility)
    let filename = imageName.components(separatedBy: "/").last ?? imageName
    return ImagePath.resolve(filename)
  }
}
