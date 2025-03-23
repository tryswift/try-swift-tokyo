import Foundation
import Ignite
import SharedModels

struct SponsorComponent: HTML {
  let sponsor: Sponsor
  let size: CGSize
  let language: SupportedLanguage

  var body: some HTML {
    var image: any InlineElement {
      Image(sponsor.imageFilename, description: sponsor.name ?? "sponsor logo")
        .resizable()
        .frame(maxWidth: Int(size.width), maxHeight: Int(size.height))
        .margin(.bottom, .px(16))
    }
    if let target = sponsor.getLocalizedLink(language: language)?.absoluteString {
      Link(image, target: target)
        .target(.newWindow)
    } else {
      image
    }
  }
}

private extension Sponsor {
  func getLocalizedLink(language: SupportedLanguage) -> URL? {
    switch language {
    case .ja: japaneseLink ?? link
    case .en: link
    }
  }

  var imageFilename: String {
    "/images/from_app/\(imageName).png"
  }
}
