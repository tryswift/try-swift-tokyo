# sponsor.tryswift.jp Foundation — Design Spec

**Status:** Approved (2026-04-30)
**Authors:** Brainstormed with Claude
**Scope:** Foundation sub-project (first of multiple sub-projects for the sponsor management platform)

## Context

try! Swift Tokyo は毎年スポンサー営業を Google Form と Google Drive ベースで運用している。資料請求／申込／契約／請求／チケット配布／Slack招待／ロゴ反映が複数ツールに分散しており、Organizer の手作業負担とリードの追跡漏れが恒常的に発生している。

本 spec は、これを段階的にリプレースする多年計画の **第一弾（Foundation サブプロジェクト）** を定義する。Foundation のゴールは「営業窓口の電子化」を最速で立ち上げること、すなわち **資料請求 → アカウント発行 → ログイン → プラン申込 → Organizer 承認** までを `sponsor.tryswift.jp` 上で完結させることである。

副次的に、ユーザー判断で **既存の `CfPWeb/` と `Website/` を新しい `Web/` SwiftPM パッケージに統合**し、新しい Sponsor SSR Component を `Web/Sources/WebSponsor/` library として共存させる。これは Foundation の物理レイアウトを将来の運用に耐える形に整理することが目的である。

## Sub-projects (multi-year roadmap)

このドキュメントが扱うのは **(1) Foundation のみ**。残りは別 spec で定義する。

1. **Foundation**（本 spec）— 資料請求 / アカウント / 認証 / 申込 / Organizer 承認 / Web パッケージ統合
2. **契約・財務書類** — 契約書雛形 DL / 請求書 / W-8 / 電子署名・追跡
3. **チケット発行** — プラン別枠管理、コード発行、配布状況追跡
4. **ロゴ＆Web 資材** — ロゴアップロード、アイソレーションプレビュー、Website への自動反映
5. **Organizer Dashboard** — KPI、グラフ、Slack 招待自動化、ノベルティ配送管理
6. **リード CRM / メールリマインド** — 見込み顧客管理、テンプレ送信、自動追跡

## Decisions (agreed during brainstorming)

| 項目 | 決定 |
|---|---|
| ホスティング | 既存 Vapor `Server` に同居（fly.io app `tryswift-api-prod`）、Host ヘッダで `sponsor.tryswift.jp` を捌く |
| 認証（Sponsor 側） | magic-link メール → JWT cookie `sponsor_auth_token`（`Domain=.tryswift.jp`） |
| 認証（Organizer 側） | 既存 `User` + GitHub OAuth + role `.admin` を流用 |
| アカウント粒度 | `SponsorOrganization` + `SponsorUser` の組織モデル（Owner / Member） |
| メール配信 | Resend |
| プラン定義 | DB（`SponsorPlan` + `SponsorPlanLocalization`）、Conference に紐付け、Seed Migration で投入 |
| 多言語 | 日英バイリンガル（URL prefix `/ja/` `/en/` → cookie → Accept-Language） |
| フロントエンド | Vapor + Elementary SSR + HTMX (CDN, SRI 付き) |
| Sponsor SSR の物理位置 | 新規 SwiftPM `Web/` パッケージ内 `WebSponsor` library。Server が import |
| 既存 CfPWeb / Website | `Web/` パッケージ配下に物理移動（`WebCfP` / `WebConference` ターゲット） |

## In Scope

- 資料請求フォーム（公開）→ アカウント自動発行 + magic-link
- magic-link 認証（発行 / 検証 / Cookie）
- 組織プロフィール / メンバー招待・管理（Owner / Member）
- プラン一覧（DB 駆動、二言語）
- 申込フォーム + 申込ステータス追跡
- Organizer 用承認画面（一覧 / 詳細 / 承認 / 却下）
- 承認時の Slack 通知（既存 `SlackNotifier` 流用）
- 二言語メールテンプレ
- `sponsor.tryswift.jp` のサブドメイン配信
- `Web/` パッケージへの物理統合と既存 CfPWeb / Website のターゲット移動

