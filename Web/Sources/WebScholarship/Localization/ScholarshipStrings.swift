import SharedModels

/// Centralised EN/JA strings for the student.tryswift.jp portal.
///
/// Keys are grouped by page so localisation churn stays predictable; UI
/// rendering code calls `ScholarshipStrings.t(.someKey, locale)`.
public enum ScholarshipStringKey: String, CaseIterable, Sendable {
  // Navigation
  case navApply, navMyApplication, navLogin, navLogout, navOrganizer

  // Info page
  case infoTitle, infoSubtitle, infoApplyCTA, infoEligibilityTitle, infoIncludedTitle,
    infoBudgetTotal, infoBudgetApproved, infoBudgetRemaining, infoBudgetNotSet,
    infoNoOpenConference

  // Login flow
  case loginTitle, loginEmailLabel, loginSubmit, loginSentTitle, loginSentBody, loginInvalid

  // Apply form (sections + buttons)
  case applyTitle, applySection1, applySection2, applySection3, applySection4,
    applySection5, applySection6, applySection7, applySubmit, applySuccess
  case applyEmailLabel, applyNameLabel, applySchoolLabel, applyYearLabel,
    applyPortfolioLabel, applyGitHubLabel, applyLanguageLabel, applyLanguageJa,
    applyLanguageEn, applyPurposeLabel, applyTicketInfoLabel, applySupportTypeLabel,
    applyOriginCityLabel, applyTransportLabel, applyTripCostLabel,
    applyAccommodationLabel, applyReservationLabel, applyAccommodationNameLabel,
    applyAccommodationAddressLabel, applyCheckInLabel, applyCheckOutLabel,
    applyAccommodationCostLabel, applyTotalCostLabel, applyDesiredAmountLabel,
    applySelfPaymentLabel, applyAdditionalCommentsLabel
  case applyAgreeTravelRegs, applyAgreeApplicationConfirmation,
    applyAgreePrivacy, applyAgreeCodeOfConduct
  case applyEducationalEmailHint
  case applyEstimateButton

  // My application
  case myAppTitle, myAppNoApplication, myAppWithdraw, myAppWithdrawConfirm,
    myAppStatusLabel, myAppApprovedAmount

  // Organizer
  case orgListTitle, orgDetailTitle, orgBudgetTitle, orgApprove, orgReject,
    orgRevert, orgExportCSV, orgApprovedAmountLabel, orgNotesLabel, orgSaveBudget,
    orgTotalBudgetLabel, orgBudgetNotesLabel, orgConfirmDelete
}

public enum ScholarshipStrings {
  public static func t(_ key: ScholarshipStringKey, _ locale: ScholarshipPortalLocale) -> String {
    locale == .ja ? ja(key) : en(key)
  }

