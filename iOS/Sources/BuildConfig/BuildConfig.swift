import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct BuildConfig: Sendable {
  public var liveTranslationRoomNumber: @Sendable () -> String = { "" }
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
