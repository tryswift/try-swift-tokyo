import SharedModels

public enum PortalStringKey: String, CaseIterable, Sendable {
  case inquiryTitle, inquirySubmit, loginTitle, loginSubmit,
    dashboardTitle, profileTitle, teamTitle, plansTitle,
    applicationFormTitle, applicationSubmit, applicationDetailTitle,
    organizerSponsors, organizerInquiries, organizerApplications
}

public enum PortalStrings {
  public static func t(_ key: PortalStringKey, _ locale: SponsorPortalLocale) -> String {
    switch (key, locale) {
    case (.inquiryTitle, .ja): return "資料請求"
    case (.inquiryTitle, .en): return "Request Materials"
    case (.inquirySubmit, .ja): return "送信"
    case (.inquirySubmit, .en): return "Submit"
    case (.loginTitle, .ja): return "ログイン"
    case (.loginTitle, .en): return "Log in"
    case (.loginSubmit, .ja): return "ログインリンクを送る"
    case (.loginSubmit, .en): return "Send login link"
    case (.dashboardTitle, .ja): return "ダッシュボード"
    case (.dashboardTitle, .en): return "Dashboard"
    case (.profileTitle, .ja): return "プロフィール"
    case (.profileTitle, .en): return "Profile"
    case (.teamTitle, .ja): return "メンバー"
    case (.teamTitle, .en): return "Team"
    case (.plansTitle, .ja): return "プラン一覧"
    case (.plansTitle, .en): return "Plans"
    case (.applicationFormTitle, .ja): return "申込フォーム"
    case (.applicationFormTitle, .en): return "Apply"
    case (.applicationSubmit, .ja): return "申し込む"
    case (.applicationSubmit, .en): return "Submit application"
    case (.applicationDetailTitle, .ja): return "申込内容"
    case (.applicationDetailTitle, .en): return "Application"
    case (.organizerSponsors, .ja): return "スポンサー一覧"
    case (.organizerSponsors, .en): return "Sponsors"
    case (.organizerInquiries, .ja): return "問い合わせ"
    case (.organizerInquiries, .en): return "Inquiries"
    case (.organizerApplications, .ja): return "申込"
    case (.organizerApplications, .en): return "Applications"
    }
  }
}
