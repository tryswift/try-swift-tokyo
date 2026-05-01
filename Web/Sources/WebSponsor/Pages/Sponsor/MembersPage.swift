import Elementary
import SharedModels

public struct MembersPage: HTML {
  public struct MemberRow: Sendable {
    public let userID: String
    public let email: String
    public let role: SponsorMemberRole
    public init(userID: String, email: String, role: SponsorMemberRole) {
      self.userID = userID
      self.email = email
      self.role = role
    }
  }

  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let members: [MemberRow]
  public let isOwner: Bool
  public let flash: String?

  public init(
    locale: SponsorPortalLocale, csrfToken: String,
    members: [MemberRow], isOwner: Bool, flash: String? = nil
  ) {
    self.locale = locale
    self.csrfToken = csrfToken
    self.members = members
    self.isOwner = isOwner
    self.flash = flash
  }

  public var body: some HTML {
    PortalLayout(
      pageTitle: PortalStrings.t(.teamTitle, locale),
      locale: locale, isAuthenticated: true, flash: flash
    ) {
      h1 { PortalStrings.t(.teamTitle, locale) }
      ul {
        for m in members {
          li {
            "\(m.email) (\(m.role.rawValue))"
            if isOwner && m.role != .owner {
              form(.method(.post), .action("/team/\(m.userID)/remove")) {
                input(.type(.hidden), .name("_csrf"), .value(csrfToken))
                button(.type(.submit)) { locale == .ja ? "削除" : "Remove" }
              }
            }
          }
        }
      }
      if isOwner {
        h2 { locale == .ja ? "メンバーを招待" : "Invite member" }
        form(.method(.post), .action("/team/invite")) {
          input(.type(.hidden), .name("_csrf"), .value(csrfToken))
          FormField(label: "Email", name: "email", inputType: "email", isRequired: true)
          button(.type(.submit)) { locale == .ja ? "招待" : "Invite" }
        }
      }
    }
  }
}