## Out of Scope (送り先サブプロジェクト)

- 契約書 / 請求書 / W-8 ダウンロード（→ #2）
- 各種チケット発行（→ #3）
- ロゴアップロード / アイソレーションプレビュー / Website への自動反映（→ #4）
- Organizer Dashboard（KPI / グラフ）（→ #5）
- 見込み顧客リマインダー自動化（→ #6）
- ノベルティ配送管理（→ #5）

## Assumptions

実装フェーズで verify。

- Magic-link TTL = 30 分、単回使用、レート制限 5 件/メール/時間
- メンバー招待トークン TTL = 7 日、単回使用
- 申込取り下げは `status=submitted` のときのみ可能（`underReview` 以降は不可）
- Conference は同時 1 active 前提、`Conference.isAcceptingSponsors` フラグを追加
- 資料 PDF は `Server/Public/sponsor/materials/` に静的配置、署名 URL なしの公開配信
- HTMX は CDN（unpkg）から SRI hash 付きで読み込み、ビルドパイプラインに変更なし
- Sponsor 専用静的アセット（CSS / 画像）は `Server/Public/sponsor/` 配下、既存 `FileMiddleware` で配信
- Sponsor cookie ドメイン: `.tryswift.jp`（既存 `auth_token` cookie と同じ親ドメイン共有方式、`Server/Sources/Server/Controllers/AuthController.swift:447-458` 参照）

## Architecture

```
┌─────────────────────── tryswift-api-prod (single Fly.io app) ──────────────────────────┐
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐  │
│  │   HostRoutingMiddleware                                                          │  │
│  │     Host: api.tryswift.jp        →  既存 /api/v1/... + GitHub OAuth /auth/...   │  │
│  │     Host: cfp.tryswift.jp        →  既存（Cloudflare Pages 配信、独立）         │  │
│  │     Host: sponsor.tryswift.jp    →  SponsorRoutes（このプロジェクトで新規）     │  │
│  └─────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                         │
│  Server/Sources/Server/Sponsor/                                                         │
│    Auth/  Models/  Migrations/  Controllers/  DTOs/  Services/  Middleware/  Routes/    │
│    └─ import WebSponsor → SSR rendering                                                 │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
                ↑                          ↑                              ↑
                │ depends                  │ depends                      │ depends
                │                          │                              │
        SharedModels/             Web/ (SwiftPM)                  fluent-postgres-driver
        (Sponsor/* DTOs           ├─ WebShared (lib)              + jwt + vapor
         追加)                    ├─ WebSponsor (lib)
                                   ├─ WebCfP (exec, 旧 CfPWeb)
                                   └─ WebConference (exec, 旧 Website)
```

### Boundaries

- `WebSponsor` は **Vapor 非依存**。Page 関数は `(viewModel) -> HTML` を返し、Server 側の Controller が `Response(status:, body: rendered.render())` でラップする。
- `SharedModels/Sponsor/*` は Foundation のみに依存し、Vapor / Fluent を持ち込まない。Server / WebSponsor / 将来の iOS / Android のいずれからも安全に参照可能。
- `Server/Sponsor/` の境界は `SponsorRoutes` の `RouteCollection` に閉じる。`routes.swift` への追加は 1 行のみ。

## File-Level Plan

### 1. New `Web/` SwiftPM package

**`Web/Package.swift`** (新規)

ターゲット:
- `.library(WebShared)` — Foundation + Elementary。共通 Layout / Locale / HTMX 属性 / デザイントークン
- `.library(WebSponsor)` — Foundation + Elementary + WebShared + SharedModels。Sponsor SSR コンポーネント
- `.executable(WebCfP)` — Foundation + Elementary + WebShared。`CfPWeb/` から移動
- `.executable(WebConference)` — Foundation + Ignite + swift-dependencies + DataClient + LocalizationGenerated + WebShared。`Website/` から移動
- platforms: `[.macOS(.v15)]`

**ディレクトリ移動 (`git mv`)**

