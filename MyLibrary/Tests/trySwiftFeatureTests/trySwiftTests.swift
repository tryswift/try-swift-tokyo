import ComposableArchitecture
import DependencyExtra
import SharedModels
import XCTest

@testable import trySwiftFeature

final class trySwiftTests: XCTestCase {
  @MainActor
  func testOrganizerTapped() async {
    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    }

    await store.send(\.view.organizerTapped) {
      $0.path[id: 0] = .organizers(.init())
    }
  }

  @MainActor
  func testCodeOfConductTapped() async {
    let receivedUrl = ActorIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          await receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.codeOfConductTapped)
    await receivedUrl.withValue {
      XCTAssertTrue($0!.absoluteString.hasPrefix("https://tryswift.jp/code-of-conduct"))
    }
  }

  @MainActor
  func testPrivacyPolicyTapped() async {
    let receivedUrl = ActorIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          await receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.privacyPolicyTapped)
    await receivedUrl.withValue {
      XCTAssertTrue($0!.absoluteString.hasPrefix("https://tryswift.jp/privacy-policy"))
    }
  }

  @MainActor
  func testAcknowledgementsTapped() async {
    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    }

    await store.send(\.view.acknowledgementsTapped) {
      $0.path[id: 0] = .acknowledgements(.init())
    }
  }

  @MainActor
  func testEventBriteTapped() async {
    let receivedUrl = ActorIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          await receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.eventbriteTapped)
    await receivedUrl.withValue {
      XCTAssertEqual(
        $0, URL(string: "https://www.eventbrite.com/e/try-swift-tokyo-2024-tickets-712565200697")!)
    }
  }

  @MainActor
  func testWebsiteTapped() async {
    let receivedUrl = ActorIsolated<URL?>(nil)

    let store = TestStore(initialState: TrySwift.State()) {
      TrySwift()
    } withDependencies: {
      $0.safari = { @Sendable in
        SafariEffect { url in
          await receivedUrl.withValue {
            $0 = url
            return true
          }
        }
      }()
    }

    await store.send(\.view.websiteTapped)
    await receivedUrl.withValue {
      XCTAssertTrue($0!.absoluteString.hasPrefix("https://tryswift.jp"))
    }
  }

  @MainActor
  func testProfileNavigation() async {
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
