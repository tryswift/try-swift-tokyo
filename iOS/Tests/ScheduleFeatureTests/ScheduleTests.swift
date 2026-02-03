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

  @Test
  func fetchData_withoutDay3() async {
    struct NotFound: Equatable, Error {}
    let store = TestStore(initialState: Schedule.State()) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in throw NotFound() }
    }
    await store.send(.view(.onAppear))
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
    }
  }

  @Test
  func yearSelected_switchesToNewYear() async {
    var state = Schedule.State()
    state.selectedYear = .year2026
    state.day1 = .mock1
    state.day2 = .mock2
    state.day3 = .mock3

    let store = TestStore(initialState: state) {
      Schedule()
    } withDependencies: {
      $0[DataClient.self].fetchDay1 = { @Sendable _ in .mock1 }
      $0[DataClient.self].fetchDay2 = { @Sendable _ in .mock2 }
      $0[DataClient.self].fetchDay3 = { @Sendable _ in throw DataClientError.resourceNotFound("2017-day3") }
    }

    await store.send(.view(.yearSelected(.year2017))) {
      $0.selectedYear = .year2017
      $0.selectedDay = .day1
      $0.day1 = nil
      $0.day2 = nil
      $0.day3 = nil
    }
    await store.receive(\.view.onAppear)
    await store.receive(\.fetchResponse.success) {
      $0.day1 = .mock1
      $0.day2 = .mock2
      $0.day3 = nil
    }
  }
}
