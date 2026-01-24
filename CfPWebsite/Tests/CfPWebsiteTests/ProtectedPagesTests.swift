import Testing
@testable import CfPWebsite

@Suite("Protected Pages Tests")
struct ProtectedPagesTests {

  @Test("SubmitPage has title")
  @MainActor
  func submitPageTitle() {
    let page = SubmitPage()
    #expect(page.title == "Submit Proposal")
  }

  @Test("MyProposalsPage has title")
  @MainActor
  func myProposalsPageTitle() {
    let page = MyProposalsPage()
    #expect(page.title == "My Proposals")
  }

  @Test("GuidelinesPage has title")
  @MainActor
  func guidelinesPageTitle() {
    let page = GuidelinesPage()
    #expect(page.title == "Submission Guidelines")
  }
}
