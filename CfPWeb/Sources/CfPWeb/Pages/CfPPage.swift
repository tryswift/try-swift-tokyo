enum CfPPage: String, CaseIterable, Sendable {
  case home
  case guidelines
  case login
  case profile
  case submit
  case workshops
  case myProposals = "my-proposals"
  case feedback
  case organizer

  var path: String {
    switch self {
    case .home: return "/"
    case .guidelines: return "/guidelines"
    case .login: return "/login"
    case .profile: return "/profile"
    case .submit: return "/submit"
    case .workshops: return "/workshops"
    case .myProposals: return "/my-proposals"
    case .feedback: return "/feedback"
    case .organizer: return "/organizer"
    }
  }

  func path(for language: AppLanguage) -> String {
    guard language == .ja else { return path }
    return path == "/" ? "/ja" : "/ja\(path)"
  }

  func title(for language: AppLanguage) -> String {
    switch self {
    case .home:
      return language == .ja ? "プロポーザル募集" : "Call for Proposals"
    case .guidelines:
      return language == .ja ? "応募ガイドライン" : "Submission Guidelines"
    case .login:
      return language == .ja ? "ログイン" : "Login"
    case .profile:
      return language == .ja ? "プロフィール" : "Profile"
    case .submit:
      return language == .ja ? "プロポーザルを提出" : "Submit Proposal"
    case .workshops:
      return language == .ja ? "ワークショップ" : "Workshops"
    case .myProposals:
      return language == .ja ? "マイプロポーザル" : "My Proposals"
    case .feedback:
      return language == .ja ? "フィードバック" : "Feedback"
    case .organizer:
      return language == .ja ? "運営向け" : "Organizer"
    }
  }

  func navigationTitle(for language: AppLanguage) -> String {
    switch self {
    case .home:
      return language == .ja ? "ホーム" : "Home"
    case .guidelines:
      return language == .ja ? "ガイドライン" : "Guidelines"
    case .submit:
      return language == .ja ? "応募する" : "Submit"
    case .workshops:
      return language == .ja ? "ワークショップ" : "Workshops"
    default:
      return title(for: language)
    }
  }

  func description(for language: AppLanguage) -> String {
    switch self {
    case .home:
      return language == .ja
        ? "try! Swift Tokyo の各イベントへのセッション提案を募集しています。"
        : "Submit your talk proposal for try! Swift Tokyo events."
    case .guidelines:
      return language == .ja
        ? "try! Swift Tokyo への応募に必要な情報をまとめています。"
        : "Everything you need to know about submitting a talk proposal for try! Swift Tokyo."
    default:
      return title(for: language)
    }
  }
}

enum AppLanguage: String, Sendable {
  case en
  case ja

  var rootPath: String {
    self == .ja ? "/ja" : "/"
  }
}
