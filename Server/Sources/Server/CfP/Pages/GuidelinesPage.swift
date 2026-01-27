import Elementary
import SharedModels

struct GuidelinesPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage

  init(user: UserDTO?, language: CfPLanguage = .en) {
    self.user = user
    self.language = language
  }

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-4")) {
        language == .ja ? "応募ガイドライン" : "Submission Guidelines"
      }
      p(.class("lead text-muted mb-5")) {
        language == .ja
          ? "try! Swift Tokyo 2026にトークプロポーザルを提出するために必要な情報をまとめました。"
          : "Everything you need to know about submitting a talk proposal for try! Swift Tokyo 2026."
      }

      // What We're Looking For
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) {
            language == .ja ? "私たちが求めているもの" : "What We're Looking For"
          }
          ul(.class("mb-0")) {
            li {
              language == .ja
                ? "他の主要なカンファレンスで発表されていないオリジナルコンテンツ"
                : "Original content that hasn't been presented at other major conferences"
            }
            li {
              language == .ja
                ? "参加者が実際の仕事に活かせる実践的な知識"
                : "Practical knowledge that attendees can apply in their work"
            }
            li {
              language == .ja
                ? "聴衆にとって明確な学習成果"
                : "Clear learning outcomes for the audience"
            }
            li {
              language == .ja
                ? "デモを含む、よく構成されたプレゼンテーション"
                : "Well-structured presentations with demos when applicable"
            }
            li {
              language == .ja
                ? "Swiftコミュニティに関連するトピック"
                : "Topics relevant to the Swift community"
            }
          }
        }
      }

      // Talk Formats
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) {
            language == .ja ? "トーク形式" : "Talk Formats"
          }

          h4(.class("fw-semibold mt-3")) {
            language == .ja ? "レギュラートーク（20分）" : "Regular Talk (20 minutes)"
          }
          p(.class("text-muted")) {
            language == .ja
              ? "トピックを深く掘り下げる包括的なセッションです。コンテキスト、例、重要なポイントを含める時間があります。ライブコーディングやデモも歓迎します！"
              : "A comprehensive session covering a topic in depth. Include time for context, examples, and key takeaways. Live coding and demos are welcome!"
          }

          h4(.class("fw-semibold mt-4")) {
            language == .ja ? "ライトニングトーク（5分）" : "Lightning Talk (5 minutes)"
          }
          p(.class("text-muted mb-0")) {
            language == .ja
              ? "1つのコンセプト、ツール、またはヒントをカバーする、焦点を絞った短いプレゼンテーションです。新しいアイデアの紹介や、ちょっとした発見の共有に最適です。"
              : "A focused, fast-paced presentation covering a single concept, tool, or tip. Perfect for sharing quick wins or introducing new ideas."
          }
        }
      }

      // Proposal Requirements
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) {
            language == .ja ? "プロポーザルの要件" : "Proposal Requirements"
          }

          h4(.class("fw-semibold mt-3")) {
            language == .ja ? "タイトル" : "Title"
          }
          p(.class("text-muted")) {
            language == .ja
              ? "トーク内容を正確に表す、明確で説明的なタイトル。"
              : "A clear, descriptive title that accurately represents your talk content."
          }

          h4(.class("fw-semibold mt-3")) {
            language == .ja ? "概要" : "Abstract"
          }
          p(.class("text-muted")) {
            language == .ja
              ? "トークが採択された場合に公開される2〜3文の要約。参加者が何を学べるかを説明してください。"
              : "A 2-3 sentence summary that will be shown publicly if your talk is accepted. This should explain what attendees will learn."
          }

          h4(.class("fw-semibold mt-3")) {
            language == .ja ? "トークの詳細" : "Talk Details"
          }
          p(.class("text-muted")) {
            language == .ja
              ? "レビュアー向けのトークの詳細な説明。アウトライン、重要なポイント、予定しているデモなどを含めてください。これはあなたのビジョンを理解するのに役立ちます。"
              : "A detailed description of your talk for reviewers. Include your outline, key points, and any demos you plan to show. This helps us understand your vision."
          }

          h4(.class("fw-semibold mt-3")) {
            language == .ja ? "スピーカー自己紹介" : "Speaker Bio"
          }
          p(.class("text-muted")) {
            language == .ja
              ? "あなたについて教えてください！経歴、経験、このトピックに興味を持った理由などを書いてください。"
              : "Tell us about yourself! Your background, experience, and what makes you excited about this topic."
          }

          h4(.class("fw-semibold mt-3")) {
            language == .ja ? "備考（任意）" : "Notes (Optional)"
          }
          p(.class("text-muted mb-0")) {
            language == .ja
              ? "主催者への追加情報。アクセシビリティの要件、スケジュールの制約、以前にこのトークを行ったことがあるかどうかなど。"
              : "Any additional information for organizers, such as accessibility needs, scheduling constraints, or whether you've given this talk before."
          }
        }
      }

      // Selection Criteria
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) {
            language == .ja ? "選考基準" : "Selection Criteria"
          }
          p {
            language == .ja
              ? "レビュー委員会は以下の基準でプロポーザルを評価します："
              : "Our review committee evaluates proposals based on:"
          }
          ul(.class("mb-0")) {
            li {
              language == .ja ? "Swiftコミュニティへの関連性" : "Relevance to the Swift community"
            }
            li {
              language == .ja ? "コンテンツの独自性とユニークさ" : "Originality and uniqueness of content"
            }
            li {
              language == .ja ? "プロポーザルと学習成果の明確さ" : "Clarity of proposal and learning outcomes"
            }
            li {
              language == .ja ? "スピーカーの専門知識とプレゼンテーション能力" : "Speaker's expertise and presentation ability"
            }
            li {
              language == .ja ? "カンファレンスプログラム全体でのトピックの多様性" : "Diversity of topics across the conference program"
            }
          }
        }
      }

      // Tips for Success
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) {
            language == .ja ? "素晴らしいプロポーザルのためのヒント" : "Tips for a Great Proposal"
          }
          ul(.class("mb-0")) {
            li {
              language == .ja ? "参加者が何を学ぶか具体的に書く" : "Be specific about what attendees will learn"
            }
            li {
              language == .ja ? "明確なアウトラインや構成を含める" : "Include a clear outline or structure"
            }
            li {
              language == .ja ? "デモやライブコーディングの予定があれば記載する" : "Mention any demos or live coding"
            }
            li {
              language == .ja ? "トピックへの情熱を示す" : "Show your passion for the topic"
            }
            li {
              language == .ja ? "提出前によく校正する" : "Proofread your submission carefully"
            }
            li {
              language == .ja ? "複数のプロポーザルを提出することをためらわない！" : "Don't be afraid to submit multiple proposals!"
            }
          }
        }
      }

      // Speaker Benefits
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) {
            language == .ja ? "スピーカー特典" : "Speaker Benefits"
          }
          ul(.class("mb-0")) {
            li {
              language == .ja ? "カンファレンスチケット無料" : "Free conference ticket"
            }
            li {
              language == .ja ? "他のスピーカーや主催者とのスピーカーディナー" : "Speaker dinner with other speakers and organizers"
            }
            li {
              language == .ja ? "海外からのスピーカーには渡航サポートあり" : "Travel support available for international speakers"
            }
            li {
              language == .ja ? "トークのプロフェッショナルなビデオ撮影" : "Professional video recording of your talk"
            }
            li {
              language == .ja ? "世界中のSwift開発者とのネットワーキングの機会" : "Networking opportunities with Swift developers worldwide"
            }
          }
        }
      }

      // CTA
      div(.class("text-center mt-5")) {
        a(.class("btn btn-primary btn-lg"), .href(language.path(for: "/submit"))) {
          language == .ja ? "プロポーザルを提出する" : "Submit Your Proposal"
        }
      }
    }
  }
}
