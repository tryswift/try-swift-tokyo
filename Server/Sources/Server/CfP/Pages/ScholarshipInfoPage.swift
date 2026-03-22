import Elementary
import Foundation
import SharedModels

struct ScholarshipInfoPageView: HTML, Sendable {
  let user: UserDTO?
  let language: CfPLanguage
  let remainingBudget: Int?
  let budgetSet: Bool
  let hasExistingApplication: Bool

  var body: some HTML {
    div(.class("container py-5")) {
      heroSection
      budgetCard
      descriptionSection
      eligibilitySection
      actionSection
    }
  }

  // MARK: - Hero Section

  private var heroSection: some HTML {
    div(.class("text-center mb-5")) {
      h1(.class("display-4 fw-bold mb-3")) {
        language == .ja ? "学生スカラシップ" : "Student Scholarship"
      }
      p(.class("lead text-muted")) {
        language == .ja
          ? "try! Swift Tokyo への参加をサポートします"
          : "Supporting your attendance at try! Swift Tokyo"
      }
    }
  }

  // MARK: - Budget Card

  @HTMLBuilder
  private var budgetCard: some HTML {
    if budgetSet, let remainingBudget {
      div(.class("alert alert-info text-center mb-4")) {
        strong {
          language == .ja
            ? "残り予算: \(formatYen(remainingBudget))円"
            : "Remaining Budget: \(formatYen(remainingBudget)) yen"
        }
      }
    }
  }

  // MARK: - Description Section

  private var descriptionSection: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "プログラム概要" : "Program Overview"
        }
      }
      div(.class("card-body")) {
        p {
          language == .ja
            ? "学生スカラシップは、学生の皆さんが try! Swift Tokyo に参加できるよう支援するプログラムです。以下の費用をサポートします："
            : "The Student Scholarship program supports students in attending try! Swift Tokyo. The following costs may be covered:"
        }
        ul {
          li {
            strong {
              language == .ja ? "参加チケット" : "Conference Ticket"
            }
            " - "
            language == .ja
              ? "カンファレンスへの参加チケットを提供します"
              : "A ticket to attend the conference"
          }
          li {
            strong {
              language == .ja ? "交通費" : "Travel"
            }
            " - "
            language == .ja
              ? "東京までの往復交通費の支援（遠方の方向け）"
              : "Round-trip transportation costs to Tokyo (for those traveling from afar)"
          }
          li {
            strong {
              language == .ja ? "宿泊費" : "Accommodation"
            }
            " - "
            language == .ja
              ? "カンファレンス期間中の宿泊費の支援"
              : "Accommodation costs during the conference"
          }
        }
      }
    }
  }

  // MARK: - Eligibility Section

  private var eligibilitySection: some HTML {
    div(.class("card mb-4")) {
      div(.class("card-header")) {
        strong {
          language == .ja ? "応募資格" : "Eligibility Criteria"
        }
      }
      div(.class("card-body")) {
        ul(.class("mb-0")) {
          li {
            language == .ja
              ? "現在、大学・大学院・専門学校・高等専門学校等に在籍していること"
              : "Currently enrolled in a university, graduate school, vocational school, or technical college"
          }
          li {
            language == .ja
              ? "Swift やプログラミングに興味があること"
              : "Have an interest in Swift and/or programming"
          }
          li {
            language == .ja
              ? "カンファレンスに全日程参加できること"
              : "Be able to attend the conference for the full duration"
          }
          li {
            language == .ja
              ? "行動規範に同意すること"
              : "Agree to the Code of Conduct"
          }
        }
      }
    }
  }

  // MARK: - Action Section

  @HTMLBuilder
  private var actionSection: some HTML {
    div(.class("text-center")) {
      if user != nil {
        if hasExistingApplication {
          a(
            .class("btn btn-outline-primary btn-lg me-2"),
            .href(language.path(for: "/scholarship/my-application"))
          ) {
            language == .ja ? "申請内容を確認する" : "View My Application"
          }
        } else {
          a(
            .class("btn btn-primary btn-lg"),
            .href(language.path(for: "/scholarship/apply"))
          ) {
            language == .ja ? "申請する" : "Apply Now"
          }
        }
      } else {
        a(
          .class("btn btn-dark btn-lg"),
          .href(AuthURL.login(returnTo: language.path(for: "/scholarship")))
        ) {
          language == .ja ? "GitHubでログインして申請" : "Sign in with GitHub to Apply"
        }
      }
    }
  }

  // MARK: - Helpers

  private func formatYen(_ amount: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
  }
}
