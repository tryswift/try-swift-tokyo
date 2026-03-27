import Elementary
import Foundation
import SharedModels

/// Page showing all available workshops for registration
struct WorkshopListPageView: HTML, Sendable {
  let workshops: [WorkshopItem]
  let language: CfPLanguage
  let applicationOpen: Bool

  struct WorkshopItem: Sendable {
    let id: UUID
    let title: String
    let titleJA: String?
    let speakerName: String
    let abstract: String
    let abstractJA: String?
    let bio: String
    let bioJa: String?
    let iconURL: String?
    let githubUsername: String?
    let isPaperCallImport: Bool
    let workshopDetails: WorkshopDetails?
    let coInstructors: [CoInstructor]?
    let capacity: Int
    let applicationCount: Int
    let workshopLanguage: WorkshopLanguage?
  }

  var body: some HTML {
    div(.class("container py-5")) {
      div(.class("mb-4")) {
        h1(.class("fw-bold mb-2")) {
          language == .ja ? "ワークショップ一覧" : "Workshops"
        }
        p(.class("lead text-muted")) {
          language == .ja
            ? "try! Swift Tokyo 2026のワークショップに申し込みましょう。第3希望まで選択でき、抽選で決定します。"
            : "Apply for try! Swift Tokyo 2026 workshops. You can select up to 3 preferences, and assignments are determined by lottery."
        }
      }

      if workshops.isEmpty {
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "📋" }
            h3(.class("fw-bold mb-2")) {
              language == .ja ? "ワークショップはまだありません" : "No Workshops Available"
            }
            p(.class("text-muted")) {
              language == .ja
                ? "ワークショップが公開されるまでお待ちください。"
                : "Please wait until workshops are published."
            }
          }
        }
      } else {
        div(.class("row g-4")) {
          for workshop in workshops {
            div(.class("col-md-6 col-lg-4")) {
              WorkshopCardView(workshop: workshop, language: language)
            }
          }
        }

        // Render modals for each workshop
        for workshop in workshops {
          WorkshopModalView(workshop: workshop, language: language)
        }

        if applicationOpen {
          div(.class("text-center mt-4")) {
            a(
              .class("btn btn-primary btn-lg"),
              .href(language.path(for: "/workshops/apply"))
            ) {
              language == .ja ? "ワークショップに申し込む" : "Apply for Workshops"
            }
          }
        }
      }
    }
  }
}

/// Individual workshop card component
struct WorkshopCardView: HTML, Sendable {
  let workshop: WorkshopListPageView.WorkshopItem
  let language: CfPLanguage

  var body: some HTML {
    div(
      .class("card h-100"),
      .style("cursor: pointer;"),
      .custom(name: "data-bs-toggle", value: "modal"),
      .custom(name: "data-bs-target", value: "#workshop-\(workshop.id.uuidString)"),
      .custom(name: "role", value: "button"),
      .custom(name: "tabindex", value: "0"),
      .custom(
        name: "onkeydown",
        value: "if(event.key==='Enter'||event.key===' '){this.click();}")
    ) {
      div(.class("card-body")) {
        if let details = workshop.workshopDetails {
          div(.class("mb-2")) {
            span(.class("badge \(languageBadgeClass(details.language))")) {
              HTMLText(details.language.displayName)
            }
          }
        }
        h5(.class("card-title fw-bold")) { HTMLText(workshop.title) }
        p(.class("text-muted small mb-2")) {
          HTMLText(workshop.speakerName)
        }
        p(.class("card-text")) {
          HTMLText(String(workshop.abstract.prefix(200)))
          if workshop.abstract.count > 200 { "..." }
        }
      }
      div(.class("card-footer bg-transparent")) {
        div(.class("d-flex justify-content-between align-items-center")) {
          div {
            span(.class("badge bg-secondary me-1")) {
              HTMLText(
                language == .ja
                  ? "定員: \(workshop.capacity)名"
                  : "Capacity: \(workshop.capacity)")
            }
            if let workshopLanguage = workshop.workshopLanguage {
              span(.class("badge bg-info text-dark")) {
                HTMLText(workshopLanguage.localizedName(for: language))
              }
            }
          }
          span(.class("text-muted small")) {
            HTMLText(
              language == .ja
                ? "\(workshop.applicationCount)名が申し込み済み"
                : "\(workshop.applicationCount) applied")
          }
        }
      }
    }
  }

  private func languageBadgeClass(_ lang: WorkshopLanguage) -> String {
    switch lang {
    case .english: return "bg-primary"
    case .japanese: return "bg-danger"
    case .bilingual: return "bg-info"
    case .other: return "bg-secondary"
    }
  }
}

/// Modal showing full workshop details
struct WorkshopModalView: HTML, Sendable {
  let workshop: WorkshopListPageView.WorkshopItem
  let language: CfPLanguage

  var body: some HTML {
    HTMLRaw(buildModalHTML())
  }

  private var displayTitle: String {
    if language == .ja, let ja = workshop.titleJA, !ja.isEmpty {
      return ja
    }
    return workshop.title
  }

  private var displayAbstract: String {
    if language == .ja, let ja = workshop.abstractJA, !ja.isEmpty {
      return ja
    }
    return workshop.abstract
  }

  private var displayBio: String {
    if language == .ja, let ja = workshop.bioJa, !ja.isEmpty {
      return ja
    }
    return workshop.bio
  }

