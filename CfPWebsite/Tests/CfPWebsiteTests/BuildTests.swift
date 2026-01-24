import Testing
@testable import CfPWebsite

@Suite("CfP Website Build Tests")
struct BuildTests {

  @Test("CfPSite instantiates without errors")
  @MainActor
  func siteInstantiates() {
    let site = CfPSite()
    #expect(site.name == "try! Swift Tokyo CfP")
  }

  @Test("Site has correct URL")
  @MainActor
  func siteURL() {
    let site = CfPSite()
    #expect(site.url.absoluteString == "https://tryswift.jp")
  }

  @Test("Site has favicon")
  @MainActor
  func siteFavicon() {
    let site = CfPSite()
    #expect(site.favicon != nil)
    #expect(site.favicon!.absoluteString.contains("/cfp/images/favicon.png"))
  }
}
