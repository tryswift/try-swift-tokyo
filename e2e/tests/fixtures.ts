import { test as base, expect, type Page, type Browser } from "@playwright/test";

const FLITTO_ROOM_NUMBER = process.env.FLITTO_ROOM_NUMBER ?? "";
const FLITTO_DEMO_ID = process.env.FLITTO_DEMO_ID ?? "";
const FLITTO_DEMO_PW = process.env.FLITTO_DEMO_PW ?? "";

export { expect };

/** Enter the 6-digit room code on the given page and join the room */
async function enterRoomCode(page: Page): Promise<void> {
  await page.goto("/");
  await page.waitForLoadState("networkidle");

  const digitInputs = page.locator("input");
  await digitInputs.first().waitFor({ state: "visible", timeout: 15_000 });

  const digits = FLITTO_ROOM_NUMBER.split("");
  for (let i = 0; i < digits.length; i++) {
    await digitInputs.nth(i).fill(digits[i]);
  }

  const joinButton = page.getByRole("button", { name: /join room/i });
  await joinButton.click();

  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(3_000);
}

/** Login to the host dashboard and enter the room */
async function loginAndEnterRoom(browser: Browser): Promise<Page> {
  const context = await browser.newContext({
    permissions: ["microphone"],
  });
  const page = await context.newPage();

  // Login
  await page.goto("/login");
  await page.waitForLoadState("networkidle");

  const usernameInput = page.getByRole("textbox").first();
  await usernameInput.waitFor({ state: "visible", timeout: 15_000 });
  await usernameInput.fill(FLITTO_DEMO_ID);

  const passwordInput = page.locator('input[type="password"]');
  await passwordInput.fill(FLITTO_DEMO_PW);

  const loginButton = page.getByRole("button", {
    name: /log\s*in|sign\s*in|submit/i,
  });
  await loginButton.click();

  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(3_000);

  // After login, we land on the room list (トークルーム一覧)
  // Click the room card that contains our room number
  const roomCard = page.getByText(FLITTO_ROOM_NUMBER).locator("..");
  await roomCard.click();

  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(3_000);

  await page.screenshot({ path: "test-results/host-room-entered.png" });

  return page;
}

/** Join the audience room by entering the 6-digit code (new browser context) */
async function joinAudienceRoom(browser: Browser): Promise<Page> {
  const context = await browser.newContext();
  const page = await context.newPage();
  await enterRoomCode(page);
  return page;
}

export const test = base.extend<{
  roomPage: Page;
  hostPage: Page;
  hostAndAudiencePages: { host: Page; audience: Page };
}>({
  // Audience fixture: enters 6-digit room code and joins the room
  roomPage: async ({ page }, use) => {
    if (!FLITTO_ROOM_NUMBER) {
      throw new Error(
        "FLITTO_ROOM_NUMBER must be set in environment variables (or .env locally)"
      );
    }

    await enterRoomCode(page);
    await use(page);
  },

  // Host fixture: logs in, then enters the room
  hostPage: async ({ browser }, use) => {
    if (!FLITTO_DEMO_ID || !FLITTO_DEMO_PW || !FLITTO_ROOM_NUMBER) {
      throw new Error(
        "FLITTO_DEMO_ID, FLITTO_DEMO_PW, and FLITTO_ROOM_NUMBER must be set"
      );
    }

    const page = await loginAndEnterRoom(browser);
    await use(page);
    await page.context().close();
  },

  // Combined fixture: host in room + audience in room
  hostAndAudiencePages: async ({ browser }, use) => {
    if (!FLITTO_DEMO_ID || !FLITTO_DEMO_PW || !FLITTO_ROOM_NUMBER) {
      throw new Error(
        "FLITTO_DEMO_ID, FLITTO_DEMO_PW, and FLITTO_ROOM_NUMBER must all be set"
      );
    }

    const hostPage = await loginAndEnterRoom(browser);
    const audiencePage = await joinAudienceRoom(browser);

    await use({ host: hostPage, audience: audiencePage });

    await hostPage.context().close();
    await audiencePage.context().close();
  },
});
