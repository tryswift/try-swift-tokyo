/// Validates whether an email address belongs to an educational institution
enum EducationalDomainValidator {
  /// Known educational domain suffixes
  static let educationalSuffixes: [String] = [
    // Japan
    ".ac.jp",
    // US / International
    ".edu",
    ".edu.au",
    ".edu.cn",
    ".edu.tw",
    ".edu.hk",
    ".edu.sg",
    ".edu.my",
    ".edu.in",
    ".edu.ph",
    ".edu.br",
    ".edu.mx",
    ".edu.co",
    // UK
    ".ac.uk",
    // Korea
    ".ac.kr",
    // New Zealand
    ".ac.nz",
    // Thailand
    ".ac.th",
    // Europe
    ".edu.es",
    ".edu.fr",
    ".edu.it",
    ".edu.pl",
    ".ac.at",
    ".ac.be",
  ]

  /// Returns true if the email domain appears to be an educational institution.
  /// This is a soft check — non-educational emails are still allowed.
  static func isEducationalEmail(_ email: String) -> Bool {
    guard let atIndex = email.lastIndex(of: "@") else { return false }
    let domain = String(email[email.index(after: atIndex)...]).lowercased()
    return educationalSuffixes.contains { domain.hasSuffix($0) }
  }

  /// Returns the domain suffix list as a JSON-safe JavaScript array string
  /// for client-side validation
  static var jsSuffixArray: String {
    let items = educationalSuffixes.map { "\"\($0)\"" }.joined(separator: ", ")
    return "[\(items)]"
  }
}
