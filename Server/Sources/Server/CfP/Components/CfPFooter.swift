import Elementary

struct CfPFooter: HTML, Sendable {
  var body: some HTML {
    footer(.class("py-5 text-center"), .style("background: #00203f;")) {
      div(.class("container")) {
        div(.class("mb-3")) {
          a(.class("text-white text-decoration-none me-3"), .href("https://tryswift.jp")) {
            "Main Website"
          }
          a(
            .class("text-white text-decoration-none me-3"),
            .href("https://tryswift.jp/code-of-conduct")
          ) {
            "Code of Conduct"
          }
          a(.class("text-white text-decoration-none"), .href("https://tryswift.jp/privacy-policy"))
          {
            "Privacy Policy"
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
