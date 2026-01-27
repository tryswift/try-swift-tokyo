import Elementary

struct CfPFooter: HTML, Sendable {
  let language: CfPLanguage

  var body: some HTML {
    footer(.class("py-5 text-center"), .style("background: #00203f;")) {
      div(.class("container")) {
        div(.class("mb-3")) {
          a(.class("text-white text-decoration-none me-3"), .href("https://tryswift.jp")) {
            CfPStrings.Footer.mainWebsite(language)
          }
          a(
            .class("text-white text-decoration-none me-3"),
            .href("https://tryswift.jp/\(language == .ja ? "ja" : "en")/code-of-conduct")
          ) {
            CfPStrings.Footer.codeOfConduct(language)
          }
          a(
            .class("text-white text-decoration-none"),
            .href("https://tryswift.jp/\(language == .ja ? "ja" : "en")/privacy-policy")
          ) {
            CfPStrings.Footer.privacyPolicy(language)
          }
        }

        div(.class("mb-3")) {
          a(
            .class("text-white text-decoration-none me-3"),
            .href("https://twitter.com/tryswiftconf")
          ) { "Twitter" }
          a(.class("text-white text-decoration-none"), .href("https://github.com/tryswift")) {
            "GitHub"
          }
        }

        p(.class("text-white-50 mb-0")) {
          "© 2026 try! Swift Tokyo. All rights reserved."
        }
      }
    }
  }
}
