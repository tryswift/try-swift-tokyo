import ComposableArchitecture
import DataClient
import XCTest

@testable import ScheduleFeature

final class ScheduleTests: XCTestCase {
  @MainActor
  func testFetchData() async {
    let store = TestStore(initialState: Schedule.State()) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable in .mock3 }
    }
    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.workshop = .mock3
    }
  }

  @MainActor
  func testFetchDataFailure() async {
    struct FetchError: Equatable, Error {}
    let store = TestStore(initialState: Schedule.State()) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable in throw FetchError() }
      $0[DataClient.self].fetchDay2 = { @Sendable in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable in .mock3 }
    }
    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.failure)
  }
}
