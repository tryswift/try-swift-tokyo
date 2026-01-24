import Ignite

struct SubmitPage: StaticPage {
  var title = "Submit Proposal"

  var body: some HTML {
    Section {
      Text("Submit Your Proposal")
        .font(.title1)
        .fontWeight(.bold)
        .margin(.bottom, .medium)

      Text("Please sign in with GitHub to submit your talk proposal.")
        .font(.lead)
        .foregroundStyle(.secondary)
        .margin(.bottom, .large)

      // Login prompt for unauthenticated users
      Card {
        Section {
          Text("🔐")
            .font(.title1)
            .margin(.bottom, .medium)

          Text("Sign In Required")
            .font(.title3)
            .fontWeight(.bold)
            .margin(.bottom, .small)

          Text("Connect your GitHub account to submit proposals and track your submissions.")
            .foregroundStyle(.secondary)
            .margin(.bottom, .large)

          Link("Sign in with GitHub", target: "https://tryswift-cfp-api.fly.dev/api/v1/auth/github")
            .linkStyle(.button)
            .role(.dark)
        }
        .horizontalAlignment(.center)
        .padding(.vertical, .large)
      }
      .margin(.bottom, .large)

      // Proposal submission form (shown after login)
      Section {
        Text("Proposal Form")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .large)
      }
      .id("proposal-form-container")
    }
    .padding(.vertical, .large)

    // JavaScript for form handling
    Script(code: """
      const API_BASE = 'https://tryswift-cfp-api.fly.dev/api/v1';

      document.addEventListener('DOMContentLoaded', function() {
        const token = localStorage.getItem('cfp_token');
        const loginCard = document.querySelector('.card:first-of-type');
        const formContainer = document.getElementById('proposal-form-container');

        if (token) {
          // Hide login prompt
          loginCard.style.display = 'none';

          // Create and show the form
          formContainer.innerHTML = `
            <div class="card">
              <div class="card-body p-4">
                <h3 class="mb-4">Submit Your Proposal</h3>
                <form id="proposal-form">
                  <div class="mb-3">
                    <label for="title" class="form-label fw-semibold">Title *</label>
                    <input type="text" class="form-control" id="title" required placeholder="Enter your talk title">
                  </div>

                  <div class="mb-3">
                    <label for="abstract" class="form-label fw-semibold">Abstract *</label>
                    <textarea class="form-control" id="abstract" rows="3" required placeholder="A brief summary of your talk (2-3 sentences)"></textarea>
                    <div class="form-text">This will be shown to the audience if your talk is accepted.</div>
                  </div>

                  <div class="mb-3">
                    <label for="talkDetails" class="form-label fw-semibold">Talk Details *</label>
                    <textarea class="form-control" id="talkDetails" rows="5" required placeholder="Detailed description for reviewers"></textarea>
                    <div class="form-text">Include outline, key points, and what attendees will learn. For reviewers only.</div>
                  </div>

                  <div class="mb-3">
                    <label for="talkDuration" class="form-label fw-semibold">Talk Duration *</label>
                    <select class="form-select" id="talkDuration" required>
                      <option value="">Choose duration...</option>
                      <option value="20min">Regular Talk (20 minutes)</option>
                      <option value="5min">Lightning Talk (5 minutes)</option>
                    </select>
                  </div>

                  <div class="mb-3">
                    <label for="bio" class="form-label fw-semibold">Speaker Bio *</label>
                    <textarea class="form-control" id="bio" rows="3" required placeholder="Tell us about yourself"></textarea>
                  </div>

                  <div class="mb-3">
                    <label for="iconUrl" class="form-label fw-semibold">Profile Picture URL (Optional)</label>
                    <input type="url" class="form-control" id="iconUrl" placeholder="https://example.com/your-photo.jpg">
                  </div>

                  <div class="mb-3">
                    <label for="notesToOrganizers" class="form-label fw-semibold">Notes for Organizers (Optional)</label>
                    <textarea class="form-control" id="notesToOrganizers" rows="2" placeholder="Any special requirements or additional information"></textarea>
                  </div>

                  <div id="error-message" style="display: none;" class="alert alert-danger"></div>
                  <div id="success-message" style="display: none;" class="alert alert-success"></div>

                  <div class="d-grid gap-2">
                    <button type="submit" class="btn btn-primary btn-lg" id="submit-btn">Submit Proposal</button>
                  </div>
                </form>
              </div>
            </div>
          `;

          // Handle form submission
          document.getElementById('proposal-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const submitBtn = document.getElementById('submit-btn');
            const errorMsg = document.getElementById('error-message');
            const successMsg = document.getElementById('success-message');

            submitBtn.disabled = true;
            submitBtn.textContent = 'Submitting...';
            errorMsg.style.display = 'none';
            successMsg.style.display = 'none';

            const proposalData = {
              title: document.getElementById('title').value,
              abstract: document.getElementById('abstract').value,
              talkDetails: document.getElementById('talkDetails').value,
              talkDuration: document.getElementById('talkDuration').value,
              bio: document.getElementById('bio').value,
              iconUrl: document.getElementById('iconUrl').value || null,
              notesToOrganizers: document.getElementById('notesToOrganizers').value || null
            };

            try {
              const response = await fetch(`${API_BASE}/proposals`, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(proposalData)
              });

              if (!response.ok) {
                const error = await response.json();
                throw new Error(error.reason || 'Failed to submit proposal');
              }

              successMsg.innerHTML = '<h5>✅ Proposal Submitted!</h5><p>Your proposal has been submitted successfully. <a href="/my-proposals">View your proposals</a></p>';
              successMsg.style.display = 'block';
              document.getElementById('proposal-form').reset();

              // Scroll to success message
              successMsg.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            } catch (error) {
              errorMsg.textContent = error.message;
              errorMsg.style.display = 'block';
              submitBtn.disabled = false;
              submitBtn.textContent = 'Submit Proposal';
            }
          });
        } else {
          // Show login prompt
          formContainer.innerHTML = '<p class="text-muted">Sign in to access the proposal submission form.</p>';
        }
      });
    """)
  }
}
