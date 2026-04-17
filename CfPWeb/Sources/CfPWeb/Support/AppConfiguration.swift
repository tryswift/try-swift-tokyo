import Foundation
import Vapor

enum AppConfiguration {
  static func apiBaseURL() -> String {
    Environment.get("CFP_API_BASE_URL") ?? "https://api.tryswift.jp"
  }
}
