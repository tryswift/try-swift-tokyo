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
      Link(target: "/") {
        Text("try! Swift Tokyo CfP")
          .fontWeight(.bold)
          .foregroundStyle(.white)
      }
    }
    .navigationBarStyle(.dark)
    .background(.darkBlue.opacity(0.9))
    .position(.fixedTop)
  }
}

struct CfPFooter: HTML {
  var body: some HTML {
    Section {
      Text {
        Link("Main Website", target: URL(string: "https://tryswift.jp")!)
          .role(.light)
          .margin(.trailing, .small)
        Link("Code of Conduct", target: URL(string: "https://tryswift.jp/code-of-conduct")!)
          .role(.light)
          .margin(.trailing, .small)
        Link("Privacy Policy", target: URL(string: "https://tryswift.jp/privacy-policy")!)
          .role(.light)
      }
      .horizontalAlignment(.center)
      .font(.body)
      .fontWeight(.semibold)
      .margin(.bottom, .medium)
      
      Text {
        Link(target: URL(string: "https://twitter.com/tryabortokyoswift")!) {
          Image(systemName: "twitter")
        }
        .role(.light)
        .margin(.trailing, .medium)
        
        Link(target: URL(string: "https://github.com/tryswift")!) {
          Image(systemName: "github")
        }
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
