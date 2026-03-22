import Elementary
import Foundation
import SharedModels

struct MyProposalDetailPageView: HTML, Sendable {
  let user: UserDTO?
  let proposal: ProposalDTO?
  let language: CfPLanguage
  let showUpdatedMessage: Bool
  let csrfToken: String

  init(
    user: UserDTO?, proposal: ProposalDTO?, language: CfPLanguage = .en,
    showUpdatedMessage: Bool = false,
    csrfToken: String = ""
  ) {
    self.user = user
    self.proposal = proposal
    self.language = language
    self.showUpdatedMessage = showUpdatedMessage
    self.csrfToken = csrfToken
  }

  var body: some HTML {
    div(.class("container py-5")) {
      if user != nil {
        if let proposal {
          // Back button
          div(.class("mb-4")) {
            a(.class("btn btn-outline-secondary"), .href(language.path(for: "/my-proposals"))) {
              language == .ja ? "← プロポーザル一覧に戻る" : "← Back to My Proposals"
            }
          }

          // Success message
          if showUpdatedMessage {
            div(
              .class("alert alert-success alert-dismissible fade show mb-4"),
              .custom(name: "role", value: "alert")
            ) {
              language == .ja ? "プロポーザルが更新されました。" : "Proposal updated successfully."
              button(
                .type(.button), .class("btn-close"),
                .custom(name: "data-bs-dismiss", value: "alert")
              ) {}
            }
          }

          // Header
          div(.class("d-flex justify-content-between align-items-start mb-4")) {
            div {
              h1(.class("fw-bold mb-2")) { HTMLText(proposal.title) }
              div(.class("d-flex align-items-center gap-3")) {
                span(
                  .class(
                    {
                      switch proposal.talkDuration {
                      case .regular: return "badge bg-primary fs-6"
                      case .workshop: return "badge bg-success fs-6"
                      case .invited: return "badge bg-dark fs-6"
                      case .lightning: return "badge bg-warning text-dark fs-6"
                      }
                    }())
                ) {
                  HTMLText(
                    language == .ja
                      ? ({
                        switch proposal.talkDuration {
                        case .regular: return "レギュラートーク"
                        case .workshop: return "ワークショップ"
                        case .lightning: return "ライトニングトーク"
                        case .invited: return "招待トーク"
                        }
                      }())
                      : proposal.talkDuration.displayName)
                }
                span(.class("text-muted")) {
                  HTMLText(proposal.conferenceDisplayName)
                }
              }
            }
            // Action buttons
            div(.class("d-flex gap-2")) {
              a(
                .class("btn btn-outline-primary"),
                .href(language.path(for: "/my-proposals/\(proposal.id.uuidString)/edit"))
              ) {
                language == .ja ? "編集" : "Edit"
              }
              button(
                .type(.button),
                .class("btn btn-outline-danger"),
                .custom(name: "data-bs-toggle", value: "modal"),
                .custom(name: "data-bs-target", value: "#withdrawModal")
              ) {
                language == .ja ? "取り下げ" : "Withdraw"
              }
            }
          }

          // Speaker info card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { language == .ja ? "スピーカー情報" : "Speaker Information" }
            }
            div(.class("card-body")) {
              div(.class("d-flex align-items-center mb-3")) {
                if let iconURL = proposal.iconURL {
                  img(
                    .src(iconURL),
                    .alt(proposal.speakerUsername),
                    .class("rounded-circle me-3"),
                    .style("width: 64px; height: 64px;")
                  )
                } else {
                  img(
                    .src("https://github.com/identicons/\(proposal.speakerUsername).png"),
                    .alt(proposal.speakerUsername),
                    .class("rounded-circle me-3"),
                    .style("width: 64px; height: 64px;")
                  )
                }
                div {
                  h5(.class("mb-1")) { HTMLText(proposal.speakerName) }
                  p(.class("text-muted mb-1 small")) { HTMLText(proposal.speakerEmail) }
                  a(
                    .href("https://github.com/\(proposal.speakerUsername)"),
                    .target(.blank),
                    .class("text-muted small")
                  ) {
                    language == .ja ? "GitHubプロフィールを見る" : "View GitHub Profile"
                  }
                }
              }
              h6(.class("fw-bold mb-2")) { language == .ja ? "自己紹介" : "Bio" }
              p(.class("mb-0"), .style("white-space: pre-wrap;")) { HTMLText(proposal.bio) }
            }
          }

          // Abstract card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { language == .ja ? "概要" : "Abstract" }
            }
            div(.class("card-body")) {
              p(.class("mb-0"), .style("white-space: pre-wrap;")) {
                HTMLText(proposal.abstract)
              }
            }
          }

