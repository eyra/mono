import { test, expect } from '@playwright/test';
import path from 'path';

/**
 * Smoke test: data donation flow.
 *
 * Navigates to a known pre-existing assignment affiliate URL (no login),
 * completes the Feldspar donation flow with a small test file, and
 * verifies the donate API responds 200.
 *
 * The assignment and Feldspar tool must exist in each environment's
 * "Smoke Test" project — set up once, reused on every smoke run.
 */

// Affiliate URL per environment — set once when the Smoke Test project is created.
// Use the /a/<code> path which auto-assigns a unique participant ID.
const DONATE_URLS: Record<string, string | null> = {
  prod:    '/a/Boi0rl',
  staging: null,
  dev:     null,
  test1:   null,
  test2:   null,
};

const env = process.env.SMOKE_ENV || 'prod';
const donateUrl = DONATE_URLS[env];

// Static Instagram fixture zip — valid package the Feldspar app can process.
const TEST_FILE = path.resolve(__dirname, 'testfiles', 'instagram_smoke.zip');

test.skip(!donateUrl, `No donate URL configured for ${env} — set DONATE_URLS["${env}"] in smoke/donate.spec.ts`);

test(`data donation flow works on ${env}`, async ({ page }, testInfo) => {
  const participantId = `smoke_${Date.now()}_${testInfo.workerIndex}`;

  test.setTimeout(60_000);

  console.log(`[SMOKE] Navigating to ${donateUrl}?p=${participantId}`);
  await page.goto(`${donateUrl}?p=${participantId}`);

  // Single task, no intro or consent — lands directly on the Feldspar tool
  // Wait for Feldspar iframe
  console.log(`[SMOKE] Waiting for Feldspar iframe...`);
  const feldsparContainer = page.locator('[phx-hook="FeldsparApp"]');
  await feldsparContainer.waitFor({ state: 'visible', timeout: 15000 });

  const frame = page.frameLocator('[phx-hook="FeldsparApp"] iframe');
  await expect(frame.getByRole('heading', { name: 'Instagram' })).toBeVisible({ timeout: 20000 });
  console.log(`[SMOKE] Instagram Feldspar app ready`);

  // Upload Instagram fixture
  await frame.locator('input[type="file"]').setInputFiles(TEST_FILE);

  await frame.getByRole('button', { name: 'Continue' }).click();

  // Verify data was parsed correctly
  await expect(frame.getByText('Summary information', { exact: true })).toBeVisible({ timeout: 10000 });
  console.log(`[SMOKE] Data parsed, summary visible`);

  // Donate
  console.log(`[SMOKE] Donating...`);
  const donateResponse = page.waitForResponse(
    r => r.url().includes('/api/feldspar/donate') && r.status() === 200,
    { timeout: 30000 }
  );

  await frame.getByRole('button', { name: 'Donate' }).click();

  const response = await donateResponse;
  expect(response.status()).toBe(200);
  console.log(`[SMOKE] Donate API responded 200 ✓`);
});
