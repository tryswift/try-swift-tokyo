# try! Swift Tokyo

## Project Structure

- `Server/` - Vapor backend (Swift 6.3). Tests: `cd Server && swift test`
  - `Server/Sources/Server/Sponsor/` - sponsor.tryswift.jp portal (auth/controllers/services/SSR via WebSponsor). Host-gated by `SponsorHostOnlyMiddleware`.
  - `Server/Sources/Server/Scholarship/` - student.tryswift.jp portal (auth/controllers/services/SSR via WebScholarship). Host-gated by `StudentHostOnlyMiddleware`. Magic-link auth on a dedicated `student_users` + `student_magic_link_tokens` tree; organizers reuse the shared `auth_token` cookie + `OrganizerOnlyMiddleware`.
- `Web/` - SSR libraries and static-site executables (Elementary + Ignite). `WebShared`, `WebSponsor`, `WebScholarship` are libraries linked into Server; `WebCfP` and `WebConference` are executables.
- `Website/` - Ignite static site. Build: `cd Website && swift build`
- `Android/` - Skip framework (Swift → Kotlin). Build: `cd Android && swift build`
- `App/` - iOS app (SwiftUI + TCA)
- `SharedModels/` - Shared Swift package
- `DataClient/` - Data access layer
- `e2e/` - Playwright E2E tests: `cd e2e && npx playwright test`

## Subdomains served by the Server (`tryswift-api-prod`)

A single Fly.io app (`tryswift-api-prod`) serves multiple hosts; `HostRoutingMiddleware` dispatches by `Host` header.

| Host | Routes | Notes |
|---|---|---|
| `api.tryswift.jp` | `/api/v1/...` | JSON API. Other hosts return 404 here (`NotSponsorHostMiddleware` + `NotStudentHostMiddleware`). |
| `sponsor.tryswift.jp` | SponsorRoutes | Magic-link auth on SponsorUser. |
| `student.tryswift.jp` | ScholarshipRoutes | Magic-link auth on StudentUser. Required env: `STUDENT_BASE_URL`, `ODPT_API_KEY` (optional, for live fare lookups), `SCHOLARSHIP_SLACK_WEBHOOK_URL` (optional, falls back to `SLACK_WEBHOOK_URL`), `RESEND_API_KEY`, `RESEND_FROM_EMAIL`. |
| `cfp.tryswift.jp` | (separate Cloudflare Pages site) | Built from `Web/Sources/WebCfP`. |

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