          // Talk details card
          div(.class("card mb-4")) {
            div(.class("card-header")) {
              strong { language == .ja ? "トーク詳細（レビュアー向け）" : "Talk Details (for reviewers)" }
            }
            div(.class("card-body")) {
              p(.class("mb-0"), .style("white-space: pre-wrap;")) {
                HTMLText(proposal.talkDetail)
              }
            }
          }

          // Workshop details card (if applicable)
          if let workshop = proposal.workshopDetails {
            div(.class("card mb-4 border-success")) {
              div(.class("card-header bg-success text-white")) {
                strong { language == .ja ? "ワークショップ詳細" : "Workshop Details" }
              }
              div(.class("card-body")) {
                dl(.class("row mb-0")) {
                  dt(.class("col-sm-3")) { language == .ja ? "言語" : "Language" }
                  dd(.class("col-sm-9")) { HTMLText(workshop.language.displayName) }

                  dt(.class("col-sm-3")) { language == .ja ? "講師数" : "Number of Tutors" }
                  dd(.class("col-sm-9")) { HTMLText("\(workshop.numberOfTutors)") }

                  dt(.class("col-sm-3")) { language == .ja ? "主な学び" : "Key Takeaways" }
                  dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                    HTMLText(workshop.keyTakeaways)
                  }

                  if let prerequisites = workshop.prerequisites, !prerequisites.isEmpty {
                    dt(.class("col-sm-3")) { language == .ja ? "前提条件" : "Prerequisites" }
                    dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                      HTMLText(prerequisites)
                    }
                  }

                  dt(.class("col-sm-3")) {
                    language == .ja ? "アジェンダ / スケジュール" : "Agenda / Schedule"
                  }
                  dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                    HTMLText(workshop.agendaSchedule)
                  }

                  dt(.class("col-sm-3")) { language == .ja ? "参加者要件" : "Participant Requirements" }
                  dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                    HTMLText(workshop.participantRequirements)
                  }

