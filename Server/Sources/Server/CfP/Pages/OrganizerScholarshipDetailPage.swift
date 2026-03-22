import Elementary
import Foundation
import SharedModels

struct OrganizerScholarshipDetailPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let application: ScholarshipApplicationDTO
  let csrfToken: String

  var body: some HTML {
    div(.class("container py-5")) {
      backButton
      headerSection
      personalInfoCard
      backgroundCard
      purposeCard
      ticketSupportCard
      travelCard
      accommodationCard
      financialCard
      additionalCard
      agreementsCard
      reviewSection
      metadataCard
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

  // MARK: - Header

  private var headerSection: some HTML {
    div(.class("d-flex justify-content-between align-items-start mb-4")) {
      div {
        div(.class("d-flex align-items-center gap-3 mb-2")) {
          h1(.class("fw-bold mb-0")) { HTMLText(application.name) }
          span(.class("badge \(application.status.badgeClass) fs-6")) {
            HTMLText(
              language == .ja
                ? application.status.displayNameJa
                : application.status.displayName
            )
          }
        }
        p(.class("text-muted mb-0")) {
          HTMLText(application.schoolAndFaculty)
          " - "
          HTMLText(application.currentYear)
        }
      }
      statusActionButtons
    }
  }

  // MARK: - Status Action Buttons

  @HTMLBuilder
  private var statusActionButtons: some HTML {
    div(.class("d-flex gap-2")) {
      if application.status == .submitted {
        HTMLRaw(
          """
          <form method="post" action="\(language.path(for: "/organizer/scholarships/\(application.id)/approve"))">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <button type="submit" class="btn btn-success">
          """)
        HTMLText(language == .ja ? "承認" : "Approve")
        HTMLRaw(
          """
            </button>
          </form>
          <form method="post" action="\(language.path(for: "/organizer/scholarships/\(application.id)/reject"))">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <button type="submit" class="btn btn-outline-danger">
          """)
        HTMLText(language == .ja ? "不採択" : "Reject")
        HTMLRaw(
          """
            </button>
          </form>
          """)
      }
      if application.status == .approved || application.status == .rejected {
        HTMLRaw(
          """
          <form method="post" action="\(language.path(for: "/organizer/scholarships/\(application.id)/revert"))">
            <input type="hidden" name="_csrf" value="\(csrfToken)">
            <button type="submit" class="btn btn-outline-secondary">
          """)
        HTMLText(language == .ja ? "申請中に戻す" : "Revert to Submitted")
        HTMLRaw(
          """
            </button>
          </form>
          """)
      }
    }
  }

  // MARK: - Personal Information

  private var personalInfoCard: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "個人情報" : "Personal Information" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-3")) { language == .ja ? "メールアドレス" : "Email" }
          dd(.class("col-sm-9")) { HTMLText(application.email) }

          dt(.class("col-sm-3")) { language == .ja ? "氏名" : "Name" }
          dd(.class("col-sm-9")) { HTMLText(application.name) }

          dt(.class("col-sm-3")) { language == .ja ? "学校名・学部" : "School & Faculty" }
          dd(.class("col-sm-9")) { HTMLText(application.schoolAndFaculty) }

          dt(.class("col-sm-3")) { language == .ja ? "学年" : "Current Year" }
          dd(.class("col-sm-9")) { HTMLText(application.currentYear) }

          dt(.class("col-sm-3")) { "GitHub" }
          dd(.class("col-sm-9")) {
            if let github = application.githubAccount, !github.isEmpty {
              a(.href("https://github.com/\(github)"), .target(.blank)) {
                HTMLText(github)
              }
            } else {
              span(.class("text-muted")) { "-" }
            }
          }

          dt(.class("col-sm-3")) { language == .ja ? "申請者ID" : "Applicant Username" }
          dd(.class("col-sm-9")) {
            a(.href("https://github.com/\(application.applicantUsername)"), .target(.blank)) {
              HTMLText(application.applicantUsername)
            }
          }
        }
      }
    }
  }

  // MARK: - Background

  @HTMLBuilder
  private var backgroundCard: some HTML {
    if let portfolio = application.portfolio, !portfolio.isEmpty {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "ポートフォリオ" : "Portfolio" }
        }
        div(.class("card-body")) {
          p(.class("mb-0"), .style("white-space: pre-wrap;")) { HTMLText(portfolio) }
        }
      }
    }
  }

  // MARK: - Purpose

  private var purposeCard: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "参加目的" : "Purpose" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-3")) { language == .ja ? "希望言語" : "Language Preference" }
          dd(.class("col-sm-9")) { HTMLText(application.languagePreference) }

          dt(.class("col-sm-3")) { language == .ja ? "目的" : "Purposes" }
          dd(.class("col-sm-9")) {
            ul(.class("mb-0")) {
              for purpose in application.purposes {
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
      }
    }
  }

  // MARK: - Ticket & Support

  private var ticketSupportCard: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "チケット・サポート" : "Ticket & Support" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-3")) { language == .ja ? "サポートタイプ" : "Support Type" }
          dd(.class("col-sm-9")) {
            HTMLText(
              language == .ja
                ? application.supportType.displayNameJa
                : application.supportType.displayName
            )
          }

          if let ticketInfo = application.existingTicketInfo, !ticketInfo.isEmpty {
            dt(.class("col-sm-3")) { language == .ja ? "既存チケット" : "Existing Ticket" }
            dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) { HTMLText(ticketInfo) }
          }
        }
      }
    }
  }

  // MARK: - Travel Details

  @HTMLBuilder
  private var travelCard: some HTML {
    if let travel = application.travelDetails {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "交通情報" : "Travel Details" }
        }
        div(.class("card-body")) {
          dl(.class("row mb-0")) {
            dt(.class("col-sm-3")) { language == .ja ? "出発地" : "Origin City" }
            dd(.class("col-sm-9")) { HTMLText(travel.originCity) }

            dt(.class("col-sm-3")) { language == .ja ? "交通手段" : "Transportation" }
            dd(.class("col-sm-9")) {
              HTMLText(
                travel.transportationMethods.map {
                  language == .ja ? $0.displayNameJa : $0.displayName
                }.joined(separator: ", ")
              )
            }

            dt(.class("col-sm-3")) { language == .ja ? "往復交通費" : "Round Trip Cost" }
            dd(.class("col-sm-9")) {
              HTMLText("\(formatYen(travel.estimatedRoundTripCost))")
              language == .ja ? "円" : " yen"
            }
          }
        }
      }
    }
  }

  // MARK: - Accommodation Details

  @HTMLBuilder
  private var accommodationCard: some HTML {
    if let accom = application.accommodationDetails {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "宿泊情報" : "Accommodation Details" }
        }
        div(.class("card-body")) {
          dl(.class("row mb-0")) {
            dt(.class("col-sm-3")) { language == .ja ? "宿泊タイプ" : "Type" }
            dd(.class("col-sm-9")) {
              HTMLText(
                language == .ja
                  ? accom.accommodationType.displayNameJa
                  : accom.accommodationType.displayName
              )
            }

            dt(.class("col-sm-3")) { language == .ja ? "予約状況" : "Reservation" }
            dd(.class("col-sm-9")) {
              HTMLText(
                language == .ja
                  ? accom.reservationStatus.displayNameJa
                  : accom.reservationStatus.displayName
              )
            }

            if let name = accom.accommodationName, !name.isEmpty {
              dt(.class("col-sm-3")) { language == .ja ? "宿泊先名" : "Name" }
              dd(.class("col-sm-9")) { HTMLText(name) }
            }

            if let address = accom.accommodationAddress, !address.isEmpty {
              dt(.class("col-sm-3")) { language == .ja ? "住所" : "Address" }
              dd(.class("col-sm-9")) { HTMLText(address) }
            }

            if let checkIn = accom.checkInDate, !checkIn.isEmpty {
              dt(.class("col-sm-3")) { language == .ja ? "チェックイン" : "Check-in" }
              dd(.class("col-sm-9")) { HTMLText(checkIn) }
            }

            if let checkOut = accom.checkOutDate, !checkOut.isEmpty {
              dt(.class("col-sm-3")) { language == .ja ? "チェックアウト" : "Check-out" }
              dd(.class("col-sm-9")) { HTMLText(checkOut) }
            }

            dt(.class("col-sm-3")) { language == .ja ? "宿泊費" : "Cost" }
            dd(.class("col-sm-9")) {
              HTMLText("\(formatYen(accom.estimatedCost))")
              language == .ja ? "円" : " yen"
            }
          }
        }
      }
    }
  }

  // MARK: - Financial Summary

  @HTMLBuilder
  private var financialCard: some HTML {
    if application.totalEstimatedCost != nil || application.desiredSupportAmount != nil {
      div(.class("card mb-4 border-warning")) {
        div(.class("card-header bg-warning text-dark")) {
          strong { language == .ja ? "費用サマリー" : "Financial Summary" }
        }
        div(.class("card-body")) {
          dl(.class("row mb-0")) {
            if let total = application.totalEstimatedCost {
              dt(.class("col-sm-3")) { language == .ja ? "合計見積もり" : "Total Estimated" }
              dd(.class("col-sm-9")) {
                HTMLText("\(formatYen(total))")
                language == .ja ? "円" : " yen"
              }
            }

            if let desired = application.desiredSupportAmount {
              dt(.class("col-sm-3")) { language == .ja ? "希望支援額" : "Desired Support" }
              dd(.class("col-sm-9")) {
                HTMLText("\(formatYen(desired))")
                language == .ja ? "円" : " yen"
              }
            }

            if let selfPay = application.selfPaymentInfo, !selfPay.isEmpty {
              dt(.class("col-sm-3")) { language == .ja ? "自己負担" : "Self Payment" }
              dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) { HTMLText(selfPay) }
            }

            if let approved = application.approvedAmount {
              dt(.class("col-sm-3")) { language == .ja ? "承認額" : "Approved Amount" }
              dd(.class("col-sm-9")) {
                strong {
                  HTMLText("\(formatYen(approved))")
                  language == .ja ? "円" : " yen"
                }
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Additional Comments

  @HTMLBuilder
  private var additionalCard: some HTML {
    if let comments = application.additionalComments, !comments.isEmpty {
      div(.class("card mb-4")) {
        div(.class("card-header")) {
          strong { language == .ja ? "追加コメント" : "Additional Comments" }
        }
        div(.class("card-body")) {
          p(.class("mb-0"), .style("white-space: pre-wrap;")) { HTMLText(comments) }
        }
      }
    }
  }

  // MARK: - Agreements

  private var agreementsCard: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong { language == .ja ? "同意事項" : "Agreements" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-6")) { language == .ja ? "旅費規程" : "Travel Regulations" }
          dd(.class("col-sm-6")) {
            agreementBadge(application.agreedTravelRegulations)
          }

          dt(.class("col-sm-6")) { language == .ja ? "申請内容確認" : "Application Confirmation" }
          dd(.class("col-sm-6")) {
            agreementBadge(application.agreedApplicationConfirmation)
          }

          dt(.class("col-sm-6")) { language == .ja ? "プライバシー" : "Privacy Policy" }
          dd(.class("col-sm-6")) {
            agreementBadge(application.agreedPrivacy)
          }

          dt(.class("col-sm-6")) { language == .ja ? "行動規範" : "Code of Conduct" }
          dd(.class("col-sm-6")) {
            agreementBadge(application.agreedCodeOfConduct)
          }
        }
      }
    }
  }

  private func agreementBadge(_ agreed: Bool) -> some HTML {
    span(.class(agreed ? "badge bg-success" : "badge bg-danger")) {
      agreed
        ? (language == .ja ? "同意済み" : "Agreed")
        : (language == .ja ? "未同意" : "Not Agreed")
    }
  }

  // MARK: - Review Section (Approve/Reject with amounts and notes)

  private var reviewSection: some HTML {
    div(.class("card mb-4 border-primary")) {
      div(.class("card-header bg-primary text-white")) {
        strong { language == .ja ? "レビュー" : "Review" }
      }
      div(.class("card-body")) {
        form(
          .method(.post),
          .action(language.path(for: "/organizer/scholarships/\(application.id)/approve"))
        ) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))

          // Approved Amount
          div(.class("mb-3")) {
            label(.class("form-label fw-semibold"), .for("approved_amount")) {
              language == .ja ? "承認額（円）" : "Approved Amount (yen)"
            }
            input(
              .type(.number),
              .class("form-control"),
              .name("approved_amount"),
              .id("approved_amount"),
              .custom(name: "min", value: "0"),
              .value(application.approvedAmount.map { "\($0)" } ?? "")
            )
          }

          // Organizer Notes
          div(.class("mb-3")) {
            label(.class("form-label fw-semibold"), .for("organizer_notes")) {
              language == .ja ? "主催者メモ" : "Organizer Notes"
            }
            textarea(
              .class("form-control"),
              .name("organizer_notes"),
              .id("organizer_notes"),
              .custom(name: "rows", value: "3"),
              .placeholder(
                language == .ja
                  ? "内部メモ（申請者にも表示されます）"
                  : "Internal notes (also visible to applicant)"
              )
            ) {
              HTMLText(application.organizerNotes ?? "")
            }
          }

          div(.class("d-grid")) {
            button(.type(.submit), .class("btn btn-primary")) {
              language == .ja ? "レビューを保存" : "Save Review"
            }
          }
        }
      }
    }
  }

  // MARK: - Metadata

  private var metadataCard: some HTML {
    div(.class("card")) {
      div(.class("card-header")) {
        strong { language == .ja ? "メタデータ" : "Metadata" }
      }
      div(.class("card-body")) {
        dl(.class("row mb-0")) {
          dt(.class("col-sm-3")) { language == .ja ? "申請ID" : "Application ID" }
          dd(.class("col-sm-9")) {
            code { HTMLText(application.id.uuidString) }
          }

          dt(.class("col-sm-3")) { language == .ja ? "カンファレンス" : "Conference" }
          dd(.class("col-sm-9")) { HTMLText(application.conferenceDisplayName) }

          dt(.class("col-sm-3")) { language == .ja ? "申請日" : "Submitted" }
          dd(.class("col-sm-9")) {
            if let createdAt = application.createdAt {
              HTMLText(formatDate(createdAt))
            } else {
              language == .ja ? "不明" : "Unknown"
            }
          }

          dt(.class("col-sm-3")) { language == .ja ? "最終更新" : "Last Updated" }
          dd(.class("col-sm-9")) {
            if let updatedAt = application.updatedAt {
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
