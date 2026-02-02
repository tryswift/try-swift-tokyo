import SwiftUI

extension View {

  @ViewBuilder
  func glassEffectIfAvailable<S: InsettableShape>(
    _ glass: Glass = .regular,
    in shape: S
  ) -> some View {
    #if os(iOS) || os(macOS)
      if #available(iOS 26.0, macOS 26.0, *) {
        self.glassEffect(glass, in: shape)
      } else {
        self
      }
    #else
      self
    #endif
  }

  @ViewBuilder
  func glassProminentIfAvailable() -> some View {
    #if os(iOS) || os(macOS)
      if #available(iOS 26.0, macOS 26.0, *) {
        self.buttonStyle(.glassProminent)
      } else {
        self.buttonStyle(.borderedProminent)
      }
    #else
      self.buttonStyle(.borderedProminent)
    #endif
  }
}
