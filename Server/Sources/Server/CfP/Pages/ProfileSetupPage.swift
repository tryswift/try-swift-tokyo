import Elementary
import SharedModels

struct ProfileSetupPageView: HTML, Sendable {
  let user: UserDTO
  let errorMessage: String?
  let successMessage: String?
  let returnTo: String?

  init(user: UserDTO, errorMessage: String? = nil, successMessage: String? = nil, returnTo: String? = nil) {
    self.user = user
    self.errorMessage = errorMessage
    self.successMessage = successMessage
    self.returnTo = returnTo
  }

  /// Check if required profile fields are missing
  var isProfileIncomplete: Bool {
    let displayNameMissing = user.displayName == nil || user.displayName?.isEmpty == true
    let emailMissing = user.email == nil || user.email?.isEmpty == true
    let bioMissing = user.bio == nil || user.bio?.isEmpty == true
    let avatarMissing = user.avatarURL == nil || user.avatarURL?.isEmpty == true
    return displayNameMissing || emailMissing || bioMissing || avatarMissing
  }

  /// Get GitHub avatar URL for default
  var githubAvatarURL: String {
    "https://avatars.githubusercontent.com/u/\(user.githubID)"
  }

  var currentAvatarURL: String {
    user.avatarURL ?? githubAvatarURL
  }

  var body: some HTML {
    div(.class("container py-5")) {
      pageHeader
      alertMessages
      formCard
    }
    previewScript
  }

  private var pageHeader: some HTML {
    div(.class("row justify-content-center")) {
      div(.class("col-md-8 col-lg-6")) {
        h1(.class("fw-bold mb-2")) { "Complete Your Profile" }
        p(.class("lead text-muted mb-4")) {
          "Please fill in your profile information before submitting a proposal."
        }
      }
    }
  }

  private var alertMessages: some HTML {
    div(.class("row justify-content-center")) {
      div(.class("col-md-8 col-lg-6")) {
        if let successMessage {
          div(.class("alert alert-success mb-4")) {
            HTMLText(successMessage)
          }
        }
        if let errorMessage {
          div(.class("alert alert-danger mb-4")) {
            HTMLText(errorMessage)
          }
        }
      }
    }
  }

  private var formCard: some HTML {
    div(.class("row justify-content-center")) {
      div(.class("col-md-8 col-lg-6")) {
        div(.class("card")) {
          div(.class("card-body p-4")) {
            profileForm
          }
        }
      }
    }
  }

  private var profileForm: some HTML {
    form(.method(.post), .action("/cfp/profile")) {
      hiddenReturnTo
      displayNameField
      emailField
      bioField
      avatarField
      submitButtons
    }
  }

  @HTMLBuilder
  private var hiddenReturnTo: some HTML {
    if let returnTo {
      input(.type(.hidden), .name("returnTo"), .value(returnTo))
    }
  }

  private var displayNameField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("displayName")) { "Name *" }
      input(
        .type(.text),
        .class("form-control"),
        .name("displayName"),
        .id("displayName"),
        .required,
        .value(user.displayName ?? ""),
        .placeholder("Your display name")
      )
      div(.class("form-text")) {
        "This name will be displayed if your talk is accepted."
      }
    }
  }

  private var emailField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("email")) { "Email *" }
      input(
        .type(.email),
        .class("form-control"),
        .name("email"),
        .id("email"),
        .required,
        .value(user.email ?? ""),
        .placeholder("your@email.com")
      )
      div(.class("form-text")) {
        "We'll use this to contact you about your proposal."
      }
    }
  }

  private var bioField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("bio")) { "Bio *" }
      textarea(
        .class("form-control"),
        .name("bio"),
        .id("bio"),
        .custom(name: "rows", value: "3"),
        .required,
        .placeholder("Tell us about yourself")
      ) {
        HTMLText(user.bio ?? "")
      }
      div(.class("form-text")) {
        "A short bio that will be displayed with your talk."
      }
    }
  }

  private var avatarField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("avatarURL")) { "Profile Picture URL *" }
      input(
        .type(.url),
        .class("form-control"),
        .name("avatarURL"),
        .id("avatarURL"),
        .required,
        .value(currentAvatarURL),
        .placeholder("https://example.com/your-photo.jpg"),
        .custom(name: "oninput", value: "updatePreview(this.value)")
      )
      div(.class("form-text mb-2")) {
        "Your GitHub avatar is shown by default. Enter a different URL if you prefer another image."
      }
      avatarPreviewSection
    }
  }

  private var avatarPreviewSection: some HTML {
    div(.class("d-flex align-items-center gap-3 mt-3")) {
      div {
        p(.class("text-muted small mb-1")) { "Preview:" }
        img(
          .id("avatarPreview"),
          .src(currentAvatarURL),
          .alt("Profile picture preview"),
          .class("rounded-circle border"),
          .style("width: 80px; height: 80px; object-fit: cover;")
        )
      }
      div {
        p(.class("text-muted small mb-1")) { "GitHub Avatar:" }
        img(
          .src(githubAvatarURL),
          .alt("GitHub avatar"),
          .class("rounded-circle border"),
          .style("width: 80px; height: 80px; object-fit: cover;")
        )
      }
    }
  }

  private var submitButtons: some HTML {
    div(.class("d-grid gap-2")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        "Save Profile"
      }
      skipButton
    }
  }

  @HTMLBuilder
  private var skipButton: some HTML {
    if !isProfileIncomplete {
      a(.class("btn btn-outline-secondary"), .href(returnTo ?? "/cfp/submit")) {
        "Skip for Now"
      }
    }
  }

  private var previewScript: some HTML {
    HTMLRaw("""
      <script>
        function updatePreview(url) {
          const preview = document.getElementById('avatarPreview');
          if (url && url.trim() !== '') {
            preview.src = url;
          }
        }
      </script>
      """)
  }
}
