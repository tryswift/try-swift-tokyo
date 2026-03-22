import { test as base, expect, type Page } from "@playwright/test";

const FLITTO_ROOM_NUMBER = process.env.FLITTO_ROOM_NUMBER ?? "";

export { expect };

export const test = base.extend<{ roomPage: Page }>({
  roomPage: async ({ page }, use) => {
    if (!FLITTO_ROOM_NUMBER) {
      throw new Error("FLITTO_ROOM_NUMBER must be set in .env");
    }

    await page.goto("/");
    await page.waitForLoadState("networkidle");

    // The page shows "Enter chat room code" with 6 individual digit inputs
    const digitInputs = page.locator("input");
    await digitInputs.first().waitFor({ state: "visible", timeout: 15_000 });

    // Type the 6-digit room code into the individual input fields
    const digits = FLITTO_ROOM_NUMBER.split("");
    for (let i = 0; i < digits.length; i++) {
      const input = digitInputs.nth(i);
      await input.fill(digits[i]);
    }

    // Click the "Join room" button
    const joinButton = page.getByRole("button", { name: /join room/i });
    await joinButton.click();

    // Wait for the translation room to load
    await page.waitForLoadState("networkidle");
    // Give extra time for WebSocket connection to establish
    await page.waitForTimeout(3_000);

    await use(page);
  },
});
