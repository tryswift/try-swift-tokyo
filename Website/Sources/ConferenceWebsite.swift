import Cocoa
import Foundation
import Ignite

@main
struct ConferenceWebsite {
  static func main() async {
    var site = ConferenceSite2025()

    do {
      try copyAssets()
      try copyAASAFile()

      try await site.publish()
    } catch {
      print(error.localizedDescription)
    }
  }

  private static func copyAssets() throws {
    let fileManager = FileManager.default

    let websiteDirectory = try URL.selectDirectories(from: #file).source
    let websiteAssetsDirectory = websiteDirectory.appending(path: "Assets")
    let iosAppDirectory = websiteDirectory.deletingLastPathComponent().appending(path: "MyLibrary")

    let sponsorMediaDirectory = iosAppDirectory.appending(path: "Sources/SponsorFeature/Media.xcassets")
    let sponsorMediaEnumerator = fileManager.enumerator(at: sponsorMediaDirectory, includingPropertiesForKeys: nil)

    let scheduleMediaDirectory = iosAppDirectory.appending(path: "Sources/ScheduleFeature/Media.xcassets")
    let scheduleMediaEnumerator = fileManager.enumerator(at: scheduleMediaDirectory, includingPropertiesForKeys: nil)

    let trySwiftMediaDirectory = iosAppDirectory.appending(path: "Sources/trySwiftFeature/Media.xcassets")
    let trySwiftMediaEnumerator = fileManager.enumerator(at: trySwiftMediaDirectory, includingPropertiesForKeys: nil)

    try [sponsorMediaEnumerator, scheduleMediaEnumerator, trySwiftMediaEnumerator].forEach {
      while let file = $0?.nextObject() as? URL {
        let destURL = websiteAssetsDirectory.appendingPathComponent("images/from_app/\(file.deletingPathExtension().lastPathComponent).png")

        let destinationDirectory = destURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
          try fileManager.createDirectory(
            at: destinationDirectory,
            withIntermediateDirectories: true,
            attributes: nil
          )
        }

        if fileManager.fileExists(atPath: destURL.path) {
          try fileManager.removeItem(at: destURL)
        }

        if file.pathExtension == "png" {
          try fileManager.copyItem(at: file, to: destURL)
        } else if let image = NSImage(contentsOf: file) {
          let pngData = NSBitmapImageRep(data: image.tiffRepresentation!)!
            .representation(using: .png, properties: [:])!
          try pngData.write(to: destURL)
        } else {
          continue
        }
      }
    }
  }

  private static func copyAASAFile() throws {
    let fileManager = FileManager.default

    let websiteDirectory = try URL.selectDirectories(from: #file).source
    let websiteWellKnownDirectory = websiteDirectory.appending(path: "Assets/.well-known")
    let aasaFile = websiteWellKnownDirectory.appending(path: "apple-app-site-association")

    if !fileManager.fileExists(atPath: websiteWellKnownDirectory.path) {
      try fileManager.createDirectory(
        at: websiteWellKnownDirectory,
        withIntermediateDirectories: true,
        attributes: nil
      )
    }

    if fileManager.fileExists(atPath: aasaFile.path) {
      try fileManager.removeItem(at: aasaFile)
    }

    let aasaContent = """
    {
        "appclips": {
            "apps": ["9PC9DZ9559.jp.tryswift.tokyo.App.Clip"]
        }
    }
    """

    try aasaContent.write(to: aasaFile, atomically: true, encoding: .utf8)
  }
}

struct ConferenceSite2025: Site {
  var titleSuffix = " try! Swift Tokyo"
  var name = "try! Swift Tokyo"
  var description: String? = String(
    "Developers from all over the world will gather for tips and tricks and the latest examples of development using Swift. The event will be held for three days from April 9 - 11, 2025, with the aim of sharing our Swift knowledge and skills and collaborating with each other!",
    language: .ja
  )
  var language: Language = .japanese
  var url = URL(string: "https://tryswift.jp")!
  var homePage = Home(language: .ja)
  var layout = MainLayout(title: "try! Swift Tokyo", ogpLink: "https://tryswift.jp/images/ogp.jpg")
  var darkTheme: (any Theme)? = nil
  var favicon = URL(string: "/images/favicon.png")

  var staticPages: [any StaticPage] {
    for language in SupportedLanguage.allCases {
      Home(language: language)
      FAQ(language: language)
      CodeOfConduct(language: language)
      PrivacyPolicy(language: language)
    }
    LegacyHome()
  }
}

private struct LegacyHome: StaticPage {
  let title = ""
  var path = "/_en"

  var body: some HTML {
    Spacer()
  }
}
