import ComposableArchitecture
import DataClient
import DependencyExtra
import Foundation
import SharedModels
import Testing

@testable import SponsorFeature

@Suite
@MainActor
struct SponsorsTests {
  @Test
  func onAppear() async {
    let store = TestStore(initialState: SponsorsList.State()) {
      SponsorsList()
    } withDependencies: {
      $0[DataClient.self].fetchSponsors = { @Sendable _ throws -> Sponsors in
        .mock
      }
    }

    await store.send(\.view.onAppear) {
      $0.sponsors = .mock
    }
  }

  @Test
  func sponsorTapped() async {
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
      #expect($0 == Sponsor.platinumMock.link)
    }

    await store.send(\.view.sponsorTapped, .goldMock)
    receivedUrl.withValue {
      #expect($0 == Sponsor.goldMock.link)
    }
  }
}