```
git mv CfPWeb/Sources/CfPWeb        Web/Sources/WebCfP
git mv CfPWeb/Public                Web/Public
git mv Website/Sources/Website      Web/Sources/WebConference
git mv Website/Assets               Web/Sources/WebConference/Assets
# CfPWeb/ Website/ ディレクトリは Package.swift などを削除して空に → 削除
```

`Web/Sources/WebShared/` を新規作成し、共通の `Layout.swift` / `Locale.swift` / `HTMX.swift` / `Tokens.swift` を配置。`WebCfP` の `AppLayout` から共有部分を抽出（最初は最小、リファクタは後追い）。

**`Web/Sources/WebSponsor/`** (新規 library)

```
WebSponsor/
├── Layout/
│   ├── PortalLayout.swift           # <html lang> + ヘッダ + flash + footer
│   ├── PortalNav.swift
│   └── HTMXBootstrap.swift          # CDN script tag + SRI hash 定数
├── Components/
│   ├── FormField.swift
│   ├── PlanCard.swift
│   ├── StatusBadge.swift
│   └── Toast.swift
├── Pages/
│   ├── Public/
│   │   ├── InquiryFormPage.swift
│   │   ├── InquiryThanksPage.swift
│   │   ├── LoginRequestPage.swift
│   │   └── LoginSentPage.swift
│   ├── Sponsor/
│   │   ├── DashboardPage.swift
│   │   ├── ProfilePage.swift
│   │   ├── MembersPage.swift
│   │   ├── InvitationAcceptPage.swift
│   │   ├── PlansPage.swift
│   │   ├── ApplicationFormPage.swift
│   │   └── ApplicationDetailPage.swift
│   └── Organizer/
│       ├── OrganizerSponsorListPage.swift
│       ├── OrganizerSponsorDetailPage.swift
│       ├── OrganizerInquiryListPage.swift
│       ├── OrganizerApplicationListPage.swift
│       └── OrganizerApplicationDetailPage.swift
└── Localization/
    └── PortalStrings.swift          # [Key: [Locale: String]]、最小辞書
```

### 2. Server changes

**新規ディレクトリ `Server/Sources/Server/Sponsor/`**

