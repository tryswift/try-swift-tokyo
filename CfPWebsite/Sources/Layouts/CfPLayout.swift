import Ignite

struct CfPLayout: Layout {
  var body: some Document {
    Head {
      Title("try! Swift Tokyo CfP")
      MetaTag(.openGraphTitle, content: "try! Swift Tokyo 2026 - Call for Proposals")
      MetaTag(.openGraphDescription, content: "Submit your talk proposal for try! Swift Tokyo 2026. Share your Swift expertise with developers from around the world.")
      MetaTag(.openGraphImage, content: "https://tryswift.jp/cfp/images/ogp.png")
      MetaTag(.twitterCard, content: "summary_large_image")
      MetaTag(.twitterTitle, content: "try! Swift Tokyo 2026 - Call for Proposals")
      MetaTag(.twitterImage, content: "https://tryswift.jp/cfp/images/ogp.png")
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
        // Helper function to delete cookie
        function deleteCookie(name) {
          document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
          document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.tryswift.jp';
        }

        document.addEventListener('DOMContentLoaded', function() {
          const token = localStorage.getItem('cfp_token');
          const username = localStorage.getItem('cfp_username');

          console.log('[Navigation] Debug:', {
            hasToken: !!token,
            hasUsername: !!username,
            username: username,
            cookies: document.cookie,
            localStorage: {
              token: localStorage.getItem('cfp_token')?.substring(0, 20) + '...',
              username: localStorage.getItem('cfp_username')
            }
          });

          // Find the login button by its text
          const navLinks = document.querySelectorAll('.navbar-nav a');
          let loginButton = null;
          navLinks.forEach(link => {
            if (link.textContent.trim() === 'Login with GitHub') {
              loginButton = link;
            }
          });

          console.log('[Navigation] Login button found:', !!loginButton);

          if (token && username && loginButton) {
            // User is logged in - replace login button with user info
            const loginLi = loginButton.parentElement; // This is the <li>
            const navUl = loginLi.parentElement; // This is the <ul>

            // Update login button to show username
            loginButton.textContent = '👤 ' + username;
            loginButton.href = '/cfp/my-proposals-page';
            loginButton.classList.remove('btn', 'btn-sm', 'btn-light');
            loginButton.classList.add('text-white', 'fw-bold', 'nav-link');
            loginButton.style.color = 'white';

            // Add My Proposals link
            const myProposalsLink = document.createElement('a');
            myProposalsLink.href = '/cfp/my-proposals-page';
            myProposalsLink.textContent = 'My Proposals';
            myProposalsLink.className = 'nav-link text-white';
            const myProposalsLi = document.createElement('li');
            myProposalsLi.className = 'nav-item';
            myProposalsLi.appendChild(myProposalsLink);
            navUl.appendChild(myProposalsLi);

            // Add Sign Out button
            const signOutLink = document.createElement('a');
            signOutLink.href = '#';
            signOutLink.textContent = 'Sign Out';
            signOutLink.className = 'btn btn-sm btn-danger text-nowrap';
            signOutLink.addEventListener('click', function(e) {
              e.preventDefault();
              // Clear both localStorage and cookies
              localStorage.removeItem('cfp_token');
              localStorage.removeItem('cfp_username');
              deleteCookie('cfp_token');
              deleteCookie('cfp_username');
              window.location.href = '/cfp/';
            });
            const signOutLi = document.createElement('li');
            signOutLi.className = 'nav-item';
            signOutLi.appendChild(signOutLink);
            navUl.appendChild(signOutLi);

            console.log('[Navigation] Successfully updated navigation for user:', username);
          } else {
            console.log('[Navigation] Not updating navigation:', {
              hasToken: !!token,
              hasUsername: !!username,
              hasLoginButton: !!loginButton
            });
          }
        });
      """)
    }
  }
}
