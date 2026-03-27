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
    let speakerName: String
    let abstract: String
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
    div(.class("card h-100")) {
      div(.class("card-body")) {
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
}
