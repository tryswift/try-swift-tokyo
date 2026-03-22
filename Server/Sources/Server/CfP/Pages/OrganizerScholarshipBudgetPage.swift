import Elementary
import Foundation
import SharedModels

struct OrganizerScholarshipBudgetPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let budget: Int?
  let notes: String?
  let approvedTotal: Int
  let applicationCount: Int
  let csrfToken: String

  var body: some HTML {
    div(.class("container py-5")) {
      backButton
      pageHeader
      summaryCards
      budgetForm
    }
  }

  // MARK: - Back Button

  private var backButton: some HTML {
    div(.class("mb-4")) {
      a(
        .class("btn btn-outline-secondary"),
        .href(language.path(for: "/organizer/scholarships"))
      ) {
        language == .ja ? "\u{2190} 申請一覧に戻る" : "\u{2190} Back to All Applications"
      }
    }
  }

  // MARK: - Page Header

  private var pageHeader: some HTML {
    div(.class("mb-4")) {
      h1(.class("fw-bold mb-2")) {
        language == .ja ? "予算管理" : "Budget Management"
      }
      p(.class("lead text-muted")) {
        language == .ja
          ? "スカラシップの予算を設定・管理します。"
          : "Set and manage the scholarship budget."
      }
    }
  }

  // MARK: - Summary Cards

  private var summaryCards: some HTML {
    div(.class("row mb-4")) {
      div(.class("col-md-3")) {
        div(.class("card bg-primary text-white")) {
          div(.class("card-body text-center")) {
            h3(.class("card-title mb-0")) {
              if let budget {
                HTMLText("\(formatYen(budget))")
              } else {
                language == .ja ? "未設定" : "Not Set"
              }
            }
            p(.class("card-text mb-0")) {
              language == .ja ? "総予算" : "Total Budget"
            }
          }
        }
      }
      div(.class("col-md-3")) {
        div(.class("card bg-success text-white")) {
          div(.class("card-body text-center")) {
            h3(.class("card-title mb-0")) {
              HTMLText("\(formatYen(approvedTotal))")
            }
            p(.class("card-text mb-0")) {
              language == .ja ? "承認済み合計" : "Approved Total"
            }
          }
        }
      }
      div(.class("col-md-3")) {
        div(.class("card bg-info text-white")) {
          div(.class("card-body text-center")) {
            h3(.class("card-title mb-0")) {
              if let budget {
                HTMLText("\(formatYen(budget - approvedTotal))")
              } else {
                "-"
              }
            }
            p(.class("card-text mb-0")) {
              language == .ja ? "残り予算" : "Remaining"
            }
          }
        }
      }
      div(.class("col-md-3")) {
        div(.class("card bg-secondary text-white")) {
          div(.class("card-body text-center")) {
            h3(.class("card-title mb-0")) {
              HTMLText("\(applicationCount)")
            }
            p(.class("card-text mb-0")) {
              language == .ja ? "申請数" : "Applications"
            }
          }
        }
      }
    }
  }

  // MARK: - Budget Form

  private var budgetForm: some HTML {
    div(.class("card")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "予算設定" : "Budget Settings"
        }
      }
      div(.class("card-body")) {
        form(
          .method(.post),
          .action(language.path(for: "/organizer/scholarship-budget"))
        ) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))

          // Total Budget
          div(.class("mb-3")) {
            label(.class("form-label fw-semibold"), .for("total_budget")) {
              language == .ja ? "総予算（円）" : "Total Budget (yen)"
            }
            input(
              .type(.number),
              .class("form-control"),
              .name("total_budget"),
              .id("total_budget"),
              .custom(name: "min", value: "0"),
              .value(budget.map { "\($0)" } ?? ""),
              .placeholder(language == .ja ? "予算額を入力" : "Enter budget amount")
            )
            div(.class("form-text")) {
              language == .ja
                ? "スカラシップに割り当てる総予算額を設定してください。"
                : "Set the total budget allocated for scholarships."
            }
          }

          // Notes
          div(.class("mb-3")) {
            label(.class("form-label fw-semibold"), .for("budget_notes")) {
              language == .ja ? "メモ（任意）" : "Notes (Optional)"
            }
            textarea(
              .class("form-control"),
              .name("budget_notes"),
              .id("budget_notes"),
              .custom(name: "rows", value: "3"),
              .placeholder(
                language == .ja
                  ? "予算に関するメモ"
                  : "Notes about the budget"
              )
            ) {
              HTMLText(notes ?? "")
            }
          }

          div(.class("d-grid")) {
            button(.type(.submit), .class("btn btn-primary btn-lg")) {
              language == .ja ? "予算を更新" : "Update Budget"
            }
          }
        }
      }
    }
  }

  // MARK: - Helpers

  private func formatYen(_ amount: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
  }
}
