import ComposableArchitecture
import DependencyExtra
import Foundation
import SharedModels
import Testing

@testable import trySwiftFeature

@Suite
@MainActor
final class trySwiftTests {
  @Test
  func organizerTapped() async {
    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    }

    await store.send(\.view.organizerTapped) {
      $0.path[id: 0] = .organizers(.init())
    }
  }

  @Test
  func codeOfConductTapped() async {
    let receivedUrl = LockIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.codeOfConductTapped)
    receivedUrl.withValue {
      #expect($0!.absoluteString.hasPrefix("https://tryswift.jp/code-of-conduct"))
    }
  }

  @Test
  func privacyPolicyTapped() async {
    let receivedUrl = LockIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.privacyPolicyTapped)
    receivedUrl.withValue {
      #expect($0!.absoluteString.hasPrefix("https://tryswift.jp/privacy-policy"))
    }
  }

  @Test
  func acknowledgementsTapped() async {
    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    }

    await store.send(\.view.acknowledgementsTapped) {
      $0.path[id: 0] = .acknowledgements(.init())
    }
  }

  @Test
  func lumaTapped() async {
    let receivedUrl = LockIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.ticketTapped)
    receivedUrl.withValue {
      #expect(
        $0!.absoluteString.hasPrefix("https://luma.com")
      )
    }
  }

  @Test
  func websiteTapped() async {
    let receivedUrl = LockIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.websiteTapped)
    receivedUrl.withValue {
      #expect($0!.absoluteString.hasPrefix("https://tryswift.jp"))
    }
  }

  @Test
  func profileNavigation() async {
    let store = TestStore(
      initialState: TrySwift.State(
        path: StackState([
          .organizers(
            Organizers.State(
              organizers: .init(arrayLiteral: .alice, .bob)
            )
          )
        ])
      )
    ) {
      TrySwift()
    }

    await store.send(\.path[id: 0].organizers.delegate.organizerTapped, .alice) {
      $0.path[id: 1] = .profile(.init(organizer: .alice))
    }
  }
}