  private func buildModalHTML() -> String {
    let modalId = "workshop-\(workshop.id.uuidString)"
    var html = ""

    html += """
      <div class="modal fade" id="\(modalId)" tabindex="-1" aria-labelledby="\(modalId)-label" aria-hidden="true">
        <div class="modal-dialog modal-lg modal-dialog-scrollable">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title fw-bold" id="\(modalId)-label">\(escapeHTML(displayTitle))</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
      """

    // Instructor section
    html += "<div class=\"d-flex align-items-start mb-4\">"
    if let iconURL = workshop.iconURL, !iconURL.isEmpty {
      html +=
        "<img src=\"\(escapeHTML(iconURL))\" alt=\"\" class=\"rounded-circle me-3\" style=\"width: 64px; height: 64px; object-fit: cover;\">"
    }
    html += "<div>"
    html += "<h6 class=\"fw-bold mb-1\">\(escapeHTML(workshop.speakerName))</h6>"
    if !workshop.isPaperCallImport, let gh = workshop.githubUsername, !gh.isEmpty {
      html +=
        "<a href=\"https://github.com/\(escapeHTML(gh))\" target=\"_blank\" rel=\"noopener\" class=\"text-muted small me-2\">"
      html += "<span class=\"me-1\">GitHub</span>\(escapeHTML(gh))</a>"
    }
    html +=
      "<p class=\"text-muted small mt-1 mb-0\" style=\"white-space: pre-wrap;\">\(escapeHTML(displayBio))</p>"
    html += "</div></div>"

    // Language badge
    if let details = workshop.workshopDetails {
      html += "<div class=\"mb-3\">"
      html += "<span class=\"badge \(languageBadgeClass(details.language))\">"
      html += escapeHTML(details.language.displayName)
      html += "</span></div>"
    }

    // Full abstract
    html += sectionHTML(
      label: language == .ja ? "説明" : "Description",
      content: displayAbstract
    )

    // Workshop details
    if let details = workshop.workshopDetails {
      html += sectionHTML(
        label: language == .ja ? "学べること" : "Key Takeaways",
        content: details.keyTakeaways
      )

      if let prerequisites = details.prerequisites, !prerequisites.isEmpty {
        html += sectionHTML(
          label: language == .ja ? "前提知識" : "Prerequisites",
          content: prerequisites
        )
      }

      html += sectionHTML(
        label: language == .ja ? "アジェンダ / スケジュール" : "Agenda / Schedule",
        content: details.agendaSchedule
      )

      html += sectionHTML(
        label: language == .ja ? "持ち物" : "What to Bring",
        content: details.participantRequirements
      )

      if let software = details.requiredSoftware, !software.isEmpty {
        html += sectionHTML(
          label: language == .ja ? "必要なソフトウェア" : "Required Software",
          content: software
        )
      }

      html += sectionHTML(
        label: language == .ja ? "ネットワーク要件" : "Network Requirements",
        content: details.networkRequirements
      )
    }

    // Co-instructors
    if let coInstructors = workshop.coInstructors, !coInstructors.isEmpty {
      html += "<hr>"
      html += "<h6 class=\"fw-bold mb-3\">"
      html += language == .ja ? "共同講師" : "Co-Instructors"
      html += "</h6>"
      for instructor in coInstructors {
        html += "<div class=\"d-flex align-items-start mb-3\">"
        if let iconURL = instructor.iconURL, !iconURL.isEmpty {
          html +=
            "<img src=\"\(escapeHTML(iconURL))\" alt=\"\" class=\"rounded-circle me-3\" style=\"width: 48px; height: 48px; object-fit: cover;\">"
        }
        html += "<div>"
        html += "<h6 class=\"fw-bold mb-1\">\(escapeHTML(instructor.name))</h6>"
        if !instructor.githubUsername.isEmpty {
          html +=
            "<a href=\"https://github.com/\(escapeHTML(instructor.githubUsername))\" target=\"_blank\" rel=\"noopener\" class=\"text-muted small me-2\">"
          html += "<span class=\"me-1\">GitHub</span>\(escapeHTML(instructor.githubUsername))</a>"
        }
        if let sns = instructor.sns, !sns.isEmpty {
          html += "<span class=\"text-muted small\">\(escapeHTML(sns))</span>"
        }
        html +=
          "<p class=\"text-muted small mt-1 mb-0\" style=\"white-space: pre-wrap;\">\(escapeHTML(instructor.bio))</p>"
        html += "</div></div>"
      }
    }

    html += """
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                \(language == .ja ? "閉じる" : "Close")
              </button>
            </div>
          </div>
        </div>
      </div>
      """

    return html
  }

  private func sectionHTML(label: String, content: String) -> String {
    var html = "<div class=\"mb-3\">"
    html += "<h6 class=\"fw-bold text-muted small text-uppercase\">\(escapeHTML(label))</h6>"
    html +=
      "<p class=\"mb-0\" style=\"white-space: pre-wrap;\">\(escapeHTML(content))</p>"
    html += "</div>"
    return html
  }

  private func languageBadgeClass(_ lang: WorkshopLanguage) -> String {
    switch lang {
    case .english: return "bg-primary"
    case .japanese: return "bg-danger"
    case .bilingual: return "bg-info"
    case .other: return "bg-secondary"
    }
  }

  private func escapeHTML(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
