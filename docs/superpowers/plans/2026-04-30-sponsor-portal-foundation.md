# sponsor.tryswift.jp Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Foundation sub-project of sponsor.tryswift.jp — a sponsor-facing portal that handles inquiry → account creation → magic-link login → plan application → Organizer approval, served from `sponsor.tryswift.jp` by the existing Vapor `Server`.

**Architecture:** Same Vapor app handles both `api.tryswift.jp` (existing) and `sponsor.tryswift.jp` (new) via `HostRoutingMiddleware`. SSR via Elementary, Components live in a new `Web/Sources/WebSponsor/` library that Server imports. Existing `CfPWeb/` and `Website/` packages move into a unified `Web/Package.swift`. Magic-link auth via Resend, separate `sponsor_auth_token` cookie sharing the `.tryswift.jp` parent domain with the existing `auth_token`.

**Tech Stack:** Swift 6.3, Vapor 4, Fluent + Postgres, JWT (HS256, swift-crypto), Elementary 0.7+, Ignite 0.6+, Resend HTTP API, HTMX (CDN, SRI), Swift Testing + VaporTesting + SQLite in-memory.

**Spec:** `docs/superpowers/specs/2026-04-30-sponsor-portal-foundation-design.md`

---

## File Structure Overview

This plan creates / modifies the following file tree. Tasks below produce these files in dependency order.

```
Web/                                           ← NEW SwiftPM package
├── Package.swift                              ← NEW
├── Public/                                    ← MOVED from CfPWeb/Public/
└── Sources/
    ├── WebShared/                             ← NEW library
    │   ├── Locale.swift
    │   ├── HTMX.swift
    │   ├── Tokens.swift
    │   └── Layout.swift
    ├── WebSponsor/                            ← NEW library
    │   ├── Layout/
    │   │   ├── PortalLayout.swift
    │   │   ├── PortalNav.swift
    │   │   └── HTMXBootstrap.swift
    │   ├── Components/
    │   │   ├── FormField.swift
    │   │   ├── PlanCard.swift
    │   │   ├── StatusBadge.swift
    │   │   └── Toast.swift
    │   ├── Pages/
    │   │   ├── Public/{Inquiry,InquiryThanks,LoginRequest,LoginSent}Page.swift
    │   │   ├── Sponsor/{Dashboard,Profile,Members,InvitationAccept,Plans,ApplicationForm,ApplicationDetail}Page.swift
    │   │   └── Organizer/{SponsorList,SponsorDetail,InquiryList,ApplicationList,ApplicationDetail}Page.swift
    │   └── Localization/PortalStrings.swift
    ├── WebCfP/                                ← MOVED from CfPWeb/Sources/CfPWeb/
    └── WebConference/                         ← MOVED from Website/Sources/Website/
        └── Assets/                            ← MOVED from Website/Assets/

CfPWeb/                                        ← DELETED
Website/                                       ← DELETED

Server/
├── Package.swift                              ← EDITED (add Web/, Crypto)
├── Public/sponsor/                            ← NEW (CSS, materials)
├── Sources/Server/
│   ├── configure.swift                        ← EDITED
│   ├── routes.swift                           ← EDITED (1-line add)
│   └── Sponsor/                               ← NEW directory
│       ├── SponsorRoutes.swift
│       ├── Auth/{SponsorJWTPayload,SponsorAuthCookie}.swift
│       ├── Models/{SponsorOrganization,SponsorUser,SponsorMembership,
│       │           SponsorPlan,SponsorPlanLocalization,
│       │           SponsorInquiry,SponsorApplication,
│       │           MagicLinkToken,SponsorInvitation}.swift
│       ├── Migrations/{...11 files...}.swift
│       ├── DTOs/{...5 files...}.swift
│       ├── Services/{ResendClient,MagicLinkService,
│       │             SponsorEmailTemplates,SponsorSlackNotifier,
│       │             SponsorApplicationService}.swift
│       ├── Middleware/{HostRoutingMiddleware,SponsorAuthMiddleware,
│       │               SponsorOwnerMiddleware,OrganizerOnlyMiddleware,
│       │               LocaleMiddleware}.swift
│       └── Controllers/{SponsorPublicController,SponsorPortalController,
│                        SponsorPlansController,SponsorApplicationController,
│                        OrganizerSponsorController}.swift
└── Tests/ServerTests/Sponsor/                 ← NEW directory
    ├── CreateSponsorTestSchema.swift
    ├── SponsorTestFactories.swift
    └── {SponsorInquiryFlow,MagicLinkService,SponsorAuthMiddleware,
          SponsorMembership,SponsorApplicationFlow,OrganizerAccess,
          HostRoutingMiddleware,LocaleMiddleware,SponsorEmailTemplates}Tests.swift

SharedModels/Sources/SharedModels/Sponsor/    ← NEW directory
└── {SponsorPortalLocale,SponsorMemberRole,SponsorOrganizationStatus,
     SponsorApplicationStatus,SponsorOrganizationDTO,SponsorUserDTO,
     SponsorMembershipDTO,SponsorPlanDTO,SponsorPlanLocalizationDTO,
     SponsorInquiryDTO,SponsorApplicationDTO,
     SponsorApplicationFormPayload}.swift

.github/workflows/                             ← EDITED
├── format.yml
├── test-website.yml
├── test-cfpweb.yml (if present)
├── deploy_website.yml
├── deploy-cfpweb.yml
└── test-api-server.yml

trySwiftTokyo.xcworkspace/contents.xcworkspacedata  ← EDITED
```

---

## Phase A: `Web/` Package Migration (independent PR)

The goal of Phase A is **mechanical**: move CfPWeb and Website into a unified `Web/` SwiftPM package, with empty `WebShared` and `WebSponsor` libraries ready for Phase B. CfPWeb and Website must continue to build and deploy unchanged.

### Task A1: Create `Web/Package.swift` skeleton with empty libraries and exec stubs

**Files:**
- Create: `Web/Package.swift`
- Create: `Web/Sources/WebShared/Placeholder.swift` (empty placeholder so SwiftPM finds the target)
- Create: `Web/Sources/WebSponsor/Placeholder.swift` (same)
- Create: `Web/Sources/WebCfP/main.swift` (empty stub, replaced by A2 move)
- Create: `Web/Sources/WebConference/main.swift` (empty stub, replaced by A3 move)

- [ ] **Step 1: Create `Web/Package.swift`**

```swift
// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "Web",
  platforms: [.macOS(.v15)],
  products: [
    .library(name: "WebShared", targets: ["WebShared"]),
    .library(name: "WebSponsor", targets: ["WebSponsor"]),
    .executable(name: "WebCfP", targets: ["WebCfP"]),
    .executable(name: "WebConference", targets: ["WebConference"]),
  ],
  dependencies: [
    .package(url: "https://github.com/sliemeobn/elementary.git", from: "0.7.1"),
    .package(url: "https://github.com/twostraws/Ignite.git", from: "0.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0"),
    .package(name: "SharedModels", path: "../SharedModels"),
    .package(name: "DataClient", path: "../DataClient"),
    .package(name: "LocalizationGenerated", path: "../LocalizationGenerated"),
  ],
  targets: [
    .target(
      name: "WebShared",
      dependencies: [
        .product(name: "Elementary", package: "elementary"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .target(
      name: "WebSponsor",
      dependencies: [
        "WebShared",
        .product(name: "Elementary", package: "elementary"),
        .product(name: "SharedModels", package: "SharedModels"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .executableTarget(
      name: "WebCfP",
      dependencies: [
        "WebShared",
        .product(name: "Elementary", package: "elementary"),
      ],
      resources: [
        .copy("../../Public")
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .executableTarget(
      name: "WebConference",
      dependencies: [
        "WebShared",
        .product(name: "Ignite", package: "Ignite"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DataClient", package: "DataClient"),
        .product(name: "LocalizationGenerated", package: "LocalizationGenerated"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
```

- [ ] **Step 2: Create empty placeholders so the targets compile**

```swift
// Web/Sources/WebShared/Placeholder.swift
// Replaced in Phase B Task B22.
```

```swift
// Web/Sources/WebSponsor/Placeholder.swift
// Replaced in Phase B Task B23+.
```

```swift
// Web/Sources/WebCfP/main.swift
print("WebCfP placeholder — overwritten by Task A2.")
```

```swift
// Web/Sources/WebConference/main.swift
print("WebConference placeholder — overwritten by Task A3.")
```

- [ ] **Step 3: Verify the skeleton builds**

Run: `cd Web && swift build`
Expected: builds 4 targets without errors. (Resources reference will warn until Public/ exists; ignore for now.)

- [ ] **Step 4: Commit**

```bash
git add Web/Package.swift Web/Sources/
git commit -m "Add Web/ package skeleton with empty libraries and exec stubs"
```

### Task A2: Move `CfPWeb/` into `Web/Sources/WebCfP/` and `Web/Public/`

**Files:**
- Move: `CfPWeb/Sources/CfPWeb/` → `Web/Sources/WebCfP/` (preserve structure: Components/, Pages/, Support/, main.swift)
- Move: `CfPWeb/Public/` → `Web/Public/`
- Delete: `CfPWeb/Package.swift`, `CfPWeb/Package.resolved`, `CfPWeb/README.md`, `CfPWeb/.swift-version` (if any), `CfPWeb/.gitignore` (if any)
- Delete: `CfPWeb/` directory itself once empty

- [ ] **Step 1: Move CfPWeb sources via `git mv`**

```bash
# remove the placeholder before moving real source in
rm Web/Sources/WebCfP/main.swift

git mv CfPWeb/Sources/CfPWeb/main.swift           Web/Sources/WebCfP/main.swift
git mv CfPWeb/Sources/CfPWeb/Components          Web/Sources/WebCfP/Components
git mv CfPWeb/Sources/CfPWeb/Pages               Web/Sources/WebCfP/Pages
git mv CfPWeb/Sources/CfPWeb/Support             Web/Sources/WebCfP/Support
git mv CfPWeb/Public                              Web/Public
```

- [ ] **Step 2: Remove CfPWeb package metadata**

```bash
rm CfPWeb/Package.swift
rm -f CfPWeb/Package.resolved CfPWeb/README.md
# remove now-empty Sources directory
rmdir CfPWeb/Sources/CfPWeb CfPWeb/Sources CfPWeb || true
rmdir CfPWeb || true
# verify
ls CfPWeb 2>/dev/null && echo "CfPWeb still exists, investigate" || echo "CfPWeb removed"
```

- [ ] **Step 3: Update WebCfP target's resource path in `Web/Package.swift`**

Verify the `resources: [.copy("../../Public")]` path resolves to `Web/Public/`. From `Web/Sources/WebCfP/`, `../../Public` is `Web/Public`. Confirm by:

```bash
ls Web/Public
```
Expected: `scripts/`, `styles/`, `images/`, etc.

- [ ] **Step 4: Build WebCfP**

Run: `cd Web && swift build --target WebCfP`
Expected: builds without errors.

If errors mention missing `WebShared` symbols, those are from CfPWeb's existing `AppLayout.swift` which currently has no external dep. They should compile as-is.

- [ ] **Step 5: Run WebCfP and verify output**

```bash
cd Web
swift run WebCfP --api-base-url http://localhost:8080 --output Build
ls Build/index.html
```
Expected: `Build/index.html` exists, same content as the previous `CfPWeb/Build/index.html`.

- [ ] **Step 6: Commit**

```bash
git add Web/ CfPWeb/
git commit -m "Move CfPWeb into Web/Sources/WebCfP and Web/Public"
```

### Task A3: Move `Website/` into `Web/Sources/WebConference/`

**Files:**
- Move: `Website/Sources/Website/` → `Web/Sources/WebConference/` (preserve subdirectories)
- Move: `Website/Assets/` → `Web/Sources/WebConference/Assets/`
- Delete: `Website/Package.swift`, `Website/Package.resolved`, `Website/README.md`
- Delete: `Website/` directory once empty

- [ ] **Step 1: Move Website sources via `git mv`**

```bash
rm Web/Sources/WebConference/main.swift  # remove placeholder

# Website's entry point file is ConferenceWebsite.swift — confirm with `ls Website/Sources/Website/`
git mv Website/Sources/Website/* Web/Sources/WebConference/
git mv Website/Assets Web/Sources/WebConference/Assets
```

- [ ] **Step 2: Remove old Website metadata**

```bash
rm Website/Package.swift
rm -f Website/Package.resolved Website/README.md
rmdir Website/Sources/Website Website/Sources Website || true
ls Website 2>/dev/null && echo "Website still exists, investigate" || echo "Website removed"
```

- [ ] **Step 3: Update Ignite resource references if needed**

Open `Web/Sources/WebConference/ConferenceWebsite.swift` (or whatever the renamed entry file is) and check whether it references `"Assets"` as a relative path. Ignite's `Site.assetsPath` may need updating. If the original used `assetsPath: "../../Assets"`, it must become `assetsPath: "Assets"` since Assets is now adjacent.

```bash
grep -n "assetsPath\|Assets/" Web/Sources/WebConference/*.swift
```

If you find a path mismatch, fix it inline so Assets resolves to `Web/Sources/WebConference/Assets/`.

- [ ] **Step 4: Build WebConference**

Run: `cd Web && swift build --target WebConference`
Expected: build succeeds.

- [ ] **Step 5: Run WebConference and verify output**

```bash
cd Web
swift run WebConference
ls Build/  # default output dir per Ignite's Site protocol
```
Expected: HTML files present, e.g. `Build/index.html`, `Build/speakers/...`.

- [ ] **Step 6: Commit**

```bash
git add Web/ Website/
git commit -m "Move Website into Web/Sources/WebConference"
```

### Task A4: Update GitHub Actions workflows for new paths

**Files:**
- Modify: `.github/workflows/format.yml`
- Modify: `.github/workflows/test-website.yml`
- Modify: `.github/workflows/test-cfpweb.yml` (if exists)
- Modify: `.github/workflows/deploy_website.yml`
- Modify: `.github/workflows/deploy-cfpweb.yml`
- Modify: `.github/workflows/test-api-server.yml`

- [ ] **Step 1: Inspect existing workflows**

```bash
ls .github/workflows/
grep -l "CfPWeb\|Website" .github/workflows/*.yml
```

- [ ] **Step 2: Update `.github/workflows/format.yml`**

Replace any `./Website` and `./CfPWeb` arguments with `./Web`. Common pattern:

```yaml
# before
- run: swift format --in-place --recursive ./SharedModels ./DataClient ./Server ./Website ./CfPWeb
# after
- run: swift format --in-place --recursive ./SharedModels ./DataClient ./Server ./Web
```

Use the actual line from the workflow file (read it first with `cat .github/workflows/format.yml`).

- [ ] **Step 3: Update `.github/workflows/test-website.yml`**

```yaml
on:
  pull_request:
    paths:
      - 'Web/Sources/WebConference/**'
      - 'Web/Sources/WebShared/**'
      - 'Web/Package.swift'
      - 'Web/Package.resolved'
      - 'SharedModels/**'
      - 'DataClient/**'
      - 'LocalizationGenerated/**'
      - '.github/workflows/test-website.yml'
jobs:
  build:
    # ...
    steps:
      # ...
      - run: cd Web && swift build --target WebConference
```

- [ ] **Step 4: Update `.github/workflows/test-cfpweb.yml` if present**

```yaml
on:
  pull_request:
    paths:
      - 'Web/Sources/WebCfP/**'
      - 'Web/Sources/WebShared/**'
      - 'Web/Public/**'
      - 'Web/Package.swift'
      - '.github/workflows/test-cfpweb.yml'
jobs:
  build:
    # ...
    steps:
      - run: cd Web && swift build --target WebCfP
```

- [ ] **Step 5: Update `.github/workflows/deploy-cfpweb.yml`**

Find the build step that currently does `cd CfPWeb && swift run CfPWeb …`. Replace with:

```yaml
- name: Build CfP site
  run: cd Web && swift run WebCfP --api-base-url ${{ vars.API_BASE_URL }} --output Build

# Wrangler deploy step — change directory:
- name: Deploy to Cloudflare Pages
  run: npx wrangler pages deploy Web/Build --project-name=tryswift-cfp
```

Update path filters:
```yaml
on:
  push:
    branches: [main]
    paths:
      - 'Web/Sources/WebCfP/**'
      - 'Web/Sources/WebShared/**'
      - 'Web/Public/**'
```

- [ ] **Step 6: Update `.github/workflows/deploy_website.yml`**

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'Web/Sources/WebConference/**'
      - 'Web/Sources/WebShared/**'
      - 'SharedModels/**'
      - 'DataClient/**'
      - 'LocalizationGenerated/**'

jobs:
  deploy:
    steps:
      - name: Build site
        run: cd Web && swift run WebConference
      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./Web/Build
