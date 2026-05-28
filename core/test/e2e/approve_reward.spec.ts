import { test, expect } from '@playwright/test';
import { missingFeaturesReason } from './lib/features';

/**
 * Approve Reward E2E Test (UC-OPP-05)
 *
 * Verifies the happy path of approving a participant reward:
 *   1. Researcher creates a questionnaire study, assigns a budget, completes
 *      payment via the local simulator (UC-OPP-01 setup).
 *   2. Participant logs in (separate browser context), opens the advert,
 *      accepts the consent, completes the questionnaire — reward flips to
 *      :pending_approval.
 *   3. Researcher opens the payout modal via the NextAction redirect URL,
 *      clicks "Pay out all", verifies the row appears in the :overview tab
 *      as :approved.
 *
 * No fixtures are used. The full flow is exercised end-to-end through the UI
 * so the test reflects real production behaviour (signals, side-effects,
 * audit trail, state-machine transitions).
 *
 * Prerequisites:
 *   - Local server (mix phx.server) on http://localhost:4000
 *   - ENABLED_APP_FEATURES contains "panl" and "e2e"
 *   - :panl_post_launch feature flag enabled (home blocks are gated on it)
 *   - PAYMENT_PROVIDER unset or "local"
 *   - Researcher account: e2e-researcher@eyra.co (seeded by /api/e2e/setup)
 */

// Skip all tests in this file when required features are not enabled.
// `missingFeaturesReason` reads from ENABLED_APP_FEATURES, which is
// populated by global-setup from the server's /api/e2e/features.
const SKIP_REASON = missingFeaturesReason('panl', 'panl_post_launch');

const RESEARCHER_EMAIL = process.env.E2E_RESEARCHER_EMAIL || 'e2e-researcher@eyra.co';
const RESEARCHER_PASSWORD = process.env.E2E_RESEARCHER_PASSWORD || 'asdf;lkjASDF0987';

// Participant is signed up fresh per run so that PaNL membership is set via the
// real signup-with-add_to_panl flow (same approach as panl_onboarding.spec.ts).
// The e2e-participant fixture from /api/e2e/setup is not in PaNL, so it cannot
// see adverts.
const PARTICIPANT_PASSWORD = process.env.E2E_PARTICIPANT_PASSWORD || 'TestPassword123!';
function generateParticipantEmail(): string {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 8);
  return `test_approve_${timestamp}_${random}@test.example.com`;
}

const SUBJECT_COUNT = '10';
const SUBJECT_REWARD = '5.00';
const AIM_OF_STUDY = 'E2E approve reward test';

const CARD_SELECTOR = "[data-testid^='card_']";
const CONNECTED_SELECTOR = '[data-phx-main].phx-connected';

