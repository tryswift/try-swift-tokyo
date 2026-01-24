import Ignite

struct MyProposalsPage: StaticPage {
  var title = "My Proposals"

  var body: some HTML {
    Section {
      Text("My Proposals")
        .font(.title1)
        .fontWeight(.bold)
        .margin(.bottom, .medium)

      Text("View and manage your submitted talk proposals.")
        .font(.lead)
        .foregroundStyle(.secondary)
        .margin(.bottom, .large)

      // User info section (populated by JS)
      Card {
        Section {
          Text("Loading...")
            .foregroundStyle(.secondary)
        }
        .horizontalAlignment(.center)
        .padding(.vertical, .medium)
      }
      .id("user-info")
      .margin(.bottom, .large)

      // Proposals list (populated by JS)
      Section {
        Text("Your Submissions")
          .font(.title3)
          .fontWeight(.bold)
          .margin(.bottom, .medium)

        Card {
          Section {
            Text("No proposals yet")
              .foregroundStyle(.secondary)
            Text("Submit your first proposal to see it here.")
              .font(.body)
              .foregroundStyle(.secondary)
              .margin(.top, .small)

            Link("Submit a Proposal", target: SubmitPage())
              .linkStyle(.button)
              .role(.primary)
              .margin(.top, .medium)
          }
          .horizontalAlignment(.center)
          .padding(.vertical, .large)
        }
        .id("proposals-empty")

        Section {
          // Proposals will be rendered here by JavaScript
        }
        .id("proposals-list")
      }
      .margin(.bottom, .large)

      // Actions
      Section {
        Link("Submit New Proposal", target: SubmitPage())
          .linkStyle(.button)
          .role(.primary)
      }
      .horizontalAlignment(.center)
    }
    .padding(.vertical, .large)

    // JavaScript for loading proposals
    Script(code: """
      const API_BASE = 'https://tryswift-cfp-api.fly.dev/api/v1';

      document.addEventListener('DOMContentLoaded', async function() {
        const token = localStorage.getItem('cfp_token');

        if (!token) {
          window.location.href = '/login';
          return;
        }

        try {
          // Fetch user info
          const userResponse = await fetch(`${API_BASE}/auth/me`, {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });

          if (!userResponse.ok) {
            localStorage.removeItem('cfp_token');
            localStorage.removeItem('cfp_username');
            window.location.href = '/login';
            return;
          }

          const user = await userResponse.json();
          document.getElementById('user-info').innerHTML = `
            <div class="d-flex align-items-center justify-content-between p-3">
              <div class="d-flex align-items-center">
                <img src="${user.avatarURL || 'https://github.com/identicons/' + user.username + '.png'}"
                     alt="${user.username}"
                     class="rounded-circle me-3"
                     style="width: 50px; height: 50px;">
                <div>
                  <strong>${user.username}</strong>
                  <div class="text-muted small">${user.role === 'admin' ? 'Organizer' : 'Speaker'}</div>
                </div>
              </div>
              <button onclick="logout()" class="btn btn-outline-danger btn-sm">Logout</button>
            </div>
          `;

          // Fetch proposals
          const proposalsResponse = await fetch(`${API_BASE}/proposals/mine`, {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          });

          if (proposalsResponse.ok) {
            const proposals = await proposalsResponse.json();

            if (proposals.length > 0) {
              document.getElementById('proposals-empty').style.display = 'none';
              document.getElementById('proposals-list').innerHTML = proposals.map(p => `
                <div class="card mb-3">
                  <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start">
                      <div>
                        <h5 class="card-title">${p.title}</h5>
                        <span class="badge ${p.talkDuration === '20min' ? 'bg-primary' : 'bg-warning text-dark'}">${p.talkDuration}</span>
                      </div>
                      <small class="text-muted">${new Date(p.createdAt).toLocaleDateString()}</small>
                    </div>
                    <p class="card-text text-muted mt-2">${p.abstract}</p>
                  </div>
                </div>
              `).join('');
            }
          }
        } catch (error) {
          console.error('Error loading proposals:', error);
          document.getElementById('user-info').innerHTML = `
            <div class="alert alert-danger">
              Failed to load data. Please try refreshing the page.
            </div>
          `;
        }
      });

      function logout() {
        // Clear both localStorage and cookies
        localStorage.removeItem('cfp_token');
        localStorage.removeItem('cfp_username');
        // Delete cookies
        document.cookie = 'cfp_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
        document.cookie = 'cfp_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.tryswift.jp';
        document.cookie = 'cfp_username=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
        document.cookie = 'cfp_username=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.tryswift.jp';
        window.location.href = '/';
      }
    """)
  }
}
