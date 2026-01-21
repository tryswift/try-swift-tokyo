import Ignite

struct LoginPage: StaticPage {
  var title = "Login"
  
  var body: some HTML {
    Section {
      Card {
        Section {
          Text("🔐")
            .font(.title1)
            .margin(.bottom, .medium)
          
          Text("Sign in to try! Swift CfP")
            .font(.title2)
            .fontWeight(.bold)
            .margin(.bottom, .small)
          
          Text("Connect your GitHub account to submit and manage your talk proposals.")
            .foregroundStyle(.secondary)
            .margin(.bottom, .large)
          
          Link("Sign in with GitHub", target: "/api/v1/auth/github")
            .linkStyle(.button)
            .role(.dark)
          
          Text("By signing in, you agree to our terms of service and privacy policy.")
            .font(.body)
            .foregroundStyle(.secondary)
            .margin(.top, .medium)
        }
        .horizontalAlignment(.center)
        .padding(.vertical, .large)
      }
    }
    .padding(.vertical, .large)
  }
}
