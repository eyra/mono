import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';

// Configure via Infisical per environment
const ASSIGNMENT_PATH = process.env.E2E_DONATE_ASSIGNMENT_PATH;
const DATA_SOURCE = process.env.E2E_DONATE_DATA_SOURCE || 'many_files';

if (!ASSIGNMENT_PATH) {
  throw new Error('Missing E2E_DONATE_ASSIGNMENT_PATH environment variable');
}

// Map data source to test files
const TEST_FILES: Record<string, string> = {
  'tiktok': 'tiktok_19MB.zip',
  'youtube': 'youtube_111MB.zip',
  'many_files': 'many_files_1000.zip',
};

function getTestFile(dataSource: string): string {
  const source = dataSource.toLowerCase();
  const filename = TEST_FILES[source];
  if (!filename) {
    throw new Error(`Unknown data source: ${dataSource}. Available: ${Object.keys(TEST_FILES).join(', ')}`);
  }
  const filePath = path.resolve(__dirname, 'testfiles', filename);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Test file not found: ${filePath}`);
  }
  return filePath;
}

test('data_donation', async ({ page }, testInfo) => {
  const participantId = `PW_${Date.now()}_${testInfo.workerIndex}_${testInfo.repeatEachIndex}`;
  const dataSource = DATA_SOURCE.toLowerCase();

  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log(`[BROWSER ERROR] ${msg.text()}`);
    }
  });

  test.setTimeout(180_000);

  console.log(`[TEST] Participant: ${participantId}`);
  console.log(`[TEST] Data source: ${dataSource}`);
  console.log(`[TEST] Navigating to ${ASSIGNMENT_PATH}...`);
  await page.goto(`${ASSIGNMENT_PATH}?p=${participantId}`);

  await page.waitForTimeout(2000);
  console.log(`[TEST] Current URL: ${page.url()}`);

  // Check if we're on an intro/consent page or directly on work items
  const continueButton = page.getByText('Continue').first();
  const yesAgreeButton = page.getByText('Yes, I agree');
  const workItems = page.locator('[data-testid^="work-list-item-"]');

  // Handle intro page if present (has Continue button but no work items yet)
  if (await continueButton.isVisible() && !(await workItems.first().isVisible({ timeout: 1000 }).catch(() => false))) {
    console.log(`[TEST] Clicking Continue on intro page...`);
    await continueButton.click();
    await page.waitForTimeout(2000);
  }

  // Handle consent page if present
  if (await yesAgreeButton.isVisible({ timeout: 2000 }).catch(() => false)) {
    console.log(`[TEST] Clicking Yes, I agree on consent page...`);
    await yesAgreeButton.click();
    await page.waitForTimeout(2000);
  }

  // Wait a moment for the page to settle after intro/consent
  await page.waitForTimeout(2000);

  // Detect flow type: check if work items exist OR if we're directly at the Feldspar iframe
  // Single-task assignments go directly to iframe; multi-task show work items list
  console.log(`[TEST] Detecting flow type...`);

  // Try to find work items first (quick check)
  const hasWorkItems = await workItems.first().isVisible({ timeout: 3000 }).catch(() => false);

  if (hasWorkItems) {
    // Multi-task flow: select and start the work item
    console.log(`[TEST] Found work items - using multi-task flow`);

    console.log(`[TEST] Looking for work item with '${dataSource}'...`);
    const count = await workItems.count();
    console.log(`[TEST] Found ${count} work items`);

    let matchedItem = null;
    for (let i = 0; i < count; i++) {
      const item = workItems.nth(i);
      const text = (await item.textContent() || '').toLowerCase();
      console.log(`[TEST] Work item ${i}: "${text.substring(0, 80)}..."`);
      if (text.includes(dataSource)) {
        matchedItem = item;
        console.log(`[TEST] Matched!`);
        break;
      }
    }

    if (!matchedItem) {
      throw new Error(`No work item found for data source: ${dataSource}`);
    }

    console.log(`[TEST] Clicking work item...`);
    await matchedItem.click();

    console.log(`[TEST] Clicking Continue in start-container...`);
    await page.getByTestId('start-container').getByText('Continue').click();
  } else {
    // Single-task flow: should already be at iframe
    console.log(`[TEST] No work items found - assuming single-task flow (iframe already visible)`);
  }

  // Wait for Feldspar iframe to be ready (regardless of flow)
  // The iframe src is set dynamically by JavaScript, so we locate via the parent container
  console.log(`[TEST] Waiting for Feldspar iframe...`);
  const feldsparContainer = page.locator('[phx-hook="FeldsparApp"]');
  await feldsparContainer.waitFor({ state: 'visible', timeout: 10000 });
  console.log(`[TEST] Feldspar container found`);

  // Get iframe element and wait for its src to be set by JavaScript
  const iframeElement = feldsparContainer.locator('iframe');
  await iframeElement.waitFor({ state: 'visible', timeout: 5000 });

  // Wait for the iframe src attribute to be set (JavaScript sets it)
  await page.waitForFunction(
    () => {
      const iframe = document.querySelector('[phx-hook="FeldsparApp"] iframe');
      return iframe && iframe.getAttribute('src')?.includes('/feldspar/');
    },
    { timeout: 10000 }
  );

  const iframeSrc = await iframeElement.getAttribute('src');
  console.log(`[TEST] Iframe src: ${iframeSrc}`);

  // Use frameLocator to interact with the iframe - this auto-waits for content
  const feldsparFrameLocator = page.frameLocator('[phx-hook="FeldsparApp"] iframe');

  // Wait for the app to render - Feldspar apps use JS to render content
  console.log(`[TEST] Waiting for Feldspar app to render...`);
  await feldsparFrameLocator.locator('h1').waitFor({ state: 'visible', timeout: 30000 });
  console.log(`[TEST] Feldspar app heading visible`);

  // Use getByRole which matches accessibility roles (in case Feldspar uses custom button elements)
  await feldsparFrameLocator.getByRole('button').first().waitFor({ state: 'visible', timeout: 10000 });
  console.log(`[TEST] Feldspar iframe ready`);

  const feldsparFrame = feldsparFrameLocator;

  // Select test file for this data source
  const testFile = getTestFile(dataSource);
  console.log(`[TEST] Using test file: ${path.basename(testFile)}`);

  // Use frameLocator for Feldspar iframe interactions
  const fileInput = feldsparFrame.locator('input[type="file"]');

  console.log(`[TEST] Setting file on input...`);
  await fileInput.setInputFiles(testFile);

  console.log(`[TEST] Clicking Continue in iframe...`);
  await feldsparFrame.getByRole('button', { name: 'Continue' }).click();

  await page.waitForTimeout(2000);
  console.log(`[TEST] Clicking Donate...`);

  const donateResponsePromise = page.waitForResponse(
    response => response.url().includes('/api/feldspar/donate') && response.status() === 200,
    { timeout: 120000 }
  );

  await feldsparFrame.getByRole('button', { name: 'Donate' }).click();

  console.log(`[TEST] Waiting for donate API response...`);
  const donateResponse = await donateResponsePromise;
  console.log(`[TEST] Donate API responded: ${donateResponse.status()}`);

  console.log(`[TEST] Waiting for completion...`);
  // For single-task assignments: "Done" / "Thank you. You have finished."
  // For multi-task assignments: "Continue, I'm done" button in task list view
  const completionText = page.getByText('Thank you. You have finished.');
  const multiTaskButton = page.getByText("Continue, I'm done");

  // Wait for either completion indicator (5 seconds max)
  await Promise.race([
    completionText.waitFor({ state: 'visible', timeout: 10000 }),
    multiTaskButton.waitFor({ state: 'visible', timeout: 10000 }),
  ]).catch(() => {
    // If neither found, throw a more helpful error
    throw new Error('Completion indicator not found: expected either "Thank you. You have finished." or "Continue, I\'m done"');
  });

  console.log(`[TEST] Done!`);
});