  private static func ja(_ key: ScholarshipStringKey) -> String {
    switch key {
    case .navApply: return "申請する"
    case .navMyApplication: return "自分の申請"
    case .navLogin: return "ログイン"
    case .navLogout: return "ログアウト"
    case .navOrganizer: return "オーガナイザー"
    case .infoTitle: return "学生スカラシップ"
    case .infoSubtitle:
      return "try! Swift Tokyo は学生エンジニアの参加を支援するためにスカラシップを提供しています。"
    case .infoApplyCTA: return "今すぐ申請する"
    case .infoEligibilityTitle: return "対象者"
    case .infoIncludedTitle: return "支援内容"
    case .infoBudgetTotal: return "総予算"
    case .infoBudgetApproved: return "承認済み"
    case .infoBudgetRemaining: return "残り予算"
    case .infoBudgetNotSet: return "予算は未設定です"
    case .infoNoOpenConference: return "現在受付中のカンファレンスはありません"
    case .loginTitle: return "ログイン"
    case .loginEmailLabel: return "メールアドレス"
    case .loginSubmit: return "ログインリンクを送る"
    case .loginSentTitle: return "メールを送信しました"
    case .loginSentBody: return "登録メールアドレスにログインリンクを送りました。30 分以内にリンクを開いてください。"
    case .loginInvalid: return "ログインリンクが無効か期限切れです。再度メールを送ってください。"
    case .applyTitle: return "スカラシップ申請"
    case .applySection1: return "1. 個人情報"
    case .applySection2: return "2. バックグラウンド"
    case .applySection3: return "3. 参加目的"
    case .applySection4: return "4. チケット情報"
    case .applySection5: return "5. 交通情報"
    case .applySection6: return "6. 宿泊情報"
    case .applySection7: return "7. 同意事項"
    case .applySubmit: return "申請を送信"
    case .applySuccess: return "申請を受け付けました。確認メールを送信しました。"
    case .applyEmailLabel: return "メールアドレス"
    case .applyNameLabel: return "氏名"
    case .applySchoolLabel: return "学校・学部"
    case .applyYearLabel: return "学年"
    case .applyPortfolioLabel: return "ポートフォリオ / 制作物 (任意)"
    case .applyGitHubLabel: return "GitHub アカウント (任意)"
    case .applyLanguageLabel: return "希望コミュニケーション言語"
    case .applyLanguageJa: return "日本語 / Japanese"
    case .applyLanguageEn: return "英語 / English"
    case .applyPurposeLabel: return "参加目的 (複数選択可)"
    case .applyTicketInfoLabel: return "既にチケットがある場合の情報 (任意)"
    case .applySupportTypeLabel: return "希望する支援内容"
    case .applyOriginCityLabel: return "出発都市"
    case .applyTransportLabel: return "利用予定の交通手段 (複数選択可)"
    case .applyTripCostLabel: return "往復交通費の見積 (円)"
    case .applyAccommodationLabel: return "宿泊先タイプ"
    case .applyReservationLabel: return "予約状況"
    case .applyAccommodationNameLabel: return "宿泊先名 (任意)"
    case .applyAccommodationAddressLabel: return "住所 (任意)"
    case .applyCheckInLabel: return "チェックイン日"
    case .applyCheckOutLabel: return "チェックアウト日"
    case .applyAccommodationCostLabel: return "宿泊費の見積 (円)"
    case .applyTotalCostLabel: return "合計見積 (円)"
    case .applyDesiredAmountLabel: return "希望する支援額 (円)"
    case .applySelfPaymentLabel: return "自己負担可能額や状況 (任意)"
    case .applyAdditionalCommentsLabel: return "その他のコメント (任意)"
    case .applyAgreeTravelRegs: return "旅費規約に同意します"
    case .applyAgreeApplicationConfirmation: return "記載内容に誤りがないことを確認しました"
    case .applyAgreePrivacy: return "プライバシーポリシーに同意します"
    case .applyAgreeCodeOfConduct: return "Code of Conduct に同意します"
    case .applyEducationalEmailHint:
      return "学校のメールアドレスでない可能性があります。誤りがないか再度ご確認ください。"
    case .applyEstimateButton: return "交通費を見積もる"
    case .myAppTitle: return "自分の申請"
    case .myAppNoApplication: return "まだ申請がありません。"
    case .myAppWithdraw: return "申請を取り下げる"
    case .myAppWithdrawConfirm: return "本当に取り下げますか？"
    case .myAppStatusLabel: return "ステータス"
    case .myAppApprovedAmount: return "承認額"
    case .orgListTitle: return "スカラシップ申請一覧"
    case .orgDetailTitle: return "申請詳細"
    case .orgBudgetTitle: return "予算管理"
    case .orgApprove: return "承認"
    case .orgReject: return "不採択"
    case .orgRevert: return "ステータスを戻す"
    case .orgExportCSV: return "CSV エクスポート"
    case .orgApprovedAmountLabel: return "承認額 (円)"
    case .orgNotesLabel: return "オーガナイザーメモ"
    case .orgSaveBudget: return "予算を保存"
    case .orgTotalBudgetLabel: return "総予算 (円)"
    case .orgBudgetNotesLabel: return "備考"
    case .orgConfirmDelete: return "本当に削除しますか？"
    }
  }

