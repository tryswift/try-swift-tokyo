import Ignite

struct CfPLayout: Layout {
  var body: some Document {
    Head {
      Title("try! Swift Tokyo CfP")
      MetaTag(.openGraphTitle, content: "try! Swift Tokyo 2026 - Call for Proposals")
      MetaTag(.openGraphDescription, content: "Submit your talk proposal for try! Swift Tokyo 2026. Share your Swift expertise with developers from around the world.")
      MetaTag(.openGraphImage, content: "https://cfp.tryswift.jp/images/ogp.png")
      MetaTag(.twitterCard, content: "summary_large_image")
      MetaTag(.twitterTitle, content: "try! Swift Tokyo 2026 - Call for Proposals")
      MetaTag(.twitterImage, content: "https://cfp.tryswift.jp/images/ogp.png")
    }

    Body {
      CfPNavigation()
      
      Section {
        content
      }
      .padding(.top, .px(60))
      
      CfPFooter()
    }
  }
}
