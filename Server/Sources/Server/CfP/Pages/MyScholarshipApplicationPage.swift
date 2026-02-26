import Elementary
import Foundation
import SharedModels

struct MyScholarshipApplicationPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let application: ScholarshipApplicationDTO?
  let csrfToken: String

  var body: some HTML {
    div(.class("container py-5")) {
      pageHeader
      mainContent
    }
  }

  // MARK: - Page Header

  private var pageHeader: some HTML {
    div(.class("mb-4")) {
      h1(.class("fw-bold mb-2")) {
        language == .ja ? "マイ スカラシップ申請" : "My Scholarship Application"
      }
      p(.class("lead text-muted")) {
        language == .ja
          ? "あなたのスカラシップ申請の状況を確認できます。"
          : "View the status of your scholarship application."
      }
    }
  }

  // MARK: - Main Content

  @HTMLBuilder
  private var mainContent: some HTML {
    if let application {
      applicationDetail(application)
    } else {
      noApplicationCard
    }
  }

  // MARK: - No Application

  private var noApplicationCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "まだ申請していません" : "You haven't applied yet"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "スカラシップにまだ申請していません。下のボタンから申請できます。"
            : "You have not yet submitted a scholarship application. Click below to apply."
        }
        a(.class("btn btn-primary btn-lg"), .href(language.path(for: "/scholarship/apply"))) {
          language == .ja ? "申請する" : "Apply Now"
        }
      }
    }
  }

  // MARK: - Application Detail

  @HTMLBuilder
  private func applicationDetail(_ app: ScholarshipApplicationDTO) -> some HTML {
    // Status Badge
    div(.class("mb-4")) {
      span(.class("badge \(app.status.badgeClass) fs-5")) {
        HTMLText(language == .ja ? app.status.displayNameJa : app.status.displayName)
      }
      if let approvedAmount = app.approvedAmount {
        span(.class("badge bg-info fs-6 ms-2")) {
          language == .ja
            ? "承認額: \(formatYen(approvedAmount))円"
            : "Approved: \(formatYen(approvedAmount)) yen"
        }
      }
    }

    // Personal Information Card
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "個人情報" : "Personal Information" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-4")) { language == .ja ? "メールアドレス" : "Email" }
          dd(.class("col-sm-8")) { HTMLText(app.email) }

          dt(.class("col-sm-4")) { language == .ja ? "氏名" : "Name" }
          dd(.class("col-sm-8")) { HTMLText(app.name) }

          dt(.class("col-sm-4")) { language == .ja ? "学校名・学部" : "School & Faculty" }
          dd(.class("col-sm-8")) { HTMLText(app.schoolAndFaculty) }

          dt(.class("col-sm-4")) { language == .ja ? "学年" : "Current Year" }
          dd(.class("col-sm-8")) { HTMLText(app.currentYear) }
        }
      }
    }

    // Background Card
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "バックグラウンド" : "Background" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          if let portfolio = app.portfolio, !portfolio.isEmpty {
            dt(.class("col-sm-4")) { language == .ja ? "ポートフォリオ" : "Portfolio" }
            dd(.class("col-sm-8"), .style("white-space: pre-wrap;")) { HTMLText(portfolio) }
          }

          if let github = app.githubAccount, !github.isEmpty {
            dt(.class("col-sm-4")) { "GitHub" }
            dd(.class("col-sm-8")) {
              a(.href("https://github.com/\(github)"), .target(.blank)) {
                HTMLText(github)
              }
            }
          }

          dt(.class("col-sm-4")) { language == .ja ? "希望言語" : "Language Preference" }
          dd(.class("col-sm-8")) { HTMLText(app.languagePreference) }
        }
      }
    }

    // Purpose Card
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "参加目的" : "Purpose" }
      }
      div(.class("card-body")) {
        ul(.class("mb-0")) {
          for purpose in app.purposes {
            li {
              if let p = ScholarshipPurpose(rawValue: purpose) {
                HTMLText(language == .ja ? p.displayNameJa : p.displayName)
              } else {
                HTMLText(purpose)
              }
            }
          }
        }
      }
    }

    // Ticket & Support Card
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "チケット・サポート" : "Ticket & Support" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          if let ticketInfo = app.existingTicketInfo, !ticketInfo.isEmpty {
            dt(.class("col-sm-4")) { language == .ja ? "既存チケット" : "Existing Ticket" }
            dd(.class("col-sm-8"), .style("white-space: pre-wrap;")) { HTMLText(ticketInfo) }
          }

          dt(.class("col-sm-4")) { language == .ja ? "サポートタイプ" : "Support Type" }
          dd(.class("col-sm-8")) {
            HTMLText(language == .ja ? app.supportType.displayNameJa : app.supportType.displayName)
          }
        }
      }
    }

    // Travel Details Card (if applicable)
    if let travel = app.travelDetails {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "交通情報" : "Travel Details" }
        }
        div(.class("card-body")) {
          dl(.class("row mb-0")) {
            dt(.class("col-sm-4")) { language == .ja ? "出発地" : "Origin City" }
            dd(.class("col-sm-8")) { HTMLText(travel.originCity) }

            dt(.class("col-sm-4")) { language == .ja ? "交通手段" : "Transportation" }
            dd(.class("col-sm-8")) {
              HTMLText(
                travel.transportationMethods.map {
                  language == .ja ? $0.displayNameJa : $0.displayName
                }.joined(separator: ", ")
              )
            }

            dt(.class("col-sm-4")) { language == .ja ? "往復交通費" : "Round Trip Cost" }
            dd(.class("col-sm-8")) {
              HTMLText("\(formatYen(travel.estimatedRoundTripCost))")
              language == .ja ? "円" : " yen"
            }
          }
        }
      }
    }

    // Accommodation Details Card (if applicable)
    if let accom = app.accommodationDetails {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "宿泊情報" : "Accommodation Details" }
        }
        div(.class("card-body")) {
          dl(.class("row mb-0")) {
            dt(.class("col-sm-4")) { language == .ja ? "宿泊タイプ" : "Type" }
            dd(.class("col-sm-8")) {
              HTMLText(
                language == .ja
                  ? accom.accommodationType.displayNameJa
                  : accom.accommodationType.displayName
              )
            }

            dt(.class("col-sm-4")) { language == .ja ? "予約状況" : "Reservation" }
            dd(.class("col-sm-8")) {
              HTMLText(
                language == .ja
                  ? accom.reservationStatus.displayNameJa
                  : accom.reservationStatus.displayName
              )
            }

            if let name = accom.accommodationName, !name.isEmpty {
              dt(.class("col-sm-4")) { language == .ja ? "宿泊先名" : "Name" }
              dd(.class("col-sm-8")) { HTMLText(name) }
            }

            if let address = accom.accommodationAddress, !address.isEmpty {
              dt(.class("col-sm-4")) { language == .ja ? "住所" : "Address" }
              dd(.class("col-sm-8")) { HTMLText(address) }
            }

            if let checkIn = accom.checkInDate, !checkIn.isEmpty {
              dt(.class("col-sm-4")) { language == .ja ? "チェックイン" : "Check-in" }
              dd(.class("col-sm-8")) { HTMLText(checkIn) }
            }

            if let checkOut = accom.checkOutDate, !checkOut.isEmpty {
              dt(.class("col-sm-4")) { language == .ja ? "チェックアウト" : "Check-out" }
              dd(.class("col-sm-8")) { HTMLText(checkOut) }
            }

            dt(.class("col-sm-4")) { language == .ja ? "宿泊費" : "Cost" }
            dd(.class("col-sm-8")) {
              HTMLText("\(formatYen(accom.estimatedCost))")
              language == .ja ? "円" : " yen"
            }
          }
        }
      }
    }

    // Financial Summary Card (if applicable)
    if app.totalEstimatedCost != nil || app.desiredSupportAmount != nil {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "費用サマリー" : "Financial Summary" }
        }
        div(.class("card-body")) {
          dl(.class("row mb-0")) {
            if let total = app.totalEstimatedCost {
              dt(.class("col-sm-4")) { language == .ja ? "合計見積もり" : "Total Estimated Cost" }
              dd(.class("col-sm-8")) {
                HTMLText("\(formatYen(total))")
                language == .ja ? "円" : " yen"
              }
            }

            if let desired = app.desiredSupportAmount {
              dt(.class("col-sm-4")) { language == .ja ? "希望支援額" : "Desired Support" }
              dd(.class("col-sm-8")) {
                HTMLText("\(formatYen(desired))")
                language == .ja ? "円" : " yen"
              }
            }

            if let selfPay = app.selfPaymentInfo, !selfPay.isEmpty {
              dt(.class("col-sm-4")) { language == .ja ? "自己負担" : "Self Payment" }
              dd(.class("col-sm-8"), .style("white-space: pre-wrap;")) { HTMLText(selfPay) }
            }
          }
        }
      }
    }

    // Additional Comments Card (if any)
    if let comments = app.additionalComments, !comments.isEmpty {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "追加コメント" : "Additional Comments" }
        }
        div(.class("card-body")) {
          p(.class("mb-0"), .style("white-space: pre-wrap;")) {
            HTMLText(comments)
          }
        }
      }
    }

    // Organizer Notes (if any, visible to applicant)
    if let notes = app.organizerNotes, !notes.isEmpty {
      div(.class("card mb-4 border-info")) {
        div(.class("card-header bg-info text-white")) {
          strong { language == .ja ? "主催者からのメモ" : "Organizer Notes" }
        }
        div(.class("card-body")) {
          p(.class("mb-0"), .style("white-space: pre-wrap;")) {
            HTMLText(notes)
          }
        }
      }
    }

    // Withdraw Button (only if submitted)
    if app.status == .submitted {
      div(.class("text-center mt-4")) {
        HTMLRaw(
          """
          <form method="post" action="\(language.path(for: "/scholarship/my-application/withdraw"))" onsubmit="return confirm('\(language == .ja ? "本当に申請を取り下げますか？" : "Are you sure you want to withdraw your application?")')">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <button type="submit" class="btn btn-outline-danger">
          """)
        HTMLText(language == .ja ? "申請を取り下げる" : "Withdraw Application")
        HTMLRaw(
          """
            </button>
          </form>
          """)
      }
    }

    // Metadata
    div(.class("card mt-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "メタデータ" : "Metadata" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-4")) { language == .ja ? "申請日" : "Submitted" }
          dd(.class("col-sm-8")) {
            if let createdAt = app.createdAt {
              HTMLText(formatDate(createdAt))
            } else {
              language == .ja ? "不明" : "Unknown"
            }
          }
          dt(.class("col-sm-4")) { language == .ja ? "最終更新" : "Last Updated" }
          dd(.class("col-sm-8")) {
            if let updatedAt = app.updatedAt {
              HTMLText(formatDate(updatedAt))
            } else {
              language == .ja ? "なし" : "Never"
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

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}
