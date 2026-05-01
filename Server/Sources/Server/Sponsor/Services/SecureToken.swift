import Crypto
import Foundation

/// Crypto-secure URL-safe token generation utilities.
///
/// `UInt8.random(in:)` uses Swift's `SystemRandomNumberGenerator`, which is
/// CSPRNG-backed on Apple/Linux platforms (`SecRandomCopyBytes` / `getrandom`).
enum SecureToken {
  /// Returns a base64URL-encoded random token of the requested byte count.
  static func urlSafe(byteCount: Int = 32) -> String {
    var bytes = [UInt8](repeating: 0, count: byteCount)
    for i in 0..<byteCount { bytes[i] = UInt8.random(in: .min ... .max) }
    return Data(bytes).base64URLEncodedString()
  }

  /// SHA-256 hex digest of `raw`. Used for at-rest token hashing.
  static func sha256Hex(_ raw: String) -> String {
    let digest = SHA256.hash(data: Data(raw.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}

extension Data {
  fileprivate func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
