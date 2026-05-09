import SharedModels
import Vapor

// SharedModels intentionally has no Vapor dependency, so the DTOs are plain
// `Codable`. Vapor's `Content` protocol layers request/response coding helpers
// on top; we add the conformance here so `SponsorAPIController` can call
// `response.content.encode(dto)` directly.
extension SponsorApplicationDTO: @retroactive Content {}
extension SponsorOrganizationDTO: @retroactive Content {}
extension SponsorPlanDTO: @retroactive Content {}
extension SponsorUserDTO: @retroactive Content {}
