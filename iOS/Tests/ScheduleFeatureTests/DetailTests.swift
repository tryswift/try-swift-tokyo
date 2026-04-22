import ComposableArchitecture
import Foundation
import SharedModels
import Testing

@testable import ScheduleFeature

@Suite
@MainActor
struct DetailTests {

  @Test
  func favoriteTapped_success() async {
    let store = TestStore(
      initialState: ScheduleDetail.State(
        proposalId: "proposal-1",
        isFavorite: false,
        favoriteCount: 0,
        title: "Test Session",
        description: "A test session",
        speakers: [.mock1]
      )
    ) {
      ScheduleDetail()
    } withDependencies: {
      $0.scheduleAPIClient.toggleFavorite = { @Sendable _, _ in (isFavorite: true, count: 1) }
    }

    await store.send(.view(.favoriteTapped)) {
      $0.isFavorite = true
    }
    await store.receive(\.favoriteToggled) {
      $0.isFavorite = true
      $0.favoriteCount = 1
    }
  }

  @Test
  func favoriteTapped_revertsOnError() async {
    struct ToggleError: Error {}

    let store = TestStore(
      initialState: ScheduleDetail.State(
        proposalId: "proposal-1",
        isFavorite: true,
        favoriteCount: 5,
        title: "Test Session",
        description: "A test session",
        speakers: [.mock1]
      )
    ) {
      ScheduleDetail()
    } withDependencies: {
      $0.scheduleAPIClient.toggleFavorite = { @Sendable _, _ in throw ToggleError() }
    }

    await store.send(.view(.favoriteTapped)) {
      $0.isFavorite = false
    }
    await store.receive(\.favoriteToggled) {
      $0.isFavorite = true
      $0.favoriteCount = 5
    }
  }

  @Test
  func submitFeedback_success() async {
    let store = TestStore(
      initialState: ScheduleDetail.State(
        proposalId: "proposal-1",
        title: "Test Session",
        description: "A test session",
        speakers: [.mock1]
      )
    ) {
      ScheduleDetail()
    } withDependencies: {
      $0.scheduleAPIClient.submitFeedback = { @Sendable _, _, _ in }
    }

    await store.send(.binding(.set(\.feedbackText, "Great talk!"))) {
      $0.feedbackText = "Great talk!"
    }

    await store.send(.view(.submitFeedbackTapped)) {
      $0.isSubmittingFeedback = true
    }
    await store.receive(\.feedbackSubmitResponse.success) {
      $0.feedbackSubmitted = true
      $0.feedbackText = ""
      $0.isSubmittingFeedback = false
    }
  }

  @Test
  func submitFeedback_failure() async {
    struct FeedbackError: Error, LocalizedError {
      var errorDescription: String? { "Server error" }
    }

    let store = TestStore(
      initialState: ScheduleDetail.State(
        proposalId: "proposal-1",
        title: "Test Session",
        description: "A test session",
        speakers: [.mock1]
      )
    ) {
      ScheduleDetail()
    } withDependencies: {
      $0.scheduleAPIClient.submitFeedback = { @Sendable _, _, _ in throw FeedbackError() }
    }

    await store.send(.binding(.set(\.feedbackText, "Great talk!"))) {
      $0.feedbackText = "Great talk!"
    }

    await store.send(.view(.submitFeedbackTapped)) {
      $0.isSubmittingFeedback = true
    }
    await store.receive(\.feedbackSubmitResponse.failure) {
      $0.isSubmittingFeedback = false
      $0.feedbackError = "Server error"
    }
  }

  @Test
  func submitFeedback_emptyText_doesNothing() async {
    let store = TestStore(
      initialState: ScheduleDetail.State(
        proposalId: "proposal-1",
        title: "Test Session",
        description: "A test session",
        speakers: [.mock1]
      )
    ) {
      ScheduleDetail()
    }

    await store.send(.binding(.set(\.feedbackText, "  "))) {
      $0.feedbackText = "  "
    }

    await store.send(.view(.submitFeedbackTapped))
  }
}
