import Elementary

/// Page for checking application status by email
struct WorkshopStatusPageView: HTML, Sendable {
  let language: CfPLanguage
  let csrfToken: String
  let application: ApplicationInfo?
  let showForm: Bool

  struct ApplicationInfo: Sendable {
    let email: String
    let applicantName: String
    let status: WorkshopApplicationStatus
    let firstChoice: String
    let secondChoice: String?
    let thirdChoice: String?
    let assignedWorkshop: String?
    let canModify: Bool
    let deleteToken: String?
  }

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-6 col-lg-5")) {
          h2(.class("fw-bold mb-4 text-center")) {
            language == .ja ? "申し込み状況確認" : "Check Application Status"
          }

          if showForm {
            emailForm
          }

          if let application {
            statusCard(application)
          }
        }
      }
    }
  }

  private var emailForm: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-body p-4")) {
        form(
          .method(.post),
          .action(language.path(for: "/workshops/status"))
        ) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          div(.class("mb-3")) {
            label(.class("form-label fw-bold"), .for("email")) {
              language == .ja ? "メールアドレス" : "Email Address"
            }
            input(
              .type(.email),
              .class("form-control"),
              .id("email"),
              .name("email"),
              .required
            )
          }
          button(.type(.submit), .class("btn btn-primary w-100")) {
            language == .ja ? "確認する" : "Check Status"
          }
        }
      }
    }
  }

  @HTMLBuilder
  private func statusCard(_ app: ApplicationInfo) -> some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        div(.class("text-center mb-3")) {
          p(.class("fs-1 mb-2")) {
            switch app.status {
            case .pending: "⏳"
            case .won: "🎉"
            case .lost: "😢"
            }
          }
          h3(.class("fw-bold")) {
            switch app.status {
            case .pending:
              language == .ja ? "抽選待ち" : "Pending Lottery"
            case .won:
              language == .ja ? "当選しました！" : "You Won!"
            case .lost:
              language == .ja ? "残念ながら落選しました" : "Not Selected"
            }
          }
        }

        div(.class("mt-3")) {
          div(.class("mb-2")) {
            strong { language == .ja ? "お名前: " : "Name: " }
            HTMLText(app.applicantName)
          }
          div(.class("mb-2")) {
            strong { language == .ja ? "第1希望: " : "1st Choice: " }
            HTMLText(app.firstChoice)
          }
          if let second = app.secondChoice {
            div(.class("mb-2")) {
              strong { language == .ja ? "第2希望: " : "2nd Choice: " }
              HTMLText(second)
            }
          }
          if let third = app.thirdChoice {
            div(.class("mb-2")) {
              strong { language == .ja ? "第3希望: " : "3rd Choice: " }
              HTMLText(third)
            }
          }
          if let assigned = app.assignedWorkshop {
            div(.class("mt-3 p-3 bg-success bg-opacity-10 rounded")) {
              strong {
                language == .ja ? "当選ワークショップ: " : "Assigned Workshop: "
              }
              HTMLText(assigned)
            }
          }
        }

        if app.canModify {
          div(.class("mt-4 pt-3 border-top")) {
            a(
              .class("btn btn-outline-primary w-100 mb-2"),
              .href(language.path(for: "/workshops/apply"))
            ) {
              language == .ja ? "申し込みを変更する" : "Edit Application"
            }

            if let deleteToken = app.deleteToken {
              form(
                .method(.post),
                .action(language.path(for: "/workshops/delete")),
                .custom(
                  name: "onsubmit",
                  value: language == .ja
                    ? "return confirm('申し込みを取り消しますか？この操作は元に戻せません。');"
                    : "return confirm('Are you sure you want to delete your application? This action cannot be undone.');"
                )
              ) {
                input(.type(.hidden), .name("_csrf"), .value(csrfToken))
                input(.type(.hidden), .name("delete_token"), .value(deleteToken))
                button(.type(.submit), .class("btn btn-outline-danger w-100")) {
                  language == .ja ? "申し込みを取り消す" : "Delete Application"
                }
              }
            }
          }
        }
      }
    }
  }
}
