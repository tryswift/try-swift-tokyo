import Elementary
import SharedModels

public struct StatusBadge: HTML {
  public let status: SponsorApplicationStatus
  public init(_ s: SponsorApplicationStatus) { self.status = s }
  public var body: some HTML {
    span(.class("status-badge status-\(status.rawValue)")) { status.rawValue }
  }
}