```
Sponsor/
├── SponsorRoutes.swift                              # RouteCollection 集約、Host 制限を内部で適用
├── Auth/
│   ├── SponsorJWTPayload.swift                      # sub=SponsorUser.id, type="sponsor", orgID
│   └── SponsorAuthCookie.swift                      # 名前: "sponsor_auth_token", Domain=".tryswift.jp"
├── Models/
│   ├── SponsorOrganization.swift                    # id, legalName, displayName, country, websiteURL, status, createdAt
│   ├── SponsorUser.swift                            # id, email (unique), displayName, locale, createdAt
│   ├── SponsorMembership.swift                      # join: orgID + userID, role (.owner|.member), invitedBy
│   ├── SponsorPlan.swift                            # id, conferenceID, slug, sortOrder, priceJPY, capacity, deadlineAt, isActive
│   ├── SponsorPlanLocalization.swift                # planID, locale, name, summary, benefits (JSONB array)
│   ├── SponsorInquiry.swift                         # companyName, contactName, email, desiredPlanSlug?, message, locale, status, conferenceID
│   ├── SponsorApplication.swift                     # orgID, planID, conferenceID, status, payload (JSONB snapshot), submittedAt, decidedAt, decidedByUserID, decisionNote
│   ├── MagicLinkToken.swift                         # id, sponsorUserID, tokenHash, expiresAt, usedAt, purpose (.login|.invite)
│   └── SponsorInvitation.swift                      # orgID, email, role, tokenHash, expiresAt, acceptedAt, invitedByUserID
├── Migrations/
│   ├── CreateSponsorOrganization.swift
│   ├── CreateSponsorUser.swift
│   ├── CreateSponsorMembership.swift                # unique(orgID, userID); index(userID)
│   ├── CreateSponsorPlan.swift                      # unique(conferenceID, slug)
│   ├── CreateSponsorPlanLocalization.swift          # unique(planID, locale)
│   ├── CreateSponsorInquiry.swift                   # index(email), index(status)
│   ├── CreateSponsorApplication.swift               # index(orgID), index(status)
│   ├── CreateMagicLinkToken.swift                   # index(sponsorUserID), index(expiresAt)
│   ├── CreateSponsorInvitation.swift                # index(email), index(orgID)
│   ├── AddIsAcceptingSponsorsToConference.swift     # Conference に bool 列追加
│   └── SeedSponsorPlans2026.swift                   # platinum / gold / silver / bronze / diversity / community を JA/EN で投入（idempotent）
├── DTOs/
│   ├── SponsorInquiryFormPayload.swift              # Vapor Content
│   ├── SponsorApplicationFormPayload.swift
│   ├── SponsorTeamInvitePayload.swift
│   ├── MagicLinkRequestPayload.swift
│   └── SponsorPageContext.swift                     # locale, currentSponsorUser?, currentMembership?, flash, csrf
├── Services/
│   ├── ResendClient.swift                           # POST https://api.resend.com/emails、SlackNotifier / LumaClient と同じパターン
│   ├── MagicLinkService.swift                       # 32B 乱数 → base64url、SHA256 ハッシュで保存、TTL 30分
│   ├── SponsorEmailTemplates.swift                  # render(_ kind:, locale:) -> EmailMessage(subject, html, text)
│   ├── SponsorSlackNotifier.swift                   # notifyInquiry / notifyApplicationSubmitted / notifyApprovedRejected
│   └── SponsorApplicationService.swift              # approve / reject の業務ロジック（DB + Slack + email を 1 関数で完結）
├── Middleware/
│   ├── HostRoutingMiddleware.swift                  # Host ヘッダで sponsor.tryswift.jp を識別、req.storage に SponsorHost フラグ
│   ├── SponsorAuthMiddleware.swift                  # sponsor_auth_token cookie を検証、SponsorUser を req.storage に注入
│   ├── SponsorOwnerMiddleware.swift                 # Owner ロール必須エンドポイント
│   ├── OrganizerOnlyMiddleware.swift                # 既存 AuthMiddleware の後段、role == .admin を強制
│   └── LocaleMiddleware.swift                       # locale を URL prefix → cookie → Accept-Language の順で解決
└── Controllers/
    ├── SponsorPublicController.swift                # /, /inquiry (GET POST), /login (GET POST), /auth/verify, /logout
    ├── SponsorPortalController.swift                # /dashboard, /profile, /team, /team/invite, /invitations/:token
    ├── SponsorPlansController.swift                 # /plans, /plans/:slug
    ├── SponsorApplicationController.swift           # /applications/new, /applications, /applications/:id, /applications/:id/withdraw
    └── OrganizerSponsorController.swift             # /admin/sponsors[/...], /admin/inquiries, /admin/applications/:id/{approve|reject}
```

**Edits to existing files**

| ファイル | 変更 |
|---|---|
| `Server/Package.swift` | `Web` パッケージへの path dependency 追加（`.package(name: "Web", path: "../Web")`）。`Server` ターゲットに `WebSponsor` / `WebShared` を product 依存。`Crypto` (swift-crypto) を追加。 |
| `Server/Sources/Server/configure.swift` | `app.middleware.use(HostRoutingMiddleware())` を `FileMiddleware` の前に追加。Sponsor 系 11 マイグレーションを既存ブロックの後に登録。`CORSMiddleware` の許容オリジンに `https://sponsor.tryswift.jp` を追加。 |
| `Server/Sources/Server/routes.swift` | `try app.register(collection: SponsorRoutes())` を 1 行追加。 |
| `Server/Sources/Server/Controllers/AuthController.swift` | 変更なし（cookie ドメイン共有は既に `.tryswift.jp` で実装済み）。 |

### 3. SharedModels additions

**`SharedModels/Sources/SharedModels/Sponsor/`**（新規ディレクトリ）

すべて `public Codable, Sendable, Equatable`、Foundation のみ依存:

