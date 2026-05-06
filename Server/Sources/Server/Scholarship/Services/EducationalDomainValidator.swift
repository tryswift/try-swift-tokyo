/// Soft-validates whether an email address belongs to an educational
/// institution. Non-educational emails are still allowed; the check only
/// drives a UI hint on the apply form so applicants can confirm they meant to
/// submit a personal address.
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

  static func isEducationalEmail(_ email: String) -> Bool {
    guard let atIndex = email.lastIndex(of: "@") else { return false }
    let domain = String(email[email.index(after: atIndex)...]).lowercased()
    return educationalSuffixes.contains { domain.hasSuffix($0) }
  }

  /// Domain suffix list as a JSON-safe JavaScript array literal so the same
  /// check can run on the client.
  static var jsSuffixArray: String {
    let items = educationalSuffixes.map { "\"\($0)\"" }.joined(separator: ", ")
    return "[\(items)]"
  }
}
