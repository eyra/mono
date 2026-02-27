import { test, expect } from '@playwright/test';

/**
 * Feldspar Log Endpoint E2E Test
 *
 * Tests that the /api/feldspar/log endpoint works correctly.
 * This endpoint forwards client logs to the server for production visibility.
 *
 * Prerequisites:
 * - A participant account must exist (via E2E fixtures)
 */

// Test participant account - configure via Infisical per environment
// Defaults match seeds.exs for localhost development
const PARTICIPANT_EMAIL = process.env.E2E_PARTICIPANT_EMAIL || 'participant@eyra.co';
const PARTICIPANT_PASSWORD = process.env.E2E_PARTICIPANT_PASSWORD || 'asdf;lkjASDF0987';

const CONNECTED_SELECTOR = '[data-phx-main].phx-connected';

test.describe('Feldspar Log Endpoint', () => {
  test('authenticated user can send log messages', async ({ page, request }) => {
    console.log('[TEST] Starting Feldspar log endpoint test');

    // Step 1: Login as participant to get session cookies
    console.log('[TEST] Step 1: Logging in as participant...');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Fill in login form (participant tab is default)
    const participantPanel = '#account_signin-tab_panel_participant';
    await page.locator(`${participantPanel} [data-testid='signin-email-input']`).fill(PARTICIPANT_EMAIL);
    await page.locator(`${participantPanel} [data-testid='signin-password-input']`).fill(PARTICIPANT_PASSWORD);
    await page.locator(`${participantPanel} [data-testid='signin-submit-button']`).click();

    // Wait for redirect after successful login
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    console.log(`[TEST] Logged in, current URL: ${page.url()}`);

    // Step 2: Get cookies from browser context for API requests
    const cookies = await page.context().cookies();
    const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ');

    // Step 3: Test logging at different levels
    console.log('[TEST] Step 2: Testing log endpoint...');

    const logLevels = ['debug', 'info', 'warn', 'error'];

    for (const level of logLevels) {
      console.log(`[TEST] Sending ${level} log...`);

      const response = await page.evaluate(
        async ({ level, cookieHeader }) => {
          const res = await fetch('/api/feldspar/log', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify({
              level: level,
              message: `E2E test log message at ${level} level`,
              context: {
                test: 'feldspar_log_e2e',
                timestamp: new Date().toISOString(),
              },
            }),
          });
          return {
            status: res.status,
            body: await res.json(),
          };
        },
        { level, cookieHeader }
      );

      console.log(`[TEST] ${level} response: ${response.status} - ${JSON.stringify(response.body)}`);
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ok');
    }

    console.log('[TEST] All log levels tested successfully!');
  });

  test('unauthenticated request returns 401', async ({ page }) => {
    console.log('[TEST] Testing unauthenticated log request...');

    // Make request without logging in first
    await page.goto('/');

    const response = await page.evaluate(async () => {
      const res = await fetch('/api/feldspar/log', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          level: 'info',
          message: 'Unauthenticated test message',
        }),
      });
      return {
        status: res.status,
        body: await res.json(),
      };
    });

    console.log(`[TEST] Unauthenticated response: ${response.status}`);
    expect(response.status).toBe(401);
    expect(response.body.error).toBe('Not authenticated');
  });

  test('invalid log level returns 400', async ({ page }) => {
    console.log('[TEST] Starting invalid level test');

    // Login first
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    const participantPanel = '#account_signin-tab_panel_participant';
    await page.locator(`${participantPanel} [data-testid='signin-email-input']`).fill(PARTICIPANT_EMAIL);
    await page.locator(`${participantPanel} [data-testid='signin-password-input']`).fill(PARTICIPANT_PASSWORD);
    await page.locator(`${participantPanel} [data-testid='signin-submit-button']`).click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });

    // Send invalid level
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/feldspar/log', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          level: 'invalid_level',
          message: 'Test with invalid level',
        }),
      });
      return {
        status: res.status,
        body: await res.json(),
      };
    });

    console.log(`[TEST] Invalid level response: ${response.status} - ${JSON.stringify(response.body)}`);
    expect(response.status).toBe(400);
    expect(response.body.error).toContain('Invalid level');
  });
});
