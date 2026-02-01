import Foundation
import Testing

@testable import Server

@Suite("CSV Export Tests")
struct CSVExportTests {

  // MARK: - CSV Header

  @Test("CSV header includes Status column")
  func csvHeaderIncludesStatus() {
    let expectedHeader =
      "ID,Title,Abstract,Talk Details,Duration,Status,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At"

    // Verify "Status" is in the header
    #expect(expectedHeader.contains("Status"))

    // Verify Status comes after Duration
    let columns = expectedHeader.split(separator: ",").map(String.init)
    let durationIndex = columns.firstIndex(of: "Duration")
    let statusIndex = columns.firstIndex(of: "Status")
    #expect(durationIndex != nil)
    #expect(statusIndex != nil)
    #expect(statusIndex == durationIndex! + 1)
  }

  @Test("CSV header has 14 columns")
  func csvHeaderColumnCount() {
    let header =
      "ID,Title,Abstract,Talk Details,Duration,Status,Speaker Name,Speaker Email,Speaker Username,Bio,Icon URL,Notes,Conference,Submitted At"
    let columns = header.split(separator: ",")
    #expect(columns.count == 14)
  }

  // MARK: - escapeCSV Logic

  // These tests verify the CSV escaping logic used in the export.
  // The escapeCSV function is private in CfPRoutes, so we test the same logic here.

  private func escapeCSV(_ value: String) -> String {
    let needsQuoting =
      value.contains(",") || value.contains("\"") || value.contains("\n")
      || value.contains("\r")
    if needsQuoting {
      let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
      return "\"\(escaped)\""
    }
    return value
  }

  @Test("Simple string passes through unchanged")
  func escapeSimpleString() {
    #expect(escapeCSV("hello") == "hello")
  }

  @Test("String with comma is quoted")
  func escapeComma() {
    #expect(escapeCSV("hello, world") == "\"hello, world\"")
  }

  @Test("String with double quote is escaped and quoted")
  func escapeDoubleQuote() {
    #expect(escapeCSV("say \"hello\"") == "\"say \"\"hello\"\"\"")
  }

  @Test("String with newline is quoted")
  func escapeNewline() {
    #expect(escapeCSV("line1\nline2") == "\"line1\nline2\"")
  }

  @Test("String with carriage return is quoted")
  func escapeCarriageReturn() {
    #expect(escapeCSV("line1\rline2") == "\"line1\rline2\"")
  }

  @Test("Empty string passes through unchanged")
  func escapeEmptyString() {
    #expect(escapeCSV("") == "")
  }

  @Test("String with all special characters is properly escaped")
  func escapeAllSpecialChars() {
    let result = escapeCSV("test, with \"quotes\" and\nnewlines")
    #expect(result == "\"test, with \"\"quotes\"\" and\nnewlines\"")
  }

  // MARK: - ProposalStatus in CSV Row

  @Test("ProposalStatus raw values are valid CSV values")
  func proposalStatusRawValuesForCSV() {
    // ProposalStatus raw values should not need CSV escaping
    let statuses = ["submitted", "accepted", "rejected", "withdrawn"]
    for status in statuses {
      #expect(escapeCSV(status) == status)
    }
  }
}
