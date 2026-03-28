Check the current PR for CI failures and Copilot review comments, then fix any issues.

First, determine the PR number for the current branch:

```bash
gh pr view --json number --jq '.number'
```

Then follow the "Post-PR Workflow" steps defined in CLAUDE.md:

1. `gh pr checks <PR_NUMBER> --watch --fail-fast` でCI完了を待つ
2. `git pull --rebase` でformat自動コミットを取り込む
3. CI失敗があれば `gh run view <RUN_ID> --log-failed` でログ確認、修正、ローカルテスト、push
4. Copilotレビューコメントを `gh api` で取得して確認
5. 有効なフィードバックに対応して commit & push
6. CI passes かつ全フィードバック対応済みになるまで繰り返す
7. 対応結果をサマリーとして報告
