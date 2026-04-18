import Elementary

struct PageContent: HTML, Sendable {
  let page: CfPPage
  let language: AppLanguage

  var body: some HTML {
    switch page {
    case .home:
      HomeLanding(language: language)
    case .guidelines:
      GuidelinesContent(language: language)
    case .submit:
      SubmitContent(language: language)
    case .workshops:
      WorkshopsContent(language: language)
    default:
      section(.class("hero-card")) {
        h1 { HTMLText(page.title(for: language)) }
        p(
          .id("page-description"),
          .data("signed-out-copy", value: signedOutDescription ?? pageDescription),
          .data("signed-in-copy", value: pageDescription)
        ) { HTMLText(initialPageDescription) }
      }

      section(.class("status-card")) {
        h2 { HTMLText(language == .ja ? "セッション" : "Session") }
        p(.id("auth-status")) {
          HTMLText(language == .ja ? "サインイン状態を確認しています..." : "Checking sign-in state...")
        }
      }

      section(.class("detail-card")) {
        p(
          .id("page-detail-copy"),
          .data("signed-out-copy", value: signedOutDescription ?? pageDescription),
          .data("signed-in-copy", value: pageDescription)
        ) { HTMLText(initialPageDescription) }
      }
    }
  }

  private var initialPageDescription: String {
    signedOutDescription ?? pageDescription
  }

  private var pageDescription: String {
    switch page {
    case .login:
      return language == .ja
        ? "GitHubアカウントでログインすると、応募の提出や管理ができます。"
        : "Sign in with your GitHub account to submit and manage your proposals."
    case .profile:
      return language == .ja
        ? "スピーカー情報やプロフィールを確認、更新できます。"
        : "Review and update your speaker profile information."
    case .submit:
      return language == .ja
        ? "トークタイトルや概要を入力して、プロポーザルを提出できます。"
        : "Fill in your talk title, abstract, and details to submit a proposal."
    case .workshops:
      return language == .ja
        ? "ワークショップの確認、応募、結果の確認ができます。"
        : "Browse workshops, apply, and check your application status."
    case .myProposals:
      return language == .ja
        ? "提案の状態確認、編集、取り下げをここで行います。"
        : "Review the status of your proposals, edit them, or withdraw them."
    case .feedback:
      return language == .ja
        ? "あなたのセッションに寄せられたフィードバックを確認できます。"
        : "Check feedback submitted for your sessions."
    case .organizer:
      return language == .ja
        ? "運営メンバー向けの管理機能です。"
        : "Organizer tools for managing proposals, workshops, and scheduling."
    default:
      return page.description(for: language)
    }
  }

  private var signedOutDescription: String? {
    switch page {
    case .submit:
      return language == .ja
        ? "プロポーザルを提出するには、GitHubアカウントでサインインしてください。"
        : "Sign in with your GitHub account to submit a proposal."
    case .myProposals:
      return language == .ja
        ? "応募内容を確認するには、GitHubアカウントでサインインしてください。"
        : "Sign in with your GitHub account to review your proposals."
    case .profile:
      return language == .ja
        ? "プロフィールを編集するには、GitHubアカウントでサインインしてください。"
        : "Sign in with your GitHub account to edit your speaker profile."
    case .feedback:
      return language == .ja
        ? "フィードバックを確認するには、GitHubアカウントでサインインしてください。"
        : "Sign in with your GitHub account to review feedback for your talks."
    case .organizer:
      return language == .ja
        ? "運営向け画面にアクセスするには、権限のあるアカウントでサインインしてください。"
        : "Sign in with an organizer account to access admin tools."
    default:
      return nil
    }
  }
}

private struct SubmitContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    section(.class("submit-shell")) {
      div(.class("submit-shell-inner")) {
        h1 { HTMLText(language == .ja ? "プロポーザルを提出" : "Submit Your Proposal") }
        p(.class("submit-lead")) {
          HTMLText(language == .ja
            ? "あなたのSwiftの知見を、世界中の開発者と共有しませんか。"
            : "Share your Swift expertise with developers from around the world.")
        }
        SubmitAuthCard(language: language)
        SubmitFormCard(language: language)
      }
    }
  }
}

