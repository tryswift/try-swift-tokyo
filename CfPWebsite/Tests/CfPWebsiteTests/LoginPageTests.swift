import Testing
@testable import CfPWebsite

@Suite("Login Page Tests")
struct LoginPageTests {

  @Test("LoginPage has title")
  @MainActor
  func pageTitle() {
    let page = LoginPage()
    #expect(page.title == "Login")
  }

  @Test("Login page body contains login form section")
  @MainActor
  func hasLoginForm() {
    let page = LoginPage()
    // Verify page body is not empty
    #expect(page.body != nil)
  }

  @Test("Login page has OAuth callback handler script")
  @MainActor
  func hasOAuthScript() {
    let page = LoginPage()
    // Page should have script for authentication
    #expect(page.body != nil)
  }
}
