import Elementary
import SharedModels

struct CfPLayout<Content: HTML & Sendable>: HTMLDocument, Sendable {
  var title: String
  let user: UserDTO?
  let pageContent: Content

  init(title: String, user: UserDTO?, @HTMLBuilder pageContent: () -> Content) {
    self.title = title
    self.user = user
    self.pageContent = pageContent()
  }

  var head: some HTML {
    meta(.charset(.utf8))
    meta(.name(.viewport), .content("width=device-width, initial-scale=1"))
    HTMLRaw("<title>\(title) - try! Swift Tokyo CfP</title>")
    link(
      .rel(.stylesheet),
      .href("https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css")
    )
    // OGP Meta tags
    meta(.property("og:title"), .content("\(title) - try! Swift Tokyo 2026"))
    meta(
      .property("og:description"),
      .content(
        "Submit your talk proposal for try! Swift Tokyo 2026. Share your Swift expertise with developers from around the world."
      )
    )
    meta(.property("og:image"), .content("https://tryswift.jp/cfp/images/ogp.png"))
    meta(.name("twitter:card"), .content("summary_large_image"))
    meta(.name("twitter:title"), .content("\(title) - try! Swift Tokyo 2026"))
    meta(.name("twitter:image"), .content("https://tryswift.jp/cfp/images/ogp.png"))
    // Custom styles
    HTMLRaw(
      """
      <style>
        .hero-section { background: #00203f; }
        .purple-text { color: #7952b3; }
        .btn-purple { background-color: #7952b3; border-color: #7952b3; color: white; }
        .btn-purple:hover { background-color: #5e3d8f; border-color: #5e3d8f; color: white; }
        .bg-purple { background-color: #7952b3; }
      </style>
      """)
  }

  var body: some HTML {
    CfPNavigation(user: user)

    main(.style("padding-top: 70px;")) {
      pageContent
    }

    CfPFooter()

    script(
      .src("https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js")
    ) {}
  }
}
