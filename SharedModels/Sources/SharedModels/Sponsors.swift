import Foundation

public enum Plan: String, Codable, Sendable, CaseIterable {
  case platinum
  case gold
  case silver
  case bronze
  case diversityAndInclusion = "Diversity and Inclusion"
  case student
  case community
  case individual
}

public struct Sponsors: Codable, Equatable, Hashable, Sendable {
  let platinum: [Sponsor]
  let gold: [Sponsor]
  let silver: [Sponsor]
  let bronze: [Sponsor]
  let diversity: [Sponsor]
  let student: [Sponsor]
  let community: [Sponsor]
  let individual: [Sponsor]

  public var allPlans: [Plan: [Sponsor]] {
    return [
      .platinum: platinum,
      .gold: gold,
      .silver: silver,
      .bronze: bronze,
      .diversityAndInclusion: diversity,
      .student: student,
      .community: community,
      .individual: individual,
    ]
  }

  public init(
    platinum: [Sponsor], gold: [Sponsor], silver: [Sponsor], bronze: [Sponsor],
    diversity: [Sponsor], student: [Sponsor], community: [Sponsor], individual: [Sponsor]
  ) {
    self.platinum = platinum
    self.gold = gold
    self.silver = silver
    self.bronze = bronze
    self.diversity = diversity
    self.student = student
    self.community = community
    self.individual = individual
  }
}

public struct Sponsor: Codable, Equatable, Hashable, Identifiable, Sendable {
  public var id: Int
  public var name: String?
  public var imageName: String
  public var link: URL?
  public var japaneseLink: URL?

  public init(id: Int, name: String, imageName: String, link: URL? = nil) {
    self.id = id
    self.name = name
    self.imageName = imageName
    self.link = link
  }
}
