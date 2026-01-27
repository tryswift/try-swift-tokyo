import Elementary
import SharedModels

struct CfPHomePage: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage

  var body: some HTML {
    // Hero Section
    section(.class("hero-section text-center py-5")) {
      div(.class("container py-5")) {
        p(.class("text-white-50 fs-5 mb-2")) { CfPStrings.Home.heroSubtitle(language) }
        h1(.class("display-3 fw-bold text-white mb-3")) { CfPStrings.Home.heroTitle(language) }
        p(.class("lead text-white-50 mb-4 mx-auto"), .style("max-width: 600px;")) {
          CfPStrings.Home.heroDescription(language)
        }
        div(.class("d-flex gap-3 justify-content-center flex-wrap")) {
          a(.class("btn btn-light btn-lg fw-bold"), .href("/cfp/\(language.urlPrefix)/submit")) {
            CfPStrings.Home.submitYourProposal(language)
          }
          a(.class("btn btn-outline-light btn-lg"), .href("/cfp/\(language.urlPrefix)/guidelines"))
          {
            CfPStrings.Home.viewGuidelines(language)
          }
          a(.class("btn btn-outline-light btn-lg"), .href("/cfp/\(language.urlPrefix)/my-proposals"))
          {
            CfPStrings.Home.myProposals(language)
          }
          if user?.role == .admin {
            a(.class("btn btn-outline-light btn-lg"), .href("/cfp/organizer/proposals")) {
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
          CfPStrings.Home.importantDates(language)
        }
        div(.class("row g-4")) {
          dateCard(
            emoji: "📅",
            title: CfPStrings.Home.cfpOpens(language),
            date: CfPStrings.Home.cfpOpensDate(language)
          )
          dateCard(
            emoji: "⏰",
            title: CfPStrings.Home.submissionDeadline(language),
            date: CfPStrings.Home.submissionDeadlineDate(language)
          )
          dateCard(
            emoji: "📣",
            title: CfPStrings.Home.notifications(language),
            date: CfPStrings.Home.notificationsDate(language)
          )
          dateCard(
            emoji: "🎤",
            title: CfPStrings.Home.conference(language),
            date: CfPStrings.Home.conferenceDate(language)
          )
        }
      }
    }

    // Talk Formats Section
    section(.class("py-5 bg-light")) {
      div(.class("container")) {
        h2(.class("text-center fw-bold purple-text mb-5")) { CfPStrings.Home.talkFormats(language) }
        div(.class("row g-4")) {
          div(.class("col-md-6")) {
            div(.class("card h-100")) {
              div(.class("card-body text-center p-4")) {
                h3(.class("fw-bold")) { "🎯 \(CfPStrings.Home.regularTalk(language))" }
                p(.class("lead text-muted")) { CfPStrings.Home.regularTalkDuration(language) }
                p(.class("mt-3")) {
                  CfPStrings.Home.regularTalkDescription(language)
                }
              }
            }
          }
          div(.class("col-md-6")) {
            div(.class("card h-100")) {
              div(.class("card-body text-center p-4")) {
                h3(.class("fw-bold")) { "⚡ \(CfPStrings.Home.lightningTalk(language))" }
                p(.class("lead text-muted")) { CfPStrings.Home.lightningTalkDuration(language) }
                p(.class("mt-3")) {
                  CfPStrings.Home.lightningTalkDescription(language)
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
        h2(.class("text-center fw-bold purple-text mb-5")) { CfPStrings.Home.topicsTitle(language) }
        div(.class("row g-4")) {
          topicCard(
            title: CfPStrings.Home.topicSwiftLanguage(language),
            description: CfPStrings.Home.topicSwiftLanguageDesc(language)
          )
          topicCard(
            title: CfPStrings.Home.topicSwiftUI(language),
            description: CfPStrings.Home.topicSwiftUIDesc(language)
          )
          topicCard(
            title: CfPStrings.Home.topicPlatforms(language),
            description: CfPStrings.Home.topicPlatformsDesc(language)
          )
          topicCard(
            title: CfPStrings.Home.topicServerSide(language),
            description: CfPStrings.Home.topicServerSideDesc(language)
          )
          topicCard(
            title: CfPStrings.Home.topicTesting(language),
            description: CfPStrings.Home.topicTestingDesc(language)
          )
          topicCard(
            title: CfPStrings.Home.topicTools(language),
            description: CfPStrings.Home.topicToolsDesc(language)
          )
        }
      }
    }

    // CTA Section
    section(.class("py-5 bg-purple text-center")) {
      div(.class("container py-4")) {
        h2(.class("fw-bold text-white mb-3")) { CfPStrings.Home.ctaTitle(language) }
        p(.class("lead text-white-50 mb-4")) {
          CfPStrings.Home.ctaDescription(language)
        }
        a(.class("btn btn-light btn-lg fw-bold"), .href("/cfp/\(language.urlPrefix)/submit")) {
          CfPStrings.Home.submitYourProposal(language)
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