- `SponsorPortalLocale.swift` — `enum: String { case ja, en }`
- `SponsorMemberRole.swift` — `enum: String { case owner, member }`
- `SponsorOrganizationStatus.swift` — `enum: String { case active, suspended, archived }`
- `SponsorApplicationStatus.swift` — `enum: String { case draft, submitted, underReview, approved, rejected, withdrawn }`
- `SponsorOrganizationDTO.swift`
- `SponsorUserDTO.swift`
- `SponsorMembershipDTO.swift`
- `SponsorPlanDTO.swift`
- `SponsorPlanLocalizationDTO.swift`
- `SponsorInquiryDTO.swift`
- `SponsorApplicationDTO.swift`
- `SponsorApplicationFormPayload.swift` — 申込フォーム入力値（`SponsorApplication.payload` JSONB の中身）

既存 `Sponsors.swift` / `Plan` enum（display-only、DataClient 用）は **触らない**。新しい型は `Sponsor/` サブディレクトリに分離。

### 4. Routing endpoints (sponsor.tryswift.jp)

| Method | URL | Controller method | Auth |
|---|---|---|---|
| GET  | `/` `/ja` `/en` | `SponsorPublicController.landing` | public |
| GET  | `/inquiry` | `SponsorPublicController.renderInquiry` | public |
| POST | `/inquiry` | `SponsorPublicController.submitInquiry` | public + rate-limit |
| GET  | `/inquiry/thanks` | `SponsorPublicController.inquiryThanks` | public |
| GET  | `/login` | `SponsorPublicController.renderLogin` | public |
| POST | `/login` | `SponsorPublicController.requestMagicLink` | public + rate-limit |
| GET  | `/login/sent` | `SponsorPublicController.loginSent` | public |
| GET  | `/auth/verify` | `SponsorPublicController.verifyMagicLink` | token query |
| POST | `/logout` | `SponsorPublicController.logout` | sponsor auth |
| GET  | `/dashboard` | `SponsorPortalController.dashboard` | sponsor auth |
| GET  | `/profile` | `SponsorPortalController.profile` | sponsor auth |
| POST | `/profile` | `SponsorPortalController.updateProfile` | owner |
| GET  | `/team` | `SponsorPortalController.team` | sponsor auth |
| POST | `/team/invite` | `SponsorPortalController.invite` | owner |
| POST | `/team/:userID/remove` | `SponsorPortalController.removeMember` | owner |
| GET  | `/invitations/:token` | `SponsorPortalController.acceptInvitation` | invitation token |
| GET  | `/plans` | `SponsorPlansController.list` | sponsor auth |
| GET  | `/applications/new` | `SponsorApplicationController.renderForm` | sponsor auth |
| POST | `/applications` | `SponsorApplicationController.submit` | sponsor auth |
| GET  | `/applications/:id` | `SponsorApplicationController.detail` | sponsor auth (org member) |
| POST | `/applications/:id/withdraw` | `SponsorApplicationController.withdraw` | owner + status=submitted |
| GET  | `/admin/sponsors` | `OrganizerSponsorController.listSponsors` | organizer (.admin) |
| GET  | `/admin/sponsors/:id` | `OrganizerSponsorController.sponsorDetail` | organizer |
| GET  | `/admin/inquiries` | `OrganizerSponsorController.listInquiries` | organizer |
| GET  | `/admin/applications` | `OrganizerSponsorController.listApplications` | organizer |
| GET  | `/admin/applications/:id` | `OrganizerSponsorController.applicationDetail` | organizer |
| POST | `/admin/applications/:id/approve` | `OrganizerSponsorController.approve` | organizer |
| POST | `/admin/applications/:id/reject` | `OrganizerSponsorController.reject` | organizer |
| GET  | `/healthz` | inline | public |

`HostRoutingMiddleware` が `Host: sponsor.tryswift.jp` のみこれらのルートを許可。それ以外のホスト（`api.tryswift.jp` 等）からは 404 を返す。逆に `api.tryswift.jp` 経由の `/api/v1/...` は引き続き既存ルーティングで処理される。

