import Elementary
import SharedModels

struct SubmitPageView: HTML, Sendable {
  let user: UserDTO?
  let success: Bool
  let errorMessage: String?
  let openConference: ConferencePublicInfo?
  let language: CfPLanguage
  let csrfToken: String

  init(
    user: UserDTO?,
    success: Bool,
    errorMessage: String?,
    openConference: ConferencePublicInfo? = nil,
    language: CfPLanguage = .en,
    csrfToken: String = ""
  ) {
    self.user = user
    self.success = success
    self.errorMessage = errorMessage
    self.openConference = openConference
    self.language = language
    self.csrfToken = csrfToken
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
      input(.type(.hidden), .name("_csrf"), .value(csrfToken))
      typeField
      titleField
      abstractField
      talkDetailsField
      workshopFieldsSection
      speakerInfoSection
      coInstructorFieldsSection
      notesField
      submitButton
    }
  }

  // MARK: - Type Field (formerly Duration)

  /// Whether the current user is an invited speaker
  private var isInvitedSpeaker: Bool {
    user?.role.isInvitedSpeaker == true
  }

  private var typeField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("talkDuration")) {
        language == .ja ? "タイプ *" : "Type *"
      }
      select(
        .class("form-select"), .name("talkDuration"), .id("talkDuration"), .required
      ) {
        option(.value("")) {
          language == .ja ? "タイプを選択..." : "Choose type..."
        }
        if isInvitedSpeaker {
          option(.value("invited")) {
            language == .ja ? "招待スピーカー（20分）" : "Invited Talk (20 minutes)"
          }
        } else {
          option(.value("20min")) {
            language == .ja ? "レギュラートーク（20分）" : "Regular Talk (20 minutes)"
          }
          option(.value("LT")) {
            language == .ja ? "ライトニングトーク（5分）" : "Lightning Talk (5 minutes)"
          }
          option(.value("workshop")) {
            language == .ja ? "ワークショップ" : "Workshop"
          }
        }
      }
    }
  }

  // MARK: - Basic Proposal Fields

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

  // MARK: - Workshop-specific Fields

  @HTMLBuilder
  private var workshopFieldsSection: some HTML {
    HTMLRaw(
      """
      <div id="workshopFields" style="display: none;">
      """)
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) {
          language == .ja ? "ワークショップ詳細" : "Workshop Details"
        }

        workshopLanguageField
        workshopTutorsField
        workshopKeyTakeawaysField
        workshopPrerequisitesField
        workshopAgendaField
        workshopParticipantRequirementsField
        workshopRequiredSoftwareField
        workshopNetworkRequirementsField
        workshopFacilitiesField
        workshopMotivationField
        workshopUniquenessField
        workshopPotentialRisksField
      }
    }
    HTMLRaw("</div>")
  }

  private var workshopLanguageField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold")) {
        language == .ja ? "使用する言語 *" : "Language *"
      }
      div {
        for lang in WorkshopLanguage.allCases {
          div(.class("form-check form-check-inline")) {
            input(
              .type(.radio),
              .class("form-check-input"),
              .name("workshop_language"),
              .id("workshop_language_\(lang.rawValue)"),
              .value(lang.rawValue),
              .custom(name: "data-workshop-required", value: "true")
            )
            label(.class("form-check-label"), .for("workshop_language_\(lang.rawValue)")) {
              HTMLText(lang.displayName)
            }
          }
        }
      }
    }
  }

  private var workshopTutorsField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_numberOfTutors")) {
        language == .ja ? "チューターの人数 *" : "Number of Tutors *"
      }
      input(
        .type(.number),
        .class("form-control"),
        .name("workshop_numberOfTutors"),
        .id("workshop_numberOfTutors"),
        .custom(name: "min", value: "0"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder(language == .ja ? "チューターの人数（上限なし）" : "Number of tutors (unlimited)")
      )
      div(.class("form-text")) {
        language == .ja ? "上限なし" : "Unlimited"
      }
    }
  }

  private var workshopKeyTakeawaysField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_keyTakeaways")) {
        language == .ja ? "学べること *" : "Key Takeaways *"
      }
      textarea(
        .class("form-control"),
        .name("workshop_keyTakeaways"),
        .id("workshop_keyTakeaways"),
        .custom(name: "rows", value: "3"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder(
          language == .ja ? "参加者が学べることを箇条書きで記述" : "Bullet points of what participants will learn")
      ) {}
    }
  }

  private var workshopPrerequisitesField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_prerequisites")) {
        language == .ja ? "前提知識" : "Prerequisites"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("workshop_prerequisites"),
        .id("workshop_prerequisites"),
        .placeholder(
          language == .ja
            ? "例: Swift 1年以上の経験 / 基本的なiOSの知識"
            : "e.g. Swift 1+ years experience / Basic iOS knowledge")
      )
    }
  }

  private var workshopAgendaField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_agendaSchedule")) {
        language == .ja ? "アジェンダ・スケジュール *" : "Agenda & Schedule *"
      }
      textarea(
        .class("form-control"),
        .name("workshop_agendaSchedule"),
        .id("workshop_agendaSchedule"),
        .custom(name: "rows", value: "4"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder("0:00\u{2013}0:15 Intro / 0:15\u{2013}1:00 Hands-on Part 1...")
      ) {}
    }
  }

  private var workshopParticipantRequirementsField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_participantRequirements")) {
        language == .ja ? "参加者が持参するもの *" : "What Participants Need to Bring *"
      }
      textarea(
        .class("form-control"),
        .name("workshop_participantRequirements"),
        .id("workshop_participantRequirements"),
        .custom(name: "rows", value: "2"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder(
          language == .ja ? "例: ノートPC、iOS端末など" : "e.g. Notebook PC, iOS Device, etc.")
      ) {}
    }
  }

  private var workshopRequiredSoftwareField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_requiredSoftware")) {
        language == .ja
          ? "事前にインストールが必要なツール・ソフトウェア"
          : "Required Tools / Software to Install in Advance"
      }
      textarea(
        .class("form-control"),
        .name("workshop_requiredSoftware"),
        .id("workshop_requiredSoftware"),
        .custom(name: "rows", value: "2"),
        .placeholder(
          language == .ja
            ? "例: Xcode バージョン、SDK、CLIツール等"
            : "e.g. Xcode version, SDKs, CLI tools, etc.")
      ) {}
    }
  }

  private var workshopNetworkRequirementsField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_networkRequirements")) {
        language == .ja ? "ネットワーク要件 *" : "Network Requirements *"
      }
      textarea(
        .class("form-control"),
        .name("workshop_networkRequirements"),
        .id("workshop_networkRequirements"),
        .custom(name: "rows", value: "2"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder(language == .ja ? "例: APIアクセス、VPN等" : "e.g. API access, VPN, etc.")
      ) {}
    }
  }

  private var workshopFacilitiesField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold")) {
        language == .ja ? "必要な設備・機器" : "Required Facilities / Equipment"
      }
      div {
        for facility in FacilityRequirement.allCases {
          div(.class("form-check")) {
            input(
              .type(.checkbox),
              .class("form-check-input"),
              .name("workshop_requiredFacilities"),
              .id("facility_\(facility.rawValue)"),
              .value(facility.rawValue)
            )
            label(.class("form-check-label"), .for("facility_\(facility.rawValue)")) {
              HTMLText(facility.displayName)
            }
          }
        }
        div(.class("form-check")) {
          input(
            .type(.checkbox),
            .class("form-check-input"),
            .name("workshop_hasFacilityOther"),
            .id("facility_other_check"),
            .value("true"),
            .custom(name: "onchange", value: "toggleFacilityOther(this.checked)")
          )
          label(.class("form-check-label"), .for("facility_other_check")) {
            "Other"
          }
        }
        input(
          .type(.text),
          .class("form-control mt-2"),
          .name("workshop_facilityOther"),
          .id("workshop_facilityOther"),
          .style("display: none;"),
          .placeholder(language == .ja ? "その他の設備を入力" : "Specify other equipment")
        )
      }
    }
  }

  private var workshopMotivationField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_motivation")) {
        language == .ja ? "動機 *" : "Motivation *"
      }
      textarea(
        .class("form-control"),
        .name("workshop_motivation"),
        .id("workshop_motivation"),
        .custom(name: "rows", value: "3"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder(
          language == .ja
            ? "なぜ try! Swift でこのワークショップを行いたいですか？"
            : "Why this workshop at try! Swift?")
      ) {}
    }
  }

  private var workshopUniquenessField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_uniqueness")) {
        language == .ja ? "ユニークな点 *" : "Uniqueness *"
      }
      textarea(
        .class("form-control"),
        .name("workshop_uniqueness"),
        .id("workshop_uniqueness"),
        .custom(name: "rows", value: "3"),
        .custom(name: "data-workshop-required", value: "true"),
        .placeholder(
          language == .ja
            ? "類似トピックとの差別化ポイント"
            : "What differentiates this from similar topics?")
      ) {}
    }
  }

  private var workshopPotentialRisksField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_potentialRisks")) {
        language == .ja ? "潜在的なリスクや懸念事項" : "Potential Risks or Concerns"
      }
      textarea(
        .class("form-control"),
        .name("workshop_potentialRisks"),
        .id("workshop_potentialRisks"),
        .custom(name: "rows", value: "2"),
        .placeholder(
          language == .ja
            ? "例: ビルド時間、ネットワーク依存、難易度等"
            : "e.g. Build time, network dependency, difficulty, etc.")
      ) {}
    }
  }

  // MARK: - Speaker Info Section

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
      githubUsernameField
      speakerNameField
      speakerEmailField
      speakerBioField
    }
  }

  private var githubUsernameField: some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("githubUsername")) {
        language == .ja ? "GitHub ID *" : "GitHub ID *"
      }
      input(
        .type(.text),
        .class("form-control"),
        .name("githubUsername"),
        .id("githubUsername"),
        .required,
        .value(user?.username ?? ""),
        .placeholder(language == .ja ? "GitHubユーザー名" : "GitHub username"),
        .custom(name: "oninput", value: "onGitHubUsernameInput(this.value)")
      )
      div(.class("form-text")) {
        language == .ja
          ? "GitHubのユーザー名を入力してください。プロフィール画像URLが空の場合、GitHubのアバターが自動設定されます。"
          : "Enter your GitHub username. If profile picture URL is empty, your GitHub avatar will be auto-filled."
      }
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

  // MARK: - Co-Instructor Fields

  @HTMLBuilder
  private var coInstructorFieldsSection: some HTML {
    HTMLRaw(
      """
      <div id="coInstructorFields" style="display: none;">
      """)
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) {
          language == .ja ? "共同講師" : "Co-Instructors"
        }
        p(.class("text-muted small mb-3")) {
          language == .ja
            ? "ワークショップの講師を最大3名まで登録できます（あなたを含む）。追加の講師はGitHubユーザー名で指定してください。あらかじめサインインしている場合、情報が自動入力されます。"
            : "You can register up to 3 instructors for a workshop (including yourself). Specify additional instructors by GitHub username. If they have signed in before, their info will be pre-filled."
        }

        // Instructor 2
        coInstructorBlock(index: 2)

        // Instructor 3 (initially hidden)
        HTMLRaw(
          """
          <div id="coInstructor3Block" style="display: none;">
          """)
        coInstructorBlock(index: 3)
        HTMLRaw("</div>")

        // Add/Remove buttons
        HTMLRaw(
          """
          <div class="d-flex gap-2 mt-3">
            <button type="button" class="btn btn-outline-secondary btn-sm" id="addInstructor3Btn" onclick="showInstructor3()">
          """)
        HTMLText(language == .ja ? "+ 講師3を追加" : "+ Add Instructor 3")
        HTMLRaw(
          """
            </button>
            <button type="button" class="btn btn-outline-danger btn-sm" id="removeInstructor3Btn" style="display: none;" onclick="hideInstructor3()">
          """)
        HTMLText(language == .ja ? "講師3を削除" : "Remove Instructor 3")
        HTMLRaw(
          """
            </button>
          </div>
          """)
      }
    }
    HTMLRaw("</div>")
  }

  private func coInstructorBlock(index: Int) -> some HTML {
    let prefix = "coInstructor\(index)"
    let labelPrefix = language == .ja ? "講師\(index)" : "Instructor \(index)"

    return div(.class("border rounded p-3 mb-3")) {
      h6(.class("fw-semibold mb-3")) { HTMLText(labelPrefix) }

      // GitHub Username + Lookup
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_githubUsername")) {
          HTMLText("\(labelPrefix): GitHub *")
        }
        div(.class("input-group")) {
          input(
            .type(.text),
            .class("form-control"),
            .name("\(prefix)_githubUsername"),
            .id("\(prefix)_githubUsername"),
            .placeholder(language == .ja ? "GitHubユーザー名" : "GitHub username")
          )
          HTMLRaw(
            """
            <button class="btn btn-outline-primary" type="button" onclick="lookupCoInstructor(\(index))">Lookup</button>
            """)
        }
        div(.class("form-text")) {
          language == .ja
            ? "GitHubユーザー名を入力して「Lookup」を押すと、サインイン済みの場合は情報が自動入力されます。"
            : "Enter GitHub username and press 'Lookup' to auto-fill if the user has signed in before."
        }
        HTMLRaw(
          """
          <div id="\(prefix)_lookupStatus" class="form-text"></div>
          """)
      }

      // Name
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_name")) {
          HTMLText("\(labelPrefix): \(language == .ja ? "名前 *" : "Name *")")
        }
        input(
          .type(.text),
          .class("form-control"),
          .name("\(prefix)_name"),
          .id("\(prefix)_name"),
          .placeholder(language == .ja ? "表示名" : "Display name")
        )
      }

      // Email
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_email")) {
          HTMLText("\(labelPrefix): \(language == .ja ? "メールアドレス *" : "Email *")")
        }
        input(
          .type(.email),
          .class("form-control"),
          .name("\(prefix)_email"),
          .id("\(prefix)_email"),
          .placeholder("email@example.com")
        )
      }

      // SNS
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_sns")) {
          HTMLText("\(labelPrefix): SNS")
        }
        input(
          .type(.text),
          .class("form-control"),
          .name("\(prefix)_sns"),
          .id("\(prefix)_sns"),
          .placeholder(language == .ja ? "例: @username" : "e.g. @username")
        )
      }

      // Bio
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_bio")) {
          HTMLText("\(labelPrefix): \(language == .ja ? "自己紹介 *" : "Short Bio *")")
        }
        textarea(
          .class("form-control"),
          .name("\(prefix)_bio"),
          .id("\(prefix)_bio"),
          .custom(name: "rows", value: "2"),
          .placeholder(language == .ja ? "自己紹介" : "Short bio")
        ) {}
      }

      // Icon URL (hidden, auto-filled from lookup)
      input(
        .type(.hidden),
        .name("\(prefix)_iconUrl"),
        .id("\(prefix)_iconUrl")
      )
    }
  }

  // MARK: - Notes & Submit

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
          .href(AuthURL.login(returnTo: language.path(for: "/submit")))
        ) {
          language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
        }
      }
    }
  }

  // MARK: - Scripts

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
        function onGitHubUsernameInput(username) {
          const iconUrlField = document.getElementById('iconUrl');
          if (username && username.trim() !== '' && (!iconUrlField.value || iconUrlField.value.trim() === '')) {
            const avatarUrl = 'https://github.com/' + username.trim() + '.png';
            iconUrlField.value = avatarUrl;
            updateIconPreview(avatarUrl);
          }
        }

        // Workshop fields show/hide
        document.addEventListener('DOMContentLoaded', function() {
          var typeSelect = document.getElementById('talkDuration');
          if (typeSelect) {
            typeSelect.addEventListener('change', function() {
              toggleWorkshopFields(this.value === 'workshop');
            });
          }
        });

        function toggleWorkshopFields(show) {
          var workshopFields = document.getElementById('workshopFields');
          var coInstructorFields = document.getElementById('coInstructorFields');
          if (workshopFields) {
            workshopFields.style.display = show ? 'block' : 'none';
            workshopFields.querySelectorAll('[data-workshop-required]').forEach(function(el) {
              if (show) {
                el.setAttribute('required', '');
              } else {
                el.removeAttribute('required');
              }
            });
          }
          if (coInstructorFields) {
            coInstructorFields.style.display = show ? 'block' : 'none';
          }
        }

        function showInstructor3() {
          document.getElementById('coInstructor3Block').style.display = 'block';
          document.getElementById('addInstructor3Btn').style.display = 'none';
          document.getElementById('removeInstructor3Btn').style.display = 'inline-block';
        }
        function hideInstructor3() {
          document.getElementById('coInstructor3Block').style.display = 'none';
          document.getElementById('addInstructor3Btn').style.display = 'inline-block';
          document.getElementById('removeInstructor3Btn').style.display = 'none';
          ['_githubUsername', '_name', '_email', '_sns', '_bio', '_iconUrl'].forEach(function(suffix) {
            var el = document.getElementById('coInstructor3' + suffix);
            if (el) el.value = '';
          });
        }

        function toggleFacilityOther(show) {
          document.getElementById('workshop_facilityOther').style.display = show ? 'block' : 'none';
        }

        async function lookupCoInstructor(index) {
          var prefix = 'coInstructor' + index;
          var usernameField = document.getElementById(prefix + '_githubUsername');
          var statusDiv = document.getElementById(prefix + '_lookupStatus');
          var username = usernameField ? usernameField.value.trim() : '';

          if (!username) {
            statusDiv.innerHTML = '<span class="text-danger">Please enter a GitHub username.</span>';
            return;
          }

          statusDiv.innerHTML = '<span class="text-muted">Looking up...</span>';

          try {
            var response = await fetch('/api/user-lookup/' + encodeURIComponent(username));
            if (response.ok) {
              var data = await response.json();
              if (data.name) document.getElementById(prefix + '_name').value = data.name;
              if (data.email) document.getElementById(prefix + '_email').value = data.email;
              if (data.bio) document.getElementById(prefix + '_bio').value = data.bio;
              if (data.avatarURL) document.getElementById(prefix + '_iconUrl').value = data.avatarURL;
              statusDiv.innerHTML = '<span class="text-success">User found! Info pre-filled.</span>';
            } else if (response.status === 404) {
              document.getElementById(prefix + '_iconUrl').value = 'https://github.com/' + username + '.png';
              statusDiv.innerHTML = '<span class="text-warning">User not found in our system. Please fill in the details manually.</span>';
            } else {
              statusDiv.innerHTML = '<span class="text-danger">Lookup failed. Please fill in manually.</span>';
            }
          } catch (e) {
            statusDiv.innerHTML = '<span class="text-danger">Lookup error. Please fill in manually.</span>';
          }
        }
      </script>
      """)
  }
}
