import { test, expect } from '@playwright/test';

/**
 * Fund Assignment E2E Test (PR #1468)
 *
 * Verifies the happy path of assigning a budget to a PaNL questionnaire
 * assignment. The flow:
 *   1. Login as researcher
 *   2. Open (or create) a project + questionnaire study
 *   3. Open the participants tab (PanlParticipantsView)
 *   4. Open the BudgetForm modal via "Add budget"
 *   5. Fill aim_of_study, subject_reward and subject_count
 *   6. Confirm — redirects to the local payment simulator
 *   7. Click "Complete Payment" on the simulator
 *   8. Verify the transaction shows up as :completed on the participants tab
 *
 * Prerequisites:
 *   - Local server (mix phx.server) on http://localhost:4000
 *   - ENABLED_APP_FEATURES contains "panl"
 *   - PAYMENT_PROVIDER unset or "local" (default via Core.Config)
 *   - A creator account (defaults match seeds.exs)
 */

const ENABLED_FEATURES = (process.env.ENABLED_APP_FEATURES || '').split(',').map(f => f.trim());
const PANL_ENABLED = ENABLED_FEATURES.includes('panl');

const RESEARCHER_EMAIL = process.env.E2E_RESEARCHER_EMAIL || 'researcher@eyra.co';
const RESEARCHER_PASSWORD = process.env.E2E_RESEARCHER_PASSWORD || 'asdf;lkjASDF0987';

const SUBJECT_COUNT = '10';
const SUBJECT_REWARD = '5.00';
const AIM_OF_STUDY = 'E2E fund assignment test';

const CARD_SELECTOR = "[data-testid^='card_']";
const CONNECTED_SELECTOR = '[data-phx-main].phx-connected';

