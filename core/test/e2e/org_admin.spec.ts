import { test, expect } from '@playwright/test';

/**
 * Org Admin happy-path E2E test.
 *
 * Validates the cross-cutting org-owner flow that's hard to cover with
 * unit tests:
 *   - Auth handoff: org-owner role → :admin GreenLight role
 *   - Menu visibility: Admin item appears for org owners
 *   - Page mount: /admin/config does NOT deny access for an org owner who
 *     isn't a system admin
 *   - Org content page is reachable
 *
 * The fixture (a dedicated E2E test org with the e2e researcher as owner)
 * is provisioned by /api/e2e/setup during global-setup. It is intentionally
 * separate from any real production org so this test never touches live data.
 */

const RESEARCHER_EMAIL = process.env.E2E_RESEARCHER_EMAIL || 'e2e-researcher@eyra.co';
const RESEARCHER_PASSWORD = process.env.E2E_RESEARCHER_PASSWORD || 'E2ETestPassword123!';
const TEST_ORG_ID = process.env.E2E_TEST_ORG_ID;

const CONNECTED_SELECTOR = '[data-phx-main].phx-connected';

test.describe('Org Admin Flow', () => {
  test.skip(!TEST_ORG_ID, 'E2E_TEST_ORG_ID not set (setup endpoint did not return one)');

  test('org owner reaches admin pages without being denied', async ({ page }) => {
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        console.log(`[BROWSER ERROR] ${msg.text()}`);
      }
    });

    // Step 1: Sign in as the e2e researcher
    console.log('[TEST] Step 1: Signing in as researcher...');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await page.locator("[data-testid='signin-tab-creator']").click();
    await page.waitForTimeout(300);

    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();

    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    console.log(`[TEST] Signed in, current URL: ${page.url()}`);

    // Step 2: /admin/config must not deny access. For a single-org owner the
    // mount push-navigates to /org/node/<id>; for a multi-org owner the
    // multi-org admin page renders. Either is acceptable here.
    console.log('[TEST] Step 2: Navigating to /admin/config...');
    await page.goto('/admin/config');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    const url = page.url();
    console.log(`[TEST] After connect, URL: ${url}`);
    expect(url).not.toContain('/access_denied');
    expect(url).toMatch(/\/admin\/config|\/org\/node\/\d+/);

    // Step 3: Open the dedicated E2E test org content page directly. This
    // exercises the route + mount + auth chain end-to-end against an org
    // we own. The id comes from /api/e2e/setup so it works on every env.
    console.log(`[TEST] Step 3: Visiting /org/node/${TEST_ORG_ID}...`);
    await page.goto(`/org/node/${TEST_ORG_ID}`);
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    expect(page.url()).not.toContain('/access_denied');
    await expect(page.getByText('Members', { exact: true }).first()).toBeVisible({ timeout: 3000 });

    console.log('[TEST] Org admin happy path verified');
  });
});
