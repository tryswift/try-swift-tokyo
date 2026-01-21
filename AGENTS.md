Act as a Senior Swift Architect. I need to scaffold a new Monorepo project for a tech conference CfP (Call for Proposals) platform called "trySwiftCfP".

The system consists of a Vapor backend and an iOS client, sharing a Swift Package for Type-Safe APIs.

### Project Structure Requirements

Create the following directory structure:
.
├── Package.swift (Workspace root)
├── Server/ (Vapor executable)
├── WebSite / (Conference website by Ignite)
├── App/ (iOS App project with TCA)
└── MyLibrary/ (Swift Package library for Module sharing)

### Technology Stack

- Language: Swift 6.2
- Backend: Vapor latest stable
- Database: PostgreSQL (Use Fluent)
- Auth: GitHub OAuth + JWT
- Client: SwiftUI (iOS 17+)

### Core Features to Implement

1. **Shared Module (`Library`)**:
   - Define a `ProposalDTO` struct (Codable, Sendable).
   - Define a `UserRole` enum (Codable): cases `admin` (Organizer) and `speaker`.

2. **Server Implementation (`Server`)**:
   - **Models**:
     - `User`: Should store `githubID`, `username`, and `role`.
     - `Proposal`: Title, abstract, relations to User.
   - **Auth Flow**:
     - Implement GitHub OAuth.
     - **CRITICAL**: Upon login, check if the user is a member of the GitHub Organization "try-swift" (or a specific team).
     - If they are a member, set `User.role = .admin`. If not, set `.speaker`.
     - Issue a JWT (JSON Web Token) containing the user ID and role to the client.
   - **Middleware**:
     - Create an `OrganizerMiddleware`. It must check the JWT payload. If the role is NOT `admin`, return 403 Forbidden.
   - **Controllers**:
     - `AuthController`: Handle GitHub callback and JWT issuance.
     - `ProposalController`:
       - `POST /proposals`: Open to authenticated users.
       - `GET /proposals`: **Restricted** to `OrganizerMiddleware` (Only admins can view the list).

3. **Database**:
   - Set up Fluent with PostgreSQL driver.
   - Create migrations for User and Proposal.

### Instructions for You

Please generate the necessary Swift code and file structure.

- Start by creating the `Package.swift`.
- Then, set up the Vapor project in `Server/` with the necessary dependencies (Vapor, Fluent, FluentPostgresDriver, JWT).
- Implement the `OrganizerMiddleware` and the Auth logic as specified.

Let's start building.
