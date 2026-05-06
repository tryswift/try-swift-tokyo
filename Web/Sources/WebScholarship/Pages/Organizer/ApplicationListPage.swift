import Elementary
import SharedModels

public struct ApplicationListPage: HTML {
  public let locale: ScholarshipPortalLocale
  public let applications: [ScholarshipApplicationDTO]
  public let budget: ScholarshipBudgetSummaryDTO?

  public init(
    locale: ScholarshipPortalLocale,
    applications: [ScholarshipApplicationDTO],
    budget: ScholarshipBudgetSummaryDTO?
  ) {
    self.locale = locale
    self.applications = applications
    self.budget = budget
  }

  public var body: some HTML {
    ScholarshipLayout(
      pageTitle: ScholarshipStrings.t(.orgListTitle, locale),
      locale: locale,
      isAuthenticated: true,
      isOrganizer: true
    ) {
      h1 { ScholarshipStrings.t(.orgListTitle, locale) }

      section(.class("budget-summary")) {
        if let budget {
          dl {
            dt { ScholarshipStrings.t(.infoBudgetTotal, locale) }
            dd {
              if let t = budget.totalBudget {
                "¥\(t)"
              } else {
                ScholarshipStrings.t(.infoBudgetNotSet, locale)
              }
            }
            dt { ScholarshipStrings.t(.infoBudgetApproved, locale) }
            dd { "¥\(budget.approvedTotal)" }
            if let r = budget.remaining {
              dt { ScholarshipStrings.t(.infoBudgetRemaining, locale) }
              dd { "¥\(r)" }
            }
          }
          a(.href("/organizer/budget")) { ScholarshipStrings.t(.orgBudgetTitle, locale) }
        }
      }

      div(.class("toolbar")) {
        a(.href("/organizer/export")) { ScholarshipStrings.t(.orgExportCSV, locale) }
      }

      table(.class("applications")) {
        thead {
          tr {
            th { "#" }
            th { ScholarshipStrings.t(.applyNameLabel, locale) }
            th { ScholarshipStrings.t(.applySchoolLabel, locale) }
            th { ScholarshipStrings.t(.applySupportTypeLabel, locale) }
            th { ScholarshipStrings.t(.myAppStatusLabel, locale) }
            th { ScholarshipStrings.t(.myAppApprovedAmount, locale) }
            th { "" }
          }
        }
        tbody {
          for app in applications {
            tr {
              td { String(app.id.uuidString.prefix(8)) }
              td { app.name }
              td { app.schoolAndFaculty }
              td {
                locale == .ja ? app.supportType.displayNameJa : app.supportType.displayName
              }
              td { StatusBadge(status: app.status, locale: locale) }
              td { app.approvedAmount.map { "¥\($0)" } ?? "—" }
              td {
                a(.href("/organizer/\(app.id.uuidString)")) {
                  ScholarshipStrings.t(.orgDetailTitle, locale)
                }
              }
            }
          }
        }
      }
    }
  }
}
