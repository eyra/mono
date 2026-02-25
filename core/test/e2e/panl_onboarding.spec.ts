import { test, expect } from '@playwright/test';
import { waitForLiveView, waitForNavigation, debugLiveViewState } from './lib/liveview';

/**
 * PaNL Onboarding E2E Test
 *
 * Tests the complete PaNL participant onboarding flow:
 * 1. Sign up as a new participant with add_to_panl post action
 * 2. Complete onboarding (profile -> features steps)
 * 3. Verify PaNL advert is visible on home page
 *
 * Prerequisites:
 * - PaNL feature flag must be enabled on the environment
 * - At least one published PaNL study with advert must exist
 */

function generateTestEmail(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `test_panl_${timestamp}_${random}@test.example.com`;
}

const TEST_PASSWORD = 'TestPassword123!';

test.describe('PaNL Onboarding Flow', () => {
  test('new participant can sign up, complete onboarding, and see PaNL advert', async ({ page }) => {
    const testEmail = generateTestEmail();
    console.log(`[TEST] Starting with email: ${testEmail}`);

    // Enable console logging for debugging
    page.on('console', msg => {
      if (msg.type() === 'error' || msg.type() === 'warning') {
        console.log(`[BROWSER ${msg.type().toUpperCase()}] ${msg.text()}`);
      }
    });

    // Step 1: Navigate to signup page
    console.log('[TEST] Step 1: Navigating to signup page...');
    await page.goto('/user/signup/participant?post_signup_action=add_to_panl');

    const signupState = await waitForLiveView(page, { timeout: 5000, requireConnection: true });
    console.log(`[TEST] Signup page ready, connected: ${signupState.connected}`);

    // Step 2: Fill signup form
    console.log('[TEST] Step 2: Filling signup form...');
    await page.locator('#signup_form input[name="user[email]"]').fill(testEmail);
    await page.locator('#signup_form input[name="user[password]"]').fill(TEST_PASSWORD);

    // Step 3: Accept privacy policies
    console.log('[TEST] Step 3: Accepting privacy policies...');
    await page.locator("[data-selector-item='next_privacy_policy_accepted'] .selector-icon-inactive").click();
    await page.locator("[data-selector-item='panl_privacy_policy_accepted'] .selector-icon-inactive").click();

    // Step 4: Submit and wait for redirect to onboarding
    console.log('[TEST] Step 4: Submitting signup...');
    await page.locator('#signup_form button[type="submit"]').click();

    // Wait for navigation to onboarding page
    console.log('[TEST] Step 5: Waiting for onboarding page...');
    const navResult = await waitForNavigation(page, '**/user/onboarding', {
      timeout: 5000,
      requireConnection: true
    });
    console.log(`[TEST] On onboarding page: ${navResult.url}, connected: ${navResult.connected}`);

    // If not connected, debug and fail with useful info
    if (!navResult.connected) {
      await debugLiveViewState(page);
      throw new Error('LiveView did not connect on onboarding page');
    }

    // Step 6: Verify profile view is shown
    console.log('[TEST] Step 6: Checking for profile view...');
    await expect(page.locator('[data-testid="profile-view"]')).toBeVisible({ timeout: 3000 });

    // Step 7: Click continue to features step
    console.log('[TEST] Step 7: Continue to features...');
    await page.locator('[data-testid="onboarding-continue"]').click();

    // Step 8: Verify features view
    console.log('[TEST] Step 8: Checking for features view...');
    await expect(page.locator('[data-testid="features-view"]')).toBeVisible({ timeout: 3000 });

    // Step 9: Continue to activate account step
    console.log('[TEST] Step 9: Continue to activate account...');
    await page.locator('[data-testid="onboarding-continue"]').click();

    // Step 10: Finish onboarding
    console.log('[TEST] Step 10: Finish onboarding...');
    await page.locator('[data-testid="onboarding-continue"]').click();

    // Step 11: Wait for home page
    console.log('[TEST] Step 11: Waiting for home page...');
    await page.waitForURL('**/', { timeout: 3000 });
    console.log(`[TEST] On home page: ${page.url()}`);

    // Step 12: Verify PaNL advert card
    console.log('[TEST] Step 12: Checking for PaNL advert...');
    await expect(page.locator('[data-testid^="card_"]').first()).toBeVisible({ timeout: 3000 });

    console.log('[TEST] Success!');
  });

  test('signup page shows participant tab by default with add_to_panl', async ({ page }) => {
    console.log('[TEST] Checking signup page...');

    await page.goto('/user/signup/participant?post_signup_action=add_to_panl');
    await waitForLiveView(page, { timeout: 3000, requireConnection: true });

    await expect(page.locator('#signup_form')).toBeVisible();
    await expect(page.locator("[data-selector-item='next_privacy_policy_accepted']")).toBeVisible();
    await expect(page.locator("[data-selector-item='panl_privacy_policy_accepted']")).toBeVisible();

    console.log('[TEST] Signup page check completed!');
  });
});
