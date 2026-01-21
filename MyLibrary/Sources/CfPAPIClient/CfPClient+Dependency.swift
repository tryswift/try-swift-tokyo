import ComposableArchitecture
import Foundation
import SharedModels

// MARK: - TCA Dependency

extension CfPAPIClient: DependencyKey {
  public static let liveValue = CfPAPIClient(
    baseURL: URL(string: "https://cfp-api.tryswift.jp")!
  )
  
  public static let testValue = CfPAPIClient(
    baseURL: URL(string: "http://localhost:8080")!
  )
  
  public static let previewValue = CfPAPIClient(
    baseURL: URL(string: "http://localhost:8080")!
  )
}

extension DependencyValues {
  public var cfpClient: CfPAPIClient {
    get { self[CfPAPIClient.self] }
    set { self[CfPAPIClient.self] = newValue }
  }
}
