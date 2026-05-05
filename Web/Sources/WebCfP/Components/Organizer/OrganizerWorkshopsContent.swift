import Elementary

struct OrganizerWorkshopsContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card organizer-toolbar")) {
      h3 { HTMLText(language == .ja ? "ワークショップ管理" : "Workshop Management") }
      div(.class("organizer-toolbar-row")) {
        label(.class("form-field organizer-toolbar-filter")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "ワークショップ絞り込み" : "Filter") }
          select(.id("organizer-workshop-filter"), .name("workshopID")) {}
        }
        div(.class("organizer-toolbar-actions")) {
          button(.type(.button), .id("organizer-workshops-refresh"), .class("button neutral")) {
            HTMLText(language == .ja ? "更新" : "Refresh")
          }
          button(.type(.button), .id("organizer-workshop-lottery-button"), .class("button primary"))
          {
            HTMLText(language == .ja ? "抽選を実行" : "Run Lottery")
          }
          button(
            .type(.button), .id("organizer-workshop-send-tickets-button"), .class("button primary")
          ) {
            HTMLText(language == .ja ? "チケットを送信" : "Send Tickets")
          }
        }
      }
      p(.id("organizer-workshops-status"), .class("inline-status"), .hidden) {}
    }

    article(.class("detail-card")) {
      h3 { HTMLText(language == .ja ? "ワークショップ一覧" : "Workshops") }
      div(.id("organizer-workshops-list"), .class("organizer-workshops-list")) {}
    }
  }
}
