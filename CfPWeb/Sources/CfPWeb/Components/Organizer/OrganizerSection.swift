import Foundation

enum OrganizerSection: Sendable, CaseIterable {
  case proposals
  case timetable
  case workshops
  case workshopApplications
  case workshopResults
  case conferences

  static func from(routePath: String) -> OrganizerSection {
    var path = routePath
    if path.hasPrefix("/ja") {
      path = String(path.dropFirst(3))
    }
    if path.isEmpty { path = "/" }

    if path == "/organizer/timetable" { return .timetable }
    if path == "/organizer/workshops" { return .workshops }
    if path == "/organizer/workshops/applications" { return .workshopApplications }
    if path == "/organizer/workshops/results" { return .workshopResults }
    if path == "/organizer/conferences" { return .conferences }
    return .proposals
  }

  func path(for language: AppLanguage) -> String {
    let prefix = language == .ja ? "/ja" : ""
    switch self {
    case .proposals: return "\(prefix)/organizer/proposals"
    case .timetable: return "\(prefix)/organizer/timetable"
    case .workshops: return "\(prefix)/organizer/workshops"
    case .workshopApplications: return "\(prefix)/organizer/workshops/applications"
    case .workshopResults: return "\(prefix)/organizer/workshops/results"
    case .conferences: return "\(prefix)/organizer/conferences"
    }
  }

  func navigationTitle(for language: AppLanguage) -> String {
    switch self {
    case .proposals:
      return language == .ja ? "プロポーザル" : "Proposals"
    case .timetable:
      return language == .ja ? "タイムテーブル" : "Timetable"
    case .workshops:
      return language == .ja ? "ワークショップ" : "Workshops"
    case .workshopApplications:
      return language == .ja ? "応募" : "Applications"
    case .workshopResults:
      return language == .ja ? "結果" : "Results"
    case .conferences:
      return language == .ja ? "カンファレンス" : "Conferences"
    }
  }
}
