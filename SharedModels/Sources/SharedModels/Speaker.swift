import Foundation

public struct Speaker: Codable, Equatable, Hashable, Sendable {
  public var name: String
  public var imageName: String
  public var bio: String?
  public var links: [Link]?
  public var jobTitle: String?

  public struct Link: Codable, Equatable, Hashable, Sendable {
    public var name: String
    public var url: URL

    public init(name: String, url: URL) {
      self.name = name
      self.url = url
    }
  }

  public init(name: String, imageName: String, bio: String, links: [Link]) {
    self.name = name
    self.imageName = imageName
    self.bio = bio
    self.links = links
  }
}
