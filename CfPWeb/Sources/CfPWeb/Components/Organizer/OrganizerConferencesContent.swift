import Elementary

struct OrganizerConferencesContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card organizer-conferences-card")) {
      header(.class("organizer-conferences-header")) {
        h3 { HTMLText(language == .ja ? "カンファレンス管理" : "Conference Management") }
        p(.class("submit-form-intro")) {
          HTMLText(
            language == .ja
              ? "各カンファレンスの公開状態と CfP 受付状態を切り替えます。未公開のカンファレンスは運営にしか表示されません。"
              : "Toggle each conference's published state and CfP availability. Unpublished conferences are visible only to organizers."
          )
        }
      }

      div(.class("organizer-conferences-toolbar")) {
        button(
          .type(.button), .id("organizer-conferences-refresh"),
          .class("button neutral")
        ) {
          HTMLText(language == .ja ? "更新" : "Refresh")
        }
      }

      p(
        .id("organizer-conferences-status"),
        .class("inline-status"),
        .hidden
      ) {}

      div(.class("organizer-conferences-table-wrapper")) {
        table(.class("organizer-conferences-table")) {
          thead {
            tr {
              th { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
              th { HTMLText(language == .ja ? "年" : "Year") }
              th { HTMLText(language == .ja ? "応募締切" : "Deadline") }
              th { HTMLText(language == .ja ? "状態" : "Status") }
              th(.class("organizer-conferences-actions-col")) {
                HTMLText(language == .ja ? "操作" : "Actions")
              }
            }
          }
          tbody(.id("organizer-conferences-tbody")) {}
        }
      }

      p(
        .id("organizer-conferences-empty"),
        .class("organizer-conferences-empty"),
        .hidden
      ) {
        HTMLText(language == .ja ? "カンファレンスが登録されていません。" : "No conferences registered.")
      }
    }
  }
}
