import Elementary

/// Generic labelled `<input>` component used across the apply / login forms.
public struct FormField: HTML {
  public let label: String
  public let name: String
  public let value: String
  public let inputType: String
  public let isRequired: Bool

  public init(
    label: String,
    name: String,
    value: String = "",
    inputType: String = "text",
    isRequired: Bool = false
  ) {
    self.label = label
    self.name = name
    self.value = value
    self.inputType = inputType
    self.isRequired = isRequired
  }

  public var body: some HTML {
    div(.class("form-field")) {
      Elementary.label(.for(name)) { label }
      if isRequired {
        input(
          .custom(name: "type", value: inputType),
          .name(name),
          .id(name),
          .value(value),
          .required
        )
      } else {
        input(
          .custom(name: "type", value: inputType),
          .name(name),
          .id(name),
          .value(value)
        )
      }
    }
  }
}

/// `<textarea>` form field.
public struct FormTextArea: HTML {
  public let label: String
  public let name: String
  public let value: String
  public let rows: Int
  public let isRequired: Bool

  public init(
    label: String,
    name: String,
    value: String = "",
    rows: Int = 3,
    isRequired: Bool = false
  ) {
    self.label = label
    self.name = name
    self.value = value
    self.rows = rows
    self.isRequired = isRequired
  }

  public var body: some HTML {
    div(.class("form-field")) {
      Elementary.label(.for(name)) { label }
      if isRequired {
        textarea(
          .name(name),
          .id(name),
          .custom(name: "rows", value: String(rows)),
          .required
        ) { value }
      } else {
        textarea(
          .name(name),
          .id(name),
          .custom(name: "rows", value: String(rows))
        ) { value }
      }
    }
  }
}
