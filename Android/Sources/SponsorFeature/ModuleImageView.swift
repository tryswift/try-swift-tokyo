import Foundation
import SwiftUI

private func androidAssetBundle() -> Bundle? {
  #if SKIP
    guard let rootURL = URL(string: "asset:/") else { return nil }
    return Bundle(url: rootURL)
  #else
    return nil
  #endif
}

private enum ModuleImageResolver {
  private static let fileExtensions = ["png", "jpg", "jpeg", "webp"]
  private static let searchRoots = ["", "Media.xcassets", "AndroidAssets"]

  static func url(named imageName: String) -> URL? {
    var pathComponents: [String] = []
    for component in imageName.split(separator: "/") {
      pathComponents.append(String(component))
    }
    guard let imageLeafName = pathComponents.last else { return nil }
    let normalizedDirectory = pathComponents.dropLast().joined(separator: "/")

    let bundles = [Bundle.module, androidAssetBundle()].compactMap { $0 }
    for bundle in bundles {
      for root in searchRoots {
        let baseSubdirectory = combinedSubdirectory(root: root, directory: normalizedDirectory)

        for fileExtension in fileExtensions {
          if let url = bundle.url(
            forResource: imageLeafName,
            withExtension: fileExtension,
            subdirectory: baseSubdirectory
          ) {
            return url
          }

          let imageSetSubdirectory: String
          if let baseSubdirectory {
            imageSetSubdirectory = "\(baseSubdirectory)/\(imageLeafName).imageset"
          } else {
            imageSetSubdirectory = "\(imageLeafName).imageset"
          }

          if let url = bundle.url(
            forResource: imageLeafName,
            withExtension: fileExtension,
            subdirectory: imageSetSubdirectory
          ) {
            return url
          }
        }
      }
    }
    return nil
  }

  private static func combinedSubdirectory(root: String, directory: String) -> String? {
    if root.isEmpty {
      return directory.isEmpty ? nil : directory
    } else {
      return directory.isEmpty ? root : "\(root)/\(directory)"
    }
  }
}

struct ModuleImageView<Placeholder: View>: View {
  let imageName: String
  let contentMode: ContentMode
  let placeholder: Placeholder

  init(
    imageName: String,
    contentMode: ContentMode = .fill,
    @ViewBuilder placeholder: () -> Placeholder
  ) {
    self.imageName = imageName
    self.contentMode = contentMode
    self.placeholder = placeholder()
  }

  var body: some View {
    if let imageURL = ModuleImageResolver.url(named: imageName) {
      AsyncImage(url: imageURL) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .aspectRatio(contentMode: contentMode)
        default:
          placeholder
        }
      }
    } else {
      placeholder
    }
  }
}
