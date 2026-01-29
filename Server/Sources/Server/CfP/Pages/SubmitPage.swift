import Elementary
import SharedModels

struct SubmitPageView: HTML, Sendable {
  let user: UserDTO?
  let success: Bool
  let errorMessage: String?
  let openConference: ConferencePublicInfo?
  let language: CfPLanguage

  init(
    user: UserDTO?,
    success: Bool,
    errorMessage: String?,
    openConference: ConferencePublicInfo? = nil,
    language: CfPLanguage = .en
  ) {
    self.user = user
    self.success = success
    self.errorMessage = errorMessage
    self.openConference = openConference
    self.language = language
  }

  /// Get GitHub avatar URL as fallback
  private var githubAvatarURL: String {
    guard let user else { return "" }
    return "https://avatars.githubusercontent.com/u/\(user.githubID)"
  }

  /// Get effective avatar URL (user's avatarURL or GitHub avatar)
  private var effectiveAvatarURL: String {
    user?.avatarURL ?? githubAvatarURL
  }

  var body: some HTML {
    div(.class("container py-5")) {
      pageHeader
      mainContent
    }
    previewScript
  }

  private var pageHeader: some HTML {
    div {
      h1(.class("fw-bold mb-2")) {
        language == .ja ? "プロポーザルを提出する" : "Submit Your Proposal"
      }
      p(.class("lead text-muted mb-4")) {
        language == .ja
          ? "あなたのSwiftの知識を世界中の開発者と共有しましょう。"
          : "Share your Swift expertise with developers from around the world."
      }
    }
  }

  @HTMLBuilder
  private var mainContent: some HTML {
    if openConference == nil {
      noConferenceCard
    } else if user != nil {
      if success {
        successCard
      } else {
        proposalFormCard
      }
    } else {
      loginPromptCard
    }
  }

