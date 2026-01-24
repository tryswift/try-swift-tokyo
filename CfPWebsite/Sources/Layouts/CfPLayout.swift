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

      // Global script to update navigation based on login state
      Script(code: """
        document.addEventListener('DOMContentLoaded', function() {
          const token = localStorage.getItem('cfp_token');
          const username = localStorage.getItem('cfp_username');

          // Find the login button by its text
          const navLinks = document.querySelectorAll('.navbar-nav a');
          let loginButton = null;
          navLinks.forEach(link => {
            if (link.textContent.trim() === 'Login with GitHub') {
              loginButton = link;
            }
          });

          if (token && username && loginButton) {
            // User is logged in - replace login button with user info
            const navContainer = loginButton.parentElement;

            // Update login button to show username
            loginButton.textContent = '👤 ' + username;
            loginButton.href = '/my-proposals';
            loginButton.classList.remove('btn', 'btn-sm', 'btn-light');
            loginButton.classList.add('text-white', 'fw-bold');

            // Add My Proposals link
            const myProposalsLink = document.createElement('a');
            myProposalsLink.href = '/my-proposals';
            myProposalsLink.textContent = 'My Proposals';
            myProposalsLink.className = 'nav-link text-white';
            const myProposalsLi = document.createElement('li');
            myProposalsLi.className = 'nav-item';
            myProposalsLi.appendChild(myProposalsLink);
            navContainer.appendChild(myProposalsLi);

            // Add Sign Out button
            const signOutLink = document.createElement('a');
            signOutLink.href = '#';
            signOutLink.textContent = 'Sign Out';
            signOutLink.className = 'btn btn-sm btn-danger';
            signOutLink.addEventListener('click', function(e) {
              e.preventDefault();
              localStorage.removeItem('cfp_token');
              localStorage.removeItem('cfp_username');
              window.location.href = '/';
            });
            const signOutLi = document.createElement('li');
            signOutLi.className = 'nav-item';
            signOutLi.appendChild(signOutLink);
            navContainer.appendChild(signOutLi);
          }
        });
      """)
    }
  }
}
