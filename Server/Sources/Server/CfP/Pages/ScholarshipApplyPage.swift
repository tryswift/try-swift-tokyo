import Elementary
import Foundation
import SharedModels

struct ScholarshipApplyPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let csrfToken: String
  let openConference: ConferencePublicInfo?
  let remainingBudget: Int?
  let success: Bool
  let errorMessage: String?
  let isEducationalEmail: Bool?

  var body: some HTML {
    div(.class("container py-5")) {
      pageHeader
      mainContent
    }
    pageScripts
  }

  // MARK: - Page Header

  private var pageHeader: some HTML {
    div {
      h1(.class("fw-bold mb-2")) {
        language == .ja ? "学生スカラシップ申請" : "Student Scholarship Application"
      }
      p(.class("lead text-muted mb-4")) {
        language == .ja
          ? "以下のフォームに必要事項を入力してください。"
          : "Please fill in the form below with the required information."
      }
    }
  }

  // MARK: - Main Content

  @HTMLBuilder
  private var mainContent: some HTML {
    if openConference == nil {
      noConferenceCard
    } else if user != nil {
      if success {
        successCard
      } else {
        applicationFormCard
      }
    } else {
      loginPromptCard
    }
  }

  // MARK: - State Cards

  private var noConferenceCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "現在、スカラシップの募集は行っていません" : "Scholarship Applications Not Open"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "次回のカンファレンスをお待ちください。"
            : "Please check back later for the next conference."
        }
        a(.class("btn btn-outline-primary"), .href(language.path(for: "/scholarship"))) {
          language == .ja ? "スカラシップ情報に戻る" : "Back to Scholarship Info"
        }
      }
    }
  }

  private var successCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "申請が送信されました！" : "Application Submitted!"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "スカラシップの申請が正常に送信されました。結果をお待ちください。"
            : "Your scholarship application has been submitted successfully. We will review it and get back to you."
        }
        div(.class("d-flex gap-2 justify-content-center")) {
          a(.class("btn btn-primary"), .href(language.path(for: "/scholarship/my-application"))) {
            language == .ja ? "申請内容を確認する" : "View My Application"
          }
          a(.class("btn btn-outline-primary"), .href(language.path(for: "/scholarship"))) {
            language == .ja ? "スカラシップ情報に戻る" : "Back to Scholarship Info"
          }
        }
      }
    }
  }

  private var loginPromptCard: some HTML {
    div(.class("card")) {
      div(.class("card-body text-center p-5")) {
        h3(.class("fw-bold mb-2")) {
          language == .ja ? "ログインが必要です" : "Sign In Required"
        }
        p(.class("text-muted mb-4")) {
          language == .ja
            ? "スカラシップに申請するにはGitHubアカウントでログインしてください。"
            : "Please sign in with your GitHub account to apply for a scholarship."
        }
        a(
          .class("btn btn-dark"),
          .href("/api/v1/auth/github?returnTo=\(language.path(for: "/scholarship/apply"))")
        ) {
          language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
        }
      }
    }
  }

  // MARK: - Application Form Card

  private var applicationFormCard: some HTML {
    div(.class("card")) {
      div(.class("card-body p-4")) {
        errorAlert
        budgetAlert
        applicationForm
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
  private var budgetAlert: some HTML {
    if let remainingBudget {
      div(.class("alert alert-info mb-4")) {
        language == .ja
          ? "現在の残り予算: \(formatYen(remainingBudget))円"
          : "Current remaining budget: \(formatYen(remainingBudget)) yen"
      }
    }
  }

  // MARK: - The Form

  private var applicationForm: some HTML {
    form(.method(.post), .action(language.path(for: "/scholarship/apply"))) {
      input(.type(.hidden), .name("_csrf"), .value(csrfToken))
      section1PersonalInfo
      section2Background
      section3Purpose
      section4TicketInfo
      section5TravelDetails
      section6AccommodationDetails
      section7Agreements
      submitButton
    }
  }

  // MARK: - Section 1: Personal Information

  private var section1PersonalInfo: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "1. 個人情報" : "1. Personal Information"
        }
      }
      div(.class("card-body")) {
        // Email
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("email")) {
            language == .ja ? "メールアドレス *" : "Email *"
          }
          input(
            .type(.email),
            .class("form-control"),
            .name("email"),
            .id("email"),
            .required,
            .value(user?.email ?? ""),
            .placeholder("your@university.ac.jp"),
            .custom(name: "oninput", value: "checkEmailDomain(this.value)")
          )
          HTMLRaw(
            """
            <div id="emailDomainWarning" class="form-text text-warning" style="display: none;">
            """)
          HTMLText(
            language == .ja
              ? "教育機関のメールアドレス（.ac.jp, .edu 等）の使用を推奨します。"
              : "We recommend using an educational email address (.ac.jp, .edu, etc.)."
          )
          HTMLRaw("</div>")
          div(.class("form-text")) {
            language == .ja
              ? "教育機関のメールアドレスを推奨します。"
              : "Educational institution email addresses are preferred."
          }
        }

        // Name
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("name")) {
            language == .ja ? "氏名 *" : "Name *"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("name"),
            .id("name"),
            .required,
            .value(user?.displayName ?? ""),
            .placeholder(language == .ja ? "山田 太郎" : "Your full name")
          )
        }

        // School and Faculty
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("school_and_faculty")) {
            language == .ja ? "学校名・学部 *" : "School & Faculty *"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("school_and_faculty"),
            .id("school_and_faculty"),
            .required,
            .placeholder("Swift\u{5927}\u{5b66} \u{5de5}\u{5b66}\u{90e8}")
          )
        }

        // Current Year
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("current_year")) {
            language == .ja ? "学年 *" : "Current Year *"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("current_year"),
            .id("current_year"),
            .required,
            .placeholder(
              language == .ja
                ? "学部3年、修士1年"
                : "e.g. 3rd year undergraduate, 1st year master's"
            )
          )
        }
      }
    }
  }

  // MARK: - Section 2: Background

  private var section2Background: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "2. バックグラウンド" : "2. Background"
        }
      }
      div(.class("card-body")) {
        // Portfolio
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("portfolio")) {
            language == .ja ? "ポートフォリオ（任意）" : "Portfolio (Optional)"
          }
          textarea(
            .class("form-control"),
            .name("portfolio"),
            .id("portfolio"),
            .custom(name: "rows", value: "3"),
            .placeholder(
              language == .ja
                ? "ポートフォリオサイト、作品、プロジェクトなど"
                : "Portfolio site, projects, works, etc."
            )
          ) {}
        }

        // GitHub Account
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("github_account")) {
            language == .ja ? "GitHubアカウント（任意）" : "GitHub Account (Optional)"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("github_account"),
            .id("github_account"),
            .value(user?.username ?? ""),
            .placeholder("username")
          )
        }

        // Language Preference
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) {
            language == .ja ? "希望する言語 *" : "Language Preference *"
          }
          div {
            div(.class("form-check form-check-inline")) {
              input(
                .type(.radio),
                .class("form-check-input"),
                .name("language_preference"),
                .id("lang_ja"),
                .value("ja"),
                .required
              )
              label(.class("form-check-label"), .for("lang_ja")) {
                language == .ja ? "日本語" : "Japanese"
              }
            }
            div(.class("form-check form-check-inline")) {
              input(
                .type(.radio),
                .class("form-check-input"),
                .name("language_preference"),
                .id("lang_en"),
                .value("en")
              )
              label(.class("form-check-label"), .for("lang_en")) {
                language == .ja ? "英語" : "English"
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Section 3: Purpose

  private var section3Purpose: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "3. 参加目的" : "3. Purpose"
        }
      }
      div(.class("card-body")) {
        p(.class("text-muted mb-3")) {
          language == .ja
            ? "try! Swift Tokyo に参加したい理由を選択してください（複数選択可）。"
            : "Select your reasons for attending try! Swift Tokyo (multiple selections allowed)."
        }
        purposeCheckbox(
          purpose: .learnSwift,
          id: "purpose_learn_swift"
        )
        purposeCheckbox(
          purpose: .schoolCourses,
          id: "purpose_school_courses"
        )
        purposeCheckbox(
          purpose: .learnFromOtherLanguages,
          id: "purpose_learn_from_other_languages"
        )
        purposeCheckbox(
          purpose: .beginnerOpportunity,
          id: "purpose_beginner_opportunity"
        )
        purposeCheckbox(
          purpose: .networking,
          id: "purpose_networking"
        )
      }
    }
  }

  private func purposeCheckbox(purpose: ScholarshipPurpose, id: String) -> some HTML {
    div(.class("form-check mb-2")) {
      input(
        .type(.checkbox),
        .class("form-check-input"),
        .name("purposes[]"),
        .id(id),
        .value(purpose.rawValue)
      )
      label(.class("form-check-label"), .for(id)) {
        HTMLText(language == .ja ? purpose.displayNameJa : purpose.displayName)
      }
    }
  }

  // MARK: - Section 4: Ticket Information

  private var section4TicketInfo: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "4. チケット情報" : "4. Ticket Information"
        }
      }
      div(.class("card-body")) {
        // Existing Ticket Info
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("existing_ticket_info")) {
            language == .ja ? "既にチケットをお持ちの場合（任意）" : "Existing Ticket Info (Optional)"
          }
          textarea(
            .class("form-control"),
            .name("existing_ticket_info"),
            .id("existing_ticket_info"),
            .custom(name: "rows", value: "2"),
            .placeholder(
              language == .ja
                ? "既にチケットを購入済みの場合はその情報を記入してください"
                : "If you already have a ticket, please provide details"
            )
          ) {}
        }

        // Support Type
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) {
            language == .ja ? "希望するサポート *" : "Support Type *"
          }
          div {
            for supportType in ScholarshipSupportType.allCases {
              div(.class("form-check")) {
                input(
                  .type(.radio),
                  .class("form-check-input"),
                  .name("support_type"),
                  .id("support_\(supportType.rawValue)"),
                  .value(supportType.rawValue),
                  .required,
                  .custom(name: "onchange", value: "toggleTravelSections(this.value)")
                )
                label(.class("form-check-label"), .for("support_\(supportType.rawValue)")) {
                  HTMLText(language == .ja ? supportType.displayNameJa : supportType.displayName)
                }
              }
            }
          }
        }
      }
    }
  }

  // MARK: - Section 5: Travel Details

  @HTMLBuilder
  private var section5TravelDetails: some HTML {
    HTMLRaw("""
      <div id="travelSection" style="display: none;">
      """)
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "5. 交通情報" : "5. Travel Details"
        }
      }
      div(.class("card-body")) {
        // Origin City
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("origin_city")) {
            language == .ja ? "出発地 *" : "Origin City *"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("origin_city"),
            .id("origin_city"),
            .custom(name: "list", value: "cityList"),
            .placeholder(language == .ja ? "都市名を入力" : "Enter city name")
          )
          HTMLRaw(TravelCostCalculator.datalistHTML)
        }

        // Transportation Methods
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) {
            language == .ja ? "交通手段（複数選択可） *" : "Transportation Methods (multiple) *"
          }
          div {
            for method in TransportMethod.allCases {
              div(.class("form-check form-check-inline")) {
                input(
                  .type(.checkbox),
                  .class("form-check-input"),
                  .name("transportation_methods"),
                  .id("transport_\(method.rawValue)"),
                  .value(method.rawValue)
                )
                label(.class("form-check-label"), .for("transport_\(method.rawValue)")) {
                  HTMLText(language == .ja ? method.displayNameJa : method.displayName)
                }
              }
            }
          }
        }

        // Travel Cost Estimator
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) {
            language == .ja ? "交通費見積もりツール" : "Travel Cost Estimator"
          }
          div(.class("input-group")) {
            HTMLRaw(
              """
              <button type="button" class="btn btn-outline-info" onclick="estimateTravelCost()">
              """)
            HTMLText(language == .ja ? "交通費を見積もる" : "Estimate Travel Cost")
            HTMLRaw("</button>")
          }
          HTMLRaw(
            """
            <div id="travelCostResult" class="form-text mt-2"></div>
            """)
        }

        // Estimated Round Trip Cost
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("estimated_round_trip_cost")) {
            language == .ja ? "往復交通費の見積もり（円） *" : "Estimated Round Trip Cost (yen) *"
          }
          input(
            .type(.number),
            .class("form-control"),
            .name("estimated_round_trip_cost"),
            .id("estimated_round_trip_cost"),
            .custom(name: "min", value: "0"),
            .placeholder("0"),
            .custom(name: "oninput", value: "calculateTotal()")
          )
        }
      }
    }
    HTMLRaw("</div>")
  }

  // MARK: - Section 6: Accommodation Details

  @HTMLBuilder
  private var section6AccommodationDetails: some HTML {
    HTMLRaw("""
      <div id="accommodationSection" style="display: none;">
      """)
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "6. 宿泊情報" : "6. Accommodation Details"
        }
      }
      div(.class("card-body")) {
        // Accommodation Type
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) {
            language == .ja ? "宿泊タイプ *" : "Accommodation Type *"
          }
          div {
            for accomType in AccommodationType.allCases {
              div(.class("form-check")) {
                input(
                  .type(.radio),
                  .class("form-check-input"),
                  .name("accommodation_type"),
                  .id("accom_\(accomType.rawValue)"),
                  .value(accomType.rawValue)
                )
                label(.class("form-check-label"), .for("accom_\(accomType.rawValue)")) {
                  HTMLText(language == .ja ? accomType.displayNameJa : accomType.displayName)
                }
              }
            }
          }
        }

        // Reservation Status
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold")) {
            language == .ja ? "予約状況 *" : "Reservation Status *"
          }
          div {
            for resStatus in ReservationStatus.allCases {
              div(.class("form-check form-check-inline")) {
                input(
                  .type(.radio),
                  .class("form-check-input"),
                  .name("reservation_status"),
                  .id("res_\(resStatus.rawValue)"),
                  .value(resStatus.rawValue)
                )
                label(.class("form-check-label"), .for("res_\(resStatus.rawValue)")) {
                  HTMLText(language == .ja ? resStatus.displayNameJa : resStatus.displayName)
                }
              }
            }
          }
        }

        // Accommodation Name
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("accommodation_name")) {
            language == .ja ? "宿泊先名（任意）" : "Accommodation Name (Optional)"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("accommodation_name"),
            .id("accommodation_name"),
            .placeholder(language == .ja ? "ホテル名など" : "Hotel name, etc.")
          )
        }

        // Accommodation Address
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("accommodation_address")) {
            language == .ja ? "宿泊先住所（任意）" : "Accommodation Address (Optional)"
          }
          input(
            .type(.text),
            .class("form-control"),
            .name("accommodation_address"),
            .id("accommodation_address"),
            .placeholder(language == .ja ? "住所" : "Address")
          )
        }

        // Check-in / Check-out Dates
        div(.class("row")) {
          div(.class("col-md-6 mb-3")) {
            label(.class("form-label fw-semibold"), .for("check_in_date")) {
              language == .ja ? "チェックイン日" : "Check-in Date"
            }
            input(
              .type(.date),
              .class("form-control"),
              .name("check_in_date"),
              .id("check_in_date")
            )
          }
          div(.class("col-md-6 mb-3")) {
            label(.class("form-label fw-semibold"), .for("check_out_date")) {
              language == .ja ? "チェックアウト日" : "Check-out Date"
            }
            input(
              .type(.date),
              .class("form-control"),
              .name("check_out_date"),
              .id("check_out_date")
            )
          }
        }

        // Estimated Accommodation Cost
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("estimated_accommodation_cost")) {
            language == .ja ? "宿泊費の見積もり（円） *" : "Estimated Accommodation Cost (yen) *"
          }
          input(
            .type(.number),
            .class("form-control"),
            .name("estimated_accommodation_cost"),
            .id("estimated_accommodation_cost"),
            .custom(name: "min", value: "0"),
            .placeholder("0"),
            .custom(name: "oninput", value: "calculateTotal()")
          )
        }

        // Total Estimated Cost (read-only, auto-calculated)
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("total_estimated_cost")) {
            language == .ja ? "合計見積もり費用（円）" : "Total Estimated Cost (yen)"
          }
          input(
            .type(.number),
            .class("form-control"),
            .name("total_estimated_cost"),
            .id("total_estimated_cost"),
            .custom(name: "readonly", value: "true")
          )
          div(.class("form-text")) {
            language == .ja
              ? "交通費と宿泊費の合計が自動計算されます。"
              : "Auto-calculated from travel and accommodation costs."
          }
        }

        // Desired Support Amount
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("desired_support_amount")) {
            language == .ja ? "希望支援額（円） *" : "Desired Support Amount (yen) *"
          }
          input(
            .type(.number),
            .class("form-control"),
            .name("desired_support_amount"),
            .id("desired_support_amount"),
            .custom(name: "min", value: "0"),
            .placeholder("0")
          )
        }

        // Self Payment Info
        div(.class("mb-3")) {
          label(.class("form-label fw-semibold"), .for("self_payment_info")) {
            language == .ja ? "自己負担について（任意）" : "Self Payment Info (Optional)"
          }
          textarea(
            .class("form-control"),
            .name("self_payment_info"),
            .id("self_payment_info"),
            .custom(name: "rows", value: "2"),
            .placeholder(
              language == .ja
                ? "自己負担可能な金額や状況について"
                : "Information about how much you can self-fund"
            )
          ) {}
        }
      }
    }
    HTMLRaw("</div>")
  }

  // MARK: - Section 7: Agreements

  private var section7Agreements: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "7. 同意事項" : "7. Agreements"
        }
      }
      div(.class("card-body")) {
        div(.class("form-check mb-3")) {
          input(
            .type(.checkbox),
            .class("form-check-input"),
            .name("agreed_travel_regulations"),
            .id("agreed_travel_regulations"),
            .value("true"),
            .required
          )
          label(.class("form-check-label"), .for("agreed_travel_regulations")) {
            language == .ja
              ? "旅費規程に同意します *"
              : "I agree to the travel regulations *"
          }
        }

        div(.class("form-check mb-3")) {
          input(
            .type(.checkbox),
            .class("form-check-input"),
            .name("agreed_application_confirmation"),
            .id("agreed_application_confirmation"),
            .value("true"),
            .required
          )
          label(.class("form-check-label"), .for("agreed_application_confirmation")) {
            language == .ja
              ? "申請内容に虚偽がないことを確認します *"
              : "I confirm that all information provided is accurate *"
          }
        }

        div(.class("form-check mb-3")) {
          input(
            .type(.checkbox),
            .class("form-check-input"),
            .name("agreed_privacy"),
            .id("agreed_privacy"),
            .value("true"),
            .required
          )
          label(.class("form-check-label"), .for("agreed_privacy")) {
            language == .ja
              ? "プライバシーポリシーに同意します *"
              : "I agree to the Privacy Policy *"
          }
        }

        div(.class("form-check mb-3")) {
          input(
            .type(.checkbox),
            .class("form-check-input"),
            .name("agreed_code_of_conduct"),
            .id("agreed_code_of_conduct"),
            .value("true"),
            .required
          )
          label(.class("form-check-label"), .for("agreed_code_of_conduct")) {
            language == .ja
              ? "行動規範に同意します *"
              : "I agree to the Code of Conduct *"
          }
        }

        // Additional Comments
        div(.class("mb-3 mt-4")) {
          label(.class("form-label fw-semibold"), .for("additional_comments")) {
            language == .ja ? "その他コメント（任意）" : "Additional Comments (Optional)"
          }
          textarea(
            .class("form-control"),
            .name("additional_comments"),
            .id("additional_comments"),
            .custom(name: "rows", value: "3"),
            .placeholder(
              language == .ja
                ? "その他、伝えたいことがあればご記入ください"
                : "Any additional information you'd like to share"
            )
          ) {}
        }
      }
    }
  }

  // MARK: - Submit Button

  private var submitButton: some HTML {
    div(.class("d-grid")) {
      button(.type(.submit), .class("btn btn-primary btn-lg")) {
        language == .ja ? "申請を送信する" : "Submit Application"
      }
    }
  }

  // MARK: - JavaScript

  private var pageScripts: some HTML {
    HTMLRaw(
      """
      <script>
        // 1. Toggle travel/accommodation sections based on support_type
        function toggleTravelSections(value) {
          var travelSection = document.getElementById('travelSection');
          var accommodationSection = document.getElementById('accommodationSection');
          if (value === 'ticket_and_travel') {
            travelSection.style.display = 'block';
            accommodationSection.style.display = 'block';
          } else {
            travelSection.style.display = 'none';
            accommodationSection.style.display = 'none';
          }
        }

        // 2. Auto-calculate total_estimated_cost
        function calculateTotal() {
          var travel = parseInt(document.getElementById('estimated_round_trip_cost').value) || 0;
          var accommodation = parseInt(document.getElementById('estimated_accommodation_cost').value) || 0;
          document.getElementById('total_estimated_cost').value = travel + accommodation;
        }

        // 3. Email domain validation warning
        function checkEmailDomain(email) {
          var warning = document.getElementById('emailDomainWarning');
          if (!email || email.indexOf('@') === -1) {
            warning.style.display = 'none';
            return;
          }
          var domain = email.split('@')[1] || '';
          var isEdu = domain.endsWith('.ac.jp') || domain.endsWith('.edu') ||
                      domain.endsWith('.edu.') || domain.indexOf('.ac.') !== -1 ||
                      domain.indexOf('.edu.') !== -1;
          warning.style.display = isEdu ? 'none' : 'block';
        }

        // 4. Travel cost estimator fetch
        async function estimateTravelCost() {
          var city = document.getElementById('origin_city').value.trim();
          var resultDiv = document.getElementById('travelCostResult');
          if (!city) {
            resultDiv.innerHTML = '<span class="text-danger">Please enter a city name.</span>';
            return;
          }
          resultDiv.innerHTML = '<span class="text-muted">Estimating...</span>';
          try {
            var response = await fetch('/scholarship/api/travel-cost?city=' + encodeURIComponent(city));
            if (response.ok) {
              var data = await response.json();
              var html = '<strong>' + (data.city || city) + ' (' + (data.cityJa || '') + ')</strong><br>';
              if (data.bulletTrain) html += 'Bullet Train: ' + data.bulletTrain.toLocaleString() + ' yen<br>';
              if (data.airplane) html += 'Airplane: ' + data.airplane.toLocaleString() + ' yen<br>';
              if (data.bus) html += 'Bus: ' + data.bus.toLocaleString() + ' yen<br>';
              if (data.train) html += 'Train: ' + data.train.toLocaleString() + ' yen<br>';
              resultDiv.innerHTML = html;
            } else {
              resultDiv.innerHTML = '<span class="text-warning">City not found in database. Please enter the estimated cost manually.</span>';
            }
          } catch (e) {
            resultDiv.innerHTML = '<span class="text-danger">Error fetching estimate. Please enter manually.</span>';
          }
        }

        // 5. Initialize on page load
        document.addEventListener('DOMContentLoaded', function() {
          var emailField = document.getElementById('email');
          if (emailField && emailField.value) {
            checkEmailDomain(emailField.value);
          }
        });
      </script>
      """)
  }

  // MARK: - Helpers

  private func formatYen(_ amount: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
  }
}