private struct SubmitAuthCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card submit-auth-card")) {
      p(.class("submit-auth-icon"), .custom(name: "aria-hidden", value: "true")) { "🔐" }
      h3(
        .id("page-description"),
        .data("signed-out-copy", value: language == .ja ? "サインインが必要です" : "Sign In Required"),
        .data("signed-in-copy", value: language == .ja ? "サインイン済みです" : "You're Signed In")
      ) {
        HTMLText(language == .ja ? "サインインが必要です" : "Sign In Required")
      }
      p(
        .id("page-detail-copy"),
        .class("submit-auth-copy"),
        .data("signed-out-copy", value: language == .ja
          ? "GitHubアカウントを連携すると、プロポーザルの提出と応募状況の確認ができます。"
          : "Connect your GitHub account to submit proposals and track your submissions."),
        .data("signed-in-copy", value: language == .ja
          ? "GitHubアカウントとの連携が完了しています。応募状況の確認や管理をこのアカウントで行えます。"
          : "Your GitHub account is connected. You can use this account to manage your submissions.")
      ) {
        HTMLText(language == .ja
          ? "GitHubアカウントを連携すると、プロポーザルの提出と応募状況の確認ができます。"
          : "Connect your GitHub account to submit proposals and track your submissions.")
      }
      p(.id("auth-status"), .class("submit-auth-status")) {
        HTMLText(language == .ja ? "サインイン状態を確認しています..." : "Checking sign-in state...")
      }
      button(
        .type(.button),
        .id("submit-login-button"),
        .class("button submit-login-button"),
        .data("login-button", value: "true")
      ) {
        HTMLText(language == .ja ? "GitHubでサインイン" : "Sign in with GitHub")
      }
    }
  }
}

private struct SubmitFormCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.id("submit-form-card"), .class("detail-card submit-form-card"), .hidden) {
      h3 { HTMLText(language == .ja ? "プロポーザル詳細" : "Proposal Details") }
      p(.class("submit-form-intro")) {
        HTMLText(language == .ja
          ? "タイトル、概要、スピーカー情報を入力して応募できます。"
          : "Fill in your talk details and speaker information to submit.")
      }
      p(.id("submit-status"), .class("inline-status"), .hidden) {}

      form(.id("submit-form"), .class("submit-form-grid")) {
        SubmitBasicFields(language: language)
        SubmitWorkshopFields(language: language)
        div(.class("form-actions submit-form-full")) {
          button(.type(.submit), .class("button primary")) {
            HTMLText(language == .ja ? "プロポーザルを提出する" : "Submit Proposal")
          }
        }
      }
    }
  }
}

private struct SubmitBasicFields: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
      select(.id("submit-conference-path"), .name("conferencePath"), .required) {}
    }
    label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "形式" : "Format") }
      select(.name("talkDuration"), .required) {
        option(.value("20min")) { HTMLText(language == .ja ? "レギュラートーク (20分)" : "Regular Talk (20 min)") }
        option(.value("LT")) { HTMLText(language == .ja ? "ライトニングトーク (5分)" : "Lightning Talk (5 min)") }
        option(.value("workshop")) { HTMLText(language == .ja ? "ワークショップ" : "Workshop") }
      }
    }
    label(.class("form-field submit-form-full")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "タイトル" : "Title") }
      input(.type(.text), .name("title"), .required)
    }
    label(.class("form-field submit-form-full")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "概要" : "Abstract") }
      textarea(.name("abstract"), .required, .custom(name: "rows", value: "5")) {}
    }
    label(.class("form-field submit-form-full")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "詳細" : "Talk Details") }
      textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "8")) {}
    }
    label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "登壇者名" : "Speaker Name") }
      input(.type(.text), .name("speakerName"), .required)
    }
    label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "メールアドレス" : "Speaker Email") }
      input(.type(.email), .name("speakerEmail"), .required)
    }
    label(.class("form-field submit-form-full")) {
      span(.class("field-label")) { HTMLText("Bio") }
      textarea(.name("bio"), .required, .custom(name: "rows", value: "5")) {}
    }
    div(.class("form-field avatar-field submit-form-full")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "アイコンURL" : "Avatar URL") }
      div(.class("avatar-field-row")) {
        input(.type(.url), .name("iconURL"), .placeholder(language == .ja ? "https://example.com/avatar.png" : "https://example.com/avatar.png"))
        div(.class("avatar-preview"), .id("submit-avatar-preview")) {
          img(
            .id("submit-avatar-image"),
            .src("/images/riko.png"),
            .alt(language == .ja ? "アバタープレビュー" : "Avatar preview")
          )
        }
      }
    }
    label(.class("form-field submit-form-full")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "メモ" : "Notes for Organizers") }
      textarea(.name("notes"), .custom(name: "rows", value: "4")) {}
    }
  }
}

