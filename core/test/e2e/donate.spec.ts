import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';

// Configure via Infisical per environment
const ASSIGNMENT_PATH = process.env.E2E_DONATE_ASSIGNMENT_PATH;
const DATA_SOURCE = process.env.E2E_DONATE_DATA_SOURCE || 'tiktok';

if (!ASSIGNMENT_PATH) {
  throw new Error('Missing E2E_DONATE_ASSIGNMENT_PATH environment variable');
}

// Map data source to test files
const TEST_FILES: Record<string, string> = {
  'tiktok': 'tiktok_19MB.zip',
  'youtube': 'youtube_111MB.zip',
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
  console.log(`[TEST] Clicking Continue...`);
  await page.getByText('Continue').click();

  await page.waitForTimeout(2000);
  console.log(`[TEST] Clicking Yes, I agree...`);
  await page.getByText('Yes, I agree').click();

  // Wait for work items to appear and find one matching the data source
  console.log(`[TEST] Waiting for work items...`);
  await page.waitForSelector('[data-testid^="work-list-item-"]', { timeout: 10000 });

  console.log(`[TEST] Looking for work item with '${dataSource}'...`);
  const workItems = page.locator('[data-testid^="work-list-item-"]');
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

  // Select test file for this data source
  const testFile = getTestFile(dataSource);
  console.log(`[TEST] Using test file: ${path.basename(testFile)}`);

  const frame = page.locator('iframe').contentFrame();
  const fileInput = frame.locator('input[type="file"]');

  console.log(`[TEST] Setting file on input...`);
  await fileInput.setInputFiles(testFile);

  console.log(`[TEST] Clicking Continue in iframe...`);
  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Continue' }).click();

  await page.waitForTimeout(2000);
  console.log(`[TEST] Clicking Donate...`);

  const donateResponsePromise = page.waitForResponse(
    response => response.url().includes('/api/feldspar/donate') && response.status() === 200,
    { timeout: 120000 }
  );

  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Donate' }).click();

  console.log(`[TEST] Waiting for donate API response...`);
  const donateResponse = await donateResponsePromise;
  console.log(`[TEST] Donate API responded: ${donateResponse.status()}`);

  console.log(`[TEST] Waiting for completion...`);
  await expect(page.getByTestId('crew-task-list-view')).toContainText("Continue, I'm done");

  console.log(`[TEST] Done!`);
});
