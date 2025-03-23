extension String {
  func convertNewlines() -> String {
    replacingOccurrences(of: "\n\n", with: "\n<br>")
      .replacingOccurrences(of: "\n", with: "  \n")
  }
}
