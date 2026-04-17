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

  var title: String {
    switch self {
    case .home: return "Call for Proposals"
    case .guidelines: return "Guidelines"
    case .login: return "Login"
    case .profile: return "Profile"
    case .submit: return "Submit"
    case .workshops: return "Workshops"
    case .myProposals: return "My Proposals"
    case .feedback: return "Feedback"
    case .organizer: return "Organizer"
    }
  }
}
