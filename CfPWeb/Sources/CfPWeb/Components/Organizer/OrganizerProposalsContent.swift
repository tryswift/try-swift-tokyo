import Elementary

struct OrganizerProposalsContent: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    OrganizerProposalsToolbar(language: language)
    OrganizerProposalsCreateCard(language: language)
    OrganizerProposalsImportCard(language: language)
    OrganizerProposalsListCard(language: language)
    OrganizerProposalsEditorCard(language: language)
  }
}

private struct OrganizerProposalsToolbar: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card organizer-toolbar")) {
      div(.class("organizer-toolbar-row")) {
        label(.class("form-field organizer-toolbar-filter")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
          select(.id("organizer-conference-filter"), .name("conferencePath")) {}
        }
        div(.class("organizer-toolbar-actions")) {
          button(.type(.button), .id("organizer-refresh"), .class("button neutral")) {
            HTMLText(language == .ja ? "更新" : "Refresh")
          }
          a(.id("export-proposals-link"), .class("button neutral"), .href("#")) {
            HTMLText(language == .ja ? "CSV エクスポート" : "Export CSV")
          }
          a(.id("export-speakers-link"), .class("button neutral"), .href("#")) {
            HTMLText(language == .ja ? "スピーカー JSON" : "Export Speakers JSON")
          }
        }
      }
    }
  }
}

private struct OrganizerProposalsCreateCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card submit-form-card")) {
      h3 { HTMLText(language == .ja ? "プロポーザルを追加" : "Add Proposal") }
      p(.class("submit-form-intro")) {
        HTMLText(language == .ja
          ? "運営側でプロポーザルを新規登録します。GitHub ユーザー名からスピーカー情報を補完できます。"
          : "Create a proposal on behalf of a speaker. Use GitHub lookup to auto-fill speaker info.")
      }
      form(.id("organizer-create-form"), .class("submit-form-grid")) {
        div(.class("form-field submit-form-full organizer-lookup-row")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "GitHub ユーザー名" : "GitHub Username") }
          div(.class("organizer-lookup-input-row")) {
            input(.type(.text), .name("githubUsername"))
            button(.type(.button), .id("organizer-lookup-button"), .class("button neutral")) {
              HTMLText(language == .ja ? "情報を取得" : "Lookup")
            }
          }
        }

        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
          select(.id("organizer-conference-id"), .name("conferenceId"), .required) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "形式" : "Format") }
          select(.name("talkDuration"), .required) {
            option(.value("20min")) { HTMLText(language == .ja ? "レギュラートーク (20分)" : "Regular Talk (20 min)") }
            option(.value("LT")) { HTMLText(language == .ja ? "ライトニングトーク (5分)" : "Lightning Talk (5 min)") }
            option(.value("workshop")) { HTMLText(language == .ja ? "ワークショップ" : "Workshop") }
          }
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "タイトル" : "Title") }
          input(.type(.text), .name("title"), .required)
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "概要" : "Abstract") }
          textarea(.name("abstract"), .required, .custom(name: "rows", value: "5")) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "詳細" : "Talk Details") }
          textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "8")) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "登壇者名" : "Speaker Name") }
          input(.type(.text), .name("speakerName"), .required)
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "メールアドレス" : "Speaker Email") }
          input(.type(.email), .name("speakerEmail"), .required)
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText("Bio") }
          textarea(.name("bio"), .required, .custom(name: "rows", value: "5")) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "アイコンURL" : "Avatar URL") }
          input(.type(.url), .name("iconURL"))
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "メモ" : "Notes for Organizers") }
          textarea(.name("notes"), .custom(name: "rows", value: "4")) {}
        }

        OrganizerWorkshopDetailFields(
          sectionID: "organizer-create-workshop-section",
          coInstructor1Prefix: "organizer-create-co1",
          coInstructor2Prefix: "organizer-create-co2",
          language: language,
          includeJapanese: false
        )

        div(.class("form-actions submit-form-full")) {
          button(.type(.submit), .class("button primary")) {
            HTMLText(language == .ja ? "プロポーザルを作成" : "Create Proposal")
          }
        }
        p(.id("organizer-create-status"), .class("inline-status submit-form-full"), .hidden) {}
      }
    }
  }
}

