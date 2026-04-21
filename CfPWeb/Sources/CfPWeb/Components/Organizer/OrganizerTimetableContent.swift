import Elementary

struct OrganizerTimetableContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    OrganizerTimetableToolbar(language: language)
    OrganizerTimetableCreateCard(language: language)
    OrganizerTimetableListCard(language: language)
    OrganizerTimetableEditorCard(language: language)
  }
}

private struct OrganizerTimetableToolbar: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card organizer-toolbar")) {
      div(.class("organizer-toolbar-row")) {
        label(.class("form-field organizer-toolbar-filter")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
          select(.id("organizer-slot-conference-filter"), .name("conferencePath")) {}
        }
        div(.class("organizer-toolbar-actions")) {
          a(.id("export-timetable-link"), .class("button neutral"), .href("#")) {
            HTMLText(language == .ja ? "タイムテーブル JSON" : "Export Timetable JSON")
          }
        }
      }
    }
  }
}

private struct OrganizerTimetableCreateCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card submit-form-card")) {
      h3 { HTMLText(language == .ja ? "スロットを追加" : "Add Timetable Slot") }
      form(.id("organizer-slot-form"), .class("submit-form-grid")) {
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
          select(.id("organizer-slot-conference-id"), .name("conferenceId"), .required) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "Day" : "Day") }
          input(.type(.number), .name("day"), .custom(name: "min", value: "1"), .custom(name: "max", value: "3"), .value("1"), .required)
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "開始時刻" : "Start Time") }
          input(.type(.datetimeLocal), .name("startTime"), .required)
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "終了時刻 (任意)" : "End Time (optional)") }
          input(.type(.datetimeLocal), .name("endTime"))
        }
        slotTypeSelect()
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "プロポーザル (任意)" : "Proposal (optional)") }
          select(.id("organizer-slot-proposal-id"), .name("proposalId")) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カスタムタイトル" : "Custom Title") }
          input(.type(.text), .name("customTitle"))
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "会場" : "Place") }
          input(.type(.text), .name("place"))
        }
        div(.class("form-actions submit-form-full")) {
          button(.type(.submit), .class("button primary")) {
            HTMLText(language == .ja ? "スロットを作成" : "Create Slot")
          }
        }
        p(.id("organizer-timetable-status"), .class("inline-status submit-form-full"), .hidden) {}
      }
    }
  }

  @HTMLBuilder
  private func slotTypeSelect() -> some HTML {
    label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "種別" : "Slot Type") }
      select(.name("slotType"), .required) {
        option(.value("talk")) { HTMLText("Talk") }
        option(.value("lightning_talk")) { HTMLText("Lightning Talk") }
        option(.value("break")) { HTMLText("Break") }
        option(.value("lunch")) { HTMLText("Lunch") }
        option(.value("opening")) { HTMLText("Opening") }
        option(.value("closing")) { HTMLText("Closing") }
        option(.value("party")) { HTMLText("Party") }
        option(.value("custom")) { HTMLText("Custom") }
      }
    }
  }
}

private struct OrganizerTimetableListCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card")) {
      h3 { HTMLText(language == .ja ? "スロット一覧" : "Timetable Slots") }
      div(.id("organizer-slot-list"), .class("timetable-list")) {}
    }
  }
}

private struct OrganizerTimetableEditorCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card submit-form-card")) {
      h3 { HTMLText(language == .ja ? "スロットを編集" : "Edit Slot") }
      p(.id("organizer-slot-editor-placeholder"), .class("submit-form-intro")) {
        HTMLText(language == .ja
          ? "一覧から Edit を選ぶとフォームに読み込まれます。"
          : "Choose Edit on a slot above to load it here.")
      }
      form(.id("organizer-slot-editor-form"), .class("submit-form-grid")) {
        input(.type(.hidden), .name("slotID"))
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "Day" : "Day") }
          input(.type(.number), .name("day"), .custom(name: "min", value: "1"), .custom(name: "max", value: "3"), .required)
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "開始時刻" : "Start Time") }
          input(.type(.datetimeLocal), .name("startTime"))
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "終了時刻 (任意)" : "End Time (optional)") }
          input(.type(.datetimeLocal), .name("endTime"))
        }
        slotTypeSelect()
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "プロポーザル (任意)" : "Proposal (optional)") }
          select(.id("organizer-slot-editor-proposal-id"), .name("proposalId")) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カスタムタイトル" : "Custom Title") }
          input(.type(.text), .name("customTitle"))
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "会場" : "Place") }
          input(.type(.text), .name("place"))
        }
        div(.class("form-actions submit-form-full split")) {
          button(.type(.button), .id("organizer-slot-editor-reset"), .class("button neutral")) {
            HTMLText(language == .ja ? "リセット" : "Reset")
          }
          button(.type(.submit), .class("button primary")) {
            HTMLText(language == .ja ? "変更を保存" : "Save Changes")
          }
          button(.type(.button), .id("organizer-slot-reorder-button"), .class("button neutral")) {
            HTMLText(language == .ja ? "この日の順序を保存" : "Apply Day Order")
          }
        }
        p(.id("organizer-slot-editor-status"), .class("inline-status submit-form-full"), .hidden) {}
      }
    }
  }

  @HTMLBuilder
  private func slotTypeSelect() -> some HTML {
    label(.class("form-field")) {
      span(.class("field-label")) { HTMLText(language == .ja ? "種別" : "Slot Type") }
      select(.name("slotType"), .required) {
        option(.value("talk")) { HTMLText("Talk") }
        option(.value("lightning_talk")) { HTMLText("Lightning Talk") }
        option(.value("break")) { HTMLText("Break") }
        option(.value("lunch")) { HTMLText("Lunch") }
        option(.value("opening")) { HTMLText("Opening") }
        option(.value("closing")) { HTMLText("Closing") }
        option(.value("party")) { HTMLText("Party") }
        option(.value("custom")) { HTMLText("Custom") }
      }
    }
  }
}
