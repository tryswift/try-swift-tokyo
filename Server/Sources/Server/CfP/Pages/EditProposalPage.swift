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
      workshopFieldsSection(details: proposal.workshopDetails)
      speakerInfoSection(proposal: proposal)
      coInstructorFieldsSection(coInstructors: proposal.coInstructors)
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
        language == .ja ? "タイプ *" : "Type *"
      }
      select(
        .class("form-select"), .name("talkDuration"), .id("talkDuration"), .required
      ) {
        option(.value("")) {
          language == .ja ? "タイプを選択..." : "Choose type..."
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
        if selected == .workshop {
          option(.value("workshop"), .selected) {
            language == .ja ? "ワークショップ" : "Workshop"
          }
        } else {
          option(.value("workshop")) {
            language == .ja ? "ワークショップ" : "Workshop"
          }
        }
      }
    }
  }

  // MARK: - Workshop Fields (Edit mode with pre-fill)

  @HTMLBuilder
  private func workshopFieldsSection(details: WorkshopDetails?) -> some HTML {
    let isWorkshop = proposal?.talkDuration == .workshop
    HTMLRaw(
      """
      <div id="workshopFields" style="display: \(isWorkshop ? "block" : "none");">
      """)
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) {
          language == .ja ? "ワークショップ詳細" : "Workshop Details"
        }

        // Language
        workshopLanguageField(selected: details?.language)
        // Number of Tutors
        workshopTutorsField(value: details?.numberOfTutors)
        // Key Takeaways
        workshopKeyTakeawaysField(value: details?.keyTakeaways)
        // Prerequisites
        workshopPrerequisitesField(value: details?.prerequisites)
        // Agenda
        workshopAgendaField(value: details?.agendaSchedule)
        // Participant Requirements
        workshopParticipantRequirementsField(value: details?.participantRequirements)
        // Required Software
        workshopRequiredSoftwareField(value: details?.requiredSoftware)
        // Network Requirements
        workshopNetworkRequirementsField(value: details?.networkRequirements)
        // Facilities
        workshopFacilitiesField(
          selected: details?.requiredFacilities ?? [],
          otherValue: details?.facilityOther)
        // Motivation
        workshopMotivationField(value: details?.motivation)
        // Uniqueness
        workshopUniquenessField(value: details?.uniqueness)
        // Potential Risks
        workshopPotentialRisksField(value: details?.potentialRisks)
      }
    }
    HTMLRaw("</div>")
  }

  private func workshopLanguageField(selected: WorkshopLanguage?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold")) {
        language == .ja ? "使用する言語 *" : "Language *"
      }
      div {
        for lang in WorkshopLanguage.allCases {
          div(.class("form-check form-check-inline")) {
            if lang == selected {
              input(
                .type(.radio), .class("form-check-input"),
                .name("workshop_language"),
                .id("workshop_language_\(lang.rawValue)"),
                .value(lang.rawValue),
                .custom(name: "data-workshop-required", value: "true"),
                .checked
              )
            } else {
              input(
                .type(.radio), .class("form-check-input"),
                .name("workshop_language"),
                .id("workshop_language_\(lang.rawValue)"),
                .value(lang.rawValue),
                .custom(name: "data-workshop-required", value: "true")
              )
            }
            label(.class("form-check-label"), .for("workshop_language_\(lang.rawValue)")) {
              HTMLText(lang.displayName)
            }
          }
        }
      }
    }
  }

  private func workshopTutorsField(value: Int?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_numberOfTutors")) {
        language == .ja ? "チューターの人数 *" : "Number of Tutors *"
      }
      input(
        .type(.number), .class("form-control"),
        .name("workshop_numberOfTutors"),
        .id("workshop_numberOfTutors"),
        .custom(name: "min", value: "0"),
        .custom(name: "data-workshop-required", value: "true"),
        .value(value.map { "\($0)" } ?? "")
      )
    }
  }

  private func workshopKeyTakeawaysField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_keyTakeaways")) {
        language == .ja ? "学べること *" : "Key Takeaways *"
      }
      textarea(
        .class("form-control"), .name("workshop_keyTakeaways"),
        .id("workshop_keyTakeaways"),
        .custom(name: "rows", value: "3"),
        .custom(name: "data-workshop-required", value: "true")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopPrerequisitesField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_prerequisites")) {
        language == .ja ? "前提知識" : "Prerequisites"
      }
      input(
        .type(.text), .class("form-control"),
        .name("workshop_prerequisites"), .id("workshop_prerequisites"),
        .value(value ?? "")
      )
    }
  }

  private func workshopAgendaField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_agendaSchedule")) {
        language == .ja ? "アジェンダ・スケジュール *" : "Agenda & Schedule *"
      }
      textarea(
        .class("form-control"), .name("workshop_agendaSchedule"),
        .id("workshop_agendaSchedule"),
        .custom(name: "rows", value: "4"),
        .custom(name: "data-workshop-required", value: "true")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopParticipantRequirementsField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_participantRequirements")) {
        language == .ja ? "参加者が持参するもの *" : "What Participants Need to Bring *"
      }
      textarea(
        .class("form-control"), .name("workshop_participantRequirements"),
        .id("workshop_participantRequirements"),
        .custom(name: "rows", value: "2"),
        .custom(name: "data-workshop-required", value: "true")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopRequiredSoftwareField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_requiredSoftware")) {
        language == .ja
          ? "事前にインストールが必要なツール・ソフトウェア"
          : "Required Tools / Software to Install in Advance"
      }
      textarea(
        .class("form-control"), .name("workshop_requiredSoftware"),
        .id("workshop_requiredSoftware"),
        .custom(name: "rows", value: "2")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopNetworkRequirementsField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_networkRequirements")) {
        language == .ja ? "ネットワーク要件 *" : "Network Requirements *"
      }
      textarea(
        .class("form-control"), .name("workshop_networkRequirements"),
        .id("workshop_networkRequirements"),
        .custom(name: "rows", value: "2"),
        .custom(name: "data-workshop-required", value: "true")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopFacilitiesField(
    selected: [FacilityRequirement], otherValue: String?
  ) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold")) {
        language == .ja ? "必要な設備・機器" : "Required Facilities / Equipment"
      }
      div {
        for facility in FacilityRequirement.allCases {
          div(.class("form-check")) {
            if selected.contains(facility) {
              input(
                .type(.checkbox), .class("form-check-input"),
                .name("workshop_requiredFacilities"),
                .id("facility_\(facility.rawValue)"),
                .value(facility.rawValue), .checked
              )
            } else {
              input(
                .type(.checkbox), .class("form-check-input"),
                .name("workshop_requiredFacilities"),
                .id("facility_\(facility.rawValue)"),
                .value(facility.rawValue)
              )
            }
            label(.class("form-check-label"), .for("facility_\(facility.rawValue)")) {
              HTMLText(facility.displayName)
            }
          }
        }
        div(.class("form-check")) {
          if otherValue != nil {
            input(
              .type(.checkbox), .class("form-check-input"),
              .name("workshop_hasFacilityOther"), .id("facility_other_check"),
              .value("true"), .checked,
              .custom(name: "onchange", value: "toggleFacilityOther(this.checked)")
            )
          } else {
            input(
              .type(.checkbox), .class("form-check-input"),
              .name("workshop_hasFacilityOther"), .id("facility_other_check"),
              .value("true"),
              .custom(name: "onchange", value: "toggleFacilityOther(this.checked)")
            )
          }
          label(.class("form-check-label"), .for("facility_other_check")) { "Other" }
        }
        input(
          .type(.text), .class("form-control mt-2"),
          .name("workshop_facilityOther"), .id("workshop_facilityOther"),
          .style(otherValue != nil ? "" : "display: none;"),
          .value(otherValue ?? "")
        )
      }
    }
  }

  private func workshopMotivationField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_motivation")) {
        language == .ja ? "動機 *" : "Motivation *"
      }
      textarea(
        .class("form-control"), .name("workshop_motivation"),
        .id("workshop_motivation"),
        .custom(name: "rows", value: "3"),
        .custom(name: "data-workshop-required", value: "true")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopUniquenessField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_uniqueness")) {
        language == .ja ? "ユニークな点 *" : "Uniqueness *"
      }
      textarea(
        .class("form-control"), .name("workshop_uniqueness"),
        .id("workshop_uniqueness"),
        .custom(name: "rows", value: "3"),
        .custom(name: "data-workshop-required", value: "true")
      ) { HTMLText(value ?? "") }
    }
  }

  private func workshopPotentialRisksField(value: String?) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("workshop_potentialRisks")) {
        language == .ja ? "潜在的なリスクや懸念事項" : "Potential Risks or Concerns"
      }
      textarea(
        .class("form-control"), .name("workshop_potentialRisks"),
        .id("workshop_potentialRisks"),
        .custom(name: "rows", value: "2")
      ) { HTMLText(value ?? "") }
    }
  }

  // MARK: - Speaker Info

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
      githubUsernameField(value: proposal.githubUsername ?? "")
      speakerNameField(value: proposal.speakerName)
      speakerEmailField(value: proposal.speakerEmail)
      speakerBioField(value: proposal.bio)
    }
  }

  private func githubUsernameField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("githubUsername")) {
        language == .ja ? "GitHub ID *" : "GitHub ID *"
      }
      input(
        .type(.text), .class("form-control"),
        .name("githubUsername"), .id("githubUsername"),
        .required, .value(value),
        .placeholder(language == .ja ? "GitHubユーザー名" : "GitHub username"),
        .custom(name: "oninput", value: "onGitHubUsernameInput(this.value)")
      )
    }
  }

  private func speakerNameField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("speakerName")) {
        language == .ja ? "名前 *" : "Name *"
      }
      input(
        .type(.text), .class("form-control"),
        .name("speakerName"), .id("speakerName"),
        .required, .value(value),
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
        .type(.email), .class("form-control"),
        .name("speakerEmail"), .id("speakerEmail"),
        .required, .value(value),
        .placeholder("your@email.com")
      )
    }
  }

  private func speakerBioField(value: String) -> some HTML {
    div(.class("mb-3")) {
      label(.class("form-label fw-semibold"), .for("bio")) {
        language == .ja ? "スピーカー自己紹介 *" : "Speaker Bio *"
      }
      textarea(
        .class("form-control"), .name("bio"), .id("bio"),
        .custom(name: "rows", value: "3"), .required,
        .placeholder(language == .ja ? "あなたについて教えてください" : "Tell us about yourself")
      ) { HTMLText(value) }
    }
  }

  private func speakerIconField(iconURL: String?) -> some HTML {
    div(.class("col-md-4")) {
      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("iconUrl")) {
          language == .ja ? "プロフィール画像URL *" : "Profile Picture URL *"
        }
        input(
          .type(.url), .class("form-control"),
          .name("iconUrl"), .id("iconUrl"),
          .required, .value(iconURL ?? ""),
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
        .id("iconPreview"), .src(iconURL ?? ""),
        .alt(language == .ja ? "プロフィール画像プレビュー" : "Profile picture preview"),
        .class("rounded-circle border"),
        .style("width: 100px; height: 100px; object-fit: cover;")
      )
    }
  }

  // MARK: - Co-Instructor Fields (Edit mode)

  @HTMLBuilder
  private func coInstructorFieldsSection(coInstructors: [CoInstructor]?) -> some HTML {
    let isWorkshop = proposal?.talkDuration == .workshop
    let instructors = coInstructors ?? []
    let hasInstructor3 = instructors.count >= 2

    HTMLRaw(
      """
      <div id="coInstructorFields" style="display: \(isWorkshop ? "block" : "none");">
      """)
    div(.class("card bg-light mb-4")) {
      div(.class("card-body")) {
        h5(.class("card-title mb-3")) {
          language == .ja ? "共同講師" : "Co-Instructors"
        }
        p(.class("text-muted small mb-3")) {
          language == .ja
            ? "ワークショップの講師を最大3名まで登録できます（あなたを含む）。"
            : "You can register up to 3 instructors for a workshop (including yourself)."
        }

        coInstructorBlock(
          index: 2, instructor: instructors.count >= 1 ? instructors[0] : nil)

        HTMLRaw(
          """
          <div id="coInstructor3Block" style="display: \(hasInstructor3 ? "block" : "none");">
          """)
        coInstructorBlock(
          index: 3, instructor: instructors.count >= 2 ? instructors[1] : nil)
        HTMLRaw("</div>")

        HTMLRaw(
          """
          <div class="d-flex gap-2 mt-3">
            <button type="button" class="btn btn-outline-secondary btn-sm" id="addInstructor3Btn" style="display: \(hasInstructor3 ? "none" : "inline-block");" onclick="showInstructor3()">
          """)
        HTMLText(language == .ja ? "+ 講師3を追加" : "+ Add Instructor 3")
        HTMLRaw(
          """
            </button>
            <button type="button" class="btn btn-outline-danger btn-sm" id="removeInstructor3Btn" style="display: \(hasInstructor3 ? "inline-block" : "none");" onclick="hideInstructor3()">
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

  private func coInstructorBlock(index: Int, instructor: CoInstructor?) -> some HTML {
    let prefix = "coInstructor\(index)"
    let labelPrefix = language == .ja ? "講師\(index)" : "Instructor \(index)"

    return div(.class("border rounded p-3 mb-3")) {
      h6(.class("fw-semibold mb-3")) { HTMLText(labelPrefix) }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_githubUsername")) {
          HTMLText("\(labelPrefix): GitHub *")
        }
        div(.class("input-group")) {
          input(
            .type(.text), .class("form-control"),
            .name("\(prefix)_githubUsername"),
            .id("\(prefix)_githubUsername"),
            .value(instructor?.githubUsername ?? ""),
            .placeholder(language == .ja ? "GitHubユーザー名" : "GitHub username")
          )
          HTMLRaw(
            """
            <button class="btn btn-outline-primary" type="button" onclick="lookupCoInstructor(\(index))">Lookup</button>
            """)
        }
        HTMLRaw(
          """
          <div id="\(prefix)_lookupStatus" class="form-text"></div>
          """)
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_name")) {
          HTMLText("\(labelPrefix): \(language == .ja ? "名前 *" : "Name *")")
        }
        input(
          .type(.text), .class("form-control"),
          .name("\(prefix)_name"), .id("\(prefix)_name"),
          .value(instructor?.name ?? "")
        )
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_email")) {
          HTMLText("\(labelPrefix): \(language == .ja ? "メールアドレス *" : "Email *")")
        }
        input(
          .type(.email), .class("form-control"),
          .name("\(prefix)_email"), .id("\(prefix)_email"),
          .value(instructor?.email ?? "")
        )
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_sns")) {
          HTMLText("\(labelPrefix): SNS")
        }
        input(
          .type(.text), .class("form-control"),
          .name("\(prefix)_sns"), .id("\(prefix)_sns"),
          .value(instructor?.sns ?? "")
        )
      }

      div(.class("mb-3")) {
        label(.class("form-label fw-semibold"), .for("\(prefix)_bio")) {
          HTMLText("\(labelPrefix): \(language == .ja ? "自己紹介 *" : "Short Bio *")")
        }
        textarea(
          .class("form-control"),
          .name("\(prefix)_bio"), .id("\(prefix)_bio"),
          .custom(name: "rows", value: "2")
        ) { HTMLText(instructor?.bio ?? "") }
      }

      input(
        .type(.hidden),
        .name("\(prefix)_iconUrl"), .id("\(prefix)_iconUrl"),
        .value(instructor?.iconURL ?? "")
      )
    }
  }

  // MARK: - Notes & Submit

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
          var preview = document.getElementById('iconPreview');
          if (url && url.trim() !== '') { preview.src = url; }
        }
        function onGitHubUsernameInput(username) {
          var iconUrlField = document.getElementById('iconUrl');
          if (username && username.trim() !== '' && (!iconUrlField.value || iconUrlField.value.trim() === '')) {
            var avatarUrl = 'https://github.com/' + username.trim() + '.png';
            iconUrlField.value = avatarUrl;
            updateIconPreview(avatarUrl);
          }
        }
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
              if (show) { el.setAttribute('required', ''); } else { el.removeAttribute('required'); }
            });
          }
          if (coInstructorFields) { coInstructorFields.style.display = show ? 'block' : 'none'; }
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
          if (!username) { statusDiv.innerHTML = '<span class="text-danger">Please enter a GitHub username.</span>'; return; }
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
              statusDiv.innerHTML = '<span class="text-warning">User not found. Please fill in manually.</span>';
            } else {
              statusDiv.innerHTML = '<span class="text-danger">Lookup failed.</span>';
            }
          } catch (e) { statusDiv.innerHTML = '<span class="text-danger">Lookup error.</span>'; }
        }
      </script>
      """)
  }
}