```

If there is a redirect step that wrote a `cfp/index.html` redirect, keep it but adjust paths to `./Web/Build/cfp/`.

- [ ] **Step 7: Update `.github/workflows/test-api-server.yml`**

Add `Web/**` to triggers since Server now depends on Web:

```yaml
on:
  pull_request:
    paths:
      - 'Server/**'
      - 'SharedModels/**'
      - 'Web/**'
      - '.github/workflows/test-api-server.yml'
```

- [ ] **Step 8: Commit**

```bash
git add .github/workflows/
git commit -m "Point CI workflows to new Web/ package layout"
```

### Task A5: Update Xcode workspace package references

**Files:**
- Modify: `trySwiftTokyo.xcworkspace/contents.xcworkspacedata`
- Modify: `trySwiftTokyo.xcworkspace/xcshareddata/swiftpm/Package.resolved` (regenerated)

- [ ] **Step 1: Read the workspace file**

```bash
cat trySwiftTokyo.xcworkspace/contents.xcworkspacedata
```

- [ ] **Step 2: Replace CfPWeb and Website references with Web**

Replace any `<FileRef location = "group:CfPWeb">` and `<FileRef location = "group:Website">` lines with a single `<FileRef location = "group:Web">`. The XML structure is:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version = "1.0">
   <FileRef location = "group:trySwiftTokyo.xcodeproj"></FileRef>
   <FileRef location = "group:Server"></FileRef>
   <FileRef location = "group:Web"></FileRef>           <!-- NEW, replaces CfPWeb + Website -->
   <FileRef location = "group:SharedModels"></FileRef>
   <!-- ... existing entries ... -->
</Workspace>
```

- [ ] **Step 3: Regenerate Package.resolved**

```bash
cd trySwiftTokyo.xcworkspace
# Easiest path: open Xcode, File → Packages → Reset Package Caches, then File → Packages → Resolve Package Versions
# Headless alternative if xcodebuild is desired:
xcodebuild -resolvePackageDependencies -workspace trySwiftTokyo.xcworkspace -scheme Server
```

- [ ] **Step 4: Verify workspace opens cleanly**

```bash
xed trySwiftTokyo.xcworkspace
```
Manually verify Web package shows in the navigator with WebShared / WebSponsor / WebCfP / WebConference targets.

- [ ] **Step 5: Commit**

```bash
git add trySwiftTokyo.xcworkspace/
git commit -m "Update Xcode workspace to reference unified Web/ package"
```

### Task A6: Verify CfPWeb and Website still deploy end-to-end

**Files:** none (this is a verification task)

- [ ] **Step 1: Local CfPWeb deploy dry-run**

```bash
cd Web
rm -rf Build
swift run WebCfP --api-base-url https://api.tryswift.jp --output Build
test -f Build/index.html && echo OK || echo FAIL
test -f Build/styles/app.css && echo OK || echo FAIL
test -f Build/scripts/app.js && echo OK || echo FAIL
```
All three must echo `OK`.

- [ ] **Step 2: Local Website deploy dry-run**

```bash
cd Web
rm -rf Build  # Ignite reuses Build/, so wipe between runs
swift run WebConference
test -f Build/index.html && echo OK || echo FAIL
ls Build/  # eyeball: speakers/, schedule/, etc. should exist as before
```

- [ ] **Step 3: Push branch and verify CI green**

```bash
git push -u origin spec/sponsor-portal-foundation  # or whatever branch carries Phase A
# Wait for all triggered workflows (format, test-website, test-cfpweb, test-api-server) to complete
```

If anything fails, fix path filters / build commands inline and re-push.

- [ ] **Step 4: Tag Phase A complete**

```bash
git tag -a phase-a-complete -m "Web/ migration complete; CfPWeb/Website unchanged behavior"
```

(Tag is optional but useful as a checkpoint.)

---

## Phase B: Foundation Feature Implementation

Phase B builds on top of A. Server now depends on `Web/`, and `WebSponsor` library is fleshed out alongside Server-side data layer + auth + controllers.

### Task B1: Add Sponsor enums to SharedModels

**Files:**
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorPortalLocale.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorMemberRole.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorOrganizationStatus.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorApplicationStatus.swift`

- [ ] **Step 1: Write `SponsorPortalLocale.swift`**

```swift
import Foundation

public enum SponsorPortalLocale: String, Codable, Sendable, CaseIterable, Equatable {
  case ja
  case en

  public static let `default`: SponsorPortalLocale = .ja

  public var htmlLangCode: String {
    switch self {
    case .ja: return "ja"
    case .en: return "en"
    }
  }
}
```

- [ ] **Step 2: Write `SponsorMemberRole.swift`**

```swift
import Foundation

public enum SponsorMemberRole: String, Codable, Sendable, Equatable {
  case owner
  case member
}
```

- [ ] **Step 3: Write `SponsorOrganizationStatus.swift`**

```swift
import Foundation

public enum SponsorOrganizationStatus: String, Codable, Sendable, Equatable {
  case active
  case suspended
  case archived
}
```

- [ ] **Step 4: Write `SponsorApplicationStatus.swift`**

```swift
import Foundation

public enum SponsorApplicationStatus: String, Codable, Sendable, Equatable, CaseIterable {
  case draft
  case submitted
  case underReview = "under_review"
  case approved
  case rejected
  case withdrawn
}
```

- [ ] **Step 5: Build to confirm**

Run: `cd SharedModels && swift build`
Expected: succeeds with no errors.

- [ ] **Step 6: Commit**

```bash
git add SharedModels/Sources/SharedModels/Sponsor/
git commit -m "Add Sponsor enums to SharedModels"
```

### Task B2: Add Sponsor DTOs to SharedModels

**Files:**
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorOrganizationDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorUserDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorMembershipDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorPlanDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorPlanLocalizationDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorInquiryDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorApplicationDTO.swift`
- Create: `SharedModels/Sources/SharedModels/Sponsor/SponsorApplicationFormPayload.swift`

- [ ] **Step 1: `SponsorOrganizationDTO.swift`**

```swift
import Foundation

public struct SponsorOrganizationDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let legalName: String
  public let displayName: String
  public let country: String?
  public let billingAddress: String?
  public let websiteURL: String?
  public let status: SponsorOrganizationStatus
  public let createdAt: Date?
  public let updatedAt: Date?

  public init(id: UUID, legalName: String, displayName: String, country: String?,
              billingAddress: String?, websiteURL: String?,
              status: SponsorOrganizationStatus, createdAt: Date?, updatedAt: Date?) {
    self.id = id
    self.legalName = legalName
    self.displayName = displayName
    self.country = country
    self.billingAddress = billingAddress
    self.websiteURL = websiteURL
    self.status = status
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
```

- [ ] **Step 2: `SponsorUserDTO.swift`**

```swift
import Foundation

public struct SponsorUserDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let email: String
  public let displayName: String?
  public let locale: SponsorPortalLocale
  public let createdAt: Date?

  public init(id: UUID, email: String, displayName: String?,
              locale: SponsorPortalLocale, createdAt: Date?) {
    self.id = id
    self.email = email
    self.displayName = displayName
    self.locale = locale
    self.createdAt = createdAt
  }
}
```

- [ ] **Step 3: `SponsorMembershipDTO.swift`**

```swift
import Foundation

public struct SponsorMembershipDTO: Codable, Sendable, Equatable {
  public let userID: UUID
  public let organizationID: UUID
  public let role: SponsorMemberRole
  public let invitedByUserID: UUID?
  public let createdAt: Date?

  public init(userID: UUID, organizationID: UUID, role: SponsorMemberRole,
              invitedByUserID: UUID?, createdAt: Date?) {
    self.userID = userID
    self.organizationID = organizationID
    self.role = role
    self.invitedByUserID = invitedByUserID
    self.createdAt = createdAt
  }
}
```

- [ ] **Step 4: `SponsorPlanDTO.swift`**

```swift
import Foundation

public struct SponsorPlanDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceID: UUID
  public let slug: String
  public let sortOrder: Int
  public let priceJPY: Int
  public let capacity: Int?
  public let deadlineAt: Date?
  public let isActive: Bool
  public let localizations: [SponsorPlanLocalizationDTO]

  public init(id: UUID, conferenceID: UUID, slug: String, sortOrder: Int,
              priceJPY: Int, capacity: Int?, deadlineAt: Date?, isActive: Bool,
              localizations: [SponsorPlanLocalizationDTO]) {
    self.id = id
    self.conferenceID = conferenceID
    self.slug = slug
    self.sortOrder = sortOrder
    self.priceJPY = priceJPY
    self.capacity = capacity
    self.deadlineAt = deadlineAt
    self.isActive = isActive
    self.localizations = localizations
  }

  public func localized(for locale: SponsorPortalLocale) -> SponsorPlanLocalizationDTO? {
    localizations.first(where: { $0.locale == locale })
      ?? localizations.first(where: { $0.locale == .default })
  }
}
```

- [ ] **Step 5: `SponsorPlanLocalizationDTO.swift`**

```swift
import Foundation

public struct SponsorPlanLocalizationDTO: Codable, Sendable, Equatable {
  public let locale: SponsorPortalLocale
  public let name: String
  public let summary: String
  public let benefits: [String]

  public init(locale: SponsorPortalLocale, name: String, summary: String, benefits: [String]) {
    self.locale = locale
    self.name = name
    self.summary = summary
    self.benefits = benefits
  }
}
```

- [ ] **Step 6: `SponsorInquiryDTO.swift`**

```swift
import Foundation

public struct SponsorInquiryDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let conferenceID: UUID
  public let companyName: String
  public let contactName: String
  public let email: String
  public let desiredPlanSlug: String?
  public let message: String
  public let locale: SponsorPortalLocale
  public let createdAt: Date?

  public init(id: UUID, conferenceID: UUID, companyName: String, contactName: String,
              email: String, desiredPlanSlug: String?, message: String,
              locale: SponsorPortalLocale, createdAt: Date?) {
    self.id = id
    self.conferenceID = conferenceID
    self.companyName = companyName
    self.contactName = contactName
    self.email = email
    self.desiredPlanSlug = desiredPlanSlug
    self.message = message
    self.locale = locale
    self.createdAt = createdAt
  }
}
```

- [ ] **Step 7: `SponsorApplicationDTO.swift`**

```swift
import Foundation

public struct SponsorApplicationDTO: Codable, Sendable, Equatable, Identifiable {
  public let id: UUID
  public let organizationID: UUID
  public let planID: UUID
  public let conferenceID: UUID
  public let status: SponsorApplicationStatus
  public let payload: SponsorApplicationFormPayload
  public let submittedAt: Date?
  public let decidedAt: Date?
  public let decisionNote: String?

  public init(id: UUID, organizationID: UUID, planID: UUID, conferenceID: UUID,
              status: SponsorApplicationStatus, payload: SponsorApplicationFormPayload,
              submittedAt: Date?, decidedAt: Date?, decisionNote: String?) {
    self.id = id
    self.organizationID = organizationID
    self.planID = planID
    self.conferenceID = conferenceID
    self.status = status
    self.payload = payload
    self.submittedAt = submittedAt
    self.decidedAt = decidedAt
    self.decisionNote = decisionNote
  }
}
```

- [ ] **Step 8: `SponsorApplicationFormPayload.swift`**

```swift
import Foundation

/// Snapshot of the application form values at submission time.
/// Stored as JSONB in `sponsor_applications.payload`.
public struct SponsorApplicationFormPayload: Codable, Sendable, Equatable {
  public let billingContactName: String
  public let billingEmail: String
  public let invoicingNotes: String?
  public let logoNote: String?       // free-form note about logo, real upload comes in sub-project #4
  public let acceptedTerms: Bool
  public let locale: SponsorPortalLocale

  public init(billingContactName: String, billingEmail: String, invoicingNotes: String?,
              logoNote: String?, acceptedTerms: Bool, locale: SponsorPortalLocale) {
    self.billingContactName = billingContactName
    self.billingEmail = billingEmail
    self.invoicingNotes = invoicingNotes
    self.logoNote = logoNote
    self.acceptedTerms = acceptedTerms
    self.locale = locale
  }
}
```

- [ ] **Step 9: Build SharedModels**

Run: `cd SharedModels && swift build`
Expected: success.

- [ ] **Step 10: Commit**

```bash
git add SharedModels/Sources/SharedModels/Sponsor/
git commit -m "Add Sponsor DTOs and form payload to SharedModels"
```

### Task B3: Wire Server to depend on Web/ + add swift-crypto

**Files:**
- Modify: `Server/Package.swift`

- [ ] **Step 1: Read current `Server/Package.swift`**

```bash
cat Server/Package.swift
```

- [ ] **Step 2: Add `Web` and `Crypto` dependencies**

Replace the `dependencies:` array entries to add:

```swift
.package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
.package(name: "Web", path: "../Web"),
```

And in the Server target's `dependencies`:

```swift
.product(name: "WebShared", package: "Web"),
.product(name: "WebSponsor", package: "Web"),
.product(name: "Crypto", package: "swift-crypto"),
```

- [ ] **Step 3: Build**

Run: `cd Server && swift build`
Expected: succeeds (Web/Sources/WebSponsor is currently empty placeholder so links cleanly).

- [ ] **Step 4: Commit**

```bash
git add Server/Package.swift
git commit -m "Wire Server to depend on Web/ package and swift-crypto"
```

### Task B4: Conference: add `isAcceptingSponsors` column + migration

**Files:**
- Modify: `Server/Sources/Server/Models/Conference.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/AddIsAcceptingSponsorsToConference.swift`

- [ ] **Step 1: Add the field to `Conference` model**

Open `Server/Sources/Server/Models/Conference.swift`. Add after the `isOpen` field:

```swift
  /// Whether sponsor applications are currently being accepted for this conference.
  @Field(key: "is_accepting_sponsors")
  var isAcceptingSponsors: Bool
```

Add `isAcceptingSponsors: Bool = false` to the `init(...)` initializer parameter list and set `self.isAcceptingSponsors = isAcceptingSponsors`.

- [ ] **Step 2: Update `toDTO()` if `ConferenceDTO` will surface this field — DEFER**

For Foundation we keep `ConferenceDTO` as-is (existing iOS / Website don't read this flag yet). Only add to the model + migration. No DTO change needed in this task.

- [ ] **Step 3: Write the migration**

Create `Server/Sources/Server/Sponsor/Migrations/AddIsAcceptingSponsorsToConference.swift`:

```swift
import Fluent

struct AddIsAcceptingSponsorsToConference: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .field("is_accepting_sponsors", .bool, .required, .sql(.default(false)))
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Conference.schema)
      .deleteField("is_accepting_sponsors")
      .update()
  }
}
```

- [ ] **Step 4: Register in `configure.swift`**

In `Server/Sources/Server/configure.swift`, after the existing migrations and before `try await app.autoMigrate()`, add:

```swift
    app.migrations.add(AddIsAcceptingSponsorsToConference())
```

- [ ] **Step 5: Build**

Run: `cd Server && swift build`
Expected: success.

- [ ] **Step 6: Commit**

```bash
git add Server/Sources/Server/Models/Conference.swift \
        Server/Sources/Server/Sponsor/Migrations/AddIsAcceptingSponsorsToConference.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add Conference.isAcceptingSponsors column and migration"
```

### Task B5: SponsorOrganization model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorOrganization.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorOrganization.swift`

- [ ] **Step 1: Write the model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorOrganization: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_organizations"

  @ID(key: .id) var id: UUID?
  @Field(key: "legal_name") var legalName: String
  @Field(key: "display_name") var displayName: String
  @OptionalField(key: "country") var country: String?
  @OptionalField(key: "billing_address") var billingAddress: String?
  @OptionalField(key: "website_url") var websiteURL: String?
  @Field(key: "status") var status: SponsorOrganizationStatus
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  @Children(for: \.$organization) var memberships: [SponsorMembership]
  @Children(for: \.$organization) var applications: [SponsorApplication]

  init() {}

  init(id: UUID? = nil, legalName: String, displayName: String,
       country: String? = nil, billingAddress: String? = nil,
       websiteURL: String? = nil, status: SponsorOrganizationStatus = .active) {
    self.id = id
    self.legalName = legalName
    self.displayName = displayName
    self.country = country
    self.billingAddress = billingAddress
    self.websiteURL = websiteURL
    self.status = status
  }

  func toDTO() throws -> SponsorOrganizationDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorOrganization missing id") }
    return SponsorOrganizationDTO(
      id: id, legalName: legalName, displayName: displayName,
      country: country, billingAddress: billingAddress,
      websiteURL: websiteURL, status: status,
      createdAt: createdAt, updatedAt: updatedAt
    )
  }
}
```

- [ ] **Step 2: Write the migration**

```swift
import Fluent

struct CreateSponsorOrganization: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorOrganization.schema)
      .id()
      .field("legal_name", .string, .required)
      .field("display_name", .string, .required)
      .field("country", .string)
      .field("billing_address", .string)
      .field("website_url", .string)
      .field("status", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorOrganization.schema).delete()
  }
}
```

- [ ] **Step 3: Register migration**

Add in `configure.swift` after `AddIsAcceptingSponsorsToConference`:

```swift
    app.migrations.add(CreateSponsorOrganization())
```

- [ ] **Step 4: Build**

Run: `cd Server && swift build`
Expected: errors about `SponsorMembership` and `SponsorApplication` not existing — that's OK because we add them in B6/B11. Comment out the `@Children` lines temporarily; restore them in B6 / B11.

Easier alternative: skip the `@Children` for now; add them in B6 (Membership) and B11 (Application) tasks.

Apply this diff before building: remove the two `@Children` declarations.

Then run again. Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Server/Sources/Server/Sponsor/Models/SponsorOrganization.swift \
        Server/Sources/Server/Sponsor/Migrations/CreateSponsorOrganization.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorOrganization model and migration"
```

### Task B6: SponsorUser model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorUser.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorUser.swift`

- [ ] **Step 1: Write the model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorUser: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_users"

  @ID(key: .id) var id: UUID?
  @Field(key: "email") var email: String
  @OptionalField(key: "display_name") var displayName: String?
  @Field(key: "locale") var locale: SponsorPortalLocale
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(id: UUID? = nil, email: String, displayName: String? = nil,
       locale: SponsorPortalLocale = .default) {
    self.id = id
    self.email = email.lowercased()
    self.displayName = displayName
    self.locale = locale
  }

  func toDTO() throws -> SponsorUserDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorUser missing id") }
    return SponsorUserDTO(id: id, email: email, displayName: displayName,
                          locale: locale, createdAt: createdAt)
  }
}
```

- [ ] **Step 2: Write the migration**

```swift
import Fluent

struct CreateSponsorUser: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorUser.schema)
      .id()
      .field("email", .string, .required)
      .field("display_name", .string)
      .field("locale", .string, .required)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "email")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorUser.schema).delete()
  }
}
```

- [ ] **Step 3: Register migration**

```swift
    app.migrations.add(CreateSponsorUser())
```

- [ ] **Step 4: Build**

Run: `cd Server && swift build`
Expected: success.

- [ ] **Step 5: Commit**

```bash
git add Server/Sources/Server/Sponsor/Models/SponsorUser.swift \
        Server/Sources/Server/Sponsor/Migrations/CreateSponsorUser.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorUser model and migration"
```

### Task B7: SponsorMembership model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorMembership.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorMembership.swift`
- Modify: `Server/Sources/Server/Sponsor/Models/SponsorOrganization.swift` (re-add `@Children`)

- [ ] **Step 1: Write the model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorMembership: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_memberships"

  @ID(key: .id) var id: UUID?

  @Parent(key: "organization_id") var organization: SponsorOrganization
  @Parent(key: "sponsor_user_id") var user: SponsorUser

  @Field(key: "role") var role: SponsorMemberRole
  @OptionalField(key: "invited_by_sponsor_user_id") var invitedByUserID: UUID?

  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(id: UUID? = nil, organizationID: UUID, userID: UUID,
       role: SponsorMemberRole, invitedByUserID: UUID? = nil) {
    self.id = id
    self.$organization.id = organizationID
    self.$user.id = userID
    self.role = role
    self.invitedByUserID = invitedByUserID
  }

  func toDTO() -> SponsorMembershipDTO {
    SponsorMembershipDTO(
      userID: $user.id, organizationID: $organization.id,
      role: role, invitedByUserID: invitedByUserID, createdAt: createdAt
    )
  }
}
```

- [ ] **Step 2: Write the migration**

```swift
import Fluent

struct CreateSponsorMembership: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorMembership.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id", onDelete: .cascade))
      .field("sponsor_user_id", .uuid, .required, .references(SponsorUser.schema, "id", onDelete: .cascade))
      .field("role", .string, .required)
      .field("invited_by_sponsor_user_id", .uuid)
      .field("created_at", .datetime)
      .unique(on: "organization_id", "sponsor_user_id")
      .create()

    try await database.schema(SponsorMembership.schema)
      .field("idx_sponsor_membership_user", .custom("sponsor_user_id"))  // helper if Fluent supports indexed-by; alternatively use SQL
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorMembership.schema).delete()
  }
}
```

If Fluent's index API doesn't accept the helper above, drop the `.update()` block. Postgres will still answer fast lookups via the unique constraint; explicit `sponsor_user_id` index can be added later via a separate migration if profiling shows a need.

- [ ] **Step 3: Re-add `@Children(for: \.$organization)` to `SponsorOrganization`**

```swift
  @Children(for: \.$organization) var memberships: [SponsorMembership]
```

- [ ] **Step 4: Register migration**

```swift
    app.migrations.add(CreateSponsorMembership())
```

- [ ] **Step 5: Build & commit**

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Models/{SponsorMembership.swift,SponsorOrganization.swift} \
        Server/Sources/Server/Sponsor/Migrations/CreateSponsorMembership.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorMembership model and migration"
```

### Task B8: SponsorPlan + SponsorPlanLocalization models + migrations

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorPlan.swift`
- Create: `Server/Sources/Server/Sponsor/Models/SponsorPlanLocalization.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorPlan.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorPlanLocalization.swift`

- [ ] **Step 1: `SponsorPlan` model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorPlan: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_plans"

  @ID(key: .id) var id: UUID?
  @Parent(key: "conference_id") var conference: Conference
  @Field(key: "slug") var slug: String
  @Field(key: "sort_order") var sortOrder: Int
  @Field(key: "price_jpy") var priceJPY: Int
  @OptionalField(key: "capacity") var capacity: Int?
  @OptionalField(key: "deadline_at") var deadlineAt: Date?
  @Field(key: "is_active") var isActive: Bool
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  @Children(for: \.$plan) var localizations: [SponsorPlanLocalization]

  init() {}

  init(id: UUID? = nil, conferenceID: UUID, slug: String, sortOrder: Int,
       priceJPY: Int, capacity: Int? = nil, deadlineAt: Date? = nil,
       isActive: Bool = true) {
    self.id = id
    self.$conference.id = conferenceID
    self.slug = slug
    self.sortOrder = sortOrder
    self.priceJPY = priceJPY
    self.capacity = capacity
    self.deadlineAt = deadlineAt
    self.isActive = isActive
  }

  func toDTO() throws -> SponsorPlanDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorPlan missing id") }
    return SponsorPlanDTO(
      id: id, conferenceID: $conference.id, slug: slug, sortOrder: sortOrder,
      priceJPY: priceJPY, capacity: capacity, deadlineAt: deadlineAt,
      isActive: isActive,
      localizations: localizations.map { $0.toDTO() }
    )
  }
}
```

- [ ] **Step 2: `SponsorPlanLocalization` model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorPlanLocalization: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_plan_localizations"

  @ID(key: .id) var id: UUID?
  @Parent(key: "plan_id") var plan: SponsorPlan
  @Field(key: "locale") var locale: SponsorPortalLocale
  @Field(key: "name") var name: String
  @Field(key: "summary") var summary: String
  @Field(key: "benefits") var benefits: [String]   // stored as JSONB

  init() {}

  init(id: UUID? = nil, planID: UUID, locale: SponsorPortalLocale,
       name: String, summary: String, benefits: [String]) {
    self.id = id
    self.$plan.id = planID
    self.locale = locale
    self.name = name
    self.summary = summary
    self.benefits = benefits
  }

  func toDTO() -> SponsorPlanLocalizationDTO {
    SponsorPlanLocalizationDTO(locale: locale, name: name, summary: summary, benefits: benefits)
  }
}
```

- [ ] **Step 3: Migrations**

```swift
// CreateSponsorPlan.swift
import Fluent

struct CreateSponsorPlan: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorPlan.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id", onDelete: .cascade))
      .field("slug", .string, .required)
      .field("sort_order", .int, .required)
      .field("price_jpy", .int, .required)
      .field("capacity", .int)
      .field("deadline_at", .datetime)
      .field("is_active", .bool, .required, .sql(.default(true)))
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .unique(on: "conference_id", "slug")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorPlan.schema).delete()
  }
}
```

```swift
// CreateSponsorPlanLocalization.swift
import Fluent

struct CreateSponsorPlanLocalization: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorPlanLocalization.schema)
      .id()
      .field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id", onDelete: .cascade))
      .field("locale", .string, .required)
      .field("name", .string, .required)
      .field("summary", .string, .required)
      .field("benefits", .json, .required)
      .unique(on: "plan_id", "locale")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorPlanLocalization.schema).delete()
  }
}
```

- [ ] **Step 4: Register both migrations**

```swift
    app.migrations.add(CreateSponsorPlan())
    app.migrations.add(CreateSponsorPlanLocalization())
```

- [ ] **Step 5: Build & commit**

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Models/{SponsorPlan,SponsorPlanLocalization}.swift \
        Server/Sources/Server/Sponsor/Migrations/{CreateSponsorPlan,CreateSponsorPlanLocalization}.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorPlan and SponsorPlanLocalization models with migrations"
```

### Task B9: SponsorInquiry model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorInquiry.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorInquiry.swift`

- [ ] **Step 1: Model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorInquiry: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_inquiries"

  enum Status: String, Codable, Sendable { case open, contacted, converted, archived }

  @ID(key: .id) var id: UUID?
  @Parent(key: "conference_id") var conference: Conference
  @Field(key: "company_name") var companyName: String
  @Field(key: "contact_name") var contactName: String
  @Field(key: "email") var email: String
  @OptionalField(key: "desired_plan_slug") var desiredPlanSlug: String?
  @Field(key: "message") var message: String
  @Field(key: "locale") var locale: SponsorPortalLocale
  @Field(key: "status") var status: Status
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(id: UUID? = nil, conferenceID: UUID, companyName: String, contactName: String,
       email: String, desiredPlanSlug: String? = nil, message: String,
       locale: SponsorPortalLocale, status: Status = .open) {
    self.id = id
    self.$conference.id = conferenceID
    self.companyName = companyName
    self.contactName = contactName
    self.email = email.lowercased()
    self.desiredPlanSlug = desiredPlanSlug
    self.message = message
    self.locale = locale
    self.status = status
  }

  func toDTO() throws -> SponsorInquiryDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorInquiry missing id") }
    return SponsorInquiryDTO(
      id: id, conferenceID: $conference.id, companyName: companyName,
      contactName: contactName, email: email, desiredPlanSlug: desiredPlanSlug,
      message: message, locale: locale, createdAt: createdAt
    )
  }
}
```

- [ ] **Step 2: Migration**

```swift
import Fluent

struct CreateSponsorInquiry: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorInquiry.schema)
      .id()
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id", onDelete: .cascade))
      .field("company_name", .string, .required)
      .field("contact_name", .string, .required)
      .field("email", .string, .required)
      .field("desired_plan_slug", .string)
      .field("message", .string, .required)
      .field("locale", .string, .required)
      .field("status", .string, .required)
      .field("created_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorInquiry.schema).delete()
  }
}
```

- [ ] **Step 3: Register & commit**

```swift
    app.migrations.add(CreateSponsorInquiry())
```

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Models/SponsorInquiry.swift \
        Server/Sources/Server/Sponsor/Migrations/CreateSponsorInquiry.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorInquiry model and migration"
```

### Task B10: SponsorApplication model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorApplication.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorApplication.swift`
- Modify: `Server/Sources/Server/Sponsor/Models/SponsorOrganization.swift` (re-add `@Children` for applications)

- [ ] **Step 1: Model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorApplication: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_applications"

  @ID(key: .id) var id: UUID?
  @Parent(key: "organization_id") var organization: SponsorOrganization
  @Parent(key: "plan_id") var plan: SponsorPlan
  @Parent(key: "conference_id") var conference: Conference
  @Field(key: "status") var status: SponsorApplicationStatus
  @Field(key: "payload") var payload: SponsorApplicationFormPayload   // JSONB
  @OptionalField(key: "submitted_at") var submittedAt: Date?
  @OptionalField(key: "decided_at") var decidedAt: Date?
  @OptionalField(key: "decided_by_user_id") var decidedByUserID: UUID?
  @OptionalField(key: "decision_note") var decisionNote: String?
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?
  @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

  init() {}

  init(id: UUID? = nil, organizationID: UUID, planID: UUID, conferenceID: UUID,
       status: SponsorApplicationStatus = .submitted,
       payload: SponsorApplicationFormPayload,
       submittedAt: Date? = nil) {
    self.id = id
    self.$organization.id = organizationID
    self.$plan.id = planID
    self.$conference.id = conferenceID
    self.status = status
    self.payload = payload
    self.submittedAt = submittedAt
  }

  func toDTO() throws -> SponsorApplicationDTO {
    guard let id else { throw Abort(.internalServerError, reason: "SponsorApplication missing id") }
    return SponsorApplicationDTO(
      id: id, organizationID: $organization.id, planID: $plan.id,
      conferenceID: $conference.id, status: status, payload: payload,
      submittedAt: submittedAt, decidedAt: decidedAt, decisionNote: decisionNote
    )
  }
}
```

- [ ] **Step 2: Migration**

```swift
import Fluent

struct CreateSponsorApplication: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorApplication.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id", onDelete: .cascade))
      .field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id"))
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("status", .string, .required)
      .field("payload", .json, .required)
      .field("submitted_at", .datetime)
      .field("decided_at", .datetime)
      .field("decided_by_user_id", .uuid)
      .field("decision_note", .string)
      .field("created_at", .datetime)
      .field("updated_at", .datetime)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorApplication.schema).delete()
  }
}
```

- [ ] **Step 3: Re-add `@Children` to SponsorOrganization**

```swift
  @Children(for: \.$organization) var applications: [SponsorApplication]
```

- [ ] **Step 4: Register, build, commit**

```swift
    app.migrations.add(CreateSponsorApplication())
```

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Models/{SponsorApplication,SponsorOrganization}.swift \
        Server/Sources/Server/Sponsor/Migrations/CreateSponsorApplication.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorApplication model and migration"
```

### Task B11: MagicLinkToken model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/MagicLinkToken.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateMagicLinkToken.swift`

- [ ] **Step 1: Model**

```swift
import Fluent
import Vapor

final class MagicLinkToken: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_magic_link_tokens"

  enum Purpose: String, Codable, Sendable { case login }

  @ID(key: .id) var id: UUID?
  @Parent(key: "sponsor_user_id") var user: SponsorUser
  @Field(key: "token_hash") var tokenHash: String
  @Field(key: "purpose") var purpose: Purpose
  @Field(key: "expires_at") var expiresAt: Date
  @OptionalField(key: "used_at") var usedAt: Date?
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(id: UUID? = nil, userID: UUID, tokenHash: String,
       purpose: Purpose = .login, expiresAt: Date) {
    self.id = id
    self.$user.id = userID
    self.tokenHash = tokenHash
    self.purpose = purpose
    self.expiresAt = expiresAt
  }
}
```

- [ ] **Step 2: Migration**

```swift
import Fluent

struct CreateMagicLinkToken: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(MagicLinkToken.schema)
      .id()
      .field("sponsor_user_id", .uuid, .required, .references(SponsorUser.schema, "id", onDelete: .cascade))
      .field("token_hash", .string, .required)
      .field("purpose", .string, .required)
      .field("expires_at", .datetime, .required)
      .field("used_at", .datetime)
      .field("created_at", .datetime)
      .unique(on: "token_hash")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(MagicLinkToken.schema).delete()
  }
}
```

- [ ] **Step 3: Register, build, commit**

```swift
    app.migrations.add(CreateMagicLinkToken())
```

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Models/MagicLinkToken.swift \
        Server/Sources/Server/Sponsor/Migrations/CreateMagicLinkToken.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add MagicLinkToken model and migration"
```

### Task B12: SponsorInvitation model + migration

**Files:**
- Create: `Server/Sources/Server/Sponsor/Models/SponsorInvitation.swift`
- Create: `Server/Sources/Server/Sponsor/Migrations/CreateSponsorInvitation.swift`

- [ ] **Step 1: Model**

```swift
import Fluent
import SharedModels
import Vapor

final class SponsorInvitation: Model, Content, @unchecked Sendable {
  static let schema = "sponsor_invitations"

  @ID(key: .id) var id: UUID?
  @Parent(key: "organization_id") var organization: SponsorOrganization
  @Field(key: "email") var email: String
  @Field(key: "role") var role: SponsorMemberRole
  @Field(key: "token_hash") var tokenHash: String
  @Field(key: "expires_at") var expiresAt: Date
  @OptionalField(key: "accepted_at") var acceptedAt: Date?
  @Field(key: "invited_by_sponsor_user_id") var invitedByUserID: UUID
  @Timestamp(key: "created_at", on: .create) var createdAt: Date?

  init() {}

  init(id: UUID? = nil, organizationID: UUID, email: String,
       role: SponsorMemberRole, tokenHash: String,
       expiresAt: Date, invitedByUserID: UUID) {
    self.id = id
    self.$organization.id = organizationID
    self.email = email.lowercased()
    self.role = role
    self.tokenHash = tokenHash
    self.expiresAt = expiresAt
    self.invitedByUserID = invitedByUserID
  }
}
```

- [ ] **Step 2: Migration**

```swift
import Fluent

struct CreateSponsorInvitation: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(SponsorInvitation.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id", onDelete: .cascade))
      .field("email", .string, .required)
      .field("role", .string, .required)
      .field("token_hash", .string, .required)
      .field("expires_at", .datetime, .required)
      .field("accepted_at", .datetime)
      .field("invited_by_sponsor_user_id", .uuid, .required)
      .field("created_at", .datetime)
      .unique(on: "token_hash")
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(SponsorInvitation.schema).delete()
  }
}
```

- [ ] **Step 3: Register, build, commit**

```swift
    app.migrations.add(CreateSponsorInvitation())
```

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Models/SponsorInvitation.swift \
        Server/Sources/Server/Sponsor/Migrations/CreateSponsorInvitation.swift \
        Server/Sources/Server/configure.swift
git commit -m "Add SponsorInvitation model and migration"
```

### Task B13: SeedSponsorPlans2026 (idempotent seed)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Migrations/SeedSponsorPlans2026.swift`

- [ ] **Step 1: Write the seed**

```swift
import Fluent
import Foundation
import SharedModels

struct SeedSponsorPlans2026: AsyncMigration {
  private struct PlanSeed {
    let slug: String
    let sortOrder: Int
    let priceJPY: Int
    let capacity: Int?
    let nameJa: String
    let nameEn: String
    let summaryJa: String
    let summaryEn: String
    let benefitsJa: [String]
    let benefitsEn: [String]
  }

  private static let seeds: [PlanSeed] = [
    PlanSeed(slug: "platinum", sortOrder: 10, priceJPY: 2_000_000, capacity: 1,
             nameJa: "Platinum", nameEn: "Platinum",
             summaryJa: "最上位プラン。基調講演前後の枠をご提供。", summaryEn: "Top tier with prime placement around keynotes.",
             benefitsJa: ["ロゴ最大級掲載", "ブース", "ランチ枠"], benefitsEn: ["Largest logo", "Booth", "Lunch slots"]),
    PlanSeed(slug: "gold", sortOrder: 20, priceJPY: 1_000_000, capacity: 3,
             nameJa: "Gold", nameEn: "Gold",
             summaryJa: "ロゴ大、ブース、ランチ。", summaryEn: "Large logo, booth, lunch.",
             benefitsJa: ["ロゴ大掲載", "ブース"], benefitsEn: ["Large logo", "Booth"]),
    PlanSeed(slug: "silver", sortOrder: 30, priceJPY: 500_000, capacity: 8,
             nameJa: "Silver", nameEn: "Silver",
             summaryJa: "ロゴ中、ブース。", summaryEn: "Medium logo, booth.",
             benefitsJa: ["ロゴ中掲載"], benefitsEn: ["Medium logo"]),
    PlanSeed(slug: "bronze", sortOrder: 40, priceJPY: 200_000, capacity: nil,
             nameJa: "Bronze", nameEn: "Bronze",
             summaryJa: "ロゴ掲載。", summaryEn: "Logo placement.",
             benefitsJa: ["ロゴ掲載"], benefitsEn: ["Logo"]),
    PlanSeed(slug: "diversity", sortOrder: 50, priceJPY: 300_000, capacity: nil,
             nameJa: "Diversity & Inclusion", nameEn: "Diversity & Inclusion",
             summaryJa: "D&I 支援。", summaryEn: "D&I support.",
             benefitsJa: ["D&I 招待枠"], benefitsEn: ["D&I tickets"]),
    PlanSeed(slug: "community", sortOrder: 60, priceJPY: 100_000, capacity: nil,
             nameJa: "Community", nameEn: "Community",
             summaryJa: "コミュニティ枠。", summaryEn: "Community partner.",
             benefitsJa: ["コミュニティ告知"], benefitsEn: ["Community shoutout"]),
  ]

  func prepare(on database: Database) async throws {
    guard let conference = try await Conference.query(on: database)
      .filter(\.$path == "tryswift-tokyo-2026")
      .first() else {
      database.logger.warning("SeedSponsorPlans2026: Conference 'tryswift-tokyo-2026' not found, skipping")
      return
    }
    let conferenceID = try conference.requireID()

    // Mark conference as accepting sponsors.
    if !conference.isAcceptingSponsors {
      conference.isAcceptingSponsors = true
      try await conference.save(on: database)
    }

    for seed in Self.seeds {
      let existing = try await SponsorPlan.query(on: database)
        .filter(\.$conference.$id == conferenceID)
        .filter(\.$slug == seed.slug)
        .first()

      let plan: SponsorPlan
      if let existing {
        existing.sortOrder = seed.sortOrder
        existing.priceJPY = seed.priceJPY
        existing.capacity = seed.capacity
        existing.isActive = true
        try await existing.save(on: database)
        plan = existing
      } else {
        plan = SponsorPlan(conferenceID: conferenceID, slug: seed.slug,
                           sortOrder: seed.sortOrder, priceJPY: seed.priceJPY,
                           capacity: seed.capacity)
        try await plan.save(on: database)
      }

      try await upsertLocalization(plan: plan, locale: .ja, name: seed.nameJa,
                                    summary: seed.summaryJa, benefits: seed.benefitsJa, on: database)
      try await upsertLocalization(plan: plan, locale: .en, name: seed.nameEn,
                                    summary: seed.summaryEn, benefits: seed.benefitsEn, on: database)
    }
  }

  func revert(on database: Database) async throws {
    // Delete plans created by this seed.
    let slugs = Self.seeds.map(\.slug)
    try await SponsorPlan.query(on: database)
      .filter(\.$slug ~~ slugs)
      .delete()
  }

  private func upsertLocalization(plan: SponsorPlan, locale: SponsorPortalLocale,
                                   name: String, summary: String, benefits: [String],
                                   on database: Database) async throws {
    let planID = try plan.requireID()
    if let existing = try await SponsorPlanLocalization.query(on: database)
      .filter(\.$plan.$id == planID)
      .filter(\.$locale == locale)
      .first() {
      existing.name = name
      existing.summary = summary
      existing.benefits = benefits
      try await existing.save(on: database)
    } else {
      let loc = SponsorPlanLocalization(planID: planID, locale: locale,
                                         name: name, summary: summary, benefits: benefits)
      try await loc.save(on: database)
    }
  }
}
```

> **Note:** プラン名・価格・特典は spec の確定情報がまだ手元にない部分があるので、実装着手時にスポンサー資料 PDF（`/Users/date/Library/CloudStorage/.../2026/Public/`）の最新値で必ず上書きすること。

- [ ] **Step 2: Register**

```swift
    app.migrations.add(SeedSponsorPlans2026())
```

- [ ] **Step 3: Build & commit**

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Migrations/SeedSponsorPlans2026.swift \
        Server/Sources/Server/configure.swift
git commit -m "Seed SponsorPlan and SponsorPlanLocalization for try! Swift Tokyo 2026"
```

### Task B14: ResendClient (test stubable HTTP client)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Services/ResendClient.swift`
- Create: `Server/Tests/ServerTests/Sponsor/ResendClientTests.swift`

- [ ] **Step 1: Failing test (Swift Testing + VaporTesting)**

```swift
// Server/Tests/ServerTests/Sponsor/ResendClientTests.swift
import Foundation
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("ResendClient")
struct ResendClientTests {
  @Test("Skips send when RESEND_API_KEY missing")
  func skipsWithoutKey() async throws {
    try await withApp { app in
      // Ensure key is not set in this scope.
      let logged = TestLogger()
      let result = await ResendClient.send(
        to: "test@example.com",
        from: "Sponsorship <sponsorship@mail.tryswift.jp>",
        subject: "hi", html: "<p>hi</p>", text: "hi",
        client: app.client, logger: logged.logger,
        env: ["RESEND_API_KEY": nil]
      )
      #expect(result == .skipped)
    }
  }
}

private actor TestLogger {
  var lines: [String] = []
  nonisolated var logger: Logger {
    var l = Logger(label: "test")
    l.logLevel = .debug
    return l
  }
}

func withApp(_ body: (Application) async throws -> Void) async throws {
  let app = try await Application.make(.testing)
  defer { try? await app.asyncShutdown() }
  try await body(app)
}
```

- [ ] **Step 2: Run the test (expect FAIL)**

Run: `cd Server && swift test --filter ResendClientTests`
Expected: FAIL — `ResendClient` is undefined.

- [ ] **Step 3: Implement `ResendClient`**

```swift
// Server/Sources/Server/Sponsor/Services/ResendClient.swift
import Foundation
import Vapor

enum ResendClient {
  enum SendResult: Equatable, Sendable { case sent(messageID: String); case skipped; case failed(status: UInt) }

  /// Send an email through the Resend HTTP API. Returns `.skipped` when no API key is configured.
  static func send(
    to: String,
    from: String,
    subject: String,
    html: String,
    text: String,
    client: Client,
    logger: Logger,
    env: [String: String?] = [:]
  ) async -> SendResult {
    let apiKey = env["RESEND_API_KEY"].flatMap { $0 } ?? Environment.get("RESEND_API_KEY")
    guard let apiKey, !apiKey.isEmpty else {
      logger.debug("RESEND_API_KEY not set, skipping email")
      return .skipped
    }

    struct Payload: Encodable {
      let from: String
      let to: [String]
      let subject: String
      let html: String
      let text: String
    }
    struct ResendResponse: Decodable { let id: String }

    let payload = Payload(from: from, to: [to], subject: subject, html: html, text: text)
    do {
      let response = try await client.post(URI(string: "https://api.resend.com/emails")) { req in
        req.headers.bearerAuthorization = .init(token: apiKey)
        req.headers.contentType = .json
        try req.content.encode(payload, as: .json)
      }
      if response.status.code >= 200 && response.status.code < 300 {
        let decoded = try response.content.decode(ResendResponse.self)
        logger.info("Resend OK", metadata: ["to": .string(to), "id": .string(decoded.id)])
        return .sent(messageID: decoded.id)
      }
      logger.warning("Resend non-2xx", metadata: ["to": .string(to), "status": .stringConvertible(response.status.code)])
      return .failed(status: response.status.code)
    } catch {
      logger.warning("Resend send error", metadata: ["error": .string(String(describing: error))])
      return .failed(status: 0)
    }
  }
}
```

- [ ] **Step 4: Run test (expect PASS)**

Run: `cd Server && swift test --filter ResendClientTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Server/Sources/Server/Sponsor/Services/ResendClient.swift \
        Server/Tests/ServerTests/Sponsor/ResendClientTests.swift
git commit -m "Add ResendClient with skip-when-unconfigured behavior + test"
```

### Task B15: Test schema + factories for Sponsor tests

**Files:**
- Create: `Server/Tests/ServerTests/Sponsor/CreateSponsorTestSchema.swift`
- Create: `Server/Tests/ServerTests/Sponsor/SponsorTestFactories.swift`

- [ ] **Step 1: Write the test schema migration**

Mirror `AdminAPITests.swift`'s `CreateAdminAPITestSchema` pattern. We need User + Conference + every sponsor_* table since SQLite in-memory doesn't run our production migrations directly.

```swift
// Server/Tests/ServerTests/Sponsor/CreateSponsorTestSchema.swift
import Fluent

struct CreateSponsorTestSchema: AsyncMigration {
  var name: String { "CreateSponsorTestSchema" }

  func prepare(on database: Database) async throws {
    try await database.schema(User.schema)
      .id()
      .field("github_id", .int, .required)
      .field("username", .string, .required)
      .field("role", .string, .required)
      .field("display_name", .string).field("email", .string).field("bio", .string)
      .field("url", .string).field("organization", .string).field("avatar_url", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .create()

    try await database.schema(Conference.schema)
      .id().field("path", .string, .required).field("display_name", .string, .required)
      .field("description_en", .string).field("description_ja", .string)
      .field("year", .int, .required).field("is_open", .bool, .required)
      .field("is_accepting_sponsors", .bool, .required, .sql(.default(false)))
      .field("deadline", .datetime).field("start_date", .datetime).field("end_date", .datetime)
      .field("location", .string).field("website_url", .string)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .create()

    try await database.schema(SponsorOrganization.schema)
      .id().field("legal_name", .string, .required).field("display_name", .string, .required)
      .field("country", .string).field("billing_address", .string).field("website_url", .string)
      .field("status", .string, .required)
      .field("created_at", .datetime).field("updated_at", .datetime).create()

    try await database.schema(SponsorUser.schema)
      .id().field("email", .string, .required).field("display_name", .string)
      .field("locale", .string, .required)
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "email").create()

    try await database.schema(SponsorMembership.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id"))
      .field("sponsor_user_id", .uuid, .required, .references(SponsorUser.schema, "id"))
      .field("role", .string, .required)
      .field("invited_by_sponsor_user_id", .uuid)
      .field("created_at", .datetime)
      .unique(on: "organization_id", "sponsor_user_id")
      .create()

    try await database.schema(SponsorPlan.schema)
      .id().field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("slug", .string, .required).field("sort_order", .int, .required)
      .field("price_jpy", .int, .required).field("capacity", .int)
      .field("deadline_at", .datetime).field("is_active", .bool, .required, .sql(.default(true)))
      .field("created_at", .datetime).field("updated_at", .datetime)
      .unique(on: "conference_id", "slug").create()

    try await database.schema(SponsorPlanLocalization.schema)
      .id().field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id"))
      .field("locale", .string, .required).field("name", .string, .required)
      .field("summary", .string, .required).field("benefits", .json, .required)
      .unique(on: "plan_id", "locale").create()

    try await database.schema(SponsorInquiry.schema)
      .id().field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("company_name", .string, .required).field("contact_name", .string, .required)
      .field("email", .string, .required).field("desired_plan_slug", .string)
      .field("message", .string, .required).field("locale", .string, .required)
      .field("status", .string, .required).field("created_at", .datetime).create()

    try await database.schema(SponsorApplication.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id"))
      .field("plan_id", .uuid, .required, .references(SponsorPlan.schema, "id"))
      .field("conference_id", .uuid, .required, .references(Conference.schema, "id"))
      .field("status", .string, .required).field("payload", .json, .required)
      .field("submitted_at", .datetime).field("decided_at", .datetime)
      .field("decided_by_user_id", .uuid).field("decision_note", .string)
      .field("created_at", .datetime).field("updated_at", .datetime).create()

    try await database.schema(MagicLinkToken.schema)
      .id().field("sponsor_user_id", .uuid, .required, .references(SponsorUser.schema, "id"))
      .field("token_hash", .string, .required).field("purpose", .string, .required)
      .field("expires_at", .datetime, .required).field("used_at", .datetime)
      .field("created_at", .datetime)
      .unique(on: "token_hash").create()

    try await database.schema(SponsorInvitation.schema)
      .id()
      .field("organization_id", .uuid, .required, .references(SponsorOrganization.schema, "id"))
      .field("email", .string, .required).field("role", .string, .required)
      .field("token_hash", .string, .required).field("expires_at", .datetime, .required)
      .field("accepted_at", .datetime).field("invited_by_sponsor_user_id", .uuid, .required)
      .field("created_at", .datetime).unique(on: "token_hash").create()
  }

  func revert(on database: Database) async throws {
    for s in [SponsorInvitation.schema, MagicLinkToken.schema,
              SponsorApplication.schema, SponsorInquiry.schema,
              SponsorPlanLocalization.schema, SponsorPlan.schema,
              SponsorMembership.schema, SponsorUser.schema,
              SponsorOrganization.schema, Conference.schema, User.schema] {
      try await database.schema(s).delete()
    }
  }
}
```

- [ ] **Step 2: Write factories**

```swift
// Server/Tests/ServerTests/Sponsor/SponsorTestFactories.swift
import Fluent
import FluentSQLiteDriver
import Foundation
import SharedModels
import Vapor
import VaporTesting

@testable import Server

enum SponsorTestEnv {
  static func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.databases.use(.sqlite(.memory), as: .sqlite)
    app.migrations.add(CreateSponsorTestSchema())
    try await app.autoMigrate()
    if Environment.get("JWT_SECRET") == nil {
      setenv("JWT_SECRET", "test-secret-do-not-use-in-prod", 1)
    }
    await app.jwt.keys.add(hmac: HMACKey(from: "test-secret-do-not-use-in-prod"), digestAlgorithm: .sha256)
    return app
  }

  @discardableResult
  static func conference(_ app: Application,
                          path: String = "tryswift-tokyo-2026",
                          isAcceptingSponsors: Bool = true) async throws -> Conference {
    let c = Conference(path: path, displayName: "try! Swift Tokyo 2026", year: 2026)
    c.isAcceptingSponsors = isAcceptingSponsors
    try await c.save(on: app.db)
    return c
  }

  @discardableResult
  static func sponsorUser(_ app: Application, email: String,
                           locale: SponsorPortalLocale = .ja) async throws -> SponsorUser {
    let u = SponsorUser(email: email, displayName: nil, locale: locale)
    try await u.save(on: app.db)
    return u
  }

  @discardableResult
  static func organization(_ app: Application, ownerEmail: String) async throws -> (SponsorOrganization, SponsorUser) {
    let owner = try await sponsorUser(app, email: ownerEmail)
    let org = SponsorOrganization(legalName: "Acme Inc.", displayName: "Acme")
    try await org.save(on: app.db)
    let mem = SponsorMembership(organizationID: try org.requireID(),
                                  userID: try owner.requireID(),
                                  role: .owner)
    try await mem.save(on: app.db)
    return (org, owner)
  }

  @discardableResult
  static func plan(_ app: Application, conference: Conference, slug: String,
                    priceJPY: Int = 1_000_000) async throws -> SponsorPlan {
    let p = SponsorPlan(conferenceID: try conference.requireID(), slug: slug,
                        sortOrder: 10, priceJPY: priceJPY)
    try await p.save(on: app.db)
    let l = SponsorPlanLocalization(planID: try p.requireID(), locale: .ja,
                                     name: slug.capitalized, summary: "test plan", benefits: ["b1"])
    try await l.save(on: app.db)
    let l2 = SponsorPlanLocalization(planID: try p.requireID(), locale: .en,
                                      name: slug.capitalized, summary: "test plan", benefits: ["b1"])
    try await l2.save(on: app.db)
    return p
  }
}
```

- [ ] **Step 3: Build & commit**

```bash
cd Server && swift build --build-tests
cd ..
git add Server/Tests/ServerTests/Sponsor/CreateSponsorTestSchema.swift \
        Server/Tests/ServerTests/Sponsor/SponsorTestFactories.swift
git commit -m "Add Sponsor test schema and factories"
```

### Task B16: MagicLinkService (TDD)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Services/MagicLinkService.swift`
- Create: `Server/Tests/ServerTests/Sponsor/MagicLinkServiceTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// Server/Tests/ServerTests/Sponsor/MagicLinkServiceTests.swift
import Crypto
import Fluent
import Foundation
import Testing
import Vapor

@testable import Server

@Suite("MagicLinkService")
struct MagicLinkServiceTests {
  @Test("issue stores SHA256 hash, not the raw token")
  func issueStoresHash() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let user = try await SponsorTestEnv.sponsorUser(app, email: "owner@example.com")

    let issued = try await MagicLinkService.issue(for: user, on: app.db,
                                                   ttl: .seconds(60), now: { Date() })
    #expect(issued.rawToken.count >= 32)

    let stored = try await MagicLinkToken.query(on: app.db).first()
    #expect(stored != nil)
    #expect(stored?.tokenHash != issued.rawToken)
    #expect(stored?.tokenHash == MagicLinkService.hash(issued.rawToken))
  }

  @Test("verify returns user for valid token, nil for expired or used")
  func verifyHonorsExpiryAndSingleUse() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    let user = try await SponsorTestEnv.sponsorUser(app, email: "u@example.com")

    let now = Date()
    var clock = now
    let issued = try await MagicLinkService.issue(for: user, on: app.db,
                                                    ttl: .seconds(60), now: { clock })

    let firstResult = try await MagicLinkService.verify(rawToken: issued.rawToken,
                                                          on: app.db, now: { clock })
    #expect(firstResult?.id == user.id)

    let replay = try await MagicLinkService.verify(rawToken: issued.rawToken,
                                                     on: app.db, now: { clock })
    #expect(replay == nil, "Replay must be rejected")

    // Issue another and let it expire.
    let second = try await MagicLinkService.issue(for: user, on: app.db,
                                                    ttl: .seconds(60), now: { clock })
    clock = clock.addingTimeInterval(120)
    let expired = try await MagicLinkService.verify(rawToken: second.rawToken,
                                                      on: app.db, now: { clock })
    #expect(expired == nil, "Expired must be rejected")
  }

  @Test("verify rejects unknown / tampered tokens")
  func tamperedRejected() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    _ = try await SponsorTestEnv.sponsorUser(app, email: "u@example.com")
    let result = try await MagicLinkService.verify(rawToken: "not-a-real-token",
                                                     on: app.db, now: { Date() })
    #expect(result == nil)
  }
}
```

Run: `cd Server && swift test --filter MagicLinkServiceTests`
Expected: FAIL — `MagicLinkService` undefined.

- [ ] **Step 2: Implement `MagicLinkService`**

```swift
// Server/Sources/Server/Sponsor/Services/MagicLinkService.swift
import Crypto
import Fluent
import Foundation
import Vapor

enum MagicLinkService {
  struct Issued: Sendable {
    let rawToken: String
    let tokenID: UUID
    let expiresAt: Date
  }

  static let defaultTTL: Duration = .seconds(30 * 60)  // 30 minutes

  /// Generate a 32-byte URL-safe random token, store its SHA256 hash, return the raw value (only this once).
  static func issue(for user: SponsorUser,
                     on db: Database,
                     ttl: Duration = defaultTTL,
                     now: @Sendable () -> Date = { Date() }) async throws -> Issued {
    let raw = randomURLSafeToken(byteCount: 32)
    let hashed = hash(raw)
    let expires = now().addingTimeInterval(TimeInterval(ttl.components.seconds))
    let token = MagicLinkToken(userID: try user.requireID(), tokenHash: hashed, expiresAt: expires)
    try await token.save(on: db)
    return Issued(rawToken: raw, tokenID: try token.requireID(), expiresAt: expires)
  }

  /// Verify a raw token, mark it consumed if valid, and return the associated user.
  static func verify(rawToken: String,
                      on db: Database,
                      now: @Sendable () -> Date = { Date() }) async throws -> SponsorUser? {
    let hashed = hash(rawToken)
    guard let token = try await MagicLinkToken.query(on: db)
      .filter(\.$tokenHash == hashed)
      .with(\.$user)
      .first() else { return nil }
    if let used = token.usedAt, used > Date(timeIntervalSince1970: 0) { return nil }
    if token.expiresAt <= now() { return nil }

    token.usedAt = now()
    try await token.save(on: db)
    return token.user
  }

  static func hash(_ raw: String) -> String {
    let digest = SHA256.hash(data: Data(raw.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private static func randomURLSafeToken(byteCount: Int) -> String {
    var bytes = [UInt8](repeating: 0, count: byteCount)
    _ = SystemRandomNumberGenerator()
    for i in 0..<byteCount { bytes[i] = UInt8.random(in: .min ... .max) }
    return Data(bytes).base64URLEncodedString()
  }
}

private extension Data {
  func base64URLEncodedString() -> String {
    base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
```

- [ ] **Step 3: Run tests (expect PASS)**

Run: `cd Server && swift test --filter MagicLinkServiceTests`
Expected: PASS for all 3 tests.

- [ ] **Step 4: Commit**

```bash
git add Server/Sources/Server/Sponsor/Services/MagicLinkService.swift \
        Server/Tests/ServerTests/Sponsor/MagicLinkServiceTests.swift
git commit -m "Add MagicLinkService with issue/verify/replay tests"
```

### Task B17: SponsorEmailTemplates (data-driven)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Services/SponsorEmailTemplates.swift`
- Create: `Server/Tests/ServerTests/Sponsor/SponsorEmailTemplatesTests.swift`

- [ ] **Step 1: Failing tests for subject text snapshots**

```swift
// Server/Tests/ServerTests/Sponsor/SponsorEmailTemplatesTests.swift
import Foundation
import SharedModels
import Testing

@testable import Server

@Suite("SponsorEmailTemplates")
struct SponsorEmailTemplatesTests {
  @Test("magic-link subject is locale-specific")
  func magicLinkSubject() {
    let url = URL(string: "https://sponsor.tryswift.jp/auth/verify?token=x")!
    let ja = SponsorEmailTemplates.render(.magicLink(verifyURL: url, ttlMinutes: 30),
                                            locale: .ja, recipientName: nil)
    let en = SponsorEmailTemplates.render(.magicLink(verifyURL: url, ttlMinutes: 30),
                                            locale: .en, recipientName: nil)
    #expect(ja.subject.contains("ログイン"))
    #expect(en.subject.lowercased().contains("login"))
  }

  @Test("application-approved includes plan name")
  func approvedShowsPlan() {
    let url = URL(string: "https://sponsor.tryswift.jp/applications/abc")!
    let m = SponsorEmailTemplates.render(.applicationApproved(planName: "Gold", nextStepsURL: url),
                                           locale: .en, recipientName: "Pat")
    #expect(m.textBody.contains("Gold"))
    #expect(m.textBody.contains("Pat"))
  }
}
```

Run, expect FAIL.

- [ ] **Step 2: Implement**

```swift
// Server/Sources/Server/Sponsor/Services/SponsorEmailTemplates.swift
import Foundation
import SharedModels

enum SponsorEmailKind: Sendable {
  case magicLink(verifyURL: URL, ttlMinutes: Int)
  case inquiryReceived(materialsURL: URL)
  case memberInvite(orgName: String, inviterName: String, acceptURL: URL)
  case applicationReceived(planName: String)
  case applicationApproved(planName: String, nextStepsURL: URL)
  case applicationRejected(planName: String, reason: String)
}

struct EmailMessage: Sendable {
  let subject: String
  let htmlBody: String
  let textBody: String
}

enum SponsorEmailTemplates {
  static func render(_ kind: SponsorEmailKind,
                      locale: SponsorPortalLocale,
                      recipientName: String?) -> EmailMessage {
    let greeting = greeting(for: recipientName, locale: locale)
    switch kind {
    case let .magicLink(url, ttl):
      return locale == .ja
        ? message("【try! Swift Tokyo】スポンサーポータル ログインリンク",
                  body: "\(greeting)\n\n以下のリンクから\(ttl)分以内にログインしてください。\n\(url.absoluteString)\n\n— try! Swift Tokyo Sponsorship Team")
        : message("[try! Swift Tokyo] Sponsor portal login link",
                  body: "\(greeting)\n\nUse the link below within \(ttl) minutes to log in.\n\(url.absoluteString)\n\n— try! Swift Tokyo Sponsorship Team")

    case let .inquiryReceived(materialsURL):
      return locale == .ja
        ? message("【try! Swift Tokyo】資料をお届けします",
                  body: "\(greeting)\n\nスポンサー資料をご請求いただきありがとうございます。以下より資料をご確認ください。\n\(materialsURL.absoluteString)\n\nご検討よろしくお願いいたします。")
        : message("[try! Swift Tokyo] Sponsor materials",
                  body: "\(greeting)\n\nThank you for requesting our sponsor pack. Materials are available here:\n\(materialsURL.absoluteString)")

    case let .memberInvite(orgName, inviterName, acceptURL):
      return locale == .ja
        ? message("【try! Swift Tokyo】\(orgName) への参加招待",
                  body: "\(greeting)\n\n\(inviterName) さんから \(orgName) へ招待されました。以下より参加してください。\n\(acceptURL.absoluteString)")
        : message("[try! Swift Tokyo] You've been invited to \(orgName)",
                  body: "\(greeting)\n\n\(inviterName) invited you to join \(orgName). Accept here:\n\(acceptURL.absoluteString)")

    case let .applicationReceived(planName):
      return locale == .ja
        ? message("【try! Swift Tokyo】\(planName) プラン申込を受け付けました",
                  body: "\(greeting)\n\n\(planName) プランの申込を受け付けました。Organizer の確認後、改めてご連絡いたします。")
        : message("[try! Swift Tokyo] Application received: \(planName)",
                  body: "\(greeting)\n\nWe received your \(planName) sponsorship application. We'll get back to you after Organizer review.")

    case let .applicationApproved(planName, nextStepsURL):
      return locale == .ja
        ? message("【try! Swift Tokyo】\(planName) プラン申込が承認されました",
                  body: "\(greeting)\n\n\(planName) プランの申込が承認されました。次のステップ:\n\(nextStepsURL.absoluteString)")
        : message("[try! Swift Tokyo] Approved: \(planName)",
                  body: "\(greeting)\n\nYour \(planName) sponsorship has been approved! Next steps:\n\(nextStepsURL.absoluteString)")

    case let .applicationRejected(planName, reason):
      return locale == .ja
        ? message("【try! Swift Tokyo】\(planName) プラン申込について",
                  body: "\(greeting)\n\n\(planName) プランの申込について、今回はお見送りとさせていただきました。\n理由: \(reason)\n\nまたの機会をお待ちしております。")
        : message("[try! Swift Tokyo] About your \(planName) application",
                  body: "\(greeting)\n\nUnfortunately we were unable to confirm your \(planName) application this time.\nReason: \(reason)\n\nWe appreciate your interest.")
    }
  }

  private static func greeting(for name: String?, locale: SponsorPortalLocale) -> String {
    let n = name?.isEmpty == false ? name! : (locale == .ja ? "ご担当者" : "there")
    return locale == .ja ? "\(n) 様" : "Hi \(n),"
  }

  private static func message(_ subject: String, body: String) -> EmailMessage {
    let html = "<pre style=\"font-family: ui-monospace, monospace\">\(escapeHTML(body))</pre>"
    return EmailMessage(subject: subject, htmlBody: html, textBody: body)
  }

  private static func escapeHTML(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;")
     .replacingOccurrences(of: "<", with: "&lt;")
     .replacingOccurrences(of: ">", with: "&gt;")
  }
}
```

- [ ] **Step 3: Run tests (expect PASS) and commit**

```bash
cd Server && swift test --filter SponsorEmailTemplatesTests
cd ..
git add Server/Sources/Server/Sponsor/Services/SponsorEmailTemplates.swift \
        Server/Tests/ServerTests/Sponsor/SponsorEmailTemplatesTests.swift
git commit -m "Add SponsorEmailTemplates with JA/EN snapshot tests"
```

### Task B18: SponsorSlackNotifier

**Files:**
- Create: `Server/Sources/Server/Sponsor/Services/SponsorSlackNotifier.swift`

(No tests — mirrors `SlackNotifier` exactly which is fire-and-forget. Production behaviour: env unset → skip.)

- [ ] **Step 1: Implement**

```swift
// Server/Sources/Server/Sponsor/Services/SponsorSlackNotifier.swift
import Vapor

enum SponsorSlackNotifier {
  static func notifyInquiry(companyName: String, planSlug: String?,
                             client: Client, logger: Logger) async {
    await post(text: ":mailbox: 新しいスポンサーお問い合わせ\n*会社:* \(companyName)\n*希望プラン:* \(planSlug ?? "未指定")",
               client: client, logger: logger)
  }

  static func notifyApplicationSubmitted(orgName: String, planName: String,
                                           client: Client, logger: Logger) async {
    await post(text: ":hourglass_flowing_sand: 新しい申込\n*会社:* \(orgName)\n*プラン:* \(planName)",
               client: client, logger: logger)
  }

  static func notifyDecision(orgName: String, planName: String,
                              decision: String,
                              client: Client, logger: Logger) async {
    await post(text: ":white_check_mark: \(decision)\n*会社:* \(orgName)\n*プラン:* \(planName)",
               client: client, logger: logger)
  }

  private static func post(text: String, client: Client, logger: Logger) async {
    guard let url = Environment.get("SPONSOR_SLACK_WEBHOOK_URL") ?? Environment.get("SLACK_WEBHOOK_URL"),
          !url.isEmpty else {
      logger.debug("Sponsor Slack webhook not configured, skipping")
      return
    }
    struct Payload: Encodable { let text: String }
    do {
      let response = try await client.post(URI(string: url)) { req in
        req.headers.contentType = .json
        try req.content.encode(Payload(text: text), as: .json)
      }
      if response.status != .ok {
        logger.warning("Sponsor Slack non-OK", metadata: ["status": .stringConvertible(response.status.code)])
      }
    } catch {
      logger.warning("Sponsor Slack send error: \(error)")
    }
  }
}
```

- [ ] **Step 2: Build & commit**

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Services/SponsorSlackNotifier.swift
git commit -m "Add SponsorSlackNotifier mirroring SlackNotifier pattern"
```

### Task B19: SponsorJWTPayload + SponsorAuthCookie

**Files:**
- Create: `Server/Sources/Server/Sponsor/Auth/SponsorJWTPayload.swift`
- Create: `Server/Sources/Server/Sponsor/Auth/SponsorAuthCookie.swift`

- [ ] **Step 1: Payload**

```swift
// Server/Sources/Server/Sponsor/Auth/SponsorJWTPayload.swift
import Foundation
import JWT
import SharedModels

struct SponsorJWTPayload: JWTPayload, Sendable {
  var subject: SubjectClaim
  var orgID: UUID?
  var role: SponsorMemberRole?
  var locale: SponsorPortalLocale
  var expiration: ExpirationClaim
  var issuedAt: IssuedAtClaim

  init(userID: UUID, orgID: UUID?, role: SponsorMemberRole?, locale: SponsorPortalLocale) {
    self.subject = SubjectClaim(value: userID.uuidString)
    self.orgID = orgID
    self.role = role
    self.locale = locale
    self.expiration = ExpirationClaim(value: Date().addingTimeInterval(86400 * 30))  // 30 days
    self.issuedAt = IssuedAtClaim(value: Date())
  }

  func verify(using algorithm: some JWTAlgorithm) throws {
    try expiration.verifyNotExpired()
  }

  var sponsorUserID: UUID? { UUID(uuidString: subject.value) }
}
```

- [ ] **Step 2: Cookie helper**

```swift
// Server/Sources/Server/Sponsor/Auth/SponsorAuthCookie.swift
import Foundation
import Vapor

enum SponsorAuthCookie {
  static let name = "sponsor_auth_token"

  static func cookieDomain() -> String? {
    if let host = Environment.get("SPONSOR_BASE_URL").flatMap(URL.init(string:))?.host {
      // Promote to parent domain so api.tryswift.jp / sponsor.tryswift.jp share auth.
      let parts = host.split(separator: ".")
      if parts.count >= 2 { return "." + parts.suffix(2).joined(separator: ".") }
      return host
    }
    return nil  // localhost dev: no domain attribute
  }

  static func make(value token: String, ttl: TimeInterval = 86400 * 30) -> HTTPCookies.Value {
    let isSecure = Environment.get("APP_ENV") == "production"
    return HTTPCookies.Value(
      string: token,
      expires: Date().addingTimeInterval(ttl),
      maxAge: Int(ttl),
      domain: cookieDomain(),
      path: "/",
      isSecure: isSecure,
      isHTTPOnly: true,
      sameSite: .lax
    )
  }
}
```

- [ ] **Step 3: Build & commit**

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Auth/
git commit -m "Add SponsorJWTPayload and SponsorAuthCookie helpers"
```

### Task B20: HostRoutingMiddleware (TDD)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Middleware/HostRoutingMiddleware.swift`
- Create: `Server/Tests/ServerTests/Sponsor/HostRoutingMiddlewareTests.swift`

- [ ] **Step 1: Failing test**

```swift
// Server/Tests/ServerTests/Sponsor/HostRoutingMiddlewareTests.swift
import Foundation
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("HostRoutingMiddleware")
struct HostRoutingMiddlewareTests {
  @Test("sets isSponsorHost storage flag for sponsor.tryswift.jp")
  func setsFlag() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    app.middleware.use(HostRoutingMiddleware(sponsorHost: "sponsor.tryswift.jp"))
    app.get("debug-host") { req in
      req.isSponsorHost ? "sponsor" : "other"
    }
    try await app.testing().test(
      .GET, "debug-host",
      beforeRequest: { req in req.headers.add(name: .host, value: "sponsor.tryswift.jp") }
    ) { res in
      #expect(res.status == .ok)
      #expect(res.body.string == "sponsor")
    }
    try await app.testing().test(
      .GET, "debug-host",
      beforeRequest: { req in req.headers.add(name: .host, value: "api.tryswift.jp") }
    ) { res in
      #expect(res.body.string == "other")
    }
  }
}
```

Run: `cd Server && swift test --filter HostRoutingMiddlewareTests` → FAIL (HostRoutingMiddleware undefined).

- [ ] **Step 2: Implement**

```swift
// Server/Sources/Server/Sponsor/Middleware/HostRoutingMiddleware.swift
import Vapor

struct HostRoutingMiddleware: AsyncMiddleware {
  let sponsorHost: String

  init(sponsorHost: String? = nil) {
    self.sponsorHost = sponsorHost
      ?? Environment.get("SPONSOR_HOST")
      ?? "sponsor.tryswift.jp"
  }

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    if let host = request.headers.first(name: .host)?.lowercased() {
      let bareHost = host.split(separator: ":").first.map(String.init) ?? host
      if bareHost == sponsorHost.lowercased() {
        request.storage[SponsorHostStorageKey.self] = true
      }
    }
    return try await next.respond(to: request)
  }
}

private struct SponsorHostStorageKey: StorageKey { typealias Value = Bool }

extension Request {
  var isSponsorHost: Bool { storage[SponsorHostStorageKey.self] == true }
}
```

- [ ] **Step 3: Run tests (PASS) and commit**

```bash
cd Server && swift test --filter HostRoutingMiddlewareTests
cd ..
git add Server/Sources/Server/Sponsor/Middleware/HostRoutingMiddleware.swift \
        Server/Tests/ServerTests/Sponsor/HostRoutingMiddlewareTests.swift
git commit -m "Add HostRoutingMiddleware to flag sponsor.* requests"
```

### Task B21: LocaleMiddleware (TDD)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Middleware/LocaleMiddleware.swift`
- Create: `Server/Tests/ServerTests/Sponsor/LocaleMiddlewareTests.swift`

- [ ] **Step 1: Failing test**

```swift
// Server/Tests/ServerTests/Sponsor/LocaleMiddlewareTests.swift
import Foundation
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("LocaleMiddleware")
struct LocaleMiddlewareTests {
  @Test("URL prefix /ja wins over Accept-Language: en")
  func prefixWins() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    app.middleware.use(LocaleMiddleware())
    app.get("ja", "x") { req in req.sponsorLocale.rawValue }
    try await app.testing().test(
      .GET, "ja/x",
      beforeRequest: { req in req.headers.replaceOrAdd(name: .acceptLanguage, value: "en-US") }
    ) { res in
      #expect(res.body.string == "ja")
    }
  }

  @Test("Accept-Language used if no prefix or cookie")
  func acceptLanguage() async throws {
    let app = try await Application.make(.testing)
    defer { Task { try? await app.asyncShutdown() } }
    app.middleware.use(LocaleMiddleware())
    app.get("x") { req in req.sponsorLocale.rawValue }
    try await app.testing().test(
      .GET, "x",
      beforeRequest: { req in req.headers.replaceOrAdd(name: .acceptLanguage, value: "en") }
    ) { res in #expect(res.body.string == "en") }
  }
}
```

- [ ] **Step 2: Implement**

```swift
// Server/Sources/Server/Sponsor/Middleware/LocaleMiddleware.swift
import SharedModels
import Vapor

struct LocaleMiddleware: AsyncMiddleware {
  static let cookieName = "sponsor_locale"

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    request.storage[SponsorLocaleStorageKey.self] = resolve(request)
    return try await next.respond(to: request)
  }

  private func resolve(_ request: Request) -> SponsorPortalLocale {
    let path = request.url.path
    if path.hasPrefix("/ja") { return .ja }
    if path.hasPrefix("/en") { return .en }
    if let cookie = request.cookies[Self.cookieName]?.string,
       let l = SponsorPortalLocale(rawValue: cookie) { return l }
    if let header = request.headers.first(name: .acceptLanguage)?.lowercased() {
      if header.hasPrefix("en") { return .en }
      if header.hasPrefix("ja") { return .ja }
    }
    return .default
  }
}

private struct SponsorLocaleStorageKey: StorageKey { typealias Value = SponsorPortalLocale }

extension Request {
  var sponsorLocale: SponsorPortalLocale {
    storage[SponsorLocaleStorageKey.self] ?? .default
  }
}
```

- [ ] **Step 3: Test PASS, commit**

```bash
cd Server && swift test --filter LocaleMiddlewareTests
cd ..
git add Server/Sources/Server/Sponsor/Middleware/LocaleMiddleware.swift \
        Server/Tests/ServerTests/Sponsor/LocaleMiddlewareTests.swift
git commit -m "Add LocaleMiddleware (path > cookie > Accept-Language)"
```

### Task B22: SponsorAuthMiddleware + OrganizerOnlyMiddleware + SponsorOwnerMiddleware

**Files:**
- Create: `Server/Sources/Server/Sponsor/Middleware/SponsorAuthMiddleware.swift`
- Create: `Server/Sources/Server/Sponsor/Middleware/OrganizerOnlyMiddleware.swift`
- Create: `Server/Sources/Server/Sponsor/Middleware/SponsorOwnerMiddleware.swift`

- [ ] **Step 1: SponsorAuthMiddleware**

```swift
// Server/Sources/Server/Sponsor/Middleware/SponsorAuthMiddleware.swift
import Fluent
import JWT
import SharedModels
import Vapor

struct SponsorAuthMiddleware: AsyncMiddleware {
  /// 401 / redirect-to-login when missing or invalid sponsor_auth_token cookie.
  let onMissingRedirectTo: String?

  init(onMissingRedirectTo: String? = "/login") {
    self.onMissingRedirectTo = onMissingRedirectTo
  }

  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let raw = request.cookies[SponsorAuthCookie.name]?.string,
          let payload = try? await request.jwt.verify(raw, as: SponsorJWTPayload.self) else {
      if let path = onMissingRedirectTo {
        return request.redirect(to: path)
      }
      throw Abort(.unauthorized)
    }
    request.storage[SponsorJWTStorageKey.self] = payload
    if let id = payload.sponsorUserID,
       let user = try await SponsorUser.find(id, on: request.db) {
      request.storage[SponsorUserStorageKey.self] = user
    }
    return try await next.respond(to: request)
  }
}

private struct SponsorJWTStorageKey: StorageKey { typealias Value = SponsorJWTPayload }
private struct SponsorUserStorageKey: StorageKey { typealias Value = SponsorUser }

extension Request {
  var sponsorJWT: SponsorJWTPayload? { storage[SponsorJWTStorageKey.self] }
  var sponsorUser: SponsorUser? { storage[SponsorUserStorageKey.self] }
}
```

- [ ] **Step 2: OrganizerOnlyMiddleware**

```swift
// Server/Sources/Server/Sponsor/Middleware/OrganizerOnlyMiddleware.swift
import JWT
import SharedModels
import Vapor

struct OrganizerOnlyMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    // Reuse the existing api.tryswift.jp `auth_token` cookie (shared `.tryswift.jp` domain).
    guard let raw = request.cookies["auth_token"]?.string,
          let payload = try? await request.jwt.verify(raw, as: UserJWTPayload.self) else {
      return request.redirect(to: organizerLoginURL())
    }
    guard payload.role == .admin else { throw Abort(.forbidden) }
    request.storage[OrganizerJWTStorageKey.self] = payload
    return try await next.respond(to: request)
  }

  private func organizerLoginURL() -> String {
    // Send admins back to the existing GitHub OAuth on api.tryswift.jp/cfp.
    Environment.get("CFP_LOGIN_URL") ?? "https://cfp.tryswift.jp/login"
  }
}

private struct OrganizerJWTStorageKey: StorageKey { typealias Value = UserJWTPayload }

extension Request {
  var organizerJWT: UserJWTPayload? { storage[OrganizerJWTStorageKey.self] }
}
```

- [ ] **Step 3: SponsorOwnerMiddleware**

```swift
// Server/Sources/Server/Sponsor/Middleware/SponsorOwnerMiddleware.swift
import Fluent
import SharedModels
import Vapor

/// Requires that the authenticated sponsor user has the `.owner` role on their JWT-attached organisation.
struct SponsorOwnerMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard let payload = request.sponsorJWT, payload.role == .owner else {
      throw Abort(.forbidden)
    }
    return try await next.respond(to: request)
  }
}
```

- [ ] **Step 4: Build & commit**

```bash
cd Server && swift build
cd ..
git add Server/Sources/Server/Sponsor/Middleware/{SponsorAuthMiddleware,OrganizerOnlyMiddleware,SponsorOwnerMiddleware}.swift
git commit -m "Add Sponsor auth/owner/organizer middleware"
```

### Task B23: WebShared library (Layout / Locale / HTMX / Tokens)

**Files:**
- Replace: `Web/Sources/WebShared/Placeholder.swift` → delete
- Create: `Web/Sources/WebShared/Locale.swift`
- Create: `Web/Sources/WebShared/HTMX.swift`
- Create: `Web/Sources/WebShared/Tokens.swift`
- Create: `Web/Sources/WebShared/Layout.swift`

- [ ] **Step 1: Locale**

```swift
// Web/Sources/WebShared/Locale.swift
import Foundation

public enum WebLocale: String, Sendable, CaseIterable {
  case ja, en
  public var htmlLang: String { rawValue }
}
```

- [ ] **Step 2: HTMX**

```swift
// Web/Sources/WebShared/HTMX.swift
import Elementary

public enum HTMX {
  /// CDN script tag with SRI hash. Pin once to a verified version; bump deliberately.
  public static let scriptTag: HTML = script(.src("https://unpkg.com/htmx.org@1.9.12"),
                                              .integrity("sha384-ujb1lZYygJmzgSwoxRggbCHcjc0rB2XoQrxeTUQyRjrOnlCoYta87iKBWq3EsdM2"),
                                              .crossorigin(.anonymous)) { "" }
}
```

If `Elementary` doesn't expose those exact attribute helpers, encode manually:

```swift
public static let scriptTagRawHTML: String =
  #"<script src="https://unpkg.com/htmx.org@1.9.12" integrity="sha384-ujb1lZYygJmzgSwoxRggbCHcjc0rB2XoQrxeTUQyRjrOnlCoYta87iKBWq3EsdM2" crossorigin="anonymous"></script>"#
```

Pick whichever the surrounding Elementary version supports; check `Web/Sources/WebCfP/Components/AppLayout.swift` for the established attribute API.

- [ ] **Step 3: Tokens**

```swift
// Web/Sources/WebShared/Tokens.swift
import Foundation

public enum DesignToken {
  public static let primaryColor = "#FA7343"  // tryswift orange
  public static let textColor = "#1F2024"
  public static let backgroundColor = "#FFFFFF"
}
```

- [ ] **Step 4: Layout (skeleton)**

```swift
// Web/Sources/WebShared/Layout.swift
import Elementary

public struct WebLayout<Content: HTML>: HTML {
  public let title: String
  public let locale: WebLocale
  public let content: Content

  public init(title: String, locale: WebLocale, @HTMLBuilder content: () -> Content) {
    self.title = title
    self.locale = locale
    self.content = content()
  }

  public var content: some HTML {
    html(.lang(locale.htmlLang)) {
      head {
        meta(.charset("utf-8"))
        meta(.name("viewport"), .content("width=device-width, initial-scale=1"))
        Elementary.title { title }
        link(.rel("stylesheet"), .href("/sponsor/sponsor.css"))
        HTMX.scriptTag
      }
      body { content }
    }
  }
}
```

- [ ] **Step 5: Remove placeholder, build, commit**

```bash
rm Web/Sources/WebShared/Placeholder.swift
cd Web && swift build --target WebShared
cd ..
git add Web/Sources/WebShared/
git commit -m "Add WebShared library with Layout/Locale/HTMX/Tokens"
```

### Task B24: WebSponsor PortalLayout + minimal Components

**Files:**
- Replace: `Web/Sources/WebSponsor/Placeholder.swift` → delete
- Create: `Web/Sources/WebSponsor/Layout/PortalLayout.swift`
- Create: `Web/Sources/WebSponsor/Layout/PortalNav.swift`
- Create: `Web/Sources/WebSponsor/Components/FormField.swift`
- Create: `Web/Sources/WebSponsor/Components/StatusBadge.swift`
- Create: `Web/Sources/WebSponsor/Components/Toast.swift`
- Create: `Web/Sources/WebSponsor/Localization/PortalStrings.swift`

- [ ] **Step 1: PortalStrings (mini-i18n)**

```swift
// Web/Sources/WebSponsor/Localization/PortalStrings.swift
import SharedModels

public enum PortalStringKey: String, CaseIterable, Sendable { case
  inquiryTitle, inquirySubmit, loginTitle, loginSubmit,
  dashboardTitle, profileTitle, teamTitle, plansTitle,
  applicationFormTitle, applicationSubmit, applicationDetailTitle,
  organizerSponsors, organizerInquiries, organizerApplications
}

public enum PortalStrings {
  public static func t(_ key: PortalStringKey, _ locale: SponsorPortalLocale) -> String {
    switch (key, locale) {
    case (.inquiryTitle, .ja): return "資料請求"
    case (.inquiryTitle, .en): return "Request Materials"
    case (.inquirySubmit, .ja): return "送信"
    case (.inquirySubmit, .en): return "Submit"
    case (.loginTitle, .ja): return "ログイン"
    case (.loginTitle, .en): return "Log in"
    case (.loginSubmit, .ja): return "ログインリンクを送る"
    case (.loginSubmit, .en): return "Send login link"
    case (.dashboardTitle, .ja): return "ダッシュボード"
    case (.dashboardTitle, .en): return "Dashboard"
    case (.profileTitle, .ja): return "プロフィール"
    case (.profileTitle, .en): return "Profile"
    case (.teamTitle, .ja): return "メンバー"
    case (.teamTitle, .en): return "Team"
    case (.plansTitle, .ja): return "プラン一覧"
    case (.plansTitle, .en): return "Plans"
    case (.applicationFormTitle, .ja): return "申込フォーム"
    case (.applicationFormTitle, .en): return "Apply"
    case (.applicationSubmit, .ja): return "申し込む"
    case (.applicationSubmit, .en): return "Submit application"
    case (.applicationDetailTitle, .ja): return "申込内容"
    case (.applicationDetailTitle, .en): return "Application"
    case (.organizerSponsors, .ja): return "スポンサー一覧"
    case (.organizerSponsors, .en): return "Sponsors"
    case (.organizerInquiries, .ja): return "問い合わせ"
    case (.organizerInquiries, .en): return "Inquiries"
    case (.organizerApplications, .ja): return "申込"
    case (.organizerApplications, .en): return "Applications"
    }
  }
}
```

- [ ] **Step 2: PortalLayout / PortalNav / Components**

PortalLayout wraps WebShared.WebLayout adding sponsor nav + flash region. Implement using the same `Elementary` HTML DSL as `WebCfP/Components/AppLayout.swift`. Concretely:

```swift
// Web/Sources/WebSponsor/Layout/PortalLayout.swift
import Elementary
import SharedModels
import WebShared

public struct PortalLayout<Body: HTML>: HTML {
  public let title: String
  public let locale: SponsorPortalLocale
  public let isAuthenticated: Bool
  public let flash: String?
  public let body: Body

  public init(title: String, locale: SponsorPortalLocale, isAuthenticated: Bool,
              flash: String? = nil, @HTMLBuilder body: () -> Body) {
    self.title = title; self.locale = locale; self.isAuthenticated = isAuthenticated
    self.flash = flash; self.body = body()
  }

  public var content: some HTML {
    WebLayout(title: title, locale: locale == .ja ? .ja : .en) {
      PortalNav(locale: locale, isAuthenticated: isAuthenticated)
      if let flash { div(.class("flash")) { flash } }
      main(.class("portal-main")) { body }
    }
  }
}
```

```swift
// Web/Sources/WebSponsor/Layout/PortalNav.swift
import Elementary
import SharedModels

public struct PortalNav: HTML {
  public let locale: SponsorPortalLocale
  public let isAuthenticated: Bool
  public init(locale: SponsorPortalLocale, isAuthenticated: Bool) {
    self.locale = locale; self.isAuthenticated = isAuthenticated
  }
  public var content: some HTML {
    nav(.class("portal-nav")) {
      a(.href("/")) { "try! Swift Sponsor" }
      if isAuthenticated {
        a(.href("/dashboard")) { PortalStrings.t(.dashboardTitle, locale) }
        a(.href("/team")) { PortalStrings.t(.teamTitle, locale) }
        form(.action("/logout"), .method(.post)) { button(.type(.submit)) { "Logout" } }
      } else {
        a(.href("/login")) { PortalStrings.t(.loginTitle, locale) }
      }
    }
  }
}
```

```swift
// Web/Sources/WebSponsor/Components/FormField.swift
import Elementary

public struct FormField: HTML {
  public let label: String
  public let name: String
  public let value: String
  public let type: String
  public let required: Bool
  public init(label: String, name: String, value: String = "", type: String = "text", required: Bool = false) {
    self.label = label; self.name = name; self.value = value; self.type = type; self.required = required
  }
  public var content: some HTML {
    div(.class("form-field")) {
      Elementary.label(.for(name)) { self.label }
      input(.type(.init(rawValue: type) ?? .text), .name(name), .id(name),
            .value(value), required ? .required(true) : .empty)
    }
  }
}
```

```swift
// Web/Sources/WebSponsor/Components/StatusBadge.swift
import Elementary
import SharedModels

public struct StatusBadge: HTML {
  public let status: SponsorApplicationStatus
  public init(_ s: SponsorApplicationStatus) { self.status = s }
  public var content: some HTML {
    span(.class("status-badge status-\(status.rawValue)")) { status.rawValue }
  }
}
```

```swift
// Web/Sources/WebSponsor/Components/Toast.swift
import Elementary

public struct Toast: HTML {
  public let kind: String   // "info" | "error" | "success"
  public let message: String
  public init(kind: String = "info", message: String) { self.kind = kind; self.message = message }
  public var content: some HTML {
    div(.class("toast toast-\(kind)")) { message }
  }
}
```

> The exact `Elementary` attribute API may differ slightly from what's shown above. Check `Web/Sources/WebCfP/Components/AppLayout.swift` for the established attribute helper signatures and adjust (e.g. `.attr("required", "true")` vs `.required(true)`). Functionally equivalent — match what the existing CfPWeb file uses.

- [ ] **Step 3: Remove placeholder, build, commit**

```bash
rm Web/Sources/WebSponsor/Placeholder.swift
cd Web && swift build --target WebSponsor
cd ..
git add Web/Sources/WebSponsor/
git commit -m "Add WebSponsor PortalLayout, Nav, and base Components"
```

### Task B25: WebSponsor Public Pages (Inquiry / Login)

**Files:**
- Create: `Web/Sources/WebSponsor/Pages/Public/InquiryFormPage.swift`
- Create: `Web/Sources/WebSponsor/Pages/Public/InquiryThanksPage.swift`
- Create: `Web/Sources/WebSponsor/Pages/Public/LoginRequestPage.swift`
- Create: `Web/Sources/WebSponsor/Pages/Public/LoginSentPage.swift`

- [ ] **Step 1: InquiryFormPage**

```swift
// Web/Sources/WebSponsor/Pages/Public/InquiryFormPage.swift
import Elementary
import SharedModels

public struct InquiryFormPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let errorMessage: String?
  public init(locale: SponsorPortalLocale, csrfToken: String, errorMessage: String? = nil) {
    self.locale = locale; self.csrfToken = csrfToken; self.errorMessage = errorMessage
  }
  public var content: some HTML {
    PortalLayout(title: PortalStrings.t(.inquiryTitle, locale), locale: locale,
                  isAuthenticated: false, flash: errorMessage) {
      h1 { PortalStrings.t(.inquiryTitle, locale) }
      form(.method(.post), .action("/inquiry")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(label: locale == .ja ? "会社名" : "Company name", name: "companyName", required: true)
        FormField(label: locale == .ja ? "ご担当者名" : "Contact name", name: "contactName", required: true)
        FormField(label: "Email", name: "email", type: "email", required: true)
        FormField(label: locale == .ja ? "ご質問・希望プラン等" : "Notes / desired plan", name: "message")
        button(.type(.submit)) { PortalStrings.t(.inquirySubmit, locale) }
      }
    }
  }
}
```

- [ ] **Step 2: Other 3 pages — mirror the pattern**

```swift
// InquiryThanksPage.swift
public struct InquiryThanksPage: HTML {
  public let locale: SponsorPortalLocale
  public init(locale: SponsorPortalLocale) { self.locale = locale }
  public var content: some HTML {
    PortalLayout(title: "OK", locale: locale, isAuthenticated: false) {
      h1 { locale == .ja ? "資料請求を受け付けました" : "Materials request received" }
      p { locale == .ja ? "ご登録のメールアドレスにログインリンクをお送りしました。" : "We've emailed you a login link." }
    }
  }
}

// LoginRequestPage.swift
public struct LoginRequestPage: HTML {
  public let locale: SponsorPortalLocale
  public let csrfToken: String
  public let errorMessage: String?
  public init(locale: SponsorPortalLocale, csrfToken: String, errorMessage: String? = nil) {
    self.locale = locale; self.csrfToken = csrfToken; self.errorMessage = errorMessage
  }
  public var content: some HTML {
    PortalLayout(title: PortalStrings.t(.loginTitle, locale), locale: locale,
                  isAuthenticated: false, flash: errorMessage) {
      h1 { PortalStrings.t(.loginTitle, locale) }
      form(.method(.post), .action("/login")) {
        input(.type(.hidden), .name("_csrf"), .value(csrfToken))
        FormField(label: "Email", name: "email", type: "email", required: true)
        button(.type(.submit)) { PortalStrings.t(.loginSubmit, locale) }
      }
    }
  }
}

// LoginSentPage.swift
public struct LoginSentPage: HTML {
  public let locale: SponsorPortalLocale
  public init(locale: SponsorPortalLocale) { self.locale = locale }
  public var content: some HTML {
    PortalLayout(title: "OK", locale: locale, isAuthenticated: false) {
      h1 { locale == .ja ? "ログインリンクをお送りしました" : "Login link sent" }
      p { locale == .ja ? "メールをご確認ください。30分以内にリンクをクリックしてください。" : "Check your inbox; link expires in 30 minutes." }
    }
  }
}
```

- [ ] **Step 3: Build & commit**

```bash
cd Web && swift build --target WebSponsor
cd ..
git add Web/Sources/WebSponsor/Pages/Public/
git commit -m "Add WebSponsor public pages: Inquiry + Login"
```

### Task B26: SponsorPublicController (TDD: end-to-end inquiry happy path)

**Files:**
- Create: `Server/Sources/Server/Sponsor/DTOs/SponsorInquiryFormPayload.swift`
- Create: `Server/Sources/Server/Sponsor/DTOs/MagicLinkRequestPayload.swift`
- Create: `Server/Sources/Server/Sponsor/Controllers/SponsorPublicController.swift`
- Create: `Server/Tests/ServerTests/Sponsor/SponsorInquiryFlowTests.swift`

- [ ] **Step 1: DTOs**

```swift
// SponsorInquiryFormPayload.swift
import SharedModels
import Vapor

struct SponsorInquiryFormPayload: Content {
  let companyName: String
  let contactName: String
  let email: String
  let message: String?
  let desiredPlanSlug: String?
}

// MagicLinkRequestPayload.swift
import Vapor

struct MagicLinkRequestPayload: Content {
  let email: String
}
```

- [ ] **Step 2: Failing test (the spine of Foundation)**

```swift
// Server/Tests/ServerTests/Sponsor/SponsorInquiryFlowTests.swift
import Fluent
import Foundation
import SharedModels
import Testing
import Vapor
import VaporTesting

@testable import Server

@Suite("SponsorInquiryFlow")
struct SponsorInquiryFlowTests {
  @Test("POST /inquiry creates SponsorUser + MagicLinkToken and returns 303")
  func inquiryHappyPath() async throws {
    let app = try await SponsorTestEnv.makeApp()
    defer { Task { try? await app.asyncShutdown() } }
    try await SponsorTestEnv.conference(app)

    try await SponsorRoutes().boot(routes: app.routes)

    try await app.testing().test(.POST, "inquiry",
      beforeRequest: { req in
        req.headers.add(name: .host, value: "sponsor.tryswift.jp")
        try req.content.encode(SponsorInquiryFormPayload(
          companyName: "Acme",
          contactName: "Alice",
          email: "alice@example.com",
          message: "interested in Gold",
          desiredPlanSlug: "gold"
        ))
      }
    ) { res in
      #expect(res.status == .seeOther)
    }

    let inquiry = try await SponsorInquiry.query(on: app.db).first()
    #expect(inquiry?.companyName == "Acme")
    let user = try await SponsorUser.query(on: app.db).first()
    #expect(user?.email == "alice@example.com")
    let tokens = try await MagicLinkToken.query(on: app.db).all()
    #expect(tokens.count == 1)
  }
}
```

Run: `cd Server && swift test --filter SponsorInquiryFlowTests` → FAIL (controller / route missing).

- [ ] **Step 3: Implement `SponsorPublicController`**

```swift
// Server/Sources/Server/Sponsor/Controllers/SponsorPublicController.swift
import Elementary
import Fluent
import JWT
import SharedModels
import Vapor
import WebSponsor

struct SponsorPublicController: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    routes.get(use: landing)
    routes.get("inquiry", use: renderInquiry)
    routes.post("inquiry", use: submitInquiry)
    routes.get("inquiry", "thanks", use: inquiryThanks)
    routes.get("login", use: renderLogin)
    routes.post("login", use: requestMagicLink)
    routes.get("login", "sent", use: loginSent)
    routes.get("auth", "verify", use: verifyMagicLink)
    routes.post("logout", use: logout)
  }

  func landing(_ req: Request) async throws -> Response {
    try await renderInquiry(req)
  }

  func renderInquiry(_ req: Request) async throws -> Response {
    try respond(InquiryFormPage(locale: req.sponsorLocale, csrfToken: ""))
  }

  func submitInquiry(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(SponsorInquiryFormPayload.self)
    guard let conference = try await Conference.query(on: req.db)
      .filter(\.$isAcceptingSponsors == true)
      .sort(\.$year, .descending)
      .first() else {
      throw Abort(.serviceUnavailable, reason: "No conference is accepting sponsors")
    }

    let inquiry = SponsorInquiry(
      conferenceID: try conference.requireID(),
      companyName: payload.companyName,
      contactName: payload.contactName,
      email: payload.email,
      desiredPlanSlug: payload.desiredPlanSlug,
      message: payload.message ?? "",
      locale: req.sponsorLocale
    )
    try await inquiry.save(on: req.db)

    // Create or reuse SponsorUser
    let user: SponsorUser
    if let existing = try await SponsorUser.query(on: req.db)
      .filter(\.$email == payload.email.lowercased()).first() {
      user = existing
    } else {
      user = SponsorUser(email: payload.email, displayName: payload.contactName, locale: req.sponsorLocale)
      try await user.save(on: req.db)
    }

    let issued = try await MagicLinkService.issue(for: user, on: req.db)
    let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
    let verifyURL = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)")!
    let materialsURL = URL(string: Environment.get("SPONSOR_MATERIALS_URL")
                              ?? "\(baseURL)/sponsor/materials/sponsor-pack-2026.pdf")!

    let mail = SponsorEmailTemplates.render(
      .inquiryReceived(materialsURL: materialsURL),
      locale: req.sponsorLocale, recipientName: payload.contactName
    )
    _ = await ResendClient.send(
      to: payload.email,
      from: Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>",
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: req.client, logger: req.logger
    )
    let loginMail = SponsorEmailTemplates.render(
      .magicLink(verifyURL: verifyURL, ttlMinutes: 30),
      locale: req.sponsorLocale, recipientName: payload.contactName
    )
    _ = await ResendClient.send(
      to: payload.email, from: Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>",
      subject: loginMail.subject, html: loginMail.htmlBody, text: loginMail.textBody,
      client: req.client, logger: req.logger
    )
    await SponsorSlackNotifier.notifyInquiry(companyName: payload.companyName,
                                              planSlug: payload.desiredPlanSlug,
                                              client: req.client, logger: req.logger)
    return req.redirect(to: "/inquiry/thanks")
  }

  func inquiryThanks(_ req: Request) async throws -> Response {
    try respond(InquiryThanksPage(locale: req.sponsorLocale))
  }

  func renderLogin(_ req: Request) async throws -> Response {
    try respond(LoginRequestPage(locale: req.sponsorLocale, csrfToken: ""))
  }

  func requestMagicLink(_ req: Request) async throws -> Response {
    let payload = try req.content.decode(MagicLinkRequestPayload.self)
    if let user = try await SponsorUser.query(on: req.db)
      .filter(\.$email == payload.email.lowercased()).first() {
      let issued = try await MagicLinkService.issue(for: user, on: req.db)
      let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
      let url = URL(string: "\(baseURL)/auth/verify?token=\(issued.rawToken)")!
      let mail = SponsorEmailTemplates.render(.magicLink(verifyURL: url, ttlMinutes: 30),
                                                locale: user.locale, recipientName: user.displayName)
      _ = await ResendClient.send(to: user.email,
                                    from: Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>",
                                    subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
                                    client: req.client, logger: req.logger)
    }
    // Always redirect to /login/sent (avoid leaking whether the email exists).
    return req.redirect(to: "/login/sent")
  }

  func loginSent(_ req: Request) async throws -> Response {
    try respond(LoginSentPage(locale: req.sponsorLocale))
  }

  func verifyMagicLink(_ req: Request) async throws -> Response {
    let token = try req.query.get(String.self, at: "token")
    guard let user = try await MagicLinkService.verify(rawToken: token, on: req.db) else {
      throw Abort(.unauthorized, reason: "Invalid or expired token")
    }
    // Find primary org membership (could be none for fresh sign-ups; orgs are bootstrapped via /profile).
    let membership = try await SponsorMembership.query(on: req.db)
      .filter(\.$user.$id == (try user.requireID()))
      .first()

    let payload = SponsorJWTPayload(
      userID: try user.requireID(),
      orgID: membership?.$organization.id,
      role: membership?.role,
      locale: user.locale
    )
    let signed = try await req.jwt.sign(payload)

    let response = req.redirect(to: "/dashboard")
    response.cookies[SponsorAuthCookie.name] = SponsorAuthCookie.make(value: signed)
    return response
  }

  func logout(_ req: Request) async throws -> Response {
    let response = req.redirect(to: "/login")
    response.cookies[SponsorAuthCookie.name] = HTTPCookies.Value(string: "", expires: Date(timeIntervalSince1970: 0), maxAge: 0,
                                                                 domain: SponsorAuthCookie.cookieDomain(),
                                                                 path: "/", isHTTPOnly: true, sameSite: .lax)
    return response
  }

  private func respond<Page: HTML>(_ page: Page) throws -> Response {
    let html = page.render()
    var headers = HTTPHeaders()
    headers.contentType = .html
    return Response(status: .ok, headers: headers, body: .init(string: html))
  }
}
```

> Note on `page.render()`: confirm the exact rendering API in this Elementary version against `Web/Sources/WebCfP/Sources/`'s rendering site. If Elementary uses `String(describing: page)` or a `HTMLDocument(...)`, replace `page.render()` accordingly.

- [ ] **Step 4: Test PASS, commit**

```bash
cd Server && swift test --filter SponsorInquiryFlowTests
cd ..
git add Server/Sources/Server/Sponsor/DTOs/{SponsorInquiryFormPayload,MagicLinkRequestPayload}.swift \
        Server/Sources/Server/Sponsor/Controllers/SponsorPublicController.swift \
        Server/Tests/ServerTests/Sponsor/SponsorInquiryFlowTests.swift
git commit -m "Add SponsorPublicController with end-to-end inquiry test"
```

### Task B27: SponsorPortalController (Dashboard / Profile / Team / Invitations)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Controllers/SponsorPortalController.swift`
- Create: `Server/Sources/Server/Sponsor/DTOs/SponsorTeamInvitePayload.swift`
- Create: `Web/Sources/WebSponsor/Pages/Sponsor/{Dashboard,Profile,Members,InvitationAccept}Page.swift`

This task is large; split if needed but treat as one logical commit. Pattern:

- Pages return `PortalLayout` with content.
- Controller methods use `req.sponsorUser` (set by `SponsorAuthMiddleware`).
- `/team/invite` creates `SponsorInvitation` row, sends email; `/invitations/:token` accepts (creates `SponsorUser` if missing + `SponsorMembership`).

Implement following the established pattern in B26. Tests in `SponsorMembershipTests.swift`:
- Owner invites a new email → 1 invitation row + email sent.
- Acceptance creates `SponsorMembership` with `.member` role.
- Re-clicking the same accept URL is a no-op (token marked used).

Skeleton page:

```swift
// DashboardPage.swift
import Elementary
import SharedModels

public struct DashboardPage: HTML {
  public let locale: SponsorPortalLocale
  public let userEmail: String
  public let orgName: String?
  public init(locale: SponsorPortalLocale, userEmail: String, orgName: String?) {
    self.locale = locale; self.userEmail = userEmail; self.orgName = orgName
  }
  public var content: some HTML {
    PortalLayout(title: PortalStrings.t(.dashboardTitle, locale), locale: locale, isAuthenticated: true) {
      h1 { PortalStrings.t(.dashboardTitle, locale) }
      p { "\(locale == .ja ? "ようこそ" : "Welcome"), \(userEmail)" }
      if let orgName { p { orgName } }
      else { p { a(.href("/profile")) { locale == .ja ? "組織情報を登録する" : "Set up your organization" } } }
      ul {
        li { a(.href("/plans")) { PortalStrings.t(.plansTitle, locale) } }
        li { a(.href("/team")) { PortalStrings.t(.teamTitle, locale) } }
      }
    }
  }
}
```

The other pages follow the same shape: header + form (Profile/Members) or list (InvitationAccept). Use `FormField` for inputs.

Commit after the controller and pages compile, with at least one Sponsor membership test passing.

### Task B28: SponsorPlansController (read-only `/plans`)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Controllers/SponsorPlansController.swift`
- Create: `Web/Sources/WebSponsor/Pages/Sponsor/PlansPage.swift`
- Create: `Web/Sources/WebSponsor/Components/PlanCard.swift`

- Page lists `SponsorPlan` rows for the current accepting Conference, sorted by `sortOrder asc`.
- Controller queries `Conference.where(isAcceptingSponsors == true).sort(year desc).first` then eager-loads `plans → localizations`.
- Each card: name, summary, price (¥), benefits list, CTA link to `/applications/new?plan=<slug>`.

Test: `SponsorPlansControllerTests.swift` — request `/plans` with auth cookie; assert 200 and HTML contains seeded plan slugs.

Commit with passing test.

### Task B29: SponsorApplicationController + WebSponsor Pages (Submit / Detail / Withdraw)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Controllers/SponsorApplicationController.swift`
- Create: `Web/Sources/WebSponsor/Pages/Sponsor/{ApplicationForm,ApplicationDetail}Page.swift`
- Create: `Server/Tests/ServerTests/Sponsor/SponsorApplicationFlowTests.swift`

- Failing test: owner submits Gold application → `SponsorApplication(status=submitted)` row, Slack notify, email sent.
- Withdraw test: owner withdraws own submitted application → status=withdrawn; non-submitted state rejected.
- Permission test: member (not owner) can view but not submit/withdraw.

Implementation mirrors B26 — controller method per route, pages implement form/detail. For payload encode `SponsorApplicationFormPayload` (already in SharedModels) into `payload` JSONB.

Commit after all tests pass.

### Task B30: SponsorApplicationService (approve / reject business logic)

**Files:**
- Create: `Server/Sources/Server/Sponsor/Services/SponsorApplicationService.swift`

```swift
// Server/Sources/Server/Sponsor/Services/SponsorApplicationService.swift
import Fluent
import Foundation
import SharedModels
import Vapor

enum SponsorApplicationService {
  static func approve(applicationID: UUID, decidedByUserID: UUID,
                       on db: Database, client: Client, logger: Logger) async throws -> SponsorApplication {
    guard let application = try await SponsorApplication.query(on: db)
      .filter(\.$id == applicationID)
      .with(\.$organization)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first() else { throw Abort(.notFound) }

    application.status = .approved
    application.decidedAt = Date()
    application.decidedByUserID = decidedByUserID
    try await application.save(on: db)

    let planName = application.plan.localizations.first(where: { $0.locale == application.payload.locale })?.name
      ?? application.plan.slug
    let baseURL = Environment.get("SPONSOR_BASE_URL") ?? "https://sponsor.tryswift.jp"
    let nextStepsURL = URL(string: "\(baseURL)/applications/\(application.id?.uuidString ?? "")")!
    let mail = SponsorEmailTemplates.render(
      .applicationApproved(planName: planName, nextStepsURL: nextStepsURL),
      locale: application.payload.locale,
      recipientName: application.payload.billingContactName
    )
    _ = await ResendClient.send(
      to: application.payload.billingEmail,
      from: Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>",
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: client, logger: logger
    )
    await SponsorSlackNotifier.notifyDecision(
      orgName: application.organization.displayName,
      planName: planName, decision: "approved",
      client: client, logger: logger
    )
    return application
  }

  static func reject(applicationID: UUID, reason: String, decidedByUserID: UUID,
                      on db: Database, client: Client, logger: Logger) async throws -> SponsorApplication {
    guard let application = try await SponsorApplication.query(on: db)
      .filter(\.$id == applicationID)
      .with(\.$organization)
      .with(\.$plan) { $0.with(\.$localizations) }
      .first() else { throw Abort(.notFound) }

    application.status = .rejected
    application.decisionNote = reason
    application.decidedAt = Date()
    application.decidedByUserID = decidedByUserID
    try await application.save(on: db)

    let planName = application.plan.localizations.first(where: { $0.locale == application.payload.locale })?.name
      ?? application.plan.slug
    let mail = SponsorEmailTemplates.render(
      .applicationRejected(planName: planName, reason: reason),
      locale: application.payload.locale,
      recipientName: application.payload.billingContactName
    )
    _ = await ResendClient.send(
      to: application.payload.billingEmail,
      from: Environment.get("RESEND_FROM_EMAIL") ?? "Sponsorship <sponsorship@mail.tryswift.jp>",
      subject: mail.subject, html: mail.htmlBody, text: mail.textBody,
      client: client, logger: logger
    )
    await SponsorSlackNotifier.notifyDecision(
      orgName: application.organization.displayName,
      planName: planName, decision: "rejected",
      client: client, logger: logger
    )
    return application
  }
}
```

Commit.

### Task B31: OrganizerSponsorController + Organizer Pages

**Files:**
- Create: `Server/Sources/Server/Sponsor/Controllers/OrganizerSponsorController.swift`
- Create: `Web/Sources/WebSponsor/Pages/Organizer/{SponsorList,SponsorDetail,InquiryList,ApplicationList,ApplicationDetail}Page.swift`
- Create: `Server/Tests/ServerTests/Sponsor/OrganizerAccessTests.swift`

- Routes mounted under `/admin/...` — protected by `OrganizerOnlyMiddleware`.
- Approve/Reject endpoints call `SponsorApplicationService`.
- Tests:
  - admin role → 200 on `/admin/sponsors`
  - speaker role → 403
  - no auth cookie → 302 redirect to organizer login

Commit.

### Task B32: Wire it all together

**Files:**
- Create: `Server/Sources/Server/Sponsor/SponsorRoutes.swift`
- Modify: `Server/Sources/Server/routes.swift`
- Modify: `Server/Sources/Server/configure.swift`

- [ ] **Step 1: SponsorRoutes**

```swift
// Server/Sources/Server/Sponsor/SponsorRoutes.swift
import Vapor

struct SponsorRoutes: RouteCollection {
  func boot(routes: RoutesBuilder) throws {
    let sponsorOnly = routes.grouped(SponsorHostOnlyMiddleware())
                            .grouped(LocaleMiddleware())
    try sponsorOnly.register(collection: SponsorPublicController())

    let auth = sponsorOnly.grouped(SponsorAuthMiddleware())
    try auth.register(collection: SponsorPortalController())
    try auth.register(collection: SponsorPlansController())
    try auth.register(collection: SponsorApplicationController())

    let admin = sponsorOnly.grouped(OrganizerOnlyMiddleware())
    try admin.register(collection: OrganizerSponsorController())
  }
}

/// Returns 404 for non-sponsor host requests, so api.tryswift.jp can't reach Sponsor routes.
struct SponsorHostOnlyMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
    guard request.isSponsorHost else { throw Abort(.notFound) }
    return try await next.respond(to: request)
  }
}
```

- [ ] **Step 2: routes.swift**

Add `try app.register(collection: SponsorRoutes())` at the end of `AppRoutes.register`:

```swift
    try AppRoutes.register(app)
    try app.register(collection: SponsorRoutes())  // NEW LINE
```

(Actually inside `AppRoutes.register` itself, after the existing controllers; both styles work.)

- [ ] **Step 3: configure.swift**

Add `app.middleware.use(HostRoutingMiddleware())` BEFORE `FileMiddleware`:

```swift
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    app.middleware.use(HostRoutingMiddleware())  // NEW LINE
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
```

Update `corsConfiguration` to include `https://sponsor.tryswift.jp` if relevant:

```swift
    let corsConfiguration = CORSMiddleware.Configuration(
      allowedOrigin: .originBased,  // already permissive; no change needed
      ...
    )
```

(originBased echoes back the request's Origin, so explicit listing isn't required.)

- [ ] **Step 4: Build, run server tests end-to-end, commit**

```bash
cd Server && swift test
cd ..
git add Server/Sources/Server/Sponsor/SponsorRoutes.swift \
        Server/Sources/Server/routes.swift \
        Server/Sources/Server/configure.swift
git commit -m "Mount Sponsor routes and HostRoutingMiddleware in Vapor app"
```

### Task B33: Sponsor static assets (CSS) + materials placeholder

**Files:**
- Create: `Server/Public/sponsor/sponsor.css`
- Create: `Server/Public/sponsor/materials/.gitkeep` (placeholder; real PDF provisioned at deploy time)

- [ ] **Step 1: Minimal CSS**

```css
/* Server/Public/sponsor/sponsor.css */
:root { --primary: #FA7343; --bg: #fff; --text: #1F2024; }
body { font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif; color: var(--text); background: var(--bg); margin: 0; }
.portal-nav { display: flex; gap: 1rem; padding: 1rem; border-bottom: 1px solid #eee; }
.portal-nav a { color: var(--text); text-decoration: none; }
.portal-main { max-width: 720px; margin: 2rem auto; padding: 0 1rem; }
.flash { background: #fff7e6; border: 1px solid var(--primary); padding: 0.75rem 1rem; border-radius: 6px; margin: 1rem 0; }
.form-field { margin-bottom: 1rem; display: flex; flex-direction: column; gap: 0.25rem; }
.form-field input { padding: 0.5rem; border: 1px solid #ccc; border-radius: 4px; }
button { background: var(--primary); color: white; border: 0; padding: 0.5rem 1rem; border-radius: 4px; cursor: pointer; }
.status-badge { display: inline-block; padding: 0.125rem 0.5rem; border-radius: 999px; font-size: 0.75rem; font-weight: 600; }
.status-submitted { background: #fff7e6; color: #b06a00; }
.status-approved { background: #e6f4ea; color: #157347; }
.status-rejected { background: #fde0e1; color: #b00020; }
```

- [ ] **Step 2: Commit**

```bash
git add Server/Public/sponsor/
git commit -m "Add Sponsor portal CSS and materials placeholder"
```

### Task B34: DNS / fly.io / Resend secrets (operational checklist)

This task does NOT modify code. It is a runbook for the deploy operator.

- [ ] **Step 1: Cloudflare DNS**

In Cloudflare DNS for `tryswift.jp`, add:
```
Type:  CNAME
Name:  sponsor
Value: tryswift-api-prod.fly.dev
Proxy: <decide ON or OFF>; if ON, set SSL/TLS mode to "Full (strict)"
```
(Optional staging: `sponsor-staging` CNAME → same fly app or a staging app.)

- [ ] **Step 2: Fly.io cert**

```bash
flyctl certs add sponsor.tryswift.jp -a tryswift-api-prod
flyctl certs check sponsor.tryswift.jp -a tryswift-api-prod
```

- [ ] **Step 3: Resend domain**

In Resend dashboard, add `mail.tryswift.jp`. Configure DNS records (SPF, DKIM, DMARC) per Resend's instructions. Wait for "Verified" status.

- [ ] **Step 4: Fly secrets**

```bash
flyctl secrets set -a tryswift-api-prod \
  RESEND_API_KEY=re_xxx \
  RESEND_FROM_EMAIL='Sponsorship <sponsorship@mail.tryswift.jp>' \
  SPONSOR_BASE_URL=https://sponsor.tryswift.jp \
  SPONSOR_HOST=sponsor.tryswift.jp \
  SPONSOR_SLACK_WEBHOOK_URL=https://hooks.slack.com/services/... \
  SPONSOR_MATERIALS_URL=https://sponsor.tryswift.jp/sponsor/materials/sponsor-pack-2026.pdf
```

- [ ] **Step 5: Smoke test**

After deploy:
```bash
curl -sI https://sponsor.tryswift.jp/healthz   # expect 200
curl -sI https://api.tryswift.jp/health         # expect existing 200
curl -s -X POST https://sponsor.tryswift.jp/inquiry \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "companyName=Test&contactName=Test&email=test+e2e@example.com&message=hello"
# expect: 303 to /inquiry/thanks; verify sponsorship inbox got email
```

### Task B35: Final verification checklist

- [ ] **Step 1: All Server tests green**

```bash
cd Server && swift test 2>&1 | tail -20
```

- [ ] **Step 2: Web targets all build**

```bash
cd Web && swift build
```

- [ ] **Step 3: Full E2E walkthrough on staging**

Walk steps 1-10 from the spec's "Manual E2E (staging)" section in
`docs/superpowers/specs/2026-04-30-sponsor-portal-foundation-design.md`.

- [ ] **Step 4: Confirm existing surfaces unaffected**

- `https://api.tryswift.jp/api/v1/conferences` returns existing JSON.
- `https://cfp.tryswift.jp/` and `https://tryswift.jp/` deploy unchanged.
- `cd Server && swift test --filter Admin` (existing tests) still green.

- [ ] **Step 5: Open production-cutover PR**

Once staging is green, open the production deploy PR (typically a merge from the foundation branch into `main`). The PR description should reference the spec and this plan.

---

## Self-review notes

- **Spec coverage:** every "In Scope" bullet maps to at least one task (Inquiry → B26; Magic-link → B16, B26; Org+members → B5/B7/B12, B27; Plans DB → B8, B13; Application form → B10, B29; Organizer approval → B30, B31; Slack → B18, B30; Email templates → B17; Sub-domain → B20, B32; Web/ unification → A1–A6).
- **Out-of-scope intentionally excluded:** contracts/invoices/W-8/tickets/logo upload/dashboard/lead reminders not present in tasks (correct per spec).
- **Type consistency:** `SponsorPortalLocale.default` (B1) is referenced by `MagicLinkService` and DTOs consistently. `SponsorMemberRole.{owner,member}` reused in `SponsorJWTPayload` (B19) and `SponsorMembership` (B7). `SponsorApplicationStatus` cases match between SharedModels (B1) and SponsorApplication (B10) and ApplicationService (B30).
- **Open assumptions:** Plan price/benefit text in `SeedSponsorPlans2026` (B13) is placeholder until the PDF source-of-truth is consulted; this is called out inline in the task.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-30-sponsor-portal-foundation.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — Dispatch a fresh subagent per task, review between tasks; fast iteration, isolated context per task. Best when you want to keep oversight and the plan's task graph already has clean independent commits.

2. **Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`; batch execution with checkpoints for review. Best when you want to ride along and approve in real time.

**Which approach?**
