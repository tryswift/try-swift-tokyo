import Testing

@testable import Server

@Suite("EducationalDomainValidator")
struct EducationalDomainValidatorTests {
  @Test("recognizes Japanese ac.jp addresses")
  func acJp() {
    #expect(EducationalDomainValidator.isEducationalEmail("alice@univ.ac.jp"))
    #expect(EducationalDomainValidator.isEducationalEmail("bob@cs.tokyo.ac.jp"))
  }

  @Test("recognizes US .edu and country-specific .edu suffixes")
  func eduSuffixes() {
    #expect(EducationalDomainValidator.isEducationalEmail("alice@stanford.edu"))
    #expect(EducationalDomainValidator.isEducationalEmail("alice@unsw.edu.au"))
    #expect(EducationalDomainValidator.isEducationalEmail("alice@example.edu.tw"))
  }

  @Test("recognizes UK .ac.uk")
  func acUk() {
    #expect(EducationalDomainValidator.isEducationalEmail("alice@cam.ac.uk"))
  }

  @Test("rejects personal email providers")
  func nonEducational() {
    #expect(!EducationalDomainValidator.isEducationalEmail("alice@gmail.com"))
    #expect(!EducationalDomainValidator.isEducationalEmail("alice@example.com"))
    #expect(!EducationalDomainValidator.isEducationalEmail("alice@outlook.jp"))
  }

  @Test("returns false for malformed addresses")
  func malformed() {
    #expect(!EducationalDomainValidator.isEducationalEmail("not-an-email"))
    #expect(!EducationalDomainValidator.isEducationalEmail(""))
  }

  @Test("is case insensitive")
  func caseInsensitive() {
    #expect(EducationalDomainValidator.isEducationalEmail("Alice@Univ.AC.JP"))
    #expect(EducationalDomainValidator.isEducationalEmail("ALICE@STANFORD.EDU"))
  }

  @Test("jsSuffixArray emits a JSON-safe JS array literal")
  func jsArray() {
    let js = EducationalDomainValidator.jsSuffixArray
    #expect(js.hasPrefix("["))
    #expect(js.hasSuffix("]"))
    #expect(js.contains("\".ac.jp\""))
    #expect(js.contains("\".edu\""))
  }
}
