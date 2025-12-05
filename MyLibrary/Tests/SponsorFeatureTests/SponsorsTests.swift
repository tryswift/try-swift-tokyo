import ComposableArchitecture
import DataClient
import DependencyExtra
import SharedModels
import XCTest

@testable import SponsorFeature

final class SponsorsTests: XCTestCase {
  @MainActor
  func testOnAppear() async {
    let store = TestStore(initialState: SponsorsList.State()) {
      SponsorsList()
    } withDependencies: {
      $0[DataClient.self].fetchSponsors = { @Sendable (_: ConferenceYear) throws -> Sponsors in
        .mock
      }
    }

    await store.send(\.view.onAppear) {
      $0.sponsors = .mock
    }
  }

  @MainActor
  func testSponsorTapped() async {
    let receivedUrl = LockIsolated<URL?>(nil)

    let store = TestStore(initialState: SponsorsList.State()) {
      SponsorsList()
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

    await store.send(\.view.sponsorTapped, .platinumMock)
    receivedUrl.withValue {
      XCTAssertEqual($0, Sponsor.platinumMock.link)
    }
  }
}