test.describe('Approve Reward (UC-OPP-05)', () => {
  test.skip(SKIP_REASON !== '', SKIP_REASON);

  test('researcher approves a participant reward after questionnaire completion', async ({ browser }) => {
    test.setTimeout(180000); // 3 min — full flow with two browser contexts.

    // Two isolated browser contexts so researcher and participant don't share
    // cookies / auth state.
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

    // Login as researcher
    await researcherPage.goto('/user/signin');
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await researcherPage.locator("[data-testid='signin-tab-creator']").click();
    await researcherPage.waitForTimeout(300);
    await researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await researcherPage.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    await researcherPage.waitForTimeout(1000);

    // Open or create project
    const createProjectButton = researcherPage.locator("[data-testid='create-first-project-button']");
    if (await createProjectButton.isVisible({ timeout: 3000 })) {
      await createProjectButton.click();
      await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }
    await researcherPage.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await researcherPage.locator(CARD_SELECTOR).first().click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await researcherPage.waitForTimeout(500);

    // Create a fresh questionnaire study
    console.log('[TEST] Creating questionnaire study');
    const createFirstItemButton = researcherPage.locator("[data-testid='create-first-item-button']");
    const addItemButton = researcherPage.locator("[data-testid='add-item-button']");

    if (await createFirstItemButton.isVisible({ timeout: 3000 })) {
      await createFirstItemButton.click();
    } else if (await addItemButton.isVisible({ timeout: 2000 })) {
      await addItemButton.click();
    } else {
      throw new Error('Could not find create/add item button');
    }

    await researcherPage.waitForSelector("[data-testid='selector-item-questionnaire']", { timeout: 10000 });
    await researcherPage.locator("[data-testid='selector-item-questionnaire']").click();
    await researcherPage.waitForTimeout(300);
    await researcherPage.locator("[data-testid='create-item-button']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await researcherPage.waitForTimeout(500);

    // Open the newly created study
    await researcherPage.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    const lastCard = researcherPage.locator(CARD_SELECTOR).last();
    await lastCard.scrollIntoViewIfNeeded();
    await lastCard.click();
    await researcherPage.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    const assignmentUrl = researcherPage.url();
    assignmentId = assignmentUrl.match(/\/assignment\/(\d+)/)![1];
    console.log(`[TEST] Inside assignment ${assignmentId}: ${assignmentUrl}`);

    // Add an Instruction Manual to the workflow.
    // This is the simplest tool: participant just opens it, clicks "done" and
    // the task is complete. Avoids needing an external questionnaire URL.
    console.log('[TEST] Adding Instruction Manual to workflow');
    await researcherPage.waitForSelector("[data-testid='assignment-tab-workflow']", { timeout: 10000 });
    await researcherPage.locator("[data-testid='assignment-tab-workflow']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await researcherPage.waitForTimeout(500);
    await expect(researcherPage.locator("[data-testid='add-library-item-manual']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='add-library-item-manual']").click();
    await researcherPage.waitForTimeout(1000);

    // Navigate to participants tab
    await researcherPage.waitForSelector("[data-testid='assignment-tab-participants']", { timeout: 10000 });
    await researcherPage.locator("[data-testid='assignment-tab-participants']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await researcherPage.waitForTimeout(500);

    // Open BudgetForm modal
    const addBudgetBtn = researcherPage.locator("[data-testid='pay-add-participants-button']");
    await expect(addBudgetBtn).toBeVisible({ timeout: 5000 });
    await addBudgetBtn.click();

    // Fill BudgetForm
    const aimInput = researcherPage.locator("[data-testid='budget-form-aim-input']");
    await expect(aimInput).toBeVisible({ timeout: 5000 });
    await aimInput.fill(AIM_OF_STUDY);

    const rewardInput = researcherPage.locator("[data-testid='budget-form-reward-input']");
    await rewardInput.fill(SUBJECT_REWARD);
    await researcherPage.waitForTimeout(1500); // 1000ms debounce + server roundtrip

    const slotsInput = researcherPage.locator("[data-testid='budget-form-slots-input']");
    await slotsInput.fill(SUBJECT_COUNT);
    await researcherPage.waitForTimeout(500);

    // Confirm — redirects to local payment simulator
    const confirmBtn = researcherPage.locator("[data-testid='budget-form-confirm-button']");
    await expect(confirmBtn).toBeVisible({ timeout: 3000 });
    await confirmBtn.click();
    await researcherPage.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });

    // Complete simulated payment
    await researcherPage.locator("[data-testid='local-payment-complete-button']").click();
    await researcherPage.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Re-open participants tab and verify the transaction is :completed
    await researcherPage.locator("[data-testid='assignment-tab-participants']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await expect(researcherPage.locator("[data-testid='transaction-card-completed']")).toBeVisible({ timeout: 5000 });

    // Create the advert (same pattern as panl_study_advert.spec.ts).
    console.log('[TEST] Creating advert');
    const createAdvertButton = researcherPage.locator("[data-testid='create-advert-button']");
    const gotoAdvertButton = researcherPage.locator("[data-testid='goto-advert-button']");
    if (await createAdvertButton.isVisible({ timeout: 3000 })) {
      await createAdvertButton.scrollIntoViewIfNeeded();
      await createAdvertButton.click();
      await expect(gotoAdvertButton).toBeVisible({ timeout: 10000 });
    }

    // Publish the assignment. Wait for retract-button to appear — it replaces
    // publish-button once status flips to :online.
    console.log('[TEST] Publishing assignment');
    await expect(researcherPage.locator("[data-testid='publish-button']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='publish-button']").click();
    await expect(researcherPage.locator("[data-testid='retract-button']")).toBeVisible({ timeout: 10000 });

    // Navigate to the advert page.
    console.log('[TEST] Navigating to advert page');
    await researcherPage.locator("[data-testid='goto-advert-button']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Publish the advert
    console.log('[TEST] Publishing advert');
    await expect(researcherPage.locator("[data-testid='advert-publish-button']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='advert-publish-button']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    console.log('[TEST] Advert published — participant can now see it');

    // =========================================================================
    // PHASE 2 — Participant signs in, opens advert, completes questionnaire
    // =========================================================================

    console.log('[TEST] === Phase 2: Participant flow ===');

    // Sign up a fresh participant with PaNL membership.
    // Same pattern as panl_onboarding.spec.ts — needed because the e2e-participant
    // fixture is NOT in PaNL and would not see adverts on the homepage.
    const participantEmail = generateParticipantEmail();
    console.log(`[TEST] Signing up participant: ${participantEmail}`);

    await participantPage.goto('/user/signup/participant?post_signup_action=add_to_panl');
    await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await participantPage.locator('#signup_form input[name="user[email]"]').fill(participantEmail);
    await participantPage.locator('#signup_form input[name="user[password]"]').fill(PARTICIPANT_PASSWORD);
    await participantPage.locator("[data-selector-item='next_privacy_policy_accepted'] .selector-icon-inactive").click();
    await participantPage.locator("[data-selector-item='panl_privacy_policy_accepted'] .selector-icon-inactive").click();
    await participantPage.locator('#signup_form button[type="submit"]').click();

    // Onboarding flow
    await participantPage.waitForURL('**/user/onboarding', { timeout: 5000 });
    await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 5000 });

    await expect(participantPage.locator('[data-testid="profile-view"]')).toBeVisible({ timeout: 3000 });
    await participantPage.locator('[data-testid="onboarding-continue"]').click();

    await expect(participantPage.locator('[data-testid="features-view"]')).toBeVisible({ timeout: 3000 });
    await participantPage.locator('[data-testid="onboarding-continue"]').click();

    await expect(participantPage.locator('[data-testid="activate-account-view"]')).toBeVisible({ timeout: 3000 });
    await Promise.all([
      participantPage.waitForURL('**/', { timeout: 5000 }),
      participantPage.locator('[data-testid="onboarding-continue"]').click()
    ]);
    console.log('[TEST] Participant onboarded, on home page');

    // Fill features (gender) so the participant can match PaNL adverts.
    // Without any feature values, the homepage shows a "Kenmerken invullen"
    // banner and no advert cards. Navigate directly to /user/profile
    // (same destination as the CompleteProfile NextAction CTA).
    console.log('[TEST] Filling participant features (gender)');
    await participantPage.goto('/user/profile');
    await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    // Profile has tabs (account, features, ...) — features tab is hidden by
    // default. Activate it via the data-tab-id selector (set by the Tabbed
    // component, label-independent so safe for i18n).
    await participantPage.locator('[data-tab-id="features"]').first().click();
    await expect(participantPage.locator('[data-testid="features-view"]')).toBeVisible({ timeout: 5000 });
    await participantPage.locator("[data-testid='selector-item-man']").click();
    // Selector saves via phx-change; give the server a moment to persist.
    await participantPage.waitForTimeout(500);

    // Back to homepage — the banner should be gone and adverts should match.
    await participantPage.goto('/');
    await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Find the advert card for our study and click it. Pick the LAST card —
    // that's our freshly-published advert. Picking .first() can land on a
    // stale card from a previous test run that no longer accepts new
    // participants.
    console.log('[TEST] Participant opens advert');
    await participantPage.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await participantPage.locator(CARD_SELECTOR).last().click();

    // Wait for navigation to a /promotion/{id} URL — push_navigate fires
    // server-side, Playwright's waitForSelector(CONNECTED) alone would race.
    await participantPage.waitForURL(/\/promotion\/\d+/, { timeout: 5000 });
    await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Apply for the study via the hero CTA on the promotion page.
    console.log('[TEST] Participant applies to study');
    await expect(participantPage.locator("[data-testid='promotion-apply-button-hero']")).toBeVisible({ timeout: 5000 });
    await participantPage.locator("[data-testid='promotion-apply-button-hero']").click();
    await participantPage.waitForURL(/\/assignment\/\d+(\/.*)?$/, { timeout: 10000 });
    await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Step 2: Onboarding intro — there may be multiple intro pages.
    // Click continue until the button is no longer visible (cap at 10 clicks).
    for (let i = 0; i < 10; i++) {
      const onboardingContinue = participantPage.locator("[data-testid='assignment-onboarding-continue-button']");
      if (!(await onboardingContinue.isVisible({ timeout: 2000 }))) {
        if (i === 0) console.log('[TEST] No onboarding intro — skipping');
        else console.log(`[TEST] Onboarding intro done after ${i} click(s)`);
        break;
      }
      console.log(`[TEST] Onboarding intro click ${i + 1}`);
      await onboardingContinue.click();
      await participantPage.waitForTimeout(500);
    }

    // Step 3: Accept consent
    const consentAcceptButton = participantPage.locator("[data-testid='consent-accept-button']");
    if (await consentAcceptButton.isVisible({ timeout: 5000 })) {
      console.log('[TEST] Participant accepts consent');
      await consentAcceptButton.click();
      // consent → publish_event(:accept) → parent recomputes view model
      // → CrewPage re-renders. Give it a moment.
      await participantPage.waitForTimeout(2000);
      await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    } else {
      console.log('[TEST] No consent step — skipping');
    }

    // Step 4: Activate account via the email confirmation link.
    // Phoenix-style mail confirmation assumes the user opens the link in a
    // separate browser/tab where they are NOT logged in. Visiting the confirm
    // URL in the participant's logged-in session causes a server-side redirect
    // (no confirm-button page shown). So we open the link in a CLEAN context
    // (no cookies → unauthenticated), click the confirm button there, then
    // close it and reload the participant's assignment view.
    if (await participantPage.locator("[data-testid='activate-account-check-button']").isVisible({ timeout: 3000 })) {
      console.log('[TEST] Participant needs to activate account — fetching link from /sent_emails');
      await participantPage.goto('/sent_emails');
      await participantPage.waitForLoadState('domcontentloaded');

      const html = await participantPage.content();
      const confirmLinkMatch = html.match(/\/user\/onboarding\/confirm\/[A-Za-z0-9_\-]+/);
      if (!confirmLinkMatch) {
        throw new Error('Activation link not found in /sent_emails');
      }
      const confirmPath = confirmLinkMatch[0];
      console.log(`[TEST] Activation URL: ${confirmPath}`);

      // Open the confirm URL in a clean (unauthenticated) browser context.
      const confirmContext = await browser.newContext();
      const confirmPage = await confirmContext.newPage();
      await confirmPage.goto(`http://localhost:4000${confirmPath}`);
      await confirmPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
      await expect(confirmPage.locator("[data-testid='account-confirm-button']")).toBeVisible({ timeout: 5000 });
      console.log('[TEST] Clicking account-confirm-button in clean context');
      await confirmPage.locator("[data-testid='account-confirm-button']").click();
      await confirmPage.waitForURL(/\/user\/signin/, { timeout: 10000 });
      console.log('[TEST] Account activated — redirected to signin');
      await confirmContext.close();

      // Back to the participant's assignment so the view-router recomputes.
      await participantPage.goto(`/assignment/${assignmentId}`);
      await participantPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }

    // Step 5: Complete the Instruction Manual task.
    // Manual presents a chapter-list first. Open the first chapter, then
    // click "next" through pages until "done" on the last page →
    // publish_event(:done) → task complete → reward → :pending_approval.
    console.log('[TEST] Participant opens first chapter');
    await expect(participantPage.locator("[data-testid^='chapter-list-item-']").first()).toBeVisible({ timeout: 5000 });
    await participantPage.locator("[data-testid^='chapter-list-item-']").first().click();
    await participantPage.waitForTimeout(500);

    console.log('[TEST] Participant works through chapter pages');
    for (let i = 0; i < 20; i++) {
      const next = participantPage.locator("[data-testid='manual-chapter-next-button']");
      if (await next.isVisible({ timeout: 1000 })) {
        await next.click();
        await participantPage.waitForTimeout(300);
        continue;
      }
      const done = participantPage.locator("[data-testid='manual-chapter-done-button']");
      if (await done.isVisible({ timeout: 1000 })) {
        console.log(`[TEST] Clicking manual-done after ${i} next click(s)`);
        await done.click();
        break;
      }
      console.log(`[TEST] No next/done button on iteration ${i}, stopping`);
      break;
    }

    // Wait for the "finished" view as confirmation the task is done
    await expect(participantPage.locator("[data-testid='finished-view']")).toBeVisible({ timeout: 15000 });
    console.log('[TEST] Participant task completed (reward now :pending_approval)');

    // =========================================================================
    // PHASE 3 — Researcher approves the reward via PayoutModal
    // =========================================================================

    console.log('[TEST] === Phase 3: Researcher approves reward ===');

    // Navigate to the participants tab, click the Pending Approvals CTA to
    // open the PayoutModal.
    await researcherPage.goto(`/assignment/${assignmentId}/content?tab=participants`);
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await expect(researcherPage.locator("[data-testid='pending-approvals-cta']")).toBeVisible({ timeout: 5000 });
    await researcherPage.locator("[data-testid='pending-approvals-cta']").click();

    // PayoutModal opens on the :waiting tab by default
    await expect(researcherPage.locator("[data-testid='payout-modal']")).toBeVisible({ timeout: 5000 });
    await expect(researcherPage.locator("[data-testid='payout-tab-waiting']")).toBeVisible();

    // There should be at least one pending row
    const waitingCount = researcherPage.locator("[data-testid='payout-waiting-count']");
    await expect(waitingCount).toBeVisible();
    await expect(waitingCount).not.toHaveText('0');

    // Click "Pay out all"
    console.log('[TEST] Approving all pending payouts');
    await researcherPage.locator("[data-testid='pay-out-all-button']").click();
    await researcherPage.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Waiting tab should now be empty — the reward has left :pending_approval
    // and moved to :approved (server-side). This is the strongest UI proof we
    // have of MS.5 (Fund.pending → Fund.available wallet) in this milestone.
    //
    // NOTE: the :overview tab in PayoutModal is a placeholder ("coming soon")
    // in this milestone — see Systems.Assignment.PayoutModal.overview_tab/1.
    // It does not render approved/rejected rows yet, so we intentionally do
    // NOT assert on its contents here. Once that tab is implemented, replace
    // this comment with a check on a specific approved row.
    await expect(researcherPage.locator("[data-testid='payout-empty']")).toBeVisible({ timeout: 5000 });

    console.log('[TEST] Approve Reward (UC-OPP-05) test completed successfully');

    await researcherContext.close();
    await participantContext.close();
  });
});
