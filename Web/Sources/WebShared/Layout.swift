import Elementary

public struct WebLayout<Body: HTML>: HTML {
  public let pageTitle: String
  public let locale: WebLocale
  public let pageBody: Body

  public init(pageTitle: String, locale: WebLocale, @HTMLBuilder pageBody: () -> Body) {
    self.pageTitle = pageTitle
    self.locale = locale
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
        script(
          .src(HTMX.cdnURL),
          .integrity(HTMX.sriHash),
          .crossorigin(.anonymous)
        ) {}
      }
      Elementary.body {
        pageBody
      }
    }
  }
}
