import Elementary

/// Required agreement checkbox used in the form's section 7.
public struct AgreementCheckbox: HTML {
  public let label: String
  public let name: String
  public let isChecked: Bool

  public init(label: String, name: String, isChecked: Bool = false) {
    self.label = label
    self.name = name
    self.isChecked = isChecked
  }

  public var body: some HTML {
    div(.class("agreement")) {
      Elementary.label {
        if isChecked {
          input(
            .custom(name: "type", value: "checkbox"),
            .name(name),
            .value("true"),
            .required,
            .checked
          )
        } else {
          input(
            .custom(name: "type", value: "checkbox"),
            .name(name),
            .value("true"),
            .required
          )
        }
        " \(label)"
      }
    }
  }
}
