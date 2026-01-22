import Ignite

struct CfPNavigation: HTML {
  static let apiBaseURL = "https://tryswift-cfp-api.fly.dev"
  
  var body: some HTML {
    NavigationBar {
      Link("Home", target: CfPHome())
        .role(.light)
      Link("Guidelines", target: GuidelinesPage())
        .role(.light)
      Link("Submit", target: SubmitPage())
        .role(.light)
      
      Span {
        Link("Login with GitHub", target: URL(string: "\(Self.apiBaseURL)/auth/github")!)
          .linkStyle(.button)
          .buttonSize(.small)
          .role(.light)
          .fontWeight(.bold)
      }
      .navigationBarVisibility(.always)
    } logo: {
      Link("try! Swift Tokyo CfP", target: "/")
        .fontWeight(.bold)
        .foregroundStyle(.white)
    }
    .navigationBarStyle(.dark)
    .background(.darkBlue.opacity(0.9))
    .position(.fixedTop)
  }
}

struct CfPFooter: HTML {
  var body: some HTML {
    Section {
      Section {
        Link("Main Website", target: "https://tryswift.jp")
          .role(.light)
          .margin(.trailing, .small)
        Link("Code of Conduct", target: "https://tryswift.jp/code-of-conduct")
          .role(.light)
          .margin(.trailing, .small)
        Link("Privacy Policy", target: "https://tryswift.jp/privacy-policy")
          .role(.light)
      }
      .horizontalAlignment(.center)
      .font(.body)
      .fontWeight(.semibold)
      .margin(.bottom, .medium)
      
      Section {
        Link("Twitter", target: "https://twitter.com/tryswiftconf")
          .role(.light)
          .margin(.trailing, .medium)
        
        Link("GitHub", target: "https://github.com/tryswift")
          .role(.light)
      }
      .margin(.bottom, .medium)
      
      Text("© 2026 try! Swift Tokyo. All rights reserved.")
        .font(.body)
        .foregroundStyle(.white.opacity(0.7))
    }
    .padding(.vertical, .large)
    .background(.darkBlue)
    .horizontalAlignment(.center)
  }
}