                  if let software = workshop.requiredSoftware, !software.isEmpty {
                    dt(.class("col-sm-3")) { language == .ja ? "必要なソフトウェア" : "Required Software" }
                    dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) { HTMLText(software) }
                  }

                  dt(.class("col-sm-3")) { language == .ja ? "ネットワーク要件" : "Network Requirements" }
                  dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                    HTMLText(workshop.networkRequirements)
                  }

                  if !workshop.requiredFacilities.isEmpty {
                    dt(.class("col-sm-3")) { language == .ja ? "必要な設備" : "Required Facilities" }
                    dd(.class("col-sm-9")) {
                      HTMLText(
                        workshop.requiredFacilities.map(\.displayName).joined(separator: ", "))
                    }
                  }

                  if let facilityOther = workshop.facilityOther, !facilityOther.isEmpty {
                    dt(.class("col-sm-3")) { language == .ja ? "その他の設備" : "Other Facilities" }
                    dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                      HTMLText(facilityOther)
                    }
                  }

                  dt(.class("col-sm-3")) { language == .ja ? "動機" : "Motivation" }
                  dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                    HTMLText(workshop.motivation)
                  }

                  dt(.class("col-sm-3")) { language == .ja ? "独自性" : "Uniqueness" }
                  dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                    HTMLText(workshop.uniqueness)
                  }

                  if let risks = workshop.potentialRisks, !risks.isEmpty {
                    dt(.class("col-sm-3")) { language == .ja ? "潜在的リスク" : "Potential Risks" }
                    dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) { HTMLText(risks) }
                  }
                }
              }
            }
          }

          // Co-instructors card (if applicable)
          if let coInstructors = proposal.coInstructors, !coInstructors.isEmpty {
            div(.class("card mb-4 border-success")) {
              div(.class("card-header bg-success text-white")) {
                strong {
                  language == .ja ? "共同講師" : "Co-Instructors"
                }
              }
              div(.class("card-body")) {
                for (index, instructor) in coInstructors.enumerated() {
                  if index > 0 {
                    hr()
                  }
                  div(.class("d-flex align-items-center mb-3")) {
                    if let iconURL = instructor.iconURL {
                      img(
                        .src(iconURL),
                        .alt(instructor.name),
                        .class("rounded-circle me-3"),
                        .style("width: 48px; height: 48px;")
                      )
                    }
                    div {
                      h6(.class("mb-1 fw-bold")) { HTMLText(instructor.name) }
                      p(.class("text-muted mb-0 small")) { HTMLText(instructor.email) }
                    }
                  }
                  dl(.class("row mb-0")) {
                    dt(.class("col-sm-3")) { "GitHub" }
                    dd(.class("col-sm-9")) {
                      a(
                        .href("https://github.com/\(instructor.githubUsername)"),
                        .target(.blank)
                      ) {
                        HTMLText(instructor.githubUsername)
                      }
                    }
                    if let sns = instructor.sns, !sns.isEmpty {
                      dt(.class("col-sm-3")) { "SNS" }
                      dd(.class("col-sm-9")) { HTMLText(sns) }
                    }
                    dt(.class("col-sm-3")) { language == .ja ? "自己紹介" : "Bio" }
                    dd(.class("col-sm-9"), .style("white-space: pre-wrap;")) {
                      HTMLText(instructor.bio)
                    }
                  }
                }
              }
            }
          }

          // Notes to organizers (if any)
          if let notes = proposal.notes, !notes.isEmpty {
            div(.class("card mb-4 border-warning")) {
              div(.class("card-header bg-warning text-dark")) {
                strong { language == .ja ? "運営者へのメモ" : "Notes to Organizers" }
              }
              div(.class("card-body")) {
                p(.class("mb-0"), .style("white-space: pre-wrap;")) {
                  HTMLText(notes)
                }
              }
            }
          }

          // Metadata card
          div(.class("card")) {
            div(.class("card-header")) {
              strong { language == .ja ? "メタデータ" : "Metadata" }
            }
            div(.class("card-body")) {
              dl(.class("row mb-0")) {
                dt(.class("col-sm-3")) { language == .ja ? "提出日" : "Submitted" }
                dd(.class("col-sm-9")) {
                  if let createdAt = proposal.createdAt {
                    HTMLRaw(
                      "<time class=\"local-time\" datetime=\"\(formatISO(createdAt))\" data-style=\"medium\"></time>"
                    )
                  } else {
                    language == .ja ? "不明" : "Unknown"
                  }
                }
                dt(.class("col-sm-3")) { language == .ja ? "最終更新" : "Last Updated" }
                dd(.class("col-sm-9")) {
                  if let updatedAt = proposal.updatedAt {
                    HTMLRaw(
                      "<time class=\"local-time\" datetime=\"\(formatISO(updatedAt))\" data-style=\"medium\"></time>"
                    )
                  } else {
                    language == .ja ? "なし" : "Never"
                  }
                }
              }
            }
          }

          // Withdraw confirmation modal
          withdrawConfirmModal(proposalID: proposal.id)
        } else {
          // Proposal not found
          div(.class("card")) {
            div(.class("card-body text-center p-5")) {
              h3(.class("fw-bold mb-2")) {
                language == .ja ? "プロポーザルが見つかりません" : "Proposal Not Found"
              }
              p(.class("text-muted mb-4")) {
                language == .ja
                  ? "お探しのプロポーザルは存在しないか、アクセス権限がありません。"
                  : "The proposal you are looking for does not exist or you don't have access to it."
              }
              a(.class("btn btn-primary"), .href(language.path(for: "/my-proposals"))) {
                language == .ja ? "マイプロポーザルに戻る" : "Back to My Proposals"
              }
            }
          }
        }
      } else {
        // Not logged in
        div(.class("card")) {
          div(.class("card-body text-center p-5")) {
            p(.class("fs-1 mb-3")) { "🔐" }
            h3(.class("fw-bold mb-2")) {
              language == .ja ? "ログインが必要です" : "Sign In Required"
            }
            p(.class("text-muted mb-4")) {
              language == .ja
                ? "プロポーザルを確認するにはログインしてください。"
                : "Please sign in to view your proposals."
            }
            a(
              .class("btn btn-dark"),
              .href(AuthURL.login(returnTo: language.path(for: "/my-proposals")))
            ) {
              language == .ja ? "GitHubでログイン" : "Sign in with GitHub"
            }
          }
        }
      }
    }
  }

  private func formatISO(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
  }

  private func withdrawConfirmModal(proposalID: UUID) -> some HTML {
    let title = language == .ja ? "プロポーザルの取り下げ" : "Withdraw Proposal"
    let warning = language == .ja ? "この操作は取り消せません。" : "This action cannot be undone."
    let message =
      language == .ja
      ? "本当にこのプロポーザルを取り下げますか？提出したすべての情報が削除されます。"
      : "Are you sure you want to withdraw this proposal? All submitted information will be permanently deleted."
    let cancelText = language == .ja ? "キャンセル" : "Cancel"
    let withdrawText = language == .ja ? "取り下げる" : "Withdraw"
    let actionURL = language.path(for: "/my-proposals/\(proposalID.uuidString)/withdraw")

    return HTMLRaw(
      """
      <div class="modal fade" id="withdrawModal" tabindex="-1" aria-labelledby="withdrawModalLabel" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="withdrawModalLabel">\(title)</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <p class="text-danger fw-bold">\(warning)</p>
              <p>\(message)</p>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">\(cancelText)</button>
              <form method="post" action="\(actionURL)" style="display: inline;">
                <input type="hidden" name="_csrf" value="\(csrfToken)">
                <button type="submit" class="btn btn-danger">\(withdrawText)</button>
              </form>
            </div>
          </div>
        </div>
      </div>
      """)
  }
}
