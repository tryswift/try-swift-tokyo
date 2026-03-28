import Elementary
import Foundation

/// Workshop option for the selection form
struct WorkshopOption: Sendable {
  let id: UUID
  let title: String
  let speakerName: String
}

/// Page for selecting workshop preferences (1st, 2nd, 3rd choice)
struct WorkshopSelectPageView: HTML, Sendable {
  let workshops: [WorkshopOption]
  let email: String
  let applicantName: String
  let verifyToken: String
  let language: CfPLanguage
  let csrfToken: String
  let errorMessage: String?
  let isEditMode: Bool
  let existingSelections: ExistingSelections?

  struct ExistingSelections: Sendable {
    let firstChoiceID: UUID
    let secondChoiceID: UUID?
    let thirdChoiceID: UUID?
  }

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("row justify-content-center")) {
        div(.class("col-md-8 col-lg-7")) {
          if let errorMessage {
            div(.class("alert alert-danger mb-4")) {
              strong {
                language == .ja ? "エラー: " : "Error: "
              }
              HTMLText(errorMessage)
            }
          }

          div(.class("card")) {
            div(.class("card-body p-4")) {
              div(.class("mb-4")) {
                h2(.class("fw-bold mb-2")) {
                  if isEditMode {
                    language == .ja
                      ? "ワークショップ申し込み変更"
                      : "Edit Workshop Application"
                  } else {
                    language == .ja
                      ? "ワークショップ申し込み"
                      : "Workshop Application"
                  }
                }
                p(.class("text-muted")) {
                  if isEditMode {
                    language == .ja
                      ? "希望するワークショップを変更してください。"
                      : "Update your workshop preferences below."
                  } else {
                    language == .ja
                      ? "第1希望から第3希望まで選択してください。第2・第3希望は任意です。"
                      : "Select your preferences from 1st to 3rd choice. 2nd and 3rd choices are optional."
                  }
                }
                div(.class("alert alert-info")) {
                  strong { HTMLText(email) }
                  " "
                  language == .ja ? "として申し込みます" : "will be used for registration"
                }
              }

              form(
                .method(.post),
                .action(language.path(for: "/workshops/apply"))
              ) {
                input(.type(.hidden), .name("_csrf"), .value(csrfToken))
                input(.type(.hidden), .name("verify_token"), .value(verifyToken))
                input(.type(.hidden), .name("email"), .value(email))

                // Applicant name
                div(.class("mb-4")) {
                  label(.class("form-label fw-bold"), .for("applicant_name")) {
                    language == .ja ? "お名前" : "Your Name"
                  }
                  input(
                    .type(.text),
                    .class("form-control"),
                    .id("applicant_name"),
                    .name("applicant_name"),
                    .value(applicantName),
                    .required
                  )
                }

                // First choice (required)
                requiredWorkshopSelect(
                  label: language == .ja ? "第1希望（必須）" : "1st Choice (Required)",
                  name: "first_choice_id"
                )

                // Second choice (optional)
                optionalWorkshopSelect(
                  label: language == .ja ? "第2希望（任意）" : "2nd Choice (Optional)",
                  name: "second_choice_id"
                )

                // Third choice (optional)
                optionalWorkshopSelect(
                  label: language == .ja ? "第3希望（任意）" : "3rd Choice (Optional)",
                  name: "third_choice_id"
                )

                button(
                  .type(.submit),
                  .class("btn btn-primary btn-lg w-100 mt-3")
                ) {
                  if isEditMode {
                    language == .ja ? "申し込みを更新する" : "Update Application"
                  } else {
                    language == .ja ? "申し込む" : "Submit Application"
                  }
                }
              }
            }
          }

          div(.class("text-center mt-3")) {
            a(
              .class("text-muted"),
              .href(language.path(for: "/workshops"))
            ) {
              language == .ja ? "← ワークショップ一覧に戻る" : "← Back to Workshops"
            }
          }
        }
      }
    }
    validationScript
  }

  @HTMLBuilder
  private func requiredWorkshopSelect(label: String, name: String) -> some HTML {
    div(.class("mb-3")) {
      Elementary.label(.class("form-label fw-bold"), .for(name)) {
        HTMLText(label)
      }
      HTMLRaw(workshopSelectHTML(name: name, isRequired: true, selectedID: selectedIDForField(name)))
    }
  }

  @HTMLBuilder
  private func optionalWorkshopSelect(label: String, name: String) -> some HTML {
    div(.class("mb-3")) {
      Elementary.label(.class("form-label fw-bold"), .for(name)) {
        HTMLText(label)
      }
      HTMLRaw(workshopSelectHTML(name: name, isRequired: false, selectedID: selectedIDForField(name)))
    }
  }

  private func selectedIDForField(_ fieldName: String) -> UUID? {
    guard let selections = existingSelections else { return nil }
    switch fieldName {
    case "first_choice_id": return selections.firstChoiceID
    case "second_choice_id": return selections.secondChoiceID
    case "third_choice_id": return selections.thirdChoiceID
    default: return nil
    }
  }

  private func workshopSelectHTML(name: String, isRequired: Bool, selectedID: UUID? = nil) -> String {
    let placeholder = language == .ja ? "選択してください" : "Select a workshop"
    let requiredAttr = isRequired ? " required" : ""
    var html =
      "<select class=\"form-select\" id=\"\(name)\" name=\"\(name)\"\(requiredAttr)>"
    html += "<option value=\"\">\(placeholder)</option>"
    for workshop in workshops {
      let escapedTitle = escapeHTML("\(workshop.title) - \(workshop.speakerName)")
      let isSelected = workshop.id == selectedID ? " selected" : ""
      html += "<option value=\"\(workshop.id.uuidString)\"\(isSelected)>\(escapedTitle)</option>"
    }
    html += "</select>"
    return html
  }

  private func escapeHTML(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }

  /// Client-side validation: prevent selecting the same workshop for multiple choices
  private var validationScript: some HTML {
    HTMLRaw(
      """
      <script>
      (function() {
        var selects = ['first_choice_id', 'second_choice_id', 'third_choice_id'];
        selects.forEach(function(name) {
          var el = document.getElementById(name);
          if (el) el.addEventListener('change', validateChoices);
        });
        function validateChoices() {
          var values = selects.map(function(name) {
            return document.getElementById(name).value;
          }).filter(function(v) { return v !== ''; });
          var unique = new Set(values);
          if (unique.size !== values.length) {
            alert('\(language == .ja ? "同じワークショップを複数回選択することはできません。" : "You cannot select the same workshop more than once.")');
            this.value = '';
          }
        }
      })();
      </script>
      """)
  }
}
