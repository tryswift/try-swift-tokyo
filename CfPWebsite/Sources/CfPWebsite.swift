import Foundation
import Ignite

@main
struct CfPWebsite {
  static func main() async {
    var site = CfPSite()

    do {
      try await site.publish()
    } catch {
      print(error.localizedDescription)
    }
  }
}

struct CfPSite: Site {
  var name = "try! Swift Tokyo CfP"
  var titleSuffix = " – try! Swift Tokyo"
  var url = URL(string: "https://cfp.tryswift.jp")!
  var builtInIconsEnabled = true
  var author = "try! Swift Tokyo"
  var favicon = URL(string: "/images/favicon.png")

  var homePage = CfPHome()
  var layout = CfPLayout()

  var staticPages: [any StaticPage] {
    CfPHome()
    SubmitPage()
    GuidelinesPage()
    LoginPage()
    MyProposalsPage()
  }
}
