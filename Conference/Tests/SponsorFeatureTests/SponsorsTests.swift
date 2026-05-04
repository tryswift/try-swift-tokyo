import Foundation
import SharedModels
import SkipTCA
import SkipTCATesting
import Testing

@testable import SponsorFeature

@Suite
@MainActor
struct SponsorsTests {
  @Test
  func onAppear() async {
    let reducer = SponsorsList(
      fetchSponsors: { @Sendable in .mock },
      safari: { @Sendable _ in }
    )
    let store = TestStore(initialState: SponsorsList.State()) { state, action in
      reducer.reduce(into: &state, action: action)
    }

    await store.send(.view(.onAppear))
    await store.receive(.dataResponse(.mock)) { state in
      #expect(state.sponsors == .mock)
    }
  }

  @Test
  func sponsorTapped() async {
    let receivedUrl = LockIsolated<URL?>(nil)
    let reducer = SponsorsList(
      fetchSponsors: { @Sendable in .mock },
      safari: { @Sendable url in
        receivedUrl.withValue { $0 = url }
      }
    )
    let store = TestStore(initialState: SponsorsList.State()) { state, action in
      reducer.reduce(into: &state, action: action)
    }

    await store.send(.view(.sponsorTapped(.platinumMock)))
    await store.finish()
    receivedUrl.withValue {
      #expect($0 == Sponsor.platinumMock.link)
    }

    await store.send(.view(.sponsorTapped(.goldMock)))
    await store.finish()
    receivedUrl.withValue {
      #expect($0 == Sponsor.goldMock.link)
    }
  }
}

// Minimal lock-isolated container for tests; replicates the swift-concurrency-extras
// helper without dragging in TCA test deps.
final class LockIsolated<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func withValue<T>(_ operation: (inout Value) -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return operation(&value)
  }
}