### 5. Email templates

`SponsorEmailTemplates.swift` 内で純粋 Swift 関数として定義（テンプレートファイル不要、テスト容易）:

```swift
enum SponsorEmailKind {
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
                     recipientName: String?) -> EmailMessage
}
```

各 case ごとに JA/EN の subject / html / text を `switch` で書き分け。HTML は Elementary で組まずに文字列で記述。

### 6. CI changes

| ワークフロー | 変更 |
|---|---|
| `.github/workflows/format.yml` | `./Web` を format 対象に追加、`./Website` `./CfPWeb` を削除 |
| `.github/workflows/test-website.yml` | path filter: `Web/Sources/WebConference/**` 等に変更。コマンド: `cd Web && swift build --target WebConference` |
| `.github/workflows/test-cfpweb.yml`（あれば） | path filter / コマンド更新（`Web/Sources/WebCfP/**`） |
| `.github/workflows/deploy_website.yml` | build path → `Web/Build`、Pages artifact path 更新 |
| `.github/workflows/deploy-cfpweb.yml` | `cd Web && swift run WebCfP --api-base-url … --output Build`、Wrangler deploy path → `Web/Build` |
| `.github/workflows/test-api-server.yml` | path filter に `Web/**` を追加（Server が Web に依存） |
| `.github/workflows/build-android.yml` | 変更不要 |

`trySwiftTokyo.xcworkspace/contents.xcworkspacedata` の package 参照（`CfPWeb` / `Website` を `Web` に変更）と `xcshareddata/swiftpm/Package.resolved` のリフレッシュ。

### 7. DNS / fly.io / Resend

- DNS: Cloudflare で `sponsor.tryswift.jp` の CNAME を `tryswift-api-prod.fly.dev` に向ける
- fly.io: `fly certs add sponsor.tryswift.jp -a tryswift-api-prod`（staging 用に `sponsor-staging.tryswift.jp` も追加検討）
- 環境変数（fly.io secrets）:
  - `RESEND_API_KEY`
  - `RESEND_FROM_EMAIL`（例: `Sponsorship <sponsorship@mail.tryswift.jp>`）
  - `SPONSOR_BASE_URL=https://sponsor.tryswift.jp`
  - `SPONSOR_HOST=sponsor.tryswift.jp`
  - `SPONSOR_SLACK_WEBHOOK_URL`（既存の `SLACK_WEBHOOK_URL` と分離が望ましい）
  - `SPONSOR_MATERIALS_URL`（資料 PDF の公開 URL、`/sponsor/materials/...`）
- Resend: `mail.tryswift.jp` ドメインの DKIM / SPF / DMARC を設定

## Reusable existing code

- `Server/Sources/Server/Services/SlackNotifier.swift` — `SponsorSlackNotifier` の実装パターン（fire-and-forget、env 不在で no-op）
- `Server/Sources/Server/Services/LumaClient.swift` — `ResendClient` の実装パターン（リトライ・エラー処理）
- `Server/Sources/Server/Middleware/AuthMiddleware.swift` — Organizer 認証の経路（既存 `User` JWT + `auth_token` cookie）
- `Server/Sources/Server/Auth/JWTPayload.swift` — `SponsorJWTPayload` 設計の参考
- `Server/Sources/Server/Migrations/SeedTrySwiftTokyo2026.swift` — `SeedSponsorPlans2026` の idempotent パターン
- `SharedModels/Sources/SharedModels/CfP/UserDTO.swift` — DTO 定義の慣習
- `Server/Tests/ServerTests/AdminAPITests.swift` — VaporTesting + Swift Testing + SQLite in-memory パターン
- `CfPWeb/Sources/CfPWeb/Components/AppLayout.swift` — Elementary Layout の参考（`WebShared.PortalLayout` の元ネタ）

## Verification

### Unit / integration tests (Swift Testing + VaporTesting + SQLite)

`Server/Tests/ServerTests/Sponsor/`:

