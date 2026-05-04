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
          .type(.button), .id("organizer-conference-add"),
          .class("button primary")
        ) {
          HTMLText(language == .ja ? "カンファレンスを追加" : "Add Conference")
        }
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

    OrganizerConferenceFormCard(language: language)
  }
}

private struct OrganizerConferenceFormCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(
      .id("organizer-conference-form-card"),
      .class("detail-card submit-form-card organizer-conference-form-card"),
      .hidden
    ) {
      header(.class("editor-header-row")) {
        h3(.id("organizer-conference-form-title")) {
          HTMLText(language == .ja ? "新規カンファレンス" : "New Conference")
        }
      }
      p(.class("submit-form-intro")) {
        HTMLText(
          language == .ja
            ? "日時は UTC で扱います。説明欄は Markdown が使えます。"
            : "All dates and times are stored in UTC. Description fields accept Markdown."
        )
      }
      form(.id("organizer-conference-form"), .class("submit-form-grid")) {
        input(.type(.hidden), .name("originalPath"))

        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "スラッグ (path)" : "Slug (path)")
          }
          input(
            .type(.text), .name("path"),
            .custom(name: "pattern", value: "[a-z0-9-]+"),
            .required,
            .custom(
              name: "placeholder",
              value: "tryswift-tokyo-2027")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "表示名" : "Display Name")
          }
          input(
            .type(.text), .name("displayName"), .required,
            .custom(name: "placeholder", value: "try! Swift Tokyo 2027")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "年度" : "Year")
          }
          input(
            .type(.number), .name("year"), .required,
            .custom(name: "min", value: "2000"),
            .custom(name: "max", value: "2100")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "応募締切 (UTC)" : "Submission Deadline (UTC)")
          }
          input(
            .type(.text), .name("deadline"),
            .custom(name: "placeholder", value: "YYYY-MM-DDTHH:mm")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "開始日 (UTC)" : "Start Date (UTC)")
          }
          input(
            .type(.date), .name("startDate")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "終了日 (UTC)" : "End Date (UTC)")
          }
          input(
            .type(.date), .name("endDate")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "会場" : "Location")
          }
          input(
            .type(.text), .name("location"),
            .custom(name: "placeholder", value: "Tokyo, Japan")
          )
        }
        label(.class("form-field")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "ウェブサイト URL" : "Website URL")
          }
          input(
            .type(.url), .name("websiteURL"),
            .custom(name: "placeholder", value: "https://tryswift.jp")
          )
        }

        label(.class("form-field organizer-checkbox-row submit-form-full")) {
          input(.type(.checkbox), .name("isOpen"))
          span {
            HTMLText(language == .ja ? "CfP の応募を受け付ける" : "Accept proposals (CfP open)")
          }
        }
        label(.class("form-field organizer-checkbox-row submit-form-full")) {
          input(.type(.checkbox), .name("isPublished"))
          span {
            HTMLText(
              language == .ja
                ? "公開する（オフのままだと未公開ドラフトになります）"
                : "Publish (leave off to keep as an unpublished draft)"
            )
          }
        }

        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "説明 (英語, Markdown)" : "Description (English, Markdown)")
          }
          textarea(
            .name("descriptionEn"),
            .custom(name: "rows", value: "6")
          ) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) {
            HTMLText(language == .ja ? "説明 (日本語, Markdown)" : "Description (Japanese, Markdown)")
          }
          textarea(
            .name("descriptionJa"),
            .custom(name: "rows", value: "6")
          ) {}
        }

        p(
          .id("organizer-conference-form-status"),
          .class("inline-status submit-form-full"),
          .hidden
        ) {}

        div(.class("organizer-conference-form-actions submit-form-full")) {
          button(
            .type(.submit),
            .id("organizer-conference-form-submit"),
            .class("button primary")
          ) {
            HTMLText(language == .ja ? "保存" : "Save")
          }
          button(
            .type(.button),
            .id("organizer-conference-form-cancel"),
            .class("button neutral")
          ) {
            HTMLText(language == .ja ? "キャンセル" : "Cancel")
          }
          button(
            .type(.button),
            .id("organizer-conference-form-delete"),
            .class("button danger"),
            .hidden
          ) {
            HTMLText(language == .ja ? "削除" : "Delete")
          }
        }
      }
    }
  }
}
