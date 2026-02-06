import Elementary
import SharedModels

struct EditProposalPageView: HTML, Sendable {
  let user: UserDTO?
  let proposal: ProposalDTO?
  let errorMessage: String?
  let successMessage: String?
  let language: CfPLanguage
  let csrfToken: String

  init(
    user: UserDTO?,
    proposal: ProposalDTO?,
    errorMessage: String? = nil,
    successMessage: String? = nil,
    language: CfPLanguage = .en,
    csrfToken: String = ""
  ) {
    self.user = user
    self.proposal = proposal
    self.errorMessage = errorMessage
    self.successMessage = successMessage
    self.language = language
    self.csrfToken = csrfToken
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
      // Back button
      div(.class("mb-4")) {
        if let proposal {
          a(
            .class("btn btn-outline-secondary"),
            .href(language.path(for: "/my-proposals/\(proposal.id.uuidString)"))
          ) {
            language == .ja ? "← 詳細に戻る" : "← Back to Detail"
          }
        } else {
          a(.class("btn btn-outline-secondary"), .href(language.path(for: "/my-proposals"))) {
            language == .ja ? "← プロポーザル一覧に戻る" : "← Back to My Proposals"
          }
        }
      }
      h1(.class("fw-bold mb-2")) {
        language == .ja ? "プロポーザルを編集" : "Edit Your Proposal"
      }
      p(.class("lead text-muted mb-4")) {
        language == .ja
          ? "プロポーザルの内容を更新できます。"
          : "Update your proposal details below."
      }
    }
  }

  @HTMLBuilder
  private var mainContent: some HTML {
    if user != nil {
      if let proposal {
        editFormCard(proposal: proposal)
      } else {
        notFoundCard
      }
    } else {
      loginPromptCard
    }
  }

  private func editFormCard(proposal: ProposalDTO) -> some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        errorAlert
        successAlert
        editForm(proposal: proposal)
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

  @HTMLBuilder
  private var successAlert: some HTML {
    if let successMessage {
      div(.class("alert alert-success mb-4")) {
        HTMLText(successMessage)
      }
    }
  }

  private func editForm(proposal: ProposalDTO) -> some HTML {
    form(
      .method(.post), .action(language.path(for: "/my-proposals/\(proposal.id.uuidString)/edit"))
    ) {
      input(.type(.hidden), .name("_csrf"), .value(csrfToken))
      titleField(value: proposal.title)
      abstractField(value: proposal.abstract)
      talkDetailsField(value: proposal.talkDetail)
      durationField(selected: proposal.talkDuration)
      speakerInfoSection(proposal: proposal)
      notesField(value: proposal.notes)
      submitButton
    }
  }

  private func titleField(value: String) -> some HTML {
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
        .value(value),
        .placeholder(language == .ja ? "トークのタイトルを入力" : "Enter your talk title")
      )
    }
  }

  private func abstractField(value: String) -> some HTML {
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
      ) {
        HTMLText(value)
      }
      div(.class("form-text")) {
        language == .ja
          ? "トークが採択された場合、この内容が公開されます。"
          : "This will be shown to the audience if your talk is accepted."
      }
    }
  }

  private func talkDetailsField(value: String) -> some HTML {
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
      ) {
        HTMLText(value)
      }
      div(.class("form-text")) {
        language == .ja
          ? "アウトライン、重要なポイント、参加者が学ぶことを含めてください。レビュアーのみが閲覧します。"
          : "Include outline, key points, and what attendees will learn. For reviewers only."
      }
    }
  }

  private func durationField(selected: TalkDuration) -> some HTML {
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
        if selected == .regular {
          option(.value("20min"), .selected) {
            language == .ja ? "レギュラートーク（20分）" : "Regular Talk (20 minutes)"
          }
        } else {
          option(.value("20min")) {
            language == .ja ? "レギュラートーク（20分）" : "Regular Talk (20 minutes)"
          }
        }
        if selected == .lightning {
          option(.value("LT"), .selected) {
            language == .ja ? "ライトニングトーク（5分）" : "Lightning Talk (5 minutes)"
          }
        } else {
          option(.value("LT")) {
            language == .ja ? "ライトニングトーク（5分）" : "Lightning Talk (5 minutes)"
          }
        }
      }
    }
  }

  private func speakerInfoSection(proposal: ProposalDTO) -> some HTML {
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        speakerInfoHeader
        p(.class("text-muted small mb-3")) {
          language == .ja
            ? "このプロポーザルのスピーカー情報を編集できます。"
            : "Edit the speaker information for this proposal."
        }
        div(.class("row")) {
          speakerTextFields(proposal: proposal)
          speakerIconField(iconURL: proposal.iconURL)
        }
      }
    }
  }

  private var speakerInfoHeader: some HTML {
    h5(.class("card-title mb-3")) {
      language == .ja ? "スピーカー情報" : "Speaker Information"
    }
  }

  private func speakerTextFields(proposal: ProposalDTO) -> some HTML {
    div(.class("col-md-8")) {
      speakerNameField(value: proposal.speakerName)
      speakerEmailField(value: proposal.speakerEmail)
      speakerBioField(value: proposal.bio)
    }
  }

  private func speakerNameField(value: String) -> some HTML {
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
        .value(value),
        .placeholder(language == .ja ? "表示名" : "Your display name")
      )
    }
  }

  private func speakerEmailField(value: String) -> some HTML {
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
        .value(value),
        .placeholder("your@email.com")
      )
      div(.class("form-text")) {
        language == .ja
          ? "プロポーザルに関するご連絡に使用します。"
          : "We'll use this to contact you about your proposal."
      }
    }
  }

  private func speakerBioField(value: String) -> some HTML {
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
        HTMLText(value)
      }
    }
  }

  private func speakerIconField(iconURL: String?) -> some HTML {
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
          .value(iconURL ?? ""),
          .placeholder("https://example.com/your-photo.jpg"),
          .custom(name: "oninput", value: "updateIconPreview(this.value)")
        )
      }
      iconPreview(iconURL: iconURL)
    }
  }

  private func iconPreview(iconURL: String?) -> some HTML {
    div(.class("text-center mt-3")) {
      p(.class("text-muted small mb-2")) {
        language == .ja ? "プレビュー:" : "Preview:"
      }
      img(
        .id("iconPreview"),
        .src(iconURL ?? ""),
        .alt(language == .ja ? "プロフィール画像プレビュー" : "Profile picture preview"),
        .class("rounded-circle border"),
        .style("width: 100px; height: 100px; object-fit: cover;")
      )
    }
  }

  private func notesField(value: String?) -> some HTML {
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
      ) {
        if let value {
          HTMLText(value)
        }
      }
    }
  }

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        language == .ja ? "プロポーザルを更新" : "Update Proposal"
      }
    }
  }

  private var notFoundCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "プロポーザルが見つかりません" : "Proposal Not Found"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "お探しのプロポーザルは存在しないか、アクセス権限がありません。"
            : "The proposal you are looking for does not exist or you don't have access to it."
        }
        a(.class("btn btn-primary"), .href(language.path(for: "/my-proposals"))) {
          language == .ja ? "マイプロポーザルに戻る" : "Back to My Proposals"
        }
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
            ? "プロポーザルを編集するにはログインしてください。"
            : "Please sign in to edit your proposal."
        }
        a(
          .class("btn btn-dark"),
          .href("/api/v1/auth/github?returnTo=\(language.path(for: "/my-proposals"))")
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