- `SponsorInquiryFlowTests.swift` — 公開フォーム POST → SponsorUser + MagicLinkToken 作成、Slack stub 受信、Resend stub 受信
- `MagicLinkServiceTests.swift` — 発行 / 検証 / 期限切れ拒否 / 単回使用拒否 / 改竄拒否
- `SponsorAuthMiddlewareTests.swift` — cookie 有 → 200、無 → 302 redirect、不正 → 401
- `SponsorMembershipTests.swift` — Owner 招待 → 別 SponsorUser 受諾 → membership 1 件のみ作成（race ガード）
- `SponsorApplicationFlowTests.swift` — 提出 → 取り下げ可、Organizer 承認 → ステータス変更 + Slack + email
- `OrganizerAccessTests.swift` — `.admin` 通過、`.speaker` 403、未認証 401
- `HostRoutingMiddlewareTests.swift` — `Host: sponsor.tryswift.jp` がスポンサールートに、それ以外が既存 API に
- `LocaleMiddlewareTests.swift` — URL prefix `/ja/` 優先、cookie で記憶
- `SponsorEmailTemplatesTests.swift` — JA / EN 両方の件名・本文スナップショット（HTML はスナップショットから除外、subject + text のみ）

`ResendClient` と `SponsorSlackNotifier` はプロトコル抽出して `Application.storage` 経由でテスト時にメモリスタブを注入。Slack の既存パターン（env 不在で no-op）は本番でも利用。

### Manual E2E (staging)

1. Cloudflare Pages から `sponsor-staging.tryswift.jp` で Vapor staging に到達確認
2. JA でランディング → 資料請求 POST → メール受信（magic-link + 資料 URL）
3. magic-link クリック → `sponsor_auth_token` cookie 発行確認 → `/dashboard` 到達
4. プロフィール編集（組織名・国・住所）
5. メンバー招待 → 別アカウントで accept → membership 確立
6. プラン一覧 → Gold で申込 → status=submitted、Slack 通知確認
7. Organizer (既存 GitHub OAuth) で `cfp.tryswift.jp` にログイン → cookie が `.tryswift.jp` 共有 → `sponsor.tryswift.jp/admin/applications/:id` で承認
8. 申込スポンサー側に承認メール到達 → `/applications/:id` で status=approved 表示
9. 取り下げシナリオ: 別申込 → status=submitted → withdraw → status=withdrawn
10. 既存 `api.tryswift.jp/api/v1/conferences` が引き続き 200 を返すこと、CfPWeb と Website が引き続きデプロイ可能なこと

### Build commands (developer)

```bash
# Server tests
cd Server && swift test

# Web パッケージビルド
cd Web && swift build
cd Web && swift run WebCfP --api-base-url http://localhost:8080 --output Build
cd Web && swift run WebConference

# Sponsor 関連 only
cd Server && swift test --filter SponsorInquiryFlowTests
```

## Implementation Order (dependency graph)

**Phase A: 物理移動 PR（独立）**

1. `Web/Package.swift` 新規作成、`WebShared` `WebSponsor`（空 library）`WebCfP`（exec）`WebConference`（exec）の 4 ターゲットを定義
2. `git mv` で `CfPWeb/` → `Web/Sources/WebCfP/`、`Website/` → `Web/Sources/WebConference/`
3. CI ワークフロー一斉更新、`xcworkspace` の package 参照差し替え
4. CfPWeb と Website のローカルビルド・デプロイが従前通り動くことを確認
5. PR を切ってマージ

**Phase B: Foundation 機能 PR（A に積む）**

