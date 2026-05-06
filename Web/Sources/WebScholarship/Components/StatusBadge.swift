import Elementary
import SharedModels

public struct StatusBadge: HTML {
  public let status: ScholarshipApplicationStatus
  public let locale: ScholarshipPortalLocale

  public init(status: ScholarshipApplicationStatus, locale: ScholarshipPortalLocale) {
    self.status = status
    self.locale = locale
  }

  public var body: some HTML {
    span(.class("badge \(status.badgeClass)")) {
      locale == .ja ? status.displayNameJa : status.displayName
    }
  }
}
