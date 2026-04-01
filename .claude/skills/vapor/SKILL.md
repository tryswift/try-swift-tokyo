---
name: vapor
description: Expert guidance for Vapor 4+ development, focusing on async/await, Fluent, and content negotiation.
---

# Vapor Best Practices

## 1. Concurrency

- ALWAYS use Swift Concurrency (`async`/`await`) over `EventLoopFuture`.
- All route handlers MUST be annotated with `@Sendable`.

## 2. Controllers & Routing

- Organize routes into `RouteCollection` conformances.
- Do not put logic in `routes.swift`; delegate immediately to a Controller.
- Group routes by feature (e.g., `UsersController`, `AuthController`).
- Register controllers: `app.register(collection: MyController())`.
- API versioning: `app.grouped("api", "v1")`.

## 3. Middleware

- Use `AsyncMiddleware` for custom middleware:

```swift
struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let payload = try await request.jwt.verify(as: UserJWTPayload.self)
        request.auth.login(payload)
        return try await next.respond(to: request)
    }
}
```

- Apply to route groups: `routes.grouped(AuthMiddleware())`.

## 4. Fluent (Database)

- Use `@Parent` and `@Children` property wrappers correctly.
- Always use DTOs (Data Transfer Objects) implementing `Content` for API requests/responses. NEVER return a Fluent Model directly to the client.
- Run migrations via `app.migrations.add(...)`.
- Filter with `$` syntax: `.filter(\.$deviceID == id)`.

**Direct SQL Access** (for complex queries not expressible via Fluent):

```swift
guard let sql = req.db as? any SQLDatabase else {
    throw Abort(.internalServerError)
}
let rows = try await sql.raw("SELECT ... FROM \(raw: Model.schema)").all(decoding: SomeRow.self)
```

## 5. Environment

- Use `Environment.get("KEY")` for configuration.
- Support `Production` vs `Development` modes explicitly in `configure.swift`.

## Example Route

```swift
struct UsersController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
    }

    @Sendable
    func index(req: Request) async throws -> [UserDTO] {
        let users = try await User.query(on: req.db).all()
        return users.map { $0.toDTO() }
    }
}
```
