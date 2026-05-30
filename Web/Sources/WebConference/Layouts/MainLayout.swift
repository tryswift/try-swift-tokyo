import Ignite
import SharedModels

struct MainLayout: Layout {
  @Environment(\.page) private var currentPage
  let title: String
  let ogpLink: String

  var body: some Document {
    Head {
      if currentPage.url.path.contains("/2016") {
        MetaLink(href: "/css/retro-2016.css", rel: "stylesheet")
      }
      if currentPage.url.path.contains("/booth-map") {
        MetaTag(name: "theme-color", content: "#BDA4C4")
        MetaLink(href: "/css/booth-map.css", rel: "stylesheet")
        Script(
          code: """
            (function(){
              var v=document.querySelector('meta[name=viewport]');
              if(v&&!v.content.includes('viewport-fit')){v.content+=',viewport-fit=cover';}
            })();
            """
        )
      }
      MetaTag(.openGraphTitle, content: title)
      MetaTag(.openGraphImage, content: ogpLink)
      MetaTag(.twitterTitle, content: title)
      MetaTag(.twitterImage, content: ogpLink)

      if currentPage.url.pathComponents.last == "_en" {
        // The latest English home moved from `/en` to `/2026/en`; keep the legacy
        // `/_en` shim pointing at whatever the current English home path is.
        let redirectPath = Home.generatePath(for: .latest, language: .en)
        MetaTag(httpEquivalent: "refresh", content: "0;url=\(redirectPath)")
      }
    }

    Body {
      content
    }
  }
}
