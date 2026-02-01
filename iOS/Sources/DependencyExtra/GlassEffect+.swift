import SwiftUI

extension View {

  @ViewBuilder
  func glassEffectIfAvailable(
    _ glass: Glass = .regular,
    cornerRadius: CGFloat = 24
  ) -> some View {
    #if os(iOS) || os(macOS)
    if #available(iOS 26.0, macOS 26.0, *) {
      self.glassEffect(
        glass,
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
    } else {
      self
    }
    #else
    // visionOS / watchOS / tvOS など：何もしない（コンパイルも通る）
    self
    #endif
  }
}