private struct SubmitWorkshopFields: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    div(.id("submit-workshop-section"), .class("submit-workshop-section submit-form-full"), .hidden) {
      h4 { HTMLText(language == .ja ? "ワークショップ詳細" : "Workshop Details") }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "言語" : "Language") }
        select(.name("workshopLanguage")) {
          option(.value("english")) { HTMLText(language == .ja ? "英語" : "English") }
          option(.value("japanese")) { HTMLText(language == .ja ? "日本語" : "Japanese") }
          option(.value("bilingual")) { HTMLText(language == .ja ? "バイリンガル" : "Bilingual") }
        }
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "講師数" : "Number of Tutors") }
        input(.type(.number), .name("workshopNumberOfTutors"), .custom(name: "min", value: "1"), .value("1"))
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "学べること" : "Key Takeaways") }
        textarea(.name("workshopKeyTakeaways"), .custom(name: "rows", value: "4")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "前提知識" : "Prerequisites") }
        textarea(.name("workshopPrerequisites"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "アジェンダ" : "Agenda / Schedule") }
        textarea(.name("workshopAgendaSchedule"), .custom(name: "rows", value: "5")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "持ち物" : "What to Bring") }
        textarea(.name("workshopParticipantRequirements"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "必要なソフトウェア" : "Required Software") }
        textarea(.name("workshopRequiredSoftware"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "ネットワーク要件" : "Network Requirements") }
        textarea(.name("workshopNetworkRequirements"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "企画意図" : "Motivation") }
        textarea(.name("workshopMotivation"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "独自性" : "Uniqueness") }
        textarea(.name("workshopUniqueness"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "懸念点" : "Potential Risks") }
        textarea(.name("workshopPotentialRisks"), .custom(name: "rows", value: "3")) {}
      }
      div(.class("submit-form-full workshop-facilities")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "必要設備" : "Required Facilities") }
        label { input(.type(.checkbox), .name("workshopFacilityProjector")); HTMLText(language == .ja ? "プロジェクター" : "Projector") }
        label { input(.type(.checkbox), .name("workshopFacilityMicrophone")); HTMLText(language == .ja ? "マイク" : "Microphone") }
        label { input(.type(.checkbox), .name("workshopFacilityWhiteboard")); HTMLText(language == .ja ? "ホワイトボード" : "Whiteboard") }
        label { input(.type(.checkbox), .name("workshopFacilityPowerStrips")); HTMLText(language == .ja ? "電源タップ" : "Power Strips") }
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "その他設備" : "Other Facilities") }
        input(.type(.text), .name("workshopFacilityOther"))
      }
      SubmitCoInstructorFields(language: language, prefix: "submit-co1")
      SubmitCoInstructorFields(language: language, prefix: "submit-co2")
    }
  }
}

private struct SubmitCoInstructorFields: HTML, Sendable {
  let language: AppLanguage
  let prefix: String

  var body: some HTML {
    div(.class("submit-form-full co-instructor-fields")) {
      h4 { HTMLText(language == .ja ? "共同講師" : "Co-Instructor") }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "名前" : "Name") }
        input(.type(.text), .name("\(prefix)Name"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("Email") }
        input(.type(.email), .name("\(prefix)Email"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("GitHub") }
        input(.type(.text), .name("\(prefix)GithubUsername"))
      }
      label(.class("form-field submit-form-full")) {
        span(.class("field-label")) { HTMLText("Bio") }
        textarea(.name("\(prefix)Bio"), .custom(name: "rows", value: "3")) {}
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText("SNS") }
        input(.type(.url), .name("\(prefix)Sns"))
      }
      label(.class("form-field")) {
        span(.class("field-label")) { HTMLText(language == .ja ? "アイコンURL" : "Avatar URL") }
        input(.type(.url), .name("\(prefix)IconURL"))
      }
    }
  }
}

