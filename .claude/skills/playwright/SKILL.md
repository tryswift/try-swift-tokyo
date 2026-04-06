---
name: playwright
description: Patterns for Playwright E2E testing with custom fixtures, role-based selectors, and assertion patterns.
---

# Playwright E2E Testing Guidelines

## 1. Project Setup

- Config: `e2e/playwright.config.ts`
- Tests: `e2e/tests/`
- Run: `cd e2e && npx playwright test`
- Single project: chromium only
- Timeouts: 60s test, 15s expect

## 2. Custom Fixtures

Extend `base` test with typed fixtures for multi-browser scenarios:

```typescript
import { test as base, expect, type Page } from "@playwright/test";

export const test = base.extend<{ roomPage: Page; hostPage: Page }>({
    roomPage: async ({ page }, use) => {
        await page.goto("/");
        await use(page);
    },
    hostPage: async ({ browser }, use) => {
        const context = await browser.newContext();
        const page = await context.newPage();
        await page.goto("/host");
        await use(page);
        await page.context().close();
    },
});
export { expect };
```

Save this snippet as a shared fixture module (for example `e2e/fixtures.ts` or `e2e/fixtures.js`) and then import from it in your tests, e.g.:

```typescript
import { test, expect } from "./fixtures.js";
```

## 3. Selectors (prefer accessibility-based)

- Role: `page.getByRole("button", { name: /english/i })`
- Text: `page.getByText("Enter chat room code")`
- Chaining: `page.getByText("Label").locator("..").getByRole("button")`
- Filter: `page.getByRole("listitem").filter({ hasText: "Japanese" })`
- Nth: `page.locator("input").nth(i)`
- First: `.first()` to disambiguate multiple matches

## 4. Assertions

- Visibility: `await expect(element).toBeVisible({ timeout: 10_000 })`
- Negated: `await expect(element).not.toBeVisible({ timeout: 10_000 })`
- URL: `await expect(page).not.toHaveURL(/\/login/)`
- Count: `expect(count).toBeGreaterThan(0)`
- Text: `expect(text?.trim()).toBeTruthy()`

## 5. Wait Patterns

- **Prefer web assertions** over explicit waits: `await expect(element).toBeVisible()` auto-retries.
- Network idle: `await page.waitForLoadState("networkidle")` (DISCOURAGED by Playwright docs; used in this project for legacy reasons).
- Timeout: `await page.waitForTimeout(3_000)` (WebSocket propagation, animations).
- Element: `await element.waitFor({ state: "visible", timeout: 15_000 })`.
- Graceful: `.isVisible().catch(() => false)` for optional elements.

## 6. Screenshots

```typescript
await page.screenshot({ path: "test-results/state.png" });
await page.screenshot({ path: "test-results/full.png", fullPage: true });
```

## 7. Test Organization

- Group: `test.describe("Feature - Aspect", () => { ... })`
- Use fixture names: `async ({ roomPage: page }) => { ... }`
- Import: `import { test, expect } from "./fixtures.js"` (note `.js` extension)
