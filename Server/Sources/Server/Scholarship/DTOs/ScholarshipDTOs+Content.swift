import SharedModels
import Vapor

// SharedModels lives outside Vapor, so the DTOs are plain `Codable`.
// Vapor's `Content` protocol layers request/response coding helpers on top;
// we add the conformance here so the API controller can `response.content.encode(...)`
// the DTOs directly.
extension ScholarshipApplicationDTO: @retroactive Content {}
extension ScholarshipBudgetDTO: @retroactive Content {}
extension ScholarshipBudgetSummaryDTO: @retroactive Content {}