private struct OrganizerProposalsImportCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card submit-form-card")) {
      h3 { HTMLText(language == .ja ? "CSV / JSON をインポート" : "Import CSV / JSON") }
      p(.class("submit-form-intro")) {
        HTMLText(language == .ja
          ? "プロポーザルを一括取り込みします。既存のものと重複する場合のスキップを選択できます。"
          : "Bulk import proposals. Choose whether to skip entries that already exist.")
      }
      form(.id("organizer-import-form"), .class("submit-form-grid")) {
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
          select(.id("organizer-import-conference-id"), .name("conferenceId"), .required) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "ファイル" : "File") }
          input(.type(.file), .name("csvFile"), .custom(name: "accept", value: ".csv,.json"), .required)
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "GitHub ユーザー名 (任意)" : "GitHub Username (optional)") }
          input(.type(.text), .name("githubUsername"))
        }
        label(.class("form-field submit-form-full organizer-checkbox-row")) {
          input(.type(.checkbox), .name("skipDuplicates"), .custom(name: "checked", value: "checked"))
          span { HTMLText(language == .ja ? "重複をスキップ" : "Skip duplicates") }
        }
        div(.class("form-actions submit-form-full")) {
          button(.type(.submit), .class("button primary")) {
            HTMLText(language == .ja ? "インポート" : "Import")
          }
        }
        p(.id("organizer-import-status"), .class("inline-status submit-form-full"), .hidden) {}
      }
    }
  }
}

private struct OrganizerProposalsListCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card")) {
      h3 { HTMLText(language == .ja ? "プロポーザル一覧" : "All Proposals") }
      p(.id("organizer-status"), .class("inline-status"), .hidden) {}
      div(.id("organizer-proposals"), .class("proposal-list")) {}
    }
  }
}

private struct OrganizerProposalsEditorCard: HTML, Sendable {
  let language: AppLanguage

  var body: some HTML {
    article(.class("detail-card submit-form-card")) {
      h3 { HTMLText(language == .ja ? "プロポーザルを編集" : "Edit Proposal") }
      p(.id("organizer-editor-placeholder"), .class("submit-form-intro")) {
        HTMLText(language == .ja
          ? "一覧から Edit を選ぶとフォームに読み込まれます。"
          : "Choose Edit on a proposal above to load it here.")
      }
      form(.id("organizer-editor-form"), .class("submit-form-grid")) {
        input(.type(.hidden), .name("proposalID"))

        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "カンファレンス" : "Conference") }
          select(.id("organizer-editor-conference-id"), .name("conferenceId"), .required) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "形式" : "Format") }
          select(.name("talkDuration"), .required) {
            option(.value("20min")) { HTMLText(language == .ja ? "レギュラートーク (20分)" : "Regular Talk (20 min)") }
            option(.value("LT")) { HTMLText(language == .ja ? "ライトニングトーク (5分)" : "Lightning Talk (5 min)") }
            option(.value("workshop")) { HTMLText(language == .ja ? "ワークショップ" : "Workshop") }
          }
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "タイトル" : "Title") }
          input(.type(.text), .name("title"), .required)
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "タイトル (JA)" : "Title (JA)") }
          input(.type(.text), .name("titleJA"))
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "概要" : "Abstract") }
          textarea(.name("abstract"), .required, .custom(name: "rows", value: "5")) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "概要 (JA)" : "Abstract (JA)") }
          textarea(.name("abstractJA"), .custom(name: "rows", value: "5")) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "詳細" : "Talk Details") }
          textarea(.name("talkDetail"), .required, .custom(name: "rows", value: "8")) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "登壇者名" : "Speaker Name") }
          input(.type(.text), .name("speakerName"), .required)
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "メールアドレス" : "Speaker Email") }
          input(.type(.email), .name("speakerEmail"), .required)
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText("Bio") }
          textarea(.name("bio"), .required, .custom(name: "rows", value: "5")) {}
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "Bio (JA)" : "Bio (JA)") }
          textarea(.name("bioJa"), .custom(name: "rows", value: "5")) {}
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "肩書き" : "Job Title") }
          input(.type(.text), .name("jobTitle"))
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "肩書き (JA)" : "Job Title (JA)") }
          input(.type(.text), .name("jobTitleJa"))
        }
        label(.class("form-field")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "GitHub ユーザー名" : "GitHub Username") }
          input(.type(.text), .name("githubUsername"))
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "アイコンURL" : "Avatar URL") }
          input(.type(.url), .name("iconURL"))
        }
        label(.class("form-field submit-form-full")) {
          span(.class("field-label")) { HTMLText(language == .ja ? "メモ" : "Notes for Organizers") }
          textarea(.name("notes"), .custom(name: "rows", value: "4")) {}
        }

        OrganizerWorkshopDetailFields(
          sectionID: "organizer-edit-workshop-section",
          coInstructor1Prefix: "organizer-edit-co1",
          coInstructor2Prefix: "organizer-edit-co2",
          language: language,
          includeJapanese: true
        )

        div(.class("form-actions submit-form-full split")) {
          button(.type(.button), .id("organizer-editor-reset"), .class("button neutral")) {
            HTMLText(language == .ja ? "リセット" : "Reset")
          }
          button(.type(.submit), .class("button primary")) {
            HTMLText(language == .ja ? "変更を保存" : "Save Changes")
          }
          button(.type(.button), .id("organizer-delete-proposal-button"), .class("button danger")) {
            HTMLText(language == .ja ? "削除" : "Delete Proposal")
          }
        }
        p(.id("organizer-editor-status"), .class("inline-status submit-form-full"), .hidden) {}
      }
    }
  }
}
