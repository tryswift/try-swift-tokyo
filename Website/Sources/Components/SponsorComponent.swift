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
        "/images/from_app/\(imageName).png"
    }
}
