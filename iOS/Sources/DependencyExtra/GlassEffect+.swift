import SwiftUI

extension View {

  @ViewBuilder
  public func glassEffectIfAvailable(
    _ glass: Glass = .regular,
    cornerRadius: CGFloat = 24
  ) -> some View {
    #if os(iOS) || os(macOS)
      self.glassEffect(
        glass,
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
    #elseif os(visionOS)
      self.glassBackgroundEffect(
        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
      )
    #else
      self
    #endif
  }

  @ViewBuilder
  public func glassEffectIfAvailable<S: InsettableShape>(
    _ glass: Glass = .regular,
    in shape: S
  ) -> some View {
    #if os(iOS) || os(macOS)
      self.glassEffect(glass, in: shape)
    #elseif os(visionOS)
      self.glassBackgroundEffect(in: shape)
    #else
      self
    #endif
  }

  @ViewBuilder
  public func glassIfAvailable() -> some View {
    #if os(iOS) || os(macOS)
      self.buttonStyle(.glass)
    #else
      self.buttonStyle(.bordered)
    #endif
  }

  @ViewBuilder
  public func glassProminentIfAvailable() -> some View {
    #if os(iOS) || os(macOS)
      self.buttonStyle(.glassProminent)
    #else
      self.buttonStyle(.borderedProminent)
    #endif
  }
}

// MARK: - visionOS shim
#if os(visionOS)
  /// dummy
  public struct Glass: Equatable, Sendable {
    public init() {}

    public static var regular: Glass { .init() }
    public static var clear: Glass { .init() }
    public static var identity: Glass { .init() }

    public func tint(_ color: Color?) -> Glass { self }
    public func interactive(_ isEnabled: Bool = true) -> Glass { self }
  }
#endif