test.describe('Fund Assignment via BudgetForm', () => {
  test.skip(!PANL_ENABLED, 'PaNL feature not enabled (set ENABLED_APP_FEATURES=...,panl)');

  test('researcher can assign budget to a questionnaire and complete local payment', async ({ page }) => {
    page.on('console', msg => {
      if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
    });

    // Step 1: Login as researcher (creator tab)
    console.log('[TEST] Step 1: Logging in as researcher');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.locator("[data-testid='signin-tab-creator']").click();
    await page.waitForTimeout(300);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    await page.waitForTimeout(1000);

    // Step 2: Open existing project, or create one
    console.log('[TEST] Step 2: Opening / creating project');
    const createProjectButton = page.locator("[data-testid='create-first-project-button']");
    if (await createProjectButton.isVisible({ timeout: 3000 })) {
      await createProjectButton.click();
      await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).first().click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Step 3: Create a fresh questionnaire study so the test is self-contained
    console.log('[TEST] Step 3: Creating questionnaire study');
    const createFirstItemButton = page.locator("[data-testid='create-first-item-button']");
    const addItemButton = page.locator("[data-testid='add-item-button']");
    const addItemByEvent = page.locator("[phx-click='create_item']");

    if (await createFirstItemButton.isVisible({ timeout: 3000 })) {
      await createFirstItemButton.click();
    } else if (await addItemButton.isVisible({ timeout: 2000 })) {
      await addItemButton.click();
    } else if (await addItemByEvent.isVisible({ timeout: 2000 })) {
      await addItemByEvent.click();
    } else {
      throw new Error('Could not find create/add item button');
    }

    await page.waitForSelector("[data-testid='selector-item-questionnaire']", { timeout: 10000 });
    await page.locator("[data-testid='selector-item-questionnaire']").click();
    await page.waitForTimeout(300);
    await page.locator("[data-testid='create-item-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Step 4: Open the newly created study (last card)
    console.log('[TEST] Step 4: Opening study');
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    const lastCard = page.locator(CARD_SELECTOR).last();
    await lastCard.scrollIntoViewIfNeeded();
    await lastCard.click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    const assignmentUrl = page.url();
    console.log(`[TEST] Inside assignment: ${assignmentUrl}`);

    // Step 5: Navigate to the participants tab (PanlParticipantsView)
    console.log('[TEST] Step 5: Opening participants tab');
    await page.waitForSelector("[data-testid='assignment-tab-participants']", { timeout: 10000 });
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Step 6: Open the BudgetForm modal
    console.log('[TEST] Step 6: Opening BudgetForm modal');
    const addBudgetBtn = page.locator("[data-testid='pay-add-participants-button']");
    await expect(addBudgetBtn).toBeVisible({ timeout: 5000 });
    await addBudgetBtn.click();

    // Step 7: Fill BudgetForm — fee form first (has phx-change save_fee with 1000ms debounce)
    console.log('[TEST] Step 7: Filling BudgetForm');
    const aimInput = page.locator("[data-testid='budget-form-aim-input']");
    await expect(aimInput).toBeVisible({ timeout: 5000 });
    await aimInput.fill(AIM_OF_STUDY);

    const rewardInput = page.locator("[data-testid='budget-form-reward-input']");
    await rewardInput.fill(SUBJECT_REWARD);
    // Wait past the 1000ms debounce + server roundtrip so subject_reward is persisted.
    await page.waitForTimeout(1500);

    // Slots form — phx-change update_slots, debounce 300ms
    const slotsInput = page.locator("[data-testid='budget-form-slots-input']");
    await slotsInput.fill(SUBJECT_COUNT);
    await page.waitForTimeout(500);

    // Confirm button is enabled only when subject_count > 0 AND subject_reward > 0
    const confirmBtn = page.locator("[data-testid='budget-form-confirm-button']");
    await expect(confirmBtn).toBeVisible({ timeout: 3000 });

    // Step 8: Confirm — local provider returns a payment_url and the form redirects
    console.log('[TEST] Step 8: Confirming → expecting redirect to local payment simulator');
    await confirmBtn.click();
    await page.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });

    // Step 9: Complete the simulated payment
    console.log('[TEST] Step 9: Completing payment on local simulator');
    const completeBtn = page.locator("[data-testid='local-payment-complete-button']");
    await expect(completeBtn).toBeVisible({ timeout: 5000 });
    await completeBtn.click();

    // Step 10: Back on the assignment page → re-open participants tab and verify
    console.log('[TEST] Step 10: Back on assignment, verifying transaction is :completed');
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await page.waitForSelector("[data-testid='assignment-tab-participants']", { timeout: 10000 });
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    const completedCard = page.locator("[data-testid='transaction-card-completed']");
    await expect(completedCard).toBeVisible({ timeout: 5000 });
    console.log('[TEST] Transaction visible with :completed status — done');
  });

  test('researcher can add a second transaction on the same assignment (paid path with redirect)', async ({ page }) => {
    page.on('console', msg => {
      if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
    });

    // Login
    console.log('[TEST] Step 1: Logging in as researcher');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.locator("[data-testid='signin-tab-creator']").click();
    await page.waitForTimeout(300);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    await page.waitForTimeout(1000);

    // Open / create project
    console.log('[TEST] Step 2: Opening / creating project');
    const createProjectButton = page.locator("[data-testid='create-first-project-button']");
    if (await createProjectButton.isVisible({ timeout: 3000 })) {
      await createProjectButton.click();
      await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).first().click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Create a fresh questionnaire study (independent from the previous test)
    console.log('[TEST] Step 3: Creating questionnaire study');
    const createFirstItemButton = page.locator("[data-testid='create-first-item-button']");
    const addItemButton = page.locator("[data-testid='add-item-button']");
    const addItemByEvent = page.locator("[phx-click='create_item']");

    if (await createFirstItemButton.isVisible({ timeout: 3000 })) {
      await createFirstItemButton.click();
    } else if (await addItemButton.isVisible({ timeout: 2000 })) {
      await addItemButton.click();
    } else if (await addItemByEvent.isVisible({ timeout: 2000 })) {
      await addItemByEvent.click();
    } else {
      throw new Error('Could not find create/add item button');
    }

    await page.waitForSelector("[data-testid='selector-item-questionnaire']", { timeout: 10000 });
    await page.locator("[data-testid='selector-item-questionnaire']").click();
    await page.waitForTimeout(300);
    await page.locator("[data-testid='create-item-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Open the newly created study (last card)
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    const lastCard = page.locator(CARD_SELECTOR).last();
    await lastCard.scrollIntoViewIfNeeded();
    await lastCard.click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Open participants tab
    console.log('[TEST] Step 4: Opening participants tab');
    await page.waitForSelector("[data-testid='assignment-tab-participants']", { timeout: 10000 });
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // ────── First budget submission ──────
    console.log('[TEST] Step 5: First budget — opens BudgetForm with fee fields');
    await page.locator("[data-testid='pay-add-participants-button']").click();

    const aimInput = page.locator("[data-testid='budget-form-aim-input']");
    await expect(aimInput).toBeVisible({ timeout: 5000 });
    await aimInput.fill(AIM_OF_STUDY);

    await page.locator("[data-testid='budget-form-reward-input']").fill(SUBJECT_REWARD);
    await page.waitForTimeout(1500);

    await page.locator("[data-testid='budget-form-slots-input']").fill(SUBJECT_COUNT);
    await page.waitForTimeout(500);

    await page.locator("[data-testid='budget-form-confirm-button']").click();

    console.log('[TEST] Step 6: First payment via local simulator');
    await page.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });
    await page.locator("[data-testid='local-payment-complete-button']").click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await expect(
      page.locator("[data-testid='transaction-card-completed']")
    ).toHaveCount(1, { timeout: 5000 });

    // ────── Second budget submission ──────
    console.log('[TEST] Step 7: Second budget — fee fields are locked, only slots input');
    await page.locator("[data-testid='pay-add-participants-button']").click();

    const slotsInput2 = page.locator("[data-testid='budget-form-slots-input']");
    await expect(slotsInput2).toBeVisible({ timeout: 5000 });
    // Fee fields must be hidden because transactions != [] → reward_locked? = true
    await expect(page.locator("[data-testid='budget-form-aim-input']")).toHaveCount(0);
    await expect(page.locator("[data-testid='budget-form-reward-input']")).toHaveCount(0);

    await slotsInput2.fill('5');
    await page.waitForTimeout(500);

    console.log('[TEST] Step 8: Confirming second budget → expecting redirect to local payment simulator');
    await page.locator("[data-testid='budget-form-confirm-button']").click();
    await page.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });

    console.log('[TEST] Step 9: Completing payment on local simulator');
    await page.locator("[data-testid='local-payment-complete-button']").click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    console.log('[TEST] Step 10: Verifying both transactions are :completed');
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await expect(
      page.locator("[data-testid='transaction-card-completed']")
    ).toHaveCount(2, { timeout: 10000 });
    console.log('[TEST] Two transactions visible with :completed status — done');
  });

  test('researcher sees failed transaction when payment is rejected and can retry (UC-OPP-01.A1)', async ({ page }) => {
    page.on('console', msg => {
      if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
    });

    // Login
    console.log('[TEST] Step 1: Logging in as researcher');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.locator("[data-testid='signin-tab-creator']").click();
    await page.waitForTimeout(300);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    await page.waitForTimeout(1000);

    // Open / create project
    console.log('[TEST] Step 2: Opening / creating project');
    const createProjectButton = page.locator("[data-testid='create-first-project-button']");
    if (await createProjectButton.isVisible({ timeout: 3000 })) {
      await createProjectButton.click();
      await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).first().click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Create a fresh questionnaire study
    console.log('[TEST] Step 3: Creating questionnaire study');
    const createFirstItemButton = page.locator("[data-testid='create-first-item-button']");
    const addItemButton = page.locator("[data-testid='add-item-button']");
    const addItemByEvent = page.locator("[phx-click='create_item']");

    if (await createFirstItemButton.isVisible({ timeout: 3000 })) {
      await createFirstItemButton.click();
    } else if (await addItemButton.isVisible({ timeout: 2000 })) {
      await addItemButton.click();
    } else if (await addItemByEvent.isVisible({ timeout: 2000 })) {
      await addItemByEvent.click();
    } else {
      throw new Error('Could not find create/add item button');
    }

    await page.waitForSelector("[data-testid='selector-item-questionnaire']", { timeout: 10000 });
    await page.locator("[data-testid='selector-item-questionnaire']").click();
    await page.waitForTimeout(300);
    await page.locator("[data-testid='create-item-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Open the newly created study
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    const lastCard = page.locator(CARD_SELECTOR).last();
    await lastCard.scrollIntoViewIfNeeded();
    await lastCard.click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Open participants tab
    console.log('[TEST] Step 4: Opening participants tab');
    await page.waitForSelector("[data-testid='assignment-tab-participants']", { timeout: 10000 });
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Open BudgetForm and fill it
    console.log('[TEST] Step 5: Filling BudgetForm');
    await page.locator("[data-testid='pay-add-participants-button']").click();
    const aimInput = page.locator("[data-testid='budget-form-aim-input']");
    await expect(aimInput).toBeVisible({ timeout: 5000 });
    await aimInput.fill(AIM_OF_STUDY);
    await page.locator("[data-testid='budget-form-reward-input']").fill(SUBJECT_REWARD);
    await page.waitForTimeout(1500);
    await page.locator("[data-testid='budget-form-slots-input']").fill(SUBJECT_COUNT);
    await page.waitForTimeout(500);

    console.log('[TEST] Step 6: Confirming → expecting redirect to local payment simulator');
    await page.locator("[data-testid='budget-form-confirm-button']").click();
    await page.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });

    // Reject the payment via the Fail button on the local simulator
    console.log('[TEST] Step 7: Failing payment on local simulator');
    const failBtn = page.locator("[data-testid='local-payment-fail-button']");
    await expect(failBtn).toBeVisible({ timeout: 5000 });
    await failBtn.click();

    // Back on the assignment, transaction must be :failed and pay button must still be present
    console.log('[TEST] Step 8: Verifying transaction is :failed and Pay button is still available');
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await expect(
      page.locator("[data-testid='transaction-card-failed']")
    ).toHaveCount(1, { timeout: 5000 });
    await expect(page.locator("[data-testid='pay-add-participants-button']")).toBeVisible();

    // Retry: open the modal again and confirm a successful payment this time
    console.log('[TEST] Step 9: Retrying — confirming and completing successfully');
    await page.locator("[data-testid='pay-add-participants-button']").click();
    // Reward is locked (transactions != [] regardless of status); only slots input remains.
    const slotsRetry = page.locator("[data-testid='budget-form-slots-input']");
    await expect(slotsRetry).toBeVisible({ timeout: 5000 });
    await slotsRetry.fill(SUBJECT_COUNT);
    await page.waitForTimeout(500);
    await page.locator("[data-testid='budget-form-confirm-button']").click();
    await page.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });
    await page.locator("[data-testid='local-payment-complete-button']").click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    console.log('[TEST] Step 10: Verifying both failed and completed transactions are visible');
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await expect(page.locator("[data-testid='transaction-card-failed']")).toHaveCount(1, { timeout: 5000 });
    await expect(page.locator("[data-testid='transaction-card-completed']")).toHaveCount(1, { timeout: 5000 });
    console.log('[TEST] A1 flow done — failed + retried + completed');
  });

  test('confirm button is disabled when reward is 0 (UC-OPP-01.SEC-05)', async ({ page }) => {
    page.on('console', msg => {
      if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
    });

    // Login
    console.log('[TEST] Step 1: Logging in as researcher');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.locator("[data-testid='signin-tab-creator']").click();
    await page.waitForTimeout(300);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    await page.waitForTimeout(1000);

    // Open / create project
    console.log('[TEST] Step 2: Opening / creating project');
    const createProjectButton = page.locator("[data-testid='create-first-project-button']");
    if (await createProjectButton.isVisible({ timeout: 3000 })) {
      await createProjectButton.click();
      await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).first().click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Create a fresh questionnaire study
    console.log('[TEST] Step 3: Creating questionnaire study');
    const createFirstItemButton = page.locator("[data-testid='create-first-item-button']");
    const addItemButton = page.locator("[data-testid='add-item-button']");
    const addItemByEvent = page.locator("[phx-click='create_item']");

    if (await createFirstItemButton.isVisible({ timeout: 3000 })) {
      await createFirstItemButton.click();
    } else if (await addItemButton.isVisible({ timeout: 2000 })) {
      await addItemButton.click();
    } else if (await addItemByEvent.isVisible({ timeout: 2000 })) {
      await addItemByEvent.click();
    } else {
      throw new Error('Could not find create/add item button');
    }

    await page.waitForSelector("[data-testid='selector-item-questionnaire']", { timeout: 10000 });
    await page.locator("[data-testid='selector-item-questionnaire']").click();
    await page.waitForTimeout(300);
    await page.locator("[data-testid='create-item-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).last().click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Open BudgetForm but only set slots — leave reward at 0
    console.log('[TEST] Step 4: Open BudgetForm and fill only slots (reward stays €0)');
    await page.locator("[data-testid='pay-add-participants-button']").click();
    await expect(page.locator("[data-testid='budget-form-slots-input']")).toBeVisible({ timeout: 5000 });
    await page.locator("[data-testid='budget-form-slots-input']").fill(SUBJECT_COUNT);
    await page.waitForTimeout(500);

    // Confirm button must be disabled (rendered as a wrapping div with cursor-not-allowed)
    console.log('[TEST] Step 5: Verify confirm button is disabled when reward is 0');
    const confirmBtn = page.locator("[data-testid='budget-form-confirm-button']");
    await expect(confirmBtn).toHaveClass(/cursor-not-allowed/, { timeout: 3000 });
    console.log('[TEST] Confirm button correctly disabled at €0 reward');
  });

  test('rapid double-click on confirm does not create duplicate transactions (UC-OPP-01.SEC-09)', async ({ page }) => {
    page.on('console', msg => {
      if (msg.type() === 'error') console.log(`[BROWSER ERROR] ${msg.text()}`);
    });

    // Login
    console.log('[TEST] Step 1: Logging in as researcher');
    await page.goto('/user/signin');
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.locator("[data-testid='signin-tab-creator']").click();
    await page.waitForTimeout(300);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-email-input']").fill(RESEARCHER_EMAIL);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-password-input']").fill(RESEARCHER_PASSWORD);
    await page.locator("#account_signin-tab_panel_creator [data-testid='signin-submit-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 15000 });
    await page.waitForTimeout(1000);

    // Open / create project
    const createProjectButton = page.locator("[data-testid='create-first-project-button']");
    if (await createProjectButton.isVisible({ timeout: 3000 })) {
      await createProjectButton.click();
      await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    }
    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).first().click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Create study
    const createFirstItemButton = page.locator("[data-testid='create-first-item-button']");
    const addItemButton = page.locator("[data-testid='add-item-button']");
    const addItemByEvent = page.locator("[phx-click='create_item']");

    if (await createFirstItemButton.isVisible({ timeout: 3000 })) {
      await createFirstItemButton.click();
    } else if (await addItemButton.isVisible({ timeout: 2000 })) {
      await addItemButton.click();
    } else if (await addItemByEvent.isVisible({ timeout: 2000 })) {
      await addItemByEvent.click();
    } else {
      throw new Error('Could not find create/add item button');
    }

    await page.waitForSelector("[data-testid='selector-item-questionnaire']", { timeout: 10000 });
    await page.locator("[data-testid='selector-item-questionnaire']").click();
    await page.waitForTimeout(300);
    await page.locator("[data-testid='create-item-button']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    await page.waitForSelector(CARD_SELECTOR, { timeout: 10000 });
    await page.locator(CARD_SELECTOR).last().click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 15000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });
    await page.waitForTimeout(500);

    // Open BudgetForm and fill all fields
    console.log('[TEST] Step 2: Filling BudgetForm');
    await page.locator("[data-testid='pay-add-participants-button']").click();
    await expect(page.locator("[data-testid='budget-form-aim-input']")).toBeVisible({ timeout: 5000 });
    await page.locator("[data-testid='budget-form-aim-input']").fill(AIM_OF_STUDY);
    await page.locator("[data-testid='budget-form-reward-input']").fill(SUBJECT_REWARD);
    await page.waitForTimeout(1500);
    await page.locator("[data-testid='budget-form-slots-input']").fill(SUBJECT_COUNT);
    await page.waitForTimeout(500);

    // Fire two click events in the same JS tick to simulate a rapid double-click
    console.log('[TEST] Step 3: Rapid double-click on confirm');
    await page.evaluate(() => {
      const btn = document.querySelector("[data-testid='budget-form-confirm-button']") as HTMLElement | null;
      if (btn) {
        btn.click();
        btn.click();
      }
    });

    await page.waitForURL(/\/payment\/local\/[a-f0-9-]+$/, { timeout: 10000 });
    console.log('[TEST] Step 4: Completing payment on local simulator');
    await page.locator("[data-testid='local-payment-complete-button']").click();
    await page.waitForURL(/\/assignment\/\d+\/content/, { timeout: 10000 });
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    console.log('[TEST] Step 5: Verifying exactly one transaction was created');
    await page.locator("[data-testid='assignment-tab-participants']").click();
    await page.waitForSelector(CONNECTED_SELECTOR, { timeout: 10000 });

    // Total transactions (any status) should be exactly 1
    const allCards = page.locator("[data-testid^='transaction-card-']");
    await expect(allCards).toHaveCount(1, { timeout: 5000 });
    console.log('[TEST] Exactly one transaction — no duplicate from double-click');
  });
});
