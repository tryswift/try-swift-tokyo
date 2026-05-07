import Elementary

public struct WebLayout<Body: HTML>: HTML {
  public let pageTitle: String
  public let locale: WebLocale
  public let apiBaseURL: String?
  public let pageBody: Body

  public init(
    pageTitle: String,
    locale: WebLocale,
    apiBaseURL: String? = nil,
    @HTMLBuilder pageBody: () -> Body
  ) {
    self.pageTitle = pageTitle
    self.locale = locale
    self.apiBaseURL = apiBaseURL
    self.pageBody = pageBody()
  }

  public var body: some HTML {
    HTMLRaw("<!DOCTYPE html>")
    html(.lang(locale.htmlLang)) {
      head {
        meta(.charset(.utf8))
        meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
        title { pageTitle }
        link(.rel(.stylesheet), .href("/sponsor/sponsor.css"))
        if let apiBaseURL {
          // Cloudflare Pages build path: client JS reads this to call api.tryswift.jp.
          meta(.custom(name: "name", value: "sponsor-api-base-url"), .content(apiBaseURL))
          script(.src("/scripts/sponsor.js"), .custom(name: "defer", value: "defer")) {}
        } else {
          // Server SSR path: HTMX is wired up by the Vapor controller chain.
          script(
            .src(HTMX.cdnURL),
            .integrity(HTMX.sriHash),
            .crossorigin(.anonymous)
          ) {}
        }
      }
      Elementary.body {
        pageBody
      }
    }
  }
}
