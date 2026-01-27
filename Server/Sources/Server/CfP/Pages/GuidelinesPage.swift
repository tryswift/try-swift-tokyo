import Elementary
import SharedModels

struct GuidelinesPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage

  var body: some HTML {
    div(.class("container py-5")) {
      h1(.class("fw-bold mb-4")) { CfPStrings.Guidelines.title(language) }
      p(.class("lead text-muted mb-5")) {
        CfPStrings.Guidelines.subtitle(language)
      }

      // What We're Looking For
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { CfPStrings.Guidelines.whatWereLookingFor(language) }
          ul(.class("mb-0")) {
            li { CfPStrings.Guidelines.lookingForItem1(language) }
            li { CfPStrings.Guidelines.lookingForItem2(language) }
            li { CfPStrings.Guidelines.lookingForItem3(language) }
            li { CfPStrings.Guidelines.lookingForItem4(language) }
            li { CfPStrings.Guidelines.lookingForItem5(language) }
          }
        }
      }

      // Talk Formats
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { CfPStrings.Guidelines.talkFormats(language) }

          h4(.class("fw-semibold mt-3")) { CfPStrings.Guidelines.regularTalkTitle(language) }
          p(.class("text-muted")) {
            CfPStrings.Guidelines.regularTalkDesc(language)
          }

          h4(.class("fw-semibold mt-4")) { CfPStrings.Guidelines.lightningTalkTitle(language) }
          p(.class("text-muted mb-0")) {
            CfPStrings.Guidelines.lightningTalkDesc(language)
          }
        }
      }

      // Proposal Requirements
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { CfPStrings.Guidelines.proposalRequirements(language) }

          h4(.class("fw-semibold mt-3")) { CfPStrings.Guidelines.reqTitleLabel(language) }
          p(.class("text-muted")) {
            CfPStrings.Guidelines.reqTitleDesc(language)
          }

          h4(.class("fw-semibold mt-3")) { CfPStrings.Guidelines.reqAbstractLabel(language) }
          p(.class("text-muted")) {
            CfPStrings.Guidelines.reqAbstractDesc(language)
          }

          h4(.class("fw-semibold mt-3")) { CfPStrings.Guidelines.reqTalkDetailsLabel(language) }
          p(.class("text-muted")) {
            CfPStrings.Guidelines.reqTalkDetailsDesc(language)
          }

          h4(.class("fw-semibold mt-3")) { CfPStrings.Guidelines.reqSpeakerBioLabel(language) }
          p(.class("text-muted")) {
            CfPStrings.Guidelines.reqSpeakerBioDesc(language)
          }

          h4(.class("fw-semibold mt-3")) { CfPStrings.Guidelines.reqNotesLabel(language) }
          p(.class("text-muted mb-0")) {
            CfPStrings.Guidelines.reqNotesDesc(language)
          }
        }
      }

      // Selection Criteria
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { CfPStrings.Guidelines.selectionCriteria(language) }
          p { CfPStrings.Guidelines.selectionCriteriaIntro(language) }
          ul(.class("mb-0")) {
            li { CfPStrings.Guidelines.criteriaItem1(language) }
            li { CfPStrings.Guidelines.criteriaItem2(language) }
            li { CfPStrings.Guidelines.criteriaItem3(language) }
            li { CfPStrings.Guidelines.criteriaItem4(language) }
            li { CfPStrings.Guidelines.criteriaItem5(language) }
          }
        }
      }

      // Tips for Success
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { CfPStrings.Guidelines.tipsTitle(language) }
          ul(.class("mb-0")) {
            li { CfPStrings.Guidelines.tipItem1(language) }
            li { CfPStrings.Guidelines.tipItem2(language) }
            li { CfPStrings.Guidelines.tipItem3(language) }
            li { CfPStrings.Guidelines.tipItem4(language) }
            li { CfPStrings.Guidelines.tipItem5(language) }
            li { CfPStrings.Guidelines.tipItem6(language) }
          }
        }
      }

      // Speaker Benefits
      div(.class("card mb-4")) {
        div(.class("card-body p-4")) {
          h2(.class("fw-bold mb-3")) { CfPStrings.Guidelines.speakerBenefits(language) }
          ul(.class("mb-0")) {
            li { CfPStrings.Guidelines.benefitItem1(language) }
            li { CfPStrings.Guidelines.benefitItem2(language) }
            li { CfPStrings.Guidelines.benefitItem3(language) }
            li { CfPStrings.Guidelines.benefitItem4(language) }
            li { CfPStrings.Guidelines.benefitItem5(language) }
          }
        }
      }

      // CTA
      div(.class("text-center mt-5")) {
        a(.class("btn btn-primary btn-lg"), .href("/cfp/\(language.urlPrefix)/submit")) {
          CfPStrings.Home.submitYourProposal(language)
        }
      }
    }
  }
}