  private static func en(_ key: ScholarshipStringKey) -> String {
    switch key {
    case .navApply: return "Apply"
    case .navMyApplication: return "My Application"
    case .navLogin: return "Log in"
    case .navLogout: return "Log out"
    case .navOrganizer: return "Organizer"
    case .infoTitle: return "Student Scholarship"
    case .infoSubtitle:
      return
        "try! Swift Tokyo offers scholarships to support student engineers attending the conference."
    case .infoApplyCTA: return "Apply now"
    case .infoEligibilityTitle: return "Eligibility"
    case .infoIncludedTitle: return "What's included"
    case .infoBudgetTotal: return "Total budget"
    case .infoBudgetApproved: return "Approved"
    case .infoBudgetRemaining: return "Remaining"
    case .infoBudgetNotSet: return "Budget not set"
    case .infoNoOpenConference: return "No conference is currently accepting applications"
    case .loginTitle: return "Log in"
    case .loginEmailLabel: return "Email address"
    case .loginSubmit: return "Send login link"
    case .loginSentTitle: return "Login link sent"
    case .loginSentBody: return "Check your inbox for the login link. It expires in 30 minutes."
    case .loginInvalid: return "The login link is invalid or expired. Please request a new one."
    case .applyTitle: return "Scholarship Application"
    case .applySection1: return "1. Personal Information"
    case .applySection2: return "2. Background"
    case .applySection3: return "3. Purpose"
    case .applySection4: return "4. Ticket"
    case .applySection5: return "5. Travel"
    case .applySection6: return "6. Accommodation"
    case .applySection7: return "7. Agreements"
    case .applySubmit: return "Submit application"
    case .applySuccess: return "We received your application. A confirmation email has been sent."
    case .applyEmailLabel: return "Email"
    case .applyNameLabel: return "Full name"
    case .applySchoolLabel: return "School and faculty"
    case .applyYearLabel: return "Current year"
    case .applyPortfolioLabel: return "Portfolio / projects (optional)"
    case .applyGitHubLabel: return "GitHub account (optional)"
    case .applyLanguageLabel: return "Preferred communication language"
    case .applyLanguageJa: return "日本語 / Japanese"
    case .applyLanguageEn: return "英語 / English"
    case .applyPurposeLabel: return "Reasons to attend (select all that apply)"
    case .applyTicketInfoLabel: return "Existing ticket information (optional)"
    case .applySupportTypeLabel: return "Support type"
    case .applyOriginCityLabel: return "Origin city"
    case .applyTransportLabel: return "Transportation methods (select all)"
    case .applyTripCostLabel: return "Estimated round-trip cost (JPY)"
    case .applyAccommodationLabel: return "Accommodation type"
    case .applyReservationLabel: return "Reservation status"
    case .applyAccommodationNameLabel: return "Accommodation name (optional)"
    case .applyAccommodationAddressLabel: return "Address (optional)"
    case .applyCheckInLabel: return "Check-in"
    case .applyCheckOutLabel: return "Check-out"
    case .applyAccommodationCostLabel: return "Estimated accommodation cost (JPY)"
    case .applyTotalCostLabel: return "Total estimated cost (JPY)"
    case .applyDesiredAmountLabel: return "Desired support amount (JPY)"
    case .applySelfPaymentLabel: return "Self-payment notes (optional)"
    case .applyAdditionalCommentsLabel: return "Additional comments (optional)"
    case .applyAgreeTravelRegs: return "I agree to the travel regulations"
    case .applyAgreeApplicationConfirmation: return "I confirm the application details are accurate"
    case .applyAgreePrivacy: return "I agree to the privacy policy"
    case .applyAgreeCodeOfConduct: return "I agree to the Code of Conduct"
    case .applyEducationalEmailHint:
      return "This may not be an academic email. Please double-check the address."
    case .applyEstimateButton: return "Estimate travel cost"
    case .myAppTitle: return "My Application"
    case .myAppNoApplication: return "You have not submitted an application yet."
    case .myAppWithdraw: return "Withdraw application"
    case .myAppWithdrawConfirm: return "Are you sure you want to withdraw?"
    case .myAppStatusLabel: return "Status"
    case .myAppApprovedAmount: return "Approved amount"
    case .orgListTitle: return "Scholarship applications"
    case .orgDetailTitle: return "Application detail"
    case .orgBudgetTitle: return "Budget"
    case .orgApprove: return "Approve"
    case .orgReject: return "Reject"
    case .orgRevert: return "Revert status"
    case .orgExportCSV: return "Export CSV"
    case .orgApprovedAmountLabel: return "Approved amount (JPY)"
    case .orgNotesLabel: return "Organizer notes"
    case .orgSaveBudget: return "Save budget"
    case .orgTotalBudgetLabel: return "Total budget (JPY)"
    case .orgBudgetNotesLabel: return "Notes"
    case .orgConfirmDelete: return "Are you sure?"
    }
  }
}
