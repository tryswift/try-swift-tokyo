import Elementary
import Foundation
import SharedModels

struct OrganizerScholarshipsPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let applications: [ScholarshipApplicationDTO]
  let totalBudget: Int?
  let approvedTotal: Int
  let remainingBudget: Int?

  var body: some HTML {
    div(.class("container py-5")) {
      renderHeader
      budgetSummaryCard
      applicationsTable
    }
  }

  // MARK: - Header

  private var renderHeader: some HTML {
    div(.class("d-flex justify-content-between align-items-center mb-4")) {
      div {
        h1(.class("fw-bold mb-2")) {
          language == .ja ? "スカラシップ申請一覧" : "Scholarship Applications"
        }
        p(.class("lead text-muted mb-0")) {
          language == .ja
            ? "すべてのスカラシップ申請を管理します。"
            : "Manage all scholarship applications."
        }
      }
      div(.class("d-flex gap-2")) {
        a(
          .class("btn btn-outline-secondary"),
          .href(language.path(for: "/organizer/scholarships/budget"))
        ) {
          language == .ja ? "予算管理" : "Budget Management"
        }
        a(
          .class("btn btn-success"),
          .href(language.path(for: "/organizer/scholarships/export"))
        ) {
          language == .ja ? "CSV出力" : "Export CSV"
        }
      }
    }
  }

  // MARK: - Budget Summary

  private var budgetSummaryCard: some HTML {
    div(.class("row mb-4")) {
      div(.class("col-md-4")) {
        div(.class("card bg-primary text-white")) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) {
              if let totalBudget {
                HTMLText("\(formatYen(totalBudget))")
                language == .ja ? "円" : " yen"
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
      div(.class("col-md-4")) {
        div(.class("card bg-success text-white")) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) {
              HTMLText("\(formatYen(approvedTotal))")
              language == .ja ? "円" : " yen"
            }
            p(.class("card-text mb-0")) {
              language == .ja ? "承認済み合計" : "Approved Total"
            }
          }
        }
      }
      div(.class("col-md-4")) {
        div(.class("card bg-info text-white")) {
          div(.class("card-body")) {
            h3(.class("card-title mb-0")) {
              if let remainingBudget {
                HTMLText("\(formatYen(remainingBudget))")
                language == .ja ? "円" : " yen"
              } else {
                "-"
              }
            }
            p(.class("card-text mb-0")) {
              language == .ja ? "残り予算" : "Remaining Budget"
            }
          }
        }
      }
    }
  }

  // MARK: - Applications Table

  @HTMLBuilder
  private var applicationsTable: some HTML {
    if applications.isEmpty {
      div(.class("card")) {
        div(.class("card-body text-center p-5")) {
          p(.class("text-muted mb-0")) {
            language == .ja ? "まだ申請はありません。" : "No applications submitted yet."
          }
        }
      }
    } else {
      div(.class("card")) {
        div(.class("table-responsive")) {
          table(.class("table table-hover mb-0")) {
            thead(.class("table-light")) {
              tr {
                th(.style("width: 5%")) { "#" }
                th(.style("width: 18%")) { language == .ja ? "氏名" : "Name" }
                th(.style("width: 20%")) { language == .ja ? "学校" : "School" }
                th(.style("width: 15%")) { language == .ja ? "サポートタイプ" : "Support Type" }
                th(.style("width: 12%")) { language == .ja ? "希望額" : "Amount Requested" }
                th(.style("width: 10%")) { language == .ja ? "ステータス" : "Status" }
                th(.style("width: 12%")) { language == .ja ? "申請日" : "Date" }
                th(.style("width: 8%")) { language == .ja ? "操作" : "Actions" }
              }
            }
            tbody {
              for (index, app) in applications.enumerated() {
                tr {
                  td(.class("align-middle")) { HTMLText("\(index + 1)") }
                  td(.class("align-middle")) {
                    a(
                      .href(language.path(for: "/organizer/scholarships/\(app.id)")),
                      .class("text-decoration-none fw-semibold")
                    ) {
                      HTMLText(app.name)
                    }
                  }
                  td(.class("align-middle")) {
                    small { HTMLText(app.schoolAndFaculty) }
                  }
                  td(.class("align-middle")) {
                    HTMLText(
                      language == .ja
                        ? app.supportType.displayNameJa
                        : app.supportType.displayName
                    )
                  }
                  td(.class("align-middle")) {
                    if let desired = app.desiredSupportAmount {
                      HTMLText("\(formatYen(desired))")
                      language == .ja ? "円" : " yen"
                    } else {
                      "-"
                    }
                  }
                  td(.class("align-middle")) {
                    span(.class("badge \(app.status.badgeClass)")) {
                      HTMLText(
                        language == .ja ? app.status.displayNameJa : app.status.displayName
                      )
                    }
                  }
                  td(.class("align-middle")) {
                    if let createdAt = app.createdAt {
                      small(.class("text-muted")) {
                        HTMLText(formatDateShort(createdAt))
                      }
                    }
                  }
                  td(.class("align-middle")) {
                    a(
                      .href(language.path(for: "/organizer/scholarships/\(app.id)")),
                      .class("btn btn-sm btn-outline-primary")
                    ) {
                      language == .ja ? "詳細" : "View"
                    }
                  }
                }
              }
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

  private func formatDateShort(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }
}
