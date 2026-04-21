import Elementary

struct OrganizerWorkshopApplicationsContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card organizer-toolbar")) {
      h3 { HTMLText(language == .ja ? "ワークショップ応募" : "Workshop Applications") }
      div(.class("organizer-toolbar-row")) {
        label(.class("form-field organizer-toolbar-filter")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "ワークショップ絞り込み" : "Filter") }
          select(.id("organizer-workshop-filter"), .name("workshopID")) {}
        }
        div(.class("organizer-toolbar-actions")) {
          button(.type(.button), .id("organizer-workshop-applications-refresh"), .class("button neutral")) {
            HTMLText(language == .ja ? "更新" : "Refresh")
          }
        }
      }
      p(.id("organizer-workshop-applications-status"), .class("inline-status"), .hidden) {}
    }

    article(.class("detail-card")) {
      h3 { HTMLText(language == .ja ? "応募一覧" : "Applications") }
      div(.id("organizer-workshop-applications-list"), .class("organizer-applications-list")) {}
    }
  }
}
