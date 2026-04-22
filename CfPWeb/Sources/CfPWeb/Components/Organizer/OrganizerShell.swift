import Elementary

struct OrganizerShell: HTML, Sendable {
  let routePath: String
  let language: AppLanguage

  private var section: OrganizerSection {
    OrganizerSection.from(routePath: routePath)
  }

  var body: some HTML {
    Elementary.section(.class("submit-shell organizer-shell")) {
      div(.class("submit-shell-inner")) {
        h1 { HTMLText(CfPPage.organizer.title(for: language)) }
        p(.class("submit-lead")) {
          HTMLText(
            language == .ja
              ? "運営向けのプロポーザル・タイムテーブル・ワークショップ管理ツールです。"
              : "Admin tools for managing proposals, timetable, and workshops.")
        }

        OrganizerSignInCard(language: language)

        Elementary.section(
          .class("organizer-signed-in-wrapper"), .data("auth-signed-in-card", value: "true"),
          .hidden
        ) {
          OrganizerSubnav(activeSection: section, language: language)
          div(.class("organizer-section")) {
            renderActiveSection()
          }
        }
      }
    }
  }

  @HTMLBuilder
  private func renderActiveSection() -> some HTML {
    switch section {
    case .proposals:
      OrganizerProposalsContent(language: language)
    case .timetable:
      OrganizerTimetableContent(language: language)
    case .workshops:
      OrganizerWorkshopsContent(language: language)
    case .workshopApplications:
      OrganizerWorkshopApplicationsContent(language: language)
    case .workshopResults:
      OrganizerWorkshopResultsContent(language: language)
    }
  }
}

private struct OrganizerSignInCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(
      .class("detail-card submit-auth-card auth-required-card"),
      .data("auth-guest-card", value: "true")
    ) {
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
        .data(
          "signed-out-copy",
          value: language == .ja
            ? "運営向け画面にアクセスするには、権限のあるアカウントでサインインしてください。"
            : "Sign in with an organizer account to access admin tools."),
        .data(
          "signed-in-copy",
          value: language == .ja
            ? "GitHubアカウントとの連携が完了しています。運営向け機能をこのアカウントで利用できます。"
            : "Your GitHub account is connected. You can access organizer tools with this account.")
      ) {
        HTMLText(
          language == .ja
            ? "運営向け画面にアクセスするには、権限のあるアカウントでサインインしてください。"
            : "Sign in with an organizer account to access admin tools.")
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

private struct OrganizerSubnav: HTML, Sendable {
  let activeSection: OrganizerSection
  let language: AppLanguage

  var body: some HTML {
    nav(.class("organizer-subnav")) {
      for section in OrganizerSection.allCases {
        a(
          .href(section.path(for: language)),
          .class(
            section == activeSection ? "organizer-subnav-link active" : "organizer-subnav-link")
        ) {
          HTMLText(section.navigationTitle(for: language))
        }
      }
    }
  }
}