private struct WorkshopsContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    section(.class("workshops-shell")) {
      div(.class("workshops-shell-inner")) {
        h1 { HTMLText(language == .ja ? "ワークショップ" : "Workshops") }
        p(.class("workshops-lead")) {
          HTMLText(language == .ja
            ? "try! Swift Tokyo 2026 のワークショップに応募できます。第3希望まで選択でき、割り当ては抽選で決定されます。"
            : "Apply for try! Swift Tokyo 2026 workshops. You can select up to 3 preferences, and assignments are determined by lottery.")
        }

        p(.id("workshops-status"), .class("status-banner"), .hidden) {}

        section(.class("workshops-list-section")) {
          div(.id("workshop-list"), .class("workshops-list")) {}
        }

        section(.id("workshop-modal"), .class("workshop-modal"), .hidden) {
          div(.class("workshop-modal-backdrop"), .data("workshop-modal-close", value: "true")) {}
          div(.class("workshop-modal-dialog"), .custom(name: "role", value: "dialog"), .custom(name: "aria-modal", value: "true")) {
            button(.type(.button), .class("workshop-modal-close"), .data("workshop-modal-close", value: "true"), .custom(name: "aria-label", value: language == .ja ? "閉じる" : "Close")) { "×" }
            div(.id("workshop-modal-body"), .class("workshop-modal-body")) {}
          }
        }

        div(.class("workshop-tools-grid")) {
          article(.id("workshop-apply"), .class("detail-card workshop-tool-card")) {
            h3 { HTMLText(language == .ja ? "ワークショップに応募する" : "Apply for Workshops") }
            p {
              HTMLText(language == .ja
                ? "チケット購入時に使用したメールアドレスを入力して、応募手続きを開始してください。"
                : "Enter the email address you used for your ticket to begin your workshop application.")
            }

            form(.id("workshop-verify-form"), .class("workshop-form")) {
              label(.class("form-field")) {
                span(.class("field-label")) { HTMLText(language == .ja ? "メールアドレス" : "Email Address") }
                input(.type(.email), .name("email"), .required, .placeholder(language == .ja ? "you@example.com" : "you@example.com"))
              }
              div(.class("form-actions")) {
                button(.type(.submit), .class("button primary")) {
                  HTMLText(language == .ja ? "チケットを確認" : "Verify Ticket")
                }
              }
            }

            p(.id("workshop-verify-status"), .class("inline-status"), .hidden) {}

            form(.id("workshop-apply-form"), .class("workshop-form"), .hidden) {
              input(.type(.hidden), .name("verifyToken"))
              label(.class("form-field")) {
                span(.class("field-label")) { HTMLText(language == .ja ? "参加者名" : "Applicant Name") }
                input(.type(.text), .name("applicantName"), .required)
              }
              label(.class("form-field")) {
                span(.class("field-label")) { HTMLText(language == .ja ? "第1希望" : "First Choice") }
                select(.name("firstChoiceID"), .id("workshop-first-choice"), .required) {}
              }
              label(.class("form-field")) {
                span(.class("field-label")) { HTMLText(language == .ja ? "第2希望" : "Second Choice") }
                select(.name("secondChoiceID"), .id("workshop-second-choice")) {}
              }
              label(.class("form-field")) {
                span(.class("field-label")) { HTMLText(language == .ja ? "第3希望" : "Third Choice") }
                select(.name("thirdChoiceID"), .id("workshop-third-choice")) {}
              }
              div(.class("form-actions")) {
                button(.type(.submit), .class("button primary")) {
                  HTMLText(language == .ja ? "応募を保存" : "Save Application")
                }
              }
            }
          }

          article(.id("workshop-status"), .class("detail-card workshop-tool-card")) {
            h3 { HTMLText(language == .ja ? "応募状況を確認する" : "Check Application Status") }
            p {
              HTMLText(language == .ja
                ? "メールアドレスを入力すると、現在の応募状況や割り当て結果を確認できます。"
                : "Enter your email address to check your current workshop application or assignment.")
            }

            form(.id("workshop-status-form"), .class("workshop-form")) {
              label(.class("form-field")) {
                span(.class("field-label")) { HTMLText(language == .ja ? "メールアドレス" : "Email Address") }
                input(.type(.email), .name("email"), .required, .placeholder(language == .ja ? "you@example.com" : "you@example.com"))
              }
              div(.class("form-actions")) {
                button(.type(.submit), .class("button primary")) {
                  HTMLText(language == .ja ? "状況を確認" : "Check Status")
                }
              }
            }

            p(.id("workshop-status-check-status"), .class("inline-status"), .hidden) {}
            div(.id("workshop-status-result"), .class("workshop-status-result")) {}
          }
        }
      }
    }
  }
}

