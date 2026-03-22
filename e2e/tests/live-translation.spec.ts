import { test, expect } from "./fixtures.js";

test.describe("Live Translation - Connection", () => {
  test("should join room and leave the room code page", async ({
    roomPage: page,
  }) => {
    const roomCodeHeading = page.getByText("Enter chat room code");
    await expect(roomCodeHeading).not.toBeVisible({ timeout: 10_000 });
  });

  test("should display room title", async ({ roomPage: page }) => {
    // The main banner contains the logo + room title paragraph
    // Use .first() because language modal also has a banner
    const banner = page.getByRole("banner").first();
    await expect(banner).toBeVisible({ timeout: 10_000 });

    // Room title is the first <p> inside the banner area (e.g., "Test")
    const roomTitle = page.getByText("Test");
    await expect(roomTitle.first()).toBeVisible();
  });

  test("should show connected state (no errors)", async ({
    roomPage: page,
  }) => {
    // When connected, the page shows room content or "not started" message
    const notStarted = page.getByText(
      "The presentation has not started yet."
    );
    const hasNotStarted = await notStarted.isVisible().catch(() => false);

    if (hasNotStarted) {
      await expect(notStarted).toBeVisible();
    }

    // Verify we're in the room (banner is visible)
    const banner = page.getByRole("banner").first();
    await expect(banner).toBeVisible();
  });
});

test.describe("Live Translation - Language", () => {
  test("should show language selector button", async ({ roomPage: page }) => {
    // The language selector is a button labeled with the current language
    const langButton = page.getByRole("button", { name: /english/i });
    await expect(langButton).toBeVisible({ timeout: 10_000 });
  });

  test("should open language list when clicking language button", async ({
    roomPage: page,
  }) => {
    // Click the language button (e.g., "English")
    const langButton = page.getByRole("button", { name: /english/i });
    await langButton.click();
    await page.waitForTimeout(1_000);

    // The language list appears with listitem elements
    const languageItems = page.getByRole("listitem");
    const count = await languageItems.count();
    expect(count).toBeGreaterThan(0);

    // Verify "Select language" heading is shown
    const selectLangHeading = page.getByText("Select language");
    await expect(selectLangHeading).toBeVisible();
  });

  test("should display language names correctly", async ({
    roomPage: page,
  }) => {
    // Open language selector
    const langButton = page.getByRole("button", { name: /english/i });
    await langButton.click();
    await page.waitForTimeout(1_000);

    // Verify list items contain language names (English + native)
    const languageItems = page.getByRole("listitem");
    const count = await languageItems.count();
    expect(count).toBeGreaterThan(0);

    // Check first 5 items have non-empty text
    for (let i = 0; i < Math.min(count, 5); i++) {
      const text = await languageItems.nth(i).textContent();
      expect(text?.trim()).toBeTruthy();
    }

    // Verify some known languages exist
    await expect(page.getByText("Japanese")).toBeVisible();
    await expect(page.getByText("Korean")).toBeVisible();
    await expect(page.getByText("English").first()).toBeVisible();
  });

  test("should switch language when selecting a different one", async ({
    roomPage: page,
  }) => {
    // Open language selector
    const langButton = page.getByRole("button", { name: /english/i });
    await langButton.click();
    await page.waitForTimeout(1_000);

    // Click the Japanese language item
    const japaneseItem = page.getByRole("listitem").filter({
      hasText: "Japanese",
    });
    await japaneseItem.click();

    // Wait for language change to apply
    await page.waitForTimeout(2_000);

    // After switching, the button accessible name changes to "Japanese"
    const jaButton = page.getByRole("button", { name: /japanese/i });
    await expect(jaButton).toBeVisible({ timeout: 5_000 });
  });
});

test.describe("Live Translation - Chat Reception", () => {
  test("should show chat messages or not-started placeholder", async ({
    roomPage: page,
  }) => {
    await page.waitForTimeout(3_000);

    const notStarted = page.getByText(
      "The presentation has not started yet."
    );
    const hasNotStarted = await notStarted.isVisible().catch(() => false);

    if (hasNotStarted) {
      // Room is not streaming - this is expected for dev room
      await expect(notStarted).toBeVisible();
      const subtitle = page.getByText(
        "Once the presentation begins, the translation will be displayed on the page."
      );
      await expect(subtitle).toBeVisible();
    }

    // Take a screenshot for manual review
    await page.screenshot({ path: "test-results/chat-state.png" });
  });
});

test.describe("Live Translation - TTS", () => {
  test("should have toolbar icons (mute and settings)", async ({
    roomPage: page,
  }) => {
    // The main banner has the logo + 2 clickable toolbar icons (mute, settings)
    const banner = page.getByRole("banner").first();
    await expect(banner).toBeVisible({ timeout: 10_000 });

    // Banner contains img elements (logo, mute icon, settings icon)
    // Use getByRole("img") to match accessibility tree img roles
    const images = banner.getByRole("img");
    const count = await images.count();
    expect(count).toBeGreaterThanOrEqual(3);
  });
});

test.describe("Live Translation - Background Recovery", () => {
  test("should handle page visibility change gracefully", async ({
    roomPage: page,
  }) => {
    // Simulate going to background
    await page.evaluate(() => {
      Object.defineProperty(document, "hidden", {
        configurable: true,
        get: () => true,
      });
      document.dispatchEvent(new Event("visibilitychange"));
    });

    await page.waitForTimeout(2_000);

    // Simulate coming back to foreground
    await page.evaluate(() => {
      Object.defineProperty(document, "hidden", {
        configurable: true,
        get: () => false,
      });
      document.dispatchEvent(new Event("visibilitychange"));
    });

    await page.waitForTimeout(3_000);

    // Verify page is still functional after recovery
    const banner = page.getByRole("banner").first();
    await expect(banner).toBeVisible();
  });
});
