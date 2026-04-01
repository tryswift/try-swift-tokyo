import FoundationModels
import SharedModels

@Generable
struct SessionRelevanceRanking {
  @Guide(
    description:
      "Indices of candidate sessions ranked by relevance to the target session, most relevant first"
  )
  var rankedIndices: [Int]
}

enum SessionRelevance {
  static func rerank(
    currentTitle: String,
    currentDescription: String,
    candidates: [RelatedSession],
    limit: Int
  ) async -> [RelatedSession]? {
    guard limit > 0 else { return nil }
    let model = SystemLanguageModel.default
    guard case .available = model.availability else { return nil }
    guard !candidates.isEmpty else { return nil }

    let candidateList =
      candidates.enumerated()
      .map { i, c in
        "[\(i)] \(c.session.title): \(c.session.summary ?? c.session.description ?? "")"
      }
      .joined(separator: "\n")

    let session = LanguageModelSession {
      """
      You are a tech conference program advisor. Rank candidate sessions by how
      relevant they are to a given session. Consider topical overlap, shared
      concepts, complementary content, and whether attendees interested in one
      would benefit from the other.
      """
    }

    guard
      let result = try? await session.respond(
        to: """
          Target session:
          Title: \(currentTitle)
          Description: \(currentDescription)

          Candidate sessions:
          \(candidateList)

          Rank the candidates by relevance.
          """,
        generating: SessionRelevanceRanking.self
      )
    else { return nil }

    var seen = Set<Int>()
    let validIndices = result.content.rankedIndices.filter { index in
      guard index >= 0 && index < candidates.count else { return false }
      return seen.insert(index).inserted
    }
    let ranked = validIndices.prefix(limit).map { candidates[$0] }
    return ranked.isEmpty ? nil : Array(ranked)
  }
}
