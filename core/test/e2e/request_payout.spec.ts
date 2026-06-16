import { test, expect } from '@playwright/test';
import { missingFeaturesReason } from './lib/features';
import { activateLocalPayment, snapshotCardTestids, pickNewCardTestid } from './lib';

const ADD_ITEM_SELECTOR = "[data-testid='create-first-item-button'],[data-testid='add-item-button'],[phx-click='create_item']";

async function clickAddItemButton(page: any) {
  await page.waitForSelector(ADD_ITEM_SELECTOR, { timeout: 10000 });
  const createFirst = page.locator("[data-testid='create-first-item-button']");
  const addItem = page.locator("[data-testid='add-item-button']");
  const byEvent = page.locator("[phx-click='create_item']");
  if (await createFirst.isVisible()) {
    await createFirst.click();
  } else if (await addItem.isVisible()) {
    await addItem.click();
  } else {
    await byEvent.click();
  }
}

/**
 * Request Payout E2E Test (UC-OPP-06)
 *
 * Verifies the happy path of a participant requesting a payout after
 * receiving an approved reward:
 *   1. Researcher creates a questionnaire study, assigns a budget (≥ €5),
 *      completes payment via the local simulator (UC-OPP-01 setup).
 *   2. Participant logs in (separate browser context), completes the task —
 *      reward flips to :pending_approval.
 *   3. Researcher approves the reward via the PayoutModal (UC-OPP-05 step).
 *   4. Participant navigates to the home page, sees the approved balance in
 *      the rewards-summary widget, clicks "Uitbetalen" (payout-button).
 *   5. Because the fresh participant is not yet known at the Payment Provider,
 *      Next returns {:error, {:kyc_required, url}} — the KYC handoff modal
 *      (UC-OPP-06.A1) appears with a confirm button that would redirect to OPP.
 *      The test verifies the modal is visible; it does not follow the external
 *      OPP link (that requires a pre-verified sandbox account and is covered by
 *      manual testing).
 *
 * No fixtures are used. The full flow is exercised end-to-end through the UI.
 *
 * Wait pattern: per `core/test/e2e/CLAUDE.md`, we wait on a target-page
 * `data-testid` (or specific class transition) via `expect(...).toBeVisible()`
 * / `expect(...).not.toHaveClass(...)` (auto-polling) after each action,
 * rather than on `.phx-connected` of the source page. No `waitForTimeout`
 * calls — debounced form state, async server recomputes, and selector save
 * acks all surface as observable destination signals we can poll on.
 *
 * Prerequisites:
 *   - Local server (mix phx.server) on http://localhost:4000
 *   - ENABLED_APP_FEATURES contains "panl", "e2e", and "panl_post_launch"
 *   - PAYMENT_PROVIDER unset or "local"
 *   - Researcher account: e2e-researcher@eyra.co (seeded by /api/e2e/setup)
 */

const SKIP_REASON = missingFeaturesReason('panl', 'panl_post_launch');

const RESEARCHER_EMAIL = process.env.E2E_RESEARCHER_EMAIL || 'e2e-researcher@eyra.co';
const RESEARCHER_PASSWORD = process.env.E2E_RESEARCHER_PASSWORD || 'asdf;lkjASDF0987';

const PARTICIPANT_PASSWORD = process.env.E2E_PARTICIPANT_PASSWORD || 'TestPassword123!';
function generateParticipantEmail(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `test_payout_${timestamp}_${random}@test.example.com`;
}

// Must be ≥ €5 (500 cents) to pass the payout threshold check (SF-OPP-06).
const SUBJECT_COUNT = '10';
const SUBJECT_REWARD = '5.00';
const AIM_OF_STUDY = 'E2E request payout test';

