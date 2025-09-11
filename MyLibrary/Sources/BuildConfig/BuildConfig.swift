import Dependencies
import Foundation
import DependenciesMacros

@DependencyClient
public struct BuildConfig {
  public var liveTranslationRoomNumber: () -> String = { "" }
}

extension DependencyValues {
  public var buildConfig: BuildConfig {
    get { self[BuildConfig.self] }
    set { self[BuildConfig.self] = newValue }
  }
}

extension BuildConfig: DependencyKey {
  public static let liveValue: Self = Self(
    liveTranslationRoomNumber: {
      ProcessInfo.processInfo.environment["LIVE_TRANSLATION_KEY"]
       ?? (Bundle.main.infoDictionary?["Live translation room number"] as? String) ?? ""
    }
  )
}
