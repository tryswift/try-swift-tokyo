# try! Swift Tokyo

## Project Structure

- `Server/` - Vapor backend (Swift 6.3). Tests: `cd Server && swift test`
  - `Server/Sources/Server/Sponsor/` - sponsor.tryswift.jp portal (auth/controllers/services/SSR via WebSponsor). Host-gated by `SponsorHostOnlyMiddleware`.
  - `Server/Sources/Server/Scholarship/` - JSON / form-redirect endpoints under `/api/v1/scholarship/*` consumed by the student.tryswift.jp static site. Magic-link auth on a dedicated `student_users` + `student_magic_link_tokens` tree; organizer routes use a fetch-friendly `ScholarshipOrganizerAuthMiddleware` that returns 401/403 instead of redirecting.
- `Web/` - SSR libraries and static-site executables (Elementary + Ignite). `WebShared` and `WebSponsor` are libraries linked into Server. `WebCfP`, `WebScholarship`, and `WebConference` are executables that emit static HTML for Cloudflare Pages.
- `Website/` - Ignite static site. Build: `cd Website && swift build`
- `Android/` - Skip framework (Swift → Kotlin). Build: `cd Android && swift build`
- `App/` - iOS app (SwiftUI + TCA)
- `SharedModels/` - Shared Swift package
- `DataClient/` - Data access layer
- `e2e/` - Playwright E2E tests: `cd e2e && npx playwright test`

## Subdomain topology

| Host | Hosting | Notes |
|---|---|---|
| `api.tryswift.jp` | Fly.io (`tryswift-api-prod`) | Vapor JSON API. `NotSponsorHostMiddleware` keeps `/api/v1/...` off the sponsor host. |
| `sponsor.tryswift.jp` | Fly.io (`tryswift-api-prod`) | SSR portal, host-gated by `SponsorHostOnlyMiddleware`. Magic-link auth on `SponsorUser`. |
| `cfp.tryswift.jp` | Cloudflare Pages (`tryswift-cfp`) | Static site built from `Web/Sources/WebCfP`. Forms POST to api.tryswift.jp. |
| `student.tryswift.jp` | Cloudflare Pages (`tryswift-student`) | Static site built from `Web/Sources/WebScholarship`; client JS fetches `/api/v1/scholarship/*`. Magic-link auth on `StudentUser`; organizers reuse the shared `auth_token` cookie. |

Required server env vars for scholarship endpoints: `STUDENT_BASE_URL`, `SCHOLARSHIP_API_BASE_URL` (defaults to `API_BASE_URL` then `https://api.tryswift.jp`), `ODPT_API_KEY` (optional, for live fare lookups), `SCHOLARSHIP_SLACK_WEBHOOK_URL` (optional, falls back to `SLACK_WEBHOOK_URL`), `RESEND_API_KEY`, `RESEND_FROM_EMAIL`.

## CI Workflows

- **format.yml** - PR to main で swift-format を実行。non-fork PR では自動コミットする
- **test-api-server.yml** - `Server/**`, `SharedModels/**` 変更時に `swift test`
- **test-website.yml** - `Website/**`, `SharedModels/**`, `DataClient/**`, `LocalizationGenerated/**` 変更時に `swift build`
- **build-android.yml** - `Android/**`, `SharedModels/**`, `DataClient/**` 変更時に `swift build`
- **e2e-live-translation.yml** - `e2e/**` 変更時に Playwright テスト

## Post-PR Workflow (IMPORTANT - Default Behavior)

`gh pr create` でPRを作成した後、**必ず**以下のステップを実行すること。

### Step 1: CI完了を待つ

```bash
gh pr checks <PR_NUMBER> --watch --fail-fast
```

`--watch` でCIのステータスチェック / チェックランが全て完了するまでブロックする。Copilot code review はチェックとしては扱われないため含まれず、CI完了後に **Step 4** で明示的に確認すること。

### Step 2: format自動コミットを取り込む

```bash
git pull --rebase
```

`format.yml` が non-fork PR で swift-format の自動コミットを行うため、ローカル変更前に必ず pull する。

### Step 3: CI失敗の修正

失敗したチェックがある場合:

1. `gh run view <RUN_ID> --log-failed` でログを確認
2. 原因を特定して修正
3. ローカルでテスト実行:
   - Server: `cd Server && swift test`
   - Website: `cd Website && swift build`
   - Android: `cd Android && swift build`
4. commit & push
5. Step 1 に戻る

### Step 4: Copilotレビューコメントの確認

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

# レビュー本文の取得
gh api repos/$REPO/pulls/<PR_NUMBER>/reviews \
  --jq '.[] | select(.user.login == "copilot-pull-request-reviewer[bot]") | {id, state, body}'

# インラインコメントの取得（上記で得た review ID を使用）
gh api repos/$REPO/pulls/<PR_NUMBER>/reviews/<REVIEW_ID>/comments \
  --jq '.[] | {path, line, body}'
```

インラインコメントが0件の場合もある。

### Step 5: Copilotフィードバックへの対応

- 有効な指摘 → 修正して commit & push → Step 1 に戻る
- 対象外の指摘（変更していないコードへの指摘等） → スキップ

### Step 6: 報告

- CI結果と修正内容のサマリー
- Copilotコメントへの対応状況（対応/スキップの理由）

### Notes

- **パス限定CIトリガー**: 変更パスに該当しないワークフローは実行されない
- **複数回のCopilotレビュー**: push後に再レビューされた場合、最新のレビュー（配列の最後）を使用する
@ASC.md
