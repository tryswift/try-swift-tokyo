import Foundation

/// Helper to resolve image paths with various extensions
enum ImagePath {
  /// Supported image extensions in order of preference
  private static let supportedExtensions = ["png", "jpg", "jpeg", "gif", "webp", "svg"]

  /// Assets directory URL
  private static let assetsDirectory: URL? = {
    // Try to find the Assets directory relative to the source file
    guard let sourceDir = try? URL.selectDirectories(from: #file).source else {
      return nil
    }
    return sourceDir.deletingLastPathComponent().appending(path: "Assets/images/from_app")
  }()

  /// Resolve image path for a given image name (without extension)
  /// Returns the web path (e.g., "/images/from_app/speaker.jpg")
  static func resolve(_ imageName: String) -> String {
    // Try to find the file with various extensions
    if let assetsDir = assetsDirectory {
      for ext in supportedExtensions {
        let filePath = assetsDir.appendingPathComponent("\(imageName).\(ext)")
        if FileManager.default.fileExists(atPath: filePath.path) {
          return "/images/from_app/\(imageName).\(ext)"
        }
      }
    }

    // Fallback to PNG if file not found (will show broken image, but that's informative)
    return "/images/from_app/\(imageName).png"
  }
}
