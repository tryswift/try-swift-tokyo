import AVFoundation
import Dependencies
import DependenciesMacros
import Foundation

extension DependencyValues {
  public var speechSynthesizer: SpeechSynthesizerClient {
    get { self[SpeechSynthesizerClient.self] }
    set { self[SpeechSynthesizerClient.self] = newValue }
  }
}

@DependencyClient
public struct SpeechSynthesizerClient: Sendable {
  public var speak: @Sendable (String, String, Float) async -> Void
  public var stop: @Sendable () async -> Void
}

extension SpeechSynthesizerClient: DependencyKey {
  public static let liveValue: Self = {
    let synthesizer = SpeechSynthesizerActor()
    return Self(
      speak: { text, langCode, rate in
        await synthesizer.speak(text: text, langCode: langCode, rate: rate)
      },
      stop: {
        await synthesizer.stop()
      }
    )
  }()
}

@MainActor
private final class SpeechSynthesizerActor {
  private let synthesizer = AVSpeechSynthesizer()
  private var delegate: SpeechDelegate?
  private var continuation: CheckedContinuation<Void, Never>?

  init() {}

  private func setupDelegate() {
    if delegate == nil {
      delegate = SpeechDelegate { [weak self] in
        self?.didFinishSpeaking()
      }
      synthesizer.delegate = delegate
    }
  }

  func speak(text: String, langCode: String, rate: Float) async {
    setupDelegate()
    synthesizer.stopSpeaking(at: .immediate)

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: langCode)
    utterance.rate = rate

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      self.continuation = continuation
      synthesizer.speak(utterance)
    }
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
    continuation?.resume()
    continuation = nil
  }

  private func didFinishSpeaking() {
    continuation?.resume()
    continuation = nil
  }
}

private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
  private let onFinish: @MainActor () -> Void

  init(onFinish: @escaping @MainActor () -> Void) {
    self.onFinish = onFinish
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in
      onFinish()
    }
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in
      onFinish()
    }
  }
}
