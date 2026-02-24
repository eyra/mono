import { test, expect } from '@playwright/test';

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

// Generate unique email for each test run
function generateTestEmail(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `test_panl_${timestamp}_${random}@test.example.com`;
}

const TEST_PASSWORD = 'TestPassword123!';

test.describe('PaNL Onboarding Flow', () => {
  test('new participant can sign up, complete onboarding, and see PaNL advert', async ({ page }) => {
    const testEmail = generateTestEmail();

    console.log(`[TEST] Starting PaNL onboarding test with email: ${testEmail}`);

    // Listen for console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        console.log(`[BROWSER ERROR] ${msg.text()}`);
      }
    });

    // Step 1: Navigate to signup page (participant user type with add_to_panl post action)
    console.log('[TEST] Navigating to signup page...');
    await page.goto('/user/signup/participant?post_signup_action=add_to_panl');

    // Wait for page to be ready
    await page.waitForSelector('[data-phx-main].phx-connected', { timeout: 10000 });

    // Step 2: Fill in signup form (using Phoenix form naming: user[email], user[password])
    console.log('[TEST] Filling signup form...');
    await page.locator('#signup_form input[name="user[email]"]').fill(testEmail);
    await page.locator('#signup_form input[name="user[password]"]').fill(TEST_PASSWORD);

    // Step 3: Accept privacy policies (click on checkbox icons to avoid hitting links in text)
    console.log('[TEST] Accepting privacy policies...');

    // Click the Next privacy policy checkbox icon
    const nextCheckbox = page.locator("[data-selector-item='next_privacy_policy_accepted'] .selector-icon-inactive");
    console.log(`[TEST] Next checkbox visible: ${await nextCheckbox.isVisible()}`);
    await nextCheckbox.click();
    await page.waitForTimeout(500);

    // Click the PaNL privacy policy checkbox icon
    const panlCheckbox = page.locator("[data-selector-item='panl_privacy_policy_accepted'] .selector-icon-inactive");
    console.log(`[TEST] PaNL checkbox visible: ${await panlCheckbox.isVisible()}`);
    await panlCheckbox.click();
    await page.waitForTimeout(500);

    // Step 4: Submit signup
    console.log('[TEST] Submitting signup...');
    await page.locator('#signup_form button[type="submit"]').click();

    // Wait for form submission and check result
    await page.waitForTimeout(3000);
    console.log(`[TEST] Current URL after submit: ${page.url()}`);

    // Check for validation errors
    const pageText = await page.textContent('body');
    if (pageText) {
      if (pageText.includes('must accept') || pageText.includes('You must')) {
        console.log('[TEST] ERROR: Privacy policy not accepted properly');
        console.log('[TEST] Page text snippet:', pageText.substring(0, 500));
      }
      if (pageText.includes('rate') || pageText.includes('Rate')) {
        console.log('[TEST] ERROR: Rate limited');
      }
    }

    // Check for any error messages
    const errorText = await page.locator('.text-warning').first().textContent().catch(() => null);
    if (errorText) {
      console.log(`[TEST] Error message found: ${errorText}`);
    }

    // Step 5: Wait for redirect to onboarding page (via /user/onboarding/start)
    console.log('[TEST] Waiting for onboarding page...');
    await page.waitForURL('**/user/onboarding', { timeout: 30000 });
    await page.waitForTimeout(2000);

    // Step 6: Verify profile view is shown (first onboarding step)
    console.log('[TEST] Checking for profile view...');
    await expect(page.locator('[data-testid="profile-view"]')).toBeVisible({ timeout: 10000 });

    // Step 7: Click continue to go to features step
    console.log('[TEST] Clicking continue to features step...');
    await page.locator('[phx-click="continue"]').first().click();
    await page.waitForTimeout(500);

    // Step 8: Verify features view is shown (PaNL participant should see this)
    console.log('[TEST] Checking for features view...');
    await expect(page.locator('[data-testid="features-view"]')).toBeVisible({ timeout: 10000 });

    // Step 9: Click continue to go to activate account step
    console.log('[TEST] Clicking continue to activate account step...');
    await page.locator('[phx-click="continue"]').first().click();
    await page.waitForTimeout(500);

    // Step 10: Click continue to finish onboarding (Start browsing)
    console.log('[TEST] Clicking continue to finish onboarding...');
    await page.locator('[phx-click="continue"]').first().click();

    // Step 12: Wait for redirect to home page
    console.log('[TEST] Waiting for home page...');
    await page.waitForURL('**/', { timeout: 15000 });
    await page.waitForSelector('[data-phx-main].phx-connected', { timeout: 10000 });

    // Step 13: Verify PaNL advert card is visible
    console.log('[TEST] Checking for PaNL advert card...');
    const advertCard = page.locator('[data-testid^="card_"]');
    await expect(advertCard.first()).toBeVisible({ timeout: 10000 });

    console.log('[TEST] PaNL onboarding test completed successfully!');
  });

  test('signup page shows participant tab by default with add_to_panl', async ({ page }) => {
    console.log('[TEST] Checking signup page with add_to_panl param...');

    await page.goto('/user/signup/participant?post_signup_action=add_to_panl');
    await page.waitForSelector('[data-phx-main].phx-connected', { timeout: 10000 });

    // The signup form should be visible
    await expect(page.locator('#signup_form')).toBeVisible();
    // Privacy policy checkboxes should be visible
    await expect(page.locator("[data-selector-item='next_privacy_policy_accepted']")).toBeVisible();
    await expect(page.locator("[data-selector-item='panl_privacy_policy_accepted']")).toBeVisible();

    console.log('[TEST] Signup page check completed!');
  });
});
