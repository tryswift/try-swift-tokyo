import SharedModels

extension Speaker {
  var imageFilename: String {
    // Extract filename from namespace path (e.g., "Sponsor/2026/2026_RevenueCat" -> "2026_RevenueCat")
    // or keep as-is if no namespace (for backward compatibility)
    let filename = imageName.components(separatedBy: "/").last ?? imageName
    return ImagePath.resolve(filename)
  }
}
