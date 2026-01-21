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
          
          Link("Sign in with GitHub", target: "/api/v1/auth/github")
            .linkStyle(.button)
            .role(.dark)
        }
        .horizontalAlignment(.center)
        .padding(.vertical, .large)
      }
      .margin(.bottom, .large)
      
      // Form preview (shown after login via JavaScript)
      Card {
        Text("Proposal Form")
          .font(.title2)
          .fontWeight(.bold)
          .margin(.bottom, .large)
        
        Text("After signing in, you'll be able to fill out the following form:")
          .foregroundStyle(.secondary)
          .margin(.bottom, .large)
        
        Section {
          Text("Title")
            .fontWeight(.semibold)
          Text("Enter your talk title")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .medium)
        
        Section {
          Text("Abstract")
            .fontWeight(.semibold)
          Text("A brief summary of your talk (2-3 sentences)")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .medium)
        
        Section {
          Text("Talk Details")
            .fontWeight(.semibold)
          Text("Detailed description for reviewers including outline and key points")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .medium)
        
        Section {
          Text("Talk Duration")
            .fontWeight(.semibold)
          Text("Regular (20 min) or Lightning Talk (5 min)")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .medium)
        
        Section {
          Text("Bio")
            .fontWeight(.semibold)
          Text("Tell us about yourself")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .medium)
        
        Section {
          Text("Icon URL (Optional)")
            .fontWeight(.semibold)
          Text("URL to your profile picture")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .medium)
        
        Section {
          Text("Notes for Organizers (Optional)")
            .fontWeight(.semibold)
          Text("Any additional information")
            .foregroundStyle(.secondary)
            .font(.body)
        }
        .margin(.bottom, .large)
        
        Text("Form submission is disabled in preview mode. Please sign in to submit.")
          .font(.body)
          .foregroundStyle(.secondary)
          .horizontalAlignment(.center)
      }
      .id("proposal-form")
    }
    .padding(.vertical, .large)
    
    // JavaScript for form handling
    Script(code: """
      // This will be enhanced with actual form submission logic
      // when integrated with the backend API
      
      document.addEventListener('DOMContentLoaded', function() {
        // Check if user is logged in via token in localStorage
        const token = localStorage.getItem('cfp_token');
        if (token) {
          // Show form, hide login prompt
          document.querySelector('.card:first-of-type').style.display = 'none';
        }
      });
    """)
  }
}