test.describe('Request Payout (UC-OPP-06)', () => {
  test.skip(SKIP_REASON !== '', SKIP_REASON);

  test('participant sees payout handoff modal after researcher approves reward', async ({ browser }) => {
    test.setTimeout(240000); // 4 min — full flow with two browser contexts.

    const researcherContext = await browser.newContext();
    const participantContext = await browser.newContext();
    const researcherPage = await researcherContext.newPage();
    const participantPage = await participantContext.newPage();

    researcherPage.on('console', msg => {
      if (msg.type() === 'error') console.log(`[RESEARCHER BROWSER ERROR] ${msg.text()}`);
    });
    participantPage.on('console', msg => {
      if (msg.type() === 'error') console.log(`[PARTICIPANT BROWSER ERROR] ${msg.text()}`);
    });

    let assignmentId: string;

    // =========================================================================
    // PHASE 1 — Researcher creates study, assigns budget, completes payment
    // =========================================================================

    console.log('[TEST] === Phase 1: Researcher setup ===');

    await researcherPage.goto('/user/signin');
    await researcherPage.locator("[data-testid='signin-tab-creator']").click();
    await expect(researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await activateLocalPayment(researcherPage);

    const projectTestidsBefore = await snapshotCardTestids(researcherPage);

    const createFirstProject = researcherPage.locator("[data-testid='create-first-project-button']");
    const createNewProject = researcherPage.locator("[data-testid='create-project-button']");
    if (await createFirstProject.isVisible({ timeout: 3000 })) {
      await createFirstProject.click();
    } else {
      await createNewProject.click();
    }

    const newProjectTestid = await pickNewCardTestid(researcherPage, projectTestidsBefore);
    console.log(`[TEST] Created project: ${newProjectTestid}`);
    await researcherPage.locator(`[data-testid='${newProjectTestid}']`).click();

    const itemTestidsBefore = await snapshotCardTestids(researcherPage);

    console.log('[TEST] Creating questionnaire study');
    await clickAddItemButton(researcherPage);

    await expect(researcherPage.locator("[data-testid='selector-item-questionnaire']")).toBeVisible({ timeout: 10000 });
    await researcherPage.locator("[data-testid='selector-item-questionnaire']").click();
    await researcherPage.locator("[data-testid='create-item-button']").click();

    const newItemTestid = await pickNewCardTestid(researcherPage, itemTestidsBefore);
    console.log(`[TEST] Created item: ${newItemTestid}`);
    const newCard = researcherPage.locator(`[data-testid='${newItemTestid}']`);
    await newCard.scrollIntoViewIfNeeded();
    await newCard.click();
    await researcherPage.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    const assignmentUrl = researcherPage.url();
    assignmentId = assignmentUrl.match(/\/assignment\/(\d+)/)![1];
    console.log(`[TEST] Inside assignment ${assignmentId}`);

    console.log('[TEST] Adding Instruction Manual to workflow');
    await expect(researcherPage.locator("[data-testid='assignment-tab-workflow']")).toBeVisible({ timeout: 10000 });
    await researcherPage.locator("[data-testid='assignment-tab-workflow']").click();
    await expect(researcherPage.locator("[data-testid='add-library-item-manual']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='add-library-item-manual']").click();

    await expect(researcherPage.locator("[data-testid='assignment-tab-participants']")).toBeVisible({ timeout: 10000 });
    await researcherPage.locator("[data-testid='assignment-tab-participants']").click();

    const addBudgetBtn = researcherPage.locator("[data-testid='pay-add-participants-button']");
    await expect(addBudgetBtn).toBeVisible({ timeout: 5000 });
    await addBudgetBtn.click();

    const aimInput = researcherPage.locator("[data-testid='budget-form-aim-input']");
    await expect(aimInput).toBeVisible({ timeout: 5000 });
    await aimInput.fill(AIM_OF_STUDY);

    const rewardInput = researcherPage.locator("[data-testid='budget-form-reward-input']");
    await rewardInput.fill(SUBJECT_REWARD);

    const slotsInput = researcherPage.locator("[data-testid='budget-form-slots-input']");
    await slotsInput.fill(SUBJECT_COUNT);

    // Confirm button is disabled (cursor-not-allowed) until BudgetForm's
    // phx-change debounces fire and the server enables it. Polling on the
    // class transition is the replacement for hardcoded debounce sleeps.
    const confirmBtn = researcherPage.locator("[data-testid='budget-form-confirm-button']");
    await expect(confirmBtn).not.toHaveClass(/cursor-not-allowed/, { timeout: 5000 });
    await confirmBtn.click();
    await researcherPage.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });

    await researcherPage.locator("[data-testid='local-payment-complete-button']").click();
    await researcherPage.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });

    await researcherPage.locator("[data-testid='assignment-tab-participants']").click();
    await expect(researcherPage.locator("[data-testid='transaction-card-completed']")).toBeVisible({ timeout: 5000 });

    console.log('[TEST] Creating and publishing advert');
    const createAdvertButton = researcherPage.locator("[data-testid='create-advert-button']");
    const gotoAdvertButton = researcherPage.locator("[data-testid='goto-advert-button']");
    if (await createAdvertButton.isVisible({ timeout: 3000 })) {
      await createAdvertButton.scrollIntoViewIfNeeded();
      await createAdvertButton.click();
      await expect(gotoAdvertButton).toBeVisible({ timeout: 10000 });
    }

    await expect(researcherPage.locator("[data-testid='publish-button']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='publish-button']").click();
    await expect(researcherPage.locator("[data-testid='retract-button']")).toBeVisible({ timeout: 10000 });

    await researcherPage.locator("[data-testid='goto-advert-button']").click();

    await expect(researcherPage.locator("[data-testid='advert-publish-button']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='advert-publish-button']").click();

    const inviteLinkText = await researcherPage.locator(
      "text=/https?:\\/\\/[^/]+\\/promotion\\/\\d+/"
    ).first().textContent({ timeout: 5000 });
    const promotionPath = inviteLinkText && inviteLinkText.match(/\/promotion\/\d+/)?.[0];
    if (!promotionPath) throw new Error(`Could not extract promotion path from invite link text: ${inviteLinkText}`);
    console.log(`[TEST] Promotion path: ${promotionPath}`);

    // =========================================================================
    // PHASE 2 — Participant signs up, completes task → reward :pending_approval
    // =========================================================================

    console.log('[TEST] === Phase 2: Participant flow ===');

    const participantEmail = generateParticipantEmail();
    console.log(`[TEST] Signing up participant: ${participantEmail}`);

    await participantPage.goto('/user/signup/participant?post_signup_action=add_to_panl');

    await participantPage.locator('#signup_form input[name="user[email]"]').fill(participantEmail);
    await participantPage.locator('#signup_form input[name="user[password]"]').fill(PARTICIPANT_PASSWORD);
    await participantPage.locator("[data-selector-item='next_privacy_policy_accepted'] .selector-icon-inactive").click();
    await participantPage.locator("[data-selector-item='panl_privacy_policy_accepted'] .selector-icon-inactive").click();
    await participantPage.locator('#signup_form button[type="submit"]').click();

    await participantPage.waitForURL('**/user/onboarding', { timeout: 5000 });

    await expect(participantPage.locator('[data-testid="profile-view"]')).toBeVisible({ timeout: 3000 });
    await participantPage.locator('[data-testid="onboarding-continue"]').click();

    await expect(participantPage.locator('[data-testid="features-view"]')).toBeVisible({ timeout: 3000 });
    await participantPage.locator('[data-testid="onboarding-continue"]').click();

    await expect(participantPage.locator('[data-testid="activate-account-view"]')).toBeVisible({ timeout: 3000 });
    await Promise.all([
      participantPage.waitForURL('**/', { timeout: 5000 }),
      participantPage.locator('[data-testid="onboarding-continue"]').click()
    ]);

    console.log('[TEST] Filling participant features (gender)');
    await participantPage.goto('/user/profile');
    await participantPage.locator('[data-tab-id="features"]').first().click();
    await expect(participantPage.locator('[data-testid="features-view"]')).toBeVisible({ timeout: 5000 });
    await participantPage.locator("[data-testid='selector-item-man']").click();

    await participantPage.goto(promotionPath);

    await expect(participantPage.locator("[data-testid='promotion-apply-button-hero']")).toBeVisible({ timeout: 5000 });
    await participantPage.locator("[data-testid='promotion-apply-button-hero']").click();
    await participantPage.waitForURL(/\/assignment\/\d+(\/.*)?$/, { timeout: 10000 });

    for (let i = 0; i < 10; i++) {
      const onboardingContinue = participantPage.locator("[data-testid='assignment-onboarding-continue-button']");
      if (!(await onboardingContinue.isVisible({ timeout: 2000 }))) break;
      await onboardingContinue.click();
    }

    const consentAcceptButton = participantPage.locator("[data-testid='consent-accept-button']");
    if (await consentAcceptButton.isVisible({ timeout: 5000 })) {
      await consentAcceptButton.click();
      // The next isVisible() poll on activate-account-check-button below catches
      // the CrewPage re-render after the consent event propagates.
    }

    if (await participantPage.locator("[data-testid='activate-account-check-button']").isVisible({ timeout: 3000 })) {
      console.log(`[TEST] Activating account via E2E API for ${participantEmail}`);
      const activateResponse = await fetch(`${process.env.E2E_BASE_URL || 'http://localhost:4000'}/api/e2e/activate_user`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: participantEmail })
      });
      if (!activateResponse.ok) {
        throw new Error(`Failed to activate user: ${activateResponse.status} - ${await activateResponse.text()}`);
      }
      await participantPage.goto(`/assignment/${assignmentId}`);
    }

    console.log('[TEST] Participant completes Instruction Manual');
    await expect(participantPage.locator("[data-testid^='chapter-list-item-']").first()).toBeVisible({ timeout: 5000 });
    await participantPage.locator("[data-testid^='chapter-list-item-']").first().click();

    for (let i = 0; i < 20; i++) {
      const next = participantPage.locator("[data-testid='manual-chapter-next-button']");
      if (await next.isVisible({ timeout: 1000 })) {
        await next.click();
        continue;
      }
      const done = participantPage.locator("[data-testid='manual-chapter-done-button']");
      if (await done.isVisible({ timeout: 1000 })) {
        await done.click();
        break;
      }
      break;
    }

    await expect(participantPage.locator("[data-testid='finished-view']")).toBeVisible({ timeout: 15000 });
    console.log('[TEST] Participant task completed (reward now :pending_approval)');

    // =========================================================================
    // PHASE 3 — Researcher approves the reward
    // =========================================================================

    console.log('[TEST] === Phase 3: Researcher approves reward ===');

    await researcherPage.goto(`/assignment/${assignmentId}/content?tab=participants`);
    await expect(researcherPage.locator("[data-testid='pending-approvals-cta']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='pending-approvals-cta']").click();

    await expect(researcherPage.locator("[data-testid='payout-modal']")).toBeVisible({ timeout: 5000 });
    const waitingCount = researcherPage.locator("[data-testid='payout-waiting-count']");
    await expect(waitingCount).not.toHaveText('0');

    await researcherPage.locator("[data-testid='pay-out-all-button']").click();
    await expect(researcherPage.locator("[data-testid='payout-empty']")).toBeVisible({ timeout: 5000 });
    console.log('[TEST] Reward approved — participant wallet now has approved balance');

    // =========================================================================
    // PHASE 4 — Participant requests payout → KYC handoff modal (UC-OPP-06.A1)
    // =========================================================================

    console.log('[TEST] === Phase 4: Participant requests payout ===');

    // Navigate to home page where the rewards-summary widget is shown.
    await participantPage.goto('/');

    // Rewards summary must be visible with a non-zero approved balance.
    await expect(participantPage.locator("[data-testid='rewards-summary']")).toBeVisible({ timeout: 5000 });
    await expect(participantPage.locator("[data-testid='approved-column']")).toBeVisible({ timeout: 3000 });

    // Payout button appears only when approved_cents > 0.
    const payoutButton = participantPage.locator("[data-testid='payout-button']");
    await expect(payoutButton).toBeVisible({ timeout: 5000 });
    console.log('[TEST] Payout button visible — clicking');
    await payoutButton.click();

    // Fresh participant is not known at the Payment Provider →
    // prepare_payout/1 returns {:error, {:kyc_required, url}} →
    // KYC handoff modal (UC-OPP-06.A1) is shown.
    // The confirm button would redirect to OPP KYC onboarding.
    await expect(participantPage.locator("[data-testid='confirmation-modal-confirm-button']")).toBeVisible({ timeout: 5000 });
    await expect(participantPage.locator("[data-testid='confirmation-modal-cancel-button']")).toBeVisible({ timeout: 3000 });
    console.log('[TEST] KYC handoff modal visible — UC-OPP-06.A1 confirmed');

    // Dismiss the modal so we leave the page in a clean state.
    await participantPage.locator("[data-testid='confirmation-modal-cancel-button']").click();
    await expect(participantPage.locator("[data-testid='confirmation-modal-confirm-button']")).not.toBeVisible({ timeout: 3000 });

    console.log('[TEST] Request Payout (UC-OPP-06) test completed successfully');

    await researcherContext.close();
    await participantContext.close();
  });
});
