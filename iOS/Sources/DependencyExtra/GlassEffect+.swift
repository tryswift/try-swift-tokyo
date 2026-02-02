import SwiftUI

extension View {

  @ViewBuilder
  public func glassEffectIfAvailable(
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

  @ViewBuilder
  public func glassEffectIfAvailable<S: InsettableShape>(
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
  public func glassProminentIfAvailable() -> some View {
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

#if os(visionOS)
/// dummy for visionOS
public enum Glass : Equatable, Sendable {
  case regular
  case clear
  case identity

  // dummy
  public func tint(_ color: Color?) -> Self {
    return .regular
  }

  //
  public func interactive(_ isEnabled: Bool = true) -> Self {
    return .regular
  }
}
#endif // os(visionOS)
