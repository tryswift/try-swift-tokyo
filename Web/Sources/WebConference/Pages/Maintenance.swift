import Ignite

/// Root `/` landing page shown between conferences, modeled on Apple Store's
/// "We'll be back soon." maintenance screen. The Apple logo position is taken
/// by the try! Swift Tokyo mascot, Riko.
struct Maintenance: StaticPage {
  var title = ""
  var path = "/"
  // Override the site-level description so root metadata reflects the
  // maintenance state instead of stale 2026 conference details.
  var description = "try! Swift Tokyo will be back soon."

  var body: some HTML {
    Section {
      Image("/images/riko.png", description: "try! Swift Tokyo mascot Riko")
        .style(.width, "120px")
        .style(.height, "auto")
        .margin(.bottom, .px(32))

      Text("We'll be back soon.")
        .font(.title1)
        .fontWeight(.bold)
        .margin(.bottom, .px(16))

      Text(
        "We're making changes to the Conference and we'll be back soon. Please check back later."
      )
      .style(.color, "#86868b")
      .style(.maxWidth, "30rem")
    }
    .frame(width: .percent(100%), height: .vh(100%))
    .style(.display, "flex")
    .style(.flexDirection, "column")
    .style(.alignItems, "center")
    .style(.justifyContent, "center")
    .style(.textAlign, "center")
    .style(.backgroundColor, "#ffffff")
    .padding(.px(24))
  }
}