private struct HomeLanding: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    section(.class("hero-card hero-landing")) {
      div(.class("section-inner")) {
        p(.class("eyebrow")) { "try! Swift Tokyo 2026" }
        h1 { HTMLText(language == .ja ? "プロポーザル募集" : "Call for Proposals") }
        p(.class("hero-copy")) {
          HTMLText(language == .ja
            ? "あなたのSwiftの知識を世界中の開発者と共有しませんか？try! Swift Tokyo 2026でトークプロポーザルを提出してください！"
            : "Share your Swift expertise with developers from around the world. Submit your talk proposal for try! Swift Tokyo 2026!")
        }
        div(.class("hero-actions")) {
          a(.href(CfPPage.submit.path(for: language)), .class("button primary button-link")) {
            HTMLText(language == .ja ? "プロポーザルを提出する" : "Submit Your Proposal")
          }
          a(.href(CfPPage.guidelines.path(for: language)), .class("button light button-link")) {
            HTMLText(language == .ja ? "ガイドラインを見る" : "View Guidelines")
          }
          a(.href(CfPPage.myProposals.path(for: language)), .class("button light button-link")) {
            HTMLText(language == .ja ? "応募履歴" : "My Proposals")
          }
        }
      }
    }

    section(.class("content-section")) {
      div(.class("section-inner")) {
        h2 { HTMLText(language == .ja ? "重要な日程" : "Important Dates") }
        div(.class("card-grid dates-grid")) {
          for item in importantDates {
            article(.class("detail-card center-card")) {
              h5 { HTMLText(item.title) }
              p(.class("date-copy")) { HTMLText(item.date) }
              if item.emoji != nil {
                p(.class("date-emoji")) { HTMLText(item.emoji!) }
              }
            }
          }
        }
      }
    }

    section(.class("content-section alt-section")) {
      div(.class("section-inner")) {
        h2 { HTMLText(language == .ja ? "トークの形式" : "Talk Formats") }
        div(.class("card-grid formats-grid")) {
          for item in talkFormats {
            article(.class("detail-card")) {
              h3 {
                if let emoji = item.emoji {
                  span(.class("title-emoji")) { HTMLText(emoji) }
                }
                HTMLText(item.title)
              }
              p(.class("format-duration")) { HTMLText(item.duration) }
              p { HTMLText(item.description) }
            }
          }
        }
      }
    }

    section(.class("content-section")) {
      div(.class("section-inner")) {
        h2 { HTMLText(language == .ja ? "募集しているトピック" : "Topics We're Looking For") }
        div(.class("card-grid info-grid")) {
          for item in topics {
            article(.class("detail-card")) {
              h5 { HTMLText(item.title) }
              p { HTMLText(item.description) }
            }
          }
        }
      }
    }

    section(.class("cta-card")) {
      div(.class("cta-card-inner")) {
      h2 { HTMLText(language == .ja ? "あなたの知識を共有しませんか？" : "Ready to Share Your Knowledge?") }
      p {
        HTMLText(language == .ja
          ? "経験レベルに関係なく、すべてのスピーカーを歓迎します。初めての登壇者の方も、ぜひご応募ください！"
          : "We welcome speakers of all experience levels. First-time speakers are encouraged to apply!")
      }
      a(.href(CfPPage.submit.path(for: language)), .class("button primary button-link")) {
        HTMLText(language == .ja ? "プロポーザルを提出する" : "Submit Your Proposal")
      }
      }
    }
  }

  private var importantDates: [(title: String, date: String, emoji: String?)] {
    language == .ja
      ? [
        ("CfP開始", "2026年1月15日", "📅"),
        ("応募締切", "2026年2月1日", "⏰"),
        ("結果発表", "2026年2月8日", "📣"),
        ("カンファレンス", "2026年4月12-14日", "🎤"),
      ]
      : [
        ("CfP Opens", "January 15, 2026", "📅"),
        ("Submission Deadline", "February 1, 2026", "⏰"),
        ("Notifications", "February 8, 2026", "📣"),
        ("Conference", "April 12-14, 2026", "🎤"),
      ]
  }

  private var talkFormats: [(emoji: String?, title: String, duration: String, description: String)] {
    language == .ja
      ? [
        ("🎯", "レギュラートーク", "20分", "特定のトピックについて詳しく解説し、具体的な例やライブデモを交えてお話しください。Swiftの開発に関する包括的な知識を共有するのに最適です。"),
        ("⚡", "ライトニングトーク", "5分", "1つのアイデア、ヒント、ツールに焦点を当てた短くて集中したプレゼンテーションです。初めての登壇者や、ちょっとしたアイデアの共有に最適です！"),
      ]
      : [
        ("🎯", "Regular Talk", "20 minutes", "Deep dive into a specific topic with detailed examples and live demos. Perfect for sharing comprehensive knowledge about Swift development."),
        ("⚡", "Lightning Talk", "5 minutes", "Quick, focused presentation on a single idea, tip, or tool. Great for first-time speakers or sharing quick wins!"),
      ]
  }

  private var topics: [(title: String, description: String)] {
    language == .ja
      ? [
        ("Swift言語", "新機能、ベストプラクティス、言語の進化"),
        ("SwiftUI", "モダンなUI開発、アニメーション、アーキテクチャ"),
        ("iOS/macOS/visionOS", "プラットフォーム固有の開発とAPI"),
        ("サーバーサイドSwift", "Vapor、バックエンド開発、クラウドデプロイメント"),
        ("テストと品質", "ユニットテスト、UIテスト、コード品質"),
        ("ツールと生産性", "Xcode、デバッグ、開発者体験"),
      ]
      : [
        ("Swift Language", "New features, best practices, and language evolution"),
        ("SwiftUI", "Modern UI development, animations, and architecture"),
        ("iOS/macOS/visionOS", "Platform-specific development and APIs"),
        ("Server-Side Swift", "Vapor, backend development, and cloud deployment"),
        ("Testing & Quality", "Unit testing, UI testing, and code quality"),
        ("Tools & Productivity", "Xcode, debugging, and developer experience"),
      ]
  }
}

