import Ignite

struct MainLayout: Layout {
  @Environment(\.page) private var currentPage
  let title: String
  let ogpLink: String

  var body: some HTML {
    Head {
      MetaTag(.openGraphTitle, content: title)
      MetaTag(.openGraphImage, content: ogpLink)
      MetaTag(.twitterTitle, content: title)
      MetaTag(.twitterImage, content: ogpLink)

      if currentPage.url.pathComponents.last == "_en" {
        let redirectUrl = URL(string: currentPage.url.absoluteString.replacingOccurrences(of: "_", with: ""))!
        RedirectMetaTag(to: redirectUrl)
      }
    }

    Body {
      content
    }
  }
}
