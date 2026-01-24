import Testing
@testable import CfPWebsite

@Suite("Navigation Component Tests")
struct NavigationTests {

  @Test("Navigation has body")
  @MainActor
  func hasBody() {
    let nav = CfPNavigation()
    #expect(nav.body != nil)
  }

  @Test("Footer has copyright text")
  @MainActor
  func footerCopyright() {
    let footer = CfPFooter()
    #expect(footer.body != nil)
  }
}