private struct GuidelinesContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    section(.class("hero-card")) {
      h1 { HTMLText(language == .ja ? "応募ガイドライン" : "Submission Guidelines") }
      p(.id("page-description")) {
        HTMLText(language == .ja
          ? "try! Swift Tokyo 2026にトークプロポーザルを提出するために必要な情報をまとめました。"
          : "Everything you need to know about submitting a talk proposal for try! Swift Tokyo 2026.")
      }
    }

    section(.class("guidelines-stack")) {
      for section in sections {
        article(.class("detail-card")) {
          h2 { HTMLText(section.title) }
          if let intro = section.intro {
            p { HTMLText(intro) }
          }
          if !section.bullets.isEmpty {
            ul(.class("plain-list")) {
              for bullet in section.bullets {
                li { HTMLText(bullet) }
              }
            }
          }
          if !section.items.isEmpty {
            div(.class("guideline-items")) {
              for item in section.items {
                div(.class("guideline-item")) {
                  h4 { HTMLText(item.title) }
                  p { HTMLText(item.copy) }
                }
              }
            }
          }
        }
      }

      section(.class("detail-card cta-card")) {
        a(.href(CfPPage.submit.path(for: language)), .class("button primary button-link")) {
          HTMLText(language == .ja ? "プロポーザルを提出" : "Submit Your Proposal")
        }
      }
    }
  }

  private var sections: [(title: String, intro: String?, bullets: [String], items: [(title: String, copy: String)])] {
    if language == .ja {
      return [
        ("私たちが求めているもの", nil, [
          "他の主要なカンファレンスで発表されていないオリジナルコンテンツ",
          "参加者が実際の仕事に活かせる実践的な知識",
          "聴衆にとって明確な学習成果",
          "デモを含む、よく構成されたプレゼンテーション",
          "Swiftコミュニティに関連するトピック",
        ], []),
        ("トーク形式", nil, [], [
          ("レギュラートーク（20分）", "トピックを深く掘り下げる包括的なセッションです。コンテキスト、例、重要なポイントを含める時間があります。ライブコーディングやデモも歓迎します！"),
          ("ライトニングトーク（5分）", "1つのコンセプト、ツール、またはヒントをカバーする、焦点を絞った短いプレゼンテーションです。新しいアイデアの紹介や、ちょっとした発見の共有に最適です。"),
        ]),
        ("プロポーザルの要件", nil, [], [
          ("タイトル", "トーク内容を正確に表す、明確で説明的なタイトル。"),
          ("概要", "トークが採択された場合に公開される2〜3文の要約。参加者が何を学べるかを説明してください。"),
          ("トークの詳細", "レビュアー向けのトークの詳細な説明。アウトライン、重要なポイント、予定しているデモなどを含めてください。これはあなたのビジョンを理解するのに役立ちます。"),
          ("スピーカー自己紹介", "あなたについて教えてください！経歴、経験、このトピックに興味を持った理由などを書いてください。"),
          ("備考（任意）", "主催者への追加情報。アクセシビリティの要件、スケジュールの制約、以前にこのトークを行ったことがあるかどうかなど。"),
        ]),
        ("選考基準", "レビュー委員会は以下の基準でプロポーザルを評価します：", [
          "Swiftコミュニティへの関連性",
          "コンテンツの独自性とユニークさ",
          "プロポーザルと学習成果の明確さ",
          "スピーカーの専門知識とプレゼンテーション能力",
          "カンファレンスプログラム全体でのトピックの多様性",
        ], []),
        ("素晴らしいプロポーザルのためのヒント", nil, [
          "参加者が何を学ぶか具体的に書く",
          "明確なアウトラインや構成を含める",
          "デモやライブコーディングの予定があれば記載する",
          "トピックへの情熱を示す",
          "提出前によく校正する",
          "複数のプロポーザルを提出することをためらわない！",
        ], []),
        ("スピーカー特典", nil, [
          "カンファレンスチケット無料",
          "他のスピーカーや主催者とのスピーカーディナー",
          "海外からのスピーカーには渡航サポートあり",
          "トークのプロフェッショナルなビデオ撮影",
          "世界中のSwift開発者とのネットワーキングの機会",
        ], []),
      ]
    }

    return [
      ("What We're Looking For", nil, [
        "Original content that hasn't been presented at other major conferences",
        "Practical knowledge that attendees can apply in their work",
        "Clear learning outcomes for the audience",
        "Well-structured presentations with demos when applicable",
        "Topics relevant to the Swift community",
      ], []),
      ("Talk Formats", nil, [], [
        ("Regular Talk (20 minutes)", "A comprehensive session covering a topic in depth. Include time for context, examples, and key takeaways. Live coding and demos are welcome!"),
        ("Lightning Talk (5 minutes)", "A focused, fast-paced presentation covering a single concept, tool, or tip. Perfect for sharing quick wins or introducing new ideas."),
      ]),
      ("Proposal Requirements", nil, [], [
        ("Title", "A clear, descriptive title that accurately represents your talk content."),
        ("Abstract", "A 2-3 sentence summary that will be shown publicly if your talk is accepted. This should explain what attendees will learn."),
        ("Talk Details", "A detailed description of your talk for reviewers. Include your outline, key points, and any demos you plan to show. This helps us understand your vision."),
        ("Speaker Bio", "Tell us about yourself! Your background, experience, and what makes you excited about this topic."),
        ("Notes (Optional)", "Any additional information for organizers, such as accessibility needs, scheduling constraints, or whether you've given this talk before."),
      ]),
      ("Selection Criteria", "Our review committee evaluates proposals based on:", [
        "Relevance to the Swift community",
        "Originality and uniqueness of content",
        "Clarity of proposal and learning outcomes",
        "Speaker's expertise and presentation ability",
        "Diversity of topics across the conference program",
      ], []),
      ("Tips for a Great Proposal", nil, [
        "Be specific about what attendees will learn",
        "Include a clear outline or structure",
        "Mention any demos or live coding",
        "Show your passion for the topic",
        "Proofread your submission carefully",
        "Don't be afraid to submit multiple proposals!",
      ], []),
      ("Speaker Benefits", nil, [
        "Free conference ticket",
        "Speaker dinner with other speakers and organizers",
        "Travel support available for international speakers",
        "Professional video recording of your talk",
        "Networking opportunities with Swift developers worldwide",
      ], []),
    ]
  }
}
