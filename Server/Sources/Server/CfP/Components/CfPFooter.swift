import Elementary

struct CfPFooter: HTML, Sendable {
  let language: CfPLanguage

  init(language: CfPLanguage = .en) {
    self.language = language
  }

  var body: some HTML {
    footer(.class("py-5 text-center"), .style("background: #00203f;")) {
      div(.class("container")) {
        div(.class("mb-3")) {
          a(.class("text-white text-decoration-none me-3"), .href("https://tryswift.jp")) {
            language == .ja ? "メインサイト" : "Main Website"
          }
          a(.class("text-white text-decoration-none me-3"), .href("https://tryswift.jp/code-of-conduct")) {
            language == .ja ? "行動規範" : "Code of Conduct"
          }
          a(.class("text-white text-decoration-none"), .href("https://tryswift.jp/privacy-policy")) {
            language == .ja ? "プライバシーポリシー" : "Privacy Policy"
          }
        }

        div(.class("mb-3")) {
          a(.class("text-white text-decoration-none me-3"), .href("https://twitter.com/tryswiftconf")) { "Twitter" }
          a(.class("text-white text-decoration-none"), .href("https://github.com/tryswift")) { "GitHub" }
        }

        p(.class("text-white-50 mb-0")) {
          "© 2026 try! Swift Tokyo. All rights reserved."
        }
      }
    }
  }
}
