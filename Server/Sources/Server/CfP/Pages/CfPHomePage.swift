import Elementary
import SharedModels

struct CfPHomePage: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage

  init(user: UserDTO?, language: CfPLanguage = .en) {
    self.user = user
    self.language = language
  }

  var body: some HTML {
    // Hero Section
    section(.class("hero-section text-center py-5")) {
      div(.class("container py-5")) {
        p(.class("text-white-50 fs-5 mb-2")) { "try! Swift Tokyo 2026" }
        h1(.class("display-3 fw-bold text-white mb-3")) {
          language == .ja ? "プロポーザル募集" : "Call for Proposals"
        }
        p(.class("lead text-white-50 mb-4 mx-auto"), .style("max-width: 600px;")) {
          language == .ja
            ? "あなたのSwiftの知識を世界中の開発者と共有しませんか？try! Swift Tokyo 2026でトークプロポーザルを提出してください！"
            : "Share your Swift expertise with developers from around the world. Submit your talk proposal for try! Swift Tokyo 2026!"
        }
        div(.class("d-flex gap-3 justify-content-center flex-wrap")) {
          a(.class("btn btn-light btn-lg fw-bold"), .href(language.path(for: "/submit"))) {
            language == .ja ? "プロポーザルを提出する" : "Submit Your Proposal"
          }
          a(.class("btn btn-outline-light btn-lg"), .href(language.path(for: "/guidelines"))) {
            language == .ja ? "ガイドラインを見る" : "View Guidelines"
          }
          a(
            .class("btn btn-outline-light btn-lg"), .href(language.path(for: "/my-proposals"))
          ) {
            CfPStrings.Home.myProposals(language)
          }
          if user?.role == .admin {
            a(.class("btn btn-outline-light btn-lg"), .href("/organizer/proposals")) {
              CfPStrings.Home.allProposals(language)
            }
          }
        }
      }
    }

    // Important Dates Section
    section(.class("py-5")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) {
          language == .ja ? "重要な日程" : "Important Dates"
        }
        div(.class("row g-4")) {
          dateCard(
            emoji: "📅",
            title: language == .ja ? "CfP開始" : "CfP Opens",
            date: language == .ja ? "2026年1月15日" : "January 15, 2026"
          )
          dateCard(
            emoji: "⏰",
            title: language == .ja ? "応募締切" : "Submission Deadline",
            date: language == .ja ? "2026年2月1日" : "February 1, 2026"
          )
          dateCard(
            emoji: "📣",
            title: language == .ja ? "結果発表" : "Notifications",
            date: language == .ja ? "2026年2月8日" : "February 8, 2026"
          )
          dateCard(
            emoji: "🎤",
            title: language == .ja ? "カンファレンス" : "Conference",
            date: language == .ja ? "2026年4月12-14日" : "April 12-14, 2026"
          )
        }
      }
    }

    // Talk Formats Section
    section(.class("py-5 bg-light")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) {
          language == .ja ? "トークの形式" : "Talk Formats"
        }
        div(.class("row g-4")) {
          div(.class("col-md-6")) {
            div(.class("card h-100")) {
              div(.class("card-body text-center p-4")) {
                h3(.class("fw-bold")) { "🎯 \(language == .ja ? "レギュラートーク" : "Regular Talk")" }
                p(.class("lead text-muted")) {
                  language == .ja ? "20分" : "20 minutes"
                }
                p(.class("mt-3")) {
                  language == .ja
                    ? "特定のトピックについて詳しく解説し、具体的な例やライブデモを交えてお話しください。Swiftの開発に関する包括的な知識を共有するのに最適です。"
                    : "Deep dive into a specific topic with detailed examples and live demos. Perfect for sharing comprehensive knowledge about Swift development."
                }
              }
            }
          }
          div(.class("col-md-6")) {
            div(.class("card h-100")) {
              div(.class("card-body text-center p-4")) {
                h3(.class("fw-bold")) { "⚡ \(language == .ja ? "ライトニングトーク" : "Lightning Talk")" }
                p(.class("lead text-muted")) {
                  language == .ja ? "5分" : "5 minutes"
                }
                p(.class("mt-3")) {
                  language == .ja
                    ? "1つのアイデア、ヒント、ツールに焦点を当てた短くて集中したプレゼンテーションです。初めての登壇者や、ちょっとしたアイデアの共有に最適です！"
                    : "Quick, focused presentation on a single idea, tip, or tool. Great for first-time speakers or sharing quick wins!"
                }
              }
            }
          }
        }
      }
    }

    // Topics Section
    section(.class("py-5")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) {
          language == .ja ? "募集しているトピック" : "Topics We're Looking For"
        }
        div(.class("row g-4")) {
          topicCard(
            title: language == .ja ? "Swift言語" : "Swift Language",
            description: language == .ja
              ? "新機能、ベストプラクティス、言語の進化" : "New features, best practices, and language evolution"
          )
          topicCard(
            title: "SwiftUI",
            description: language == .ja
              ? "モダンなUI開発、アニメーション、アーキテクチャ" : "Modern UI development, animations, and architecture"
          )
          topicCard(
            title: "iOS/macOS/visionOS",
            description: language == .ja
              ? "プラットフォーム固有の開発とAPI" : "Platform-specific development and APIs"
          )
          topicCard(
            title: language == .ja ? "サーバーサイドSwift" : "Server-Side Swift",
            description: language == .ja
              ? "Vapor、バックエンド開発、クラウドデプロイメント" : "Vapor, backend development, and cloud deployment"
          )
          topicCard(
            title: language == .ja ? "テストと品質" : "Testing & Quality",
            description: language == .ja
              ? "ユニットテスト、UIテスト、コード品質" : "Unit testing, UI testing, and code quality"
          )
          topicCard(
            title: language == .ja ? "ツールと生産性" : "Tools & Productivity",
            description: language == .ja
              ? "Xcode、デバッグ、開発者体験" : "Xcode, debugging, and developer experience"
          )
        }
      }
    }

    // CTA Section
    section(.class("py-5 bg-purple text-center")) {
      div(.class("container py-4")) {
        h2(.class("fw-bold text-white mb-3")) {
          language == .ja ? "あなたの知識を共有しませんか？" : "Ready to Share Your Knowledge?"
        }
        p(.class("lead text-white-50 mb-4")) {
          language == .ja
            ? "経験レベルに関係なく、すべてのスピーカーを歓迎します。初めての登壇者の方も、ぜひご応募ください！"
            : "We welcome speakers of all experience levels. First-time speakers are encouraged to apply!"
        }
        a(.class("btn btn-light btn-lg fw-bold"), .href(language.path(for: "/submit"))) {
          language == .ja ? "プロポーザルを提出する" : "Submit Your Proposal"
        }
      }
    }
  }

  @HTMLBuilder
  private func dateCard(emoji: String, title: String, date: String) -> some HTML {
    div(.class("col-md-3 col-sm-6")) {
      div(.class("card text-center h-100")) {
        div(.class("card-body")) {
          p(.class("fs-1 mb-2")) { emoji }
          h5(.class("fw-semibold")) { title }
          p(.class("text-muted mb-0")) { date }
        }
      }
    }
  }

  @HTMLBuilder
  private func topicCard(title: String, description: String) -> some HTML {
    div(.class("col-md-4 col-sm-6")) {
      div(.class("card h-100")) {
        div(.class("card-body text-center")) {
          h5(.class("fw-semibold")) { title }
          p(.class("text-muted mb-0")) { description }
        }
      }
    }
  }
}
