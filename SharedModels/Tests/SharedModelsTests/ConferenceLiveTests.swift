import Foundation
import Testing

@testable import SharedModels

@Suite
struct ConferenceLiveTests {
  let conference = Conference(
    id: 1,
    title: "Test",
    date: Date(timeIntervalSince1970: 0),
    schedules: [
      .init(time: Date(timeIntervalSince1970: 1000), sessions: []),
      .init(time: Date(timeIntervalSince1970: 2000), sessions: []),
      .init(time: Date(timeIntervalSince1970: 3000), sessions: []),
    ]
  )

  @Test
  func beforeFirstSlot_returnsNil() {
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 500)) == nil)
  }

  @Test
  func duringFirstSlot_returnsZero() {
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 1500)) == 0)
  }

  @Test
  func duringSecondSlot_returnsOne() {
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 2500)) == 1)
  }

  @Test
  func duringLastSlot_returnsLastIndex() {
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 3100)) == 2)
  }

  @Test
  func afterLastSlotDuration_returnsNil() {
    // Default lastSlotDuration is 3600s, so end = 3000 + 3600 = 6600
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 6700)) == nil)
  }

  @Test
  func atExactBoundary_returnsNextSlot() {
    // At exactly 2000, the first slot ended and second begins
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 2000)) == 1)
  }

  @Test
  func atExactStartOfFirstSlot_returnsZero() {
    #expect(conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 1000)) == 0)
  }

  @Test
  func emptySchedules_returnsNil() {
    let empty = Conference(id: 2, title: "Empty", date: Date(), schedules: [])
    #expect(empty.liveScheduleIndex(at: Date()) == nil)
  }

  @Test
  func customLastSlotDuration() {
    // With 120s duration, last slot ends at 3000 + 120 = 3120
    #expect(
      conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 3100), lastSlotDuration: 120)
        == 2)
    #expect(
      conference.liveScheduleIndex(at: Date(timeIntervalSince1970: 3200), lastSlotDuration: 120)
        == nil)
  }
}
