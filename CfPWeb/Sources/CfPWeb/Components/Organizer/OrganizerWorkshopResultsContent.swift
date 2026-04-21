import Elementary

struct OrganizerWorkshopResultsContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card organizer-toolbar")) {
      h3 { HTMLText(language == .ja ? "抽選結果" : "Workshop Results") }
      div(.class("organizer-toolbar-row")) {
        div(.class("organizer-toolbar-actions")) {
          button(.type(.button), .id("organizer-workshop-results-refresh"), .class("button neutral")) {
            HTMLText(language == .ja ? "更新" : "Refresh")
          }
        }
      }
      p(.id("organizer-workshop-results-status"), .class("inline-status"), .hidden) {}
    }

    article(.class("detail-card")) {
      h3 { HTMLText(language == .ja ? "結果一覧" : "Results") }
      div(.id("organizer-workshop-results-list"), .class("organizer-results-list")) {}
    }
  }
}
