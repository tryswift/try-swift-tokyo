import Ignite

struct CfPNavigation: HTML {
  var body: some HTML {
    NavigationBar {
      Link("Home", target: CfPHome())
        .role(.light)
      Link("Guidelines", target: GuidelinesPage())
        .role(.light)
      Link("Submit", target: SubmitPage())
        .role(.light)
      Link("Login with GitHub", target: LoginPage())
        .role(.light)
    } logo: {
      Link("try! Swift Tokyo CfP", target: "/")
        .fontWeight(.bold)
        .foregroundStyle(.white)
    }
    .navigationBarStyle(.dark)
    .background(.darkSlateGray)
    .position(.fixedTop)
  }
}

struct CfPFooter: HTML {
  var body: some HTML {
    Section {
      Text("try! Swift Tokyo CfP")
        .font(.title3)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .margin(.bottom, .medium)
      
      Text("Submit your talk proposal for try! Swift Tokyo 2026")
        .foregroundStyle(.white)
      
      Section {
        Link("Website", target: URL(string: "https://tryswift.jp")!)
          .role(.light)
        Link("Twitter", target: URL(string: "https://twitter.com/tryswift")!)
          .role(.light)
        Link("GitHub", target: URL(string: "https://github.com/tryswift")!)
          .role(.light)
      }
      .margin(.top, .medium)
      
      Text("© 2026 try! Swift Tokyo. All rights reserved.")
        .font(.body)
        .foregroundStyle(.white)
        .margin(.top, .large)
    }
    .padding(.vertical, .large)
    .background(.darkSlateGray)
    .horizontalAlignment(.center)
  }
}
