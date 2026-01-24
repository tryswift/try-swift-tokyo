import ComposableArchitecture
import DataClient
import SharedModels
import Testing

@testable import ScheduleFeature

@Suite
@MainActor
struct ScheduleTests {
  @Test
  func fetchData_success() async {
    let store = TestStore(initialState: Schedule.State()) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in .mock3 }
    }
    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = .mock3
    }
  }

  @Test
  func fetchData_failure() async {
    struct FetchError: Equatable, Error {}
    let store = TestStore(initialState: Schedule.State()) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in throw FetchError() }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in .mock3 }
    }
    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.failure)
  }
}