6. `Server/Package.swift` に `Web` への path 依存追加、`SharedModels` に `Sponsor/` ディレクトリ追加
7. `SharedModels/Sources/SharedModels/Sponsor/*` の DTO / enum 追加
8. `Server/Sources/Server/Sponsor/Models/*` と `Migrations/*` 追加、`configure.swift` に登録
9. `MagicLinkService` `ResendClient` `SponsorSlackNotifier` `SponsorEmailTemplates` 実装、ユニットテスト
10. `SponsorJWTPayload` `SponsorAuthMiddleware` `HostRoutingMiddleware` `LocaleMiddleware` `OrganizerOnlyMiddleware` 実装
11. `Web/Sources/WebShared/Layout.swift` `Locale.swift` `HTMX.swift` 実装
12. `Web/Sources/WebSponsor/Layout/PortalLayout.swift` + Components 実装
13. `Web/Sources/WebSponsor/Pages/Public/*`（Inquiry / Login）と対応する `SponsorPublicController` を実装、E2E テスト 1 本通す
14. Sponsor authenticated pages（Dashboard / Profile / Team / Plans / Applications）と対応 Controller、テスト
15. Organizer pages と `OrganizerSponsorController`、Slack 通知、テスト
16. `routes.swift` に `SponsorRoutes` 登録、`configure.swift` に `HostRoutingMiddleware` 追加
17. CI 通過確認、PR レビュー、staging デプロイ
18. fly.io cert / DNS / Resend ドメイン設定（PR マージ前後どちらでも可）
19. 本番デプロイ

ステップ 9〜15 は Layout / Components / Email templates / 各テストファイルが互いに独立なので並列化可能。

## Risk Callouts

1. **CI / xcworkspace の連動破壊** — `Web/` への移動 PR は path filter とビルドコマンドを atomically 更新する必要あり。Phase A の PR を分離して局所化することで blast radius を抑制
2. **Cookie ドメイン共有** — 既存 `auth_token` cookie は `Domain=.tryswift.jp` で発行済み（`AuthController.swift:447`）。新規 `sponsor_auth_token` も同じドメインで設定。HostRoutingMiddleware が host で物理分離するため衝突は起きない（テストで担保）
3. **HostRoutingMiddleware の漏れ** — `sponsor.tryswift.jp` で `/api/v1/...` が叩けてしまうと既存 API が二重露出する。明示的な拒否テストを `HostRoutingMiddlewareTests` に含める
4. **Resend の到達率** — `mail.tryswift.jp` の DKIM / SPF / DMARC を本番投入前に Resend ダッシュボードで Verified 状態にすること。未設定だと magic-link が SPAM 行きになり営業全停止
5. **Race condition: 招待二重受諾** — invitation token は `usedAt` 単一 unique 制約 + DB トランザクションで 1 件のみ保証
6. **Seed migration の idempotency** — `SeedSponsorPlans2026` は `(conferenceID, slug)` の unique index を活用して `if exists then update else insert` で書く（`SeedTrySwiftTokyo2026.swift` パターン踏襲）
7. **同時 active conference 仮定** — `Conference.isAcceptingSponsors` 列を追加、true な Conference が複数あった場合の挙動は `/plans` で undefined にせず `displayOrder asc` の最初を採用、テストで明示
8. **資料 PDF の Drive → Server 公開化** — Google Drive 上の現行 PDF を `Server/Public/sponsor/materials/` に配置する運用。アクセスログは Cloudflare 側で取得可能だが、ダウンロード追跡（誰がダウンロードしたか）は Foundation スコープ外

## Open Questions

実装フェーズで verify:

1. `Sponsor Inquiry` / `Sponsor Application` Google Form の正確な項目リスト — Plan 段階では取得未遂、実装着手時に再取得（手元で fields をコピーして提供 or Chrome 拡張接続後に取得）
2. `sponsor.tryswift.jp` の Cloudflare 設定（Proxy ON/OFF）— TLS 終端を Cloudflare で行うなら origin 側は HTTP のままでよいが、要件次第
3. 資料 PDF の最終的な置き場（Server/Public か Cloudflare R2 か） — Foundation では Server/Public で進めるが、サイズが大きい場合は要再検討
4. Rate limit の永続化方法 — Foundation では in-memory（Vapor 1 インスタンス前提）。スケールアウト時には Redis / Postgres で再設計
5. Organizer 承認時の Slack channel — 既存 `SLACK_WEBHOOK_URL` を流用するか、専用 `#sponsors` channel を新設するか
