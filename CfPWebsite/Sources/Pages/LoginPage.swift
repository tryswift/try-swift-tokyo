import Ignite

struct LoginPage: StaticPage {
  var title = "Login"

  var body: some HTML {
    // Login form (hidden when logged in)
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

          Link("Sign in with GitHub", target: "https://tryswift-cfp-api.fly.dev/api/v1/auth/github")
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
    .id("login-form")
    .padding(.vertical, .large)
    
    // Success message (hidden by default, shown after login)
    Section {
      Card {
        Section {
          Text("✅")
            .font(.title1)
            .margin(.bottom, .medium)
          
          Text("Welcome!")
            .font(.title2)
            .fontWeight(.bold)
            .margin(.bottom, .small)
            .id("welcome-message")
          
          Text("You are now signed in. You can submit and manage your talk proposals.")
            .foregroundStyle(.secondary)
            .margin(.bottom, .large)
          
          Text {
            Link("Submit a Proposal", target: SubmitPage())
              .linkStyle(.button)
              .role(.primary)
              .margin(.trailing, .medium)
            
            Link("My Proposals", target: MyProposalsPage())
              .linkStyle(.button)
              .role(.secondary)
          }
          
          Text {
            Link("Logout", target: "#")
              .id("logout-link")
              .foregroundStyle(.secondary)
          }
          .margin(.top, .large)
        }
        .horizontalAlignment(.center)
        .padding(.vertical, .large)
      }
    }
    .id("logged-in-view")
    .padding(.vertical, .large)
    
    // JavaScript for handling auth callback and localStorage
    Script(code: """
      document.addEventListener('DOMContentLoaded', function() {
        const loginForm = document.getElementById('login-form');
        const loggedInView = document.getElementById('logged-in-view');
        const welcomeMessage = document.getElementById('welcome-message');
        const logoutLink = document.getElementById('logout-link');
        
        // Check URL params for token (from OAuth callback)
        const urlParams = new URLSearchParams(window.location.search);
        const token = urlParams.get('token');
        const username = urlParams.get('username');
        const error = urlParams.get('error');
        
        if (error) {
          alert('Login failed: ' + error);
          loginForm.style.display = 'block';
          loggedInView.style.display = 'none';
          return;
        }
        
        if (token) {
          // Store token from callback
          localStorage.setItem('cfp_token', token);
          if (username) {
            localStorage.setItem('cfp_username', username);
          }
          // Clean URL
          window.history.replaceState({}, document.title, window.location.pathname);
        }
        
        // Check if user is logged in
        const storedToken = localStorage.getItem('cfp_token');
        const storedUsername = localStorage.getItem('cfp_username');
        
        if (storedToken) {
          loginForm.style.display = 'none';
          loggedInView.style.display = 'block';
          if (storedUsername) {
            welcomeMessage.textContent = 'Welcome, ' + storedUsername + '!';
          }
        } else {
          loginForm.style.display = 'block';
          loggedInView.style.display = 'none';
        }
        
        // Logout handler
        if (logoutLink) {
          logoutLink.addEventListener('click', function(e) {
            e.preventDefault();
            localStorage.removeItem('cfp_token');
            localStorage.removeItem('cfp_username');
            window.location.reload();
          });
        }
      });
    """)
  }
}
