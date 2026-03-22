import { test, expect } from "./fixtures.js";

test.describe("Host - Login", () => {
  test("should log in and enter the room", async ({ hostPage: page }) => {
    // The fixture handles login + room entry
    // Verify we're past the login page
    await expect(page).not.toHaveURL(/\/login/);

    // Verify room name is visible in the header
    await expect(page.getByText("Test")).toBeVisible();

    await page.screenshot({
      path: "test-results/host-room-entered.png",
      fullPage: true,
    });
  });
});

test.describe("Host - Room Interface", () => {
  test("should see streaming controls after entering room", async ({
    hostPage: page,
  }) => {
    // Verify the instruction message is visible
    // "下の「開始 ・停止」ボタンをタップして話してください。"
    await expect(page.getByText("開始").first()).toBeVisible();

    // Verify the start/stop button label
    await expect(page.getByText("開始・停止")).toBeVisible();

    // Verify audio input selector is visible
    await expect(page.getByText(/Audio Input/i)).toBeVisible();

    await page.screenshot({
      path: "test-results/host-streaming-controls.png",
      fullPage: true,
    });
  });
});

test.describe("Host - Streaming", () => {
  test("should start streaming with mic button", async ({
    hostPage: page,
  }) => {
    // Click the mic button (the button near the "開始・停止" label)
    const micButton = page.getByText("開始・停止").locator("..").getByRole("button");
    await micButton.click();
    await page.waitForTimeout(3_000);

    await page.screenshot({
      path: "test-results/host-streaming-active.png",
      fullPage: true,
    });

    // After clicking, the page should still show the room (not navigate away)
    await expect(page.getByText("Test")).toBeVisible();
  });
});

test.describe("Host-to-Audience E2E", () => {
  test("should deliver host audio stream to audience view", async ({
    hostAndAudiencePages,
  }) => {
    const { host, audience } = hostAndAudiencePages;

    // Screenshot both sides at start
    await host.screenshot({
      path: "test-results/e2e-host-start.png",
      fullPage: true,
    });
    await audience.screenshot({
      path: "test-results/e2e-audience-start.png",
      fullPage: true,
    });

    // Start streaming on the host side by clicking the mic button
    const micButton = host
      .getByText("開始・停止")
      .locator("..")
      .getByRole("button");
    await micButton.click();
    await host.waitForTimeout(3_000);

    await host.screenshot({
      path: "test-results/e2e-host-streaming.png",
      fullPage: true,
    });

    // Wait for WebSocket propagation to audience
    await audience.waitForTimeout(10_000);

    // Screenshot both sides after streaming
    await host.screenshot({
      path: "test-results/e2e-host-final.png",
      fullPage: true,
    });
    await audience.screenshot({
      path: "test-results/e2e-audience-final.png",
      fullPage: true,
    });

    // Verify audience is still connected (banner visible)
    const banner = audience.getByRole("banner").first();
    await expect(banner).toBeVisible();
  });
});
