import Elementary

public struct Toast: HTML {
  public let kind: String
  public let message: String
  public init(kind: String = "info", message: String) {
    self.kind = kind
    self.message = message
  }
  public var body: some HTML {
    div(.class("toast toast-\(kind)")) { message }
  }
}