  private var noConferenceCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        p(.class("fs-1 mb-3")) { "📅" }
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "プロポーザル募集は終了しました" : "Call for Proposals Not Open"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "現在、プロポーザルの募集は行っていません。次回のカンファレンスをお待ちください。"
            : "The Call for Proposals is not currently open. Please check back later for the next conference."
        }
        a(.class("btn btn-outline-primary"), .href(language.path(for: "/"))) {
          language == .ja ? "ホームに戻る" : "Back to Home"
        }
      }
    }
  }

  private var successCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        p(.class("fs-1 mb-3")) { "✅" }
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "プロポーザルが送信されました！" : "Proposal Submitted!"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "プロポーザルが正常に送信されました。ご応募ありがとうございます！"
            : "Your proposal has been submitted successfully. Good luck!"
        }
        div(.class("d-flex gap-2 justify-content-center")) {
          a(.class("btn btn-primary"), .href(language.path(for: "/my-proposals"))) {
            language == .ja ? "マイプロポーザルを見る" : "View My Proposals"
          }
          a(.class("btn btn-outline-primary"), .href(language.path(for: "/submit"))) {
            language == .ja ? "別のプロポーザルを提出" : "Submit Another"
          }
        }
      }
    }
  }

  private var proposalFormCard: some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        errorAlert
        proposalForm
      }
    }
  }

  @HTMLBuilder
  private var errorAlert: some HTML {
    if let errorMessage {
      div(.class("alert alert-danger mb-4")) {
        HTMLText(errorMessage)
      }
    }
  }

  private var proposalForm: some HTML {
    form(.method(.post), .action(language.path(for: "/submit"))) {
      titleField
      abstractField
      talkDetailsField
      durationField
      speakerInfoSection
      notesField
      submitButton
    }
  }

  private var titleField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("title")) {
        language == .ja ? "タイトル *" : "Title *"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("title"),
        .id("title"),
        .required,
        .placeholder(language == .ja ? "トークのタイトルを入力" : "Enter your talk title")
      )
    }
  }

  private var abstractField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("abstract")) {
        language == .ja ? "概要 *" : "Abstract *"
      }
      textarea(
        .class("form-control"),
        .name("abstract"),
        .id("abstract"),
        .custom(name: "rows", value: "3"),
        .required,
        .placeholder(
          language == .ja ? "トークの簡単な要約（2〜3文）" : "A brief summary of your talk (2-3 sentences)")
      ) {}
      div(.class("form-text")) {
        language == .ja
          ? "トークが採択された場合、この内容が公開されます。"
          : "This will be shown to the audience if your talk is accepted."
      }
    }
  }

  private var talkDetailsField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("talkDetails")) {
        language == .ja ? "トークの詳細 *" : "Talk Details *"
      }
      textarea(
        .class("form-control"),
        .name("talkDetails"),
        .id("talkDetails"),
        .custom(name: "rows", value: "5"),
        .required,
        .placeholder(
          language == .ja ? "レビュアー向けの詳細な説明" : "Detailed description for reviewers")
      ) {}
      div(.class("form-text")) {
        language == .ja
          ? "アウトライン、重要なポイント、参加者が学ぶことを含めてください。レビュアーのみが閲覧します。"
          : "Include outline, key points, and what attendees will learn. For reviewers only."
      }
    }
  }

  private var durationField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("talkDuration")) {
        language == .ja ? "トーク時間 *" : "Talk Duration *"
      }
      select(
        .class("form-select"), .name("talkDuration"), .id("talkDuration"), .required
      ) {
        option(.value("")) {
          language == .ja ? "時間を選択..." : "Choose duration..."
        }
        option(.value("20min")) {
          language == .ja ? "レギュラートーク（20分）" : "Regular Talk (20 minutes)"
        }
        option(.value("LT")) {
          language == .ja ? "ライトニングトーク（5分）" : "Lightning Talk (5 minutes)"
        }
      }
    }
  }

  private var speakerInfoSection: some HTML {
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        speakerInfoHeader
        p(.class("text-muted small mb-3")) {
          language == .ja
            ? "この情報はプロフィールから自動入力されています。"
            : "This information is auto-filled from your profile."
        }
        div(.class("row")) {
          speakerTextFields
          speakerIconField
        }
      }
    }
  }

  private var speakerInfoHeader: some HTML {
    h5(.class("card-title mb-3")) {
      language == .ja ? "スピーカー情報" : "Speaker Information"
    }
  }

  private var speakerTextFields: some HTML {
    div(.class("col-md-8")) {
      speakerNameField
      speakerEmailField
      speakerBioField
    }
  }

  private var speakerNameField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("speakerName")) {
        language == .ja ? "名前 *" : "Name *"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("speakerName"),
        .id("speakerName"),
        .required,
        .value(user?.displayName ?? ""),
        .placeholder(language == .ja ? "表示名" : "Your display name")
      )
    }
  }

  private var speakerEmailField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("speakerEmail")) {
        language == .ja ? "メールアドレス *" : "Email *"
      }
      input(
        .type(.email),
        .class("form-control"),
        .name("speakerEmail"),
        .id("speakerEmail"),
        .required,
        .value(user?.email ?? ""),
        .placeholder("your@email.com")
      )
      div(.class("form-text")) {
        language == .ja
          ? "プロポーザルに関するご連絡に使用します。"
          : "We'll use this to contact you about your proposal."
      }
    }
  }

  private var speakerBioField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("bio")) {
        language == .ja ? "スピーカー自己紹介 *" : "Speaker Bio *"
      }
      textarea(
        .class("form-control"),
        .name("bio"),
        .id("bio"),
        .custom(name: "rows", value: "3"),
        .required,
        .placeholder(language == .ja ? "あなたについて教えてください" : "Tell us about yourself")
      ) {
        HTMLText(user?.bio ?? "")
      }
    }
  }

  private var speakerIconField: some HTML {
    div(.class("col-md-4")) {
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("iconUrl")) {
          language == .ja ? "プロフィール画像URL *" : "Profile Picture URL *"
        }
        input(
          .type(.url),
          .class("form-control"),
          .name("iconUrl"),
          .id("iconUrl"),
          .required,
          .value(effectiveAvatarURL),
          .placeholder("https://example.com/your-photo.jpg"),
          .custom(name: "oninput", value: "updateIconPreview(this.value)")
        )
      }
      iconPreview
    }
  }

  private var iconPreview: some HTML {
    div(.class("text-center mt-3")) {
      p(.class("text-muted small mb-2")) {
        language == .ja ? "プレビュー:" : "Preview:"
      }
      img(
        .id("iconPreview"),
        .src(effectiveAvatarURL),
        .alt(language == .ja ? "プロフィール画像プレビュー" : "Profile picture preview"),
        .class("rounded-circle border"),
        .style("width: 100px; height: 100px; object-fit: cover;")
      )
    }
  }

  private var notesField: some HTML {
    div(.class("mb-4")) {
      label(.class("form-label fw-semibold"), .for("notesToOrganizers")) {
        language == .ja ? "主催者への備考（任意）" : "Notes for Organizers (Optional)"
      }
      textarea(
        .class("form-control"),
        .name("notesToOrganizers"),
        .id("notesToOrganizers"),
        .custom(name: "rows", value: "2"),
        .placeholder(
          language == .ja ? "特別な要件や追加情報" : "Any special requirements or additional information")
      ) {}
    }
  }

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        language == .ja ? "プロポーザルを提出" : "Submit Proposal"
      }
    }
  }

  private var loginPromptCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        p(.class("fs-1 mb-3")) { "🔐" }
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "ログインが必要です" : "Sign In Required"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "プロポーザルを提出し、提出状況を確認するにはGitHubアカウントでログインしてください。"
            : "Connect your GitHub account to submit proposals and track your submissions."
        }
        a(
          .class("btn btn-dark"),
          .href("/api/v1/auth/github?returnTo=\(language.path(for: "/submit"))")
        ) {
          language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
        }
      }
    }
  }

  private var previewScript: some HTML {
    HTMLRaw(
      """
      <script>
        function updateIconPreview(url) {
          const preview = document.getElementById('iconPreview');
          if (url && url.trim() !== '') {
            preview.src = url;
          }
        }
      </script>
      """)
  }
}
