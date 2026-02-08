import { test, expect } from '@playwright/test';
import path from 'path';

const ASSIGNMENT_PATH = process.env.ASSIGNMENT_PATH || '/a/GAyz7L';

test('data_donation', async ({ page }, testInfo) => {
  const participantId = `PW_${Date.now()}_${testInfo.workerIndex}_${testInfo.repeatEachIndex}`;

  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log(`[BROWSER ERROR] ${msg.text()}`);
    }
  });

  test.setTimeout(180_000);

  console.log(`[TEST] Participant: ${participantId}`);
  console.log(`[TEST] Navigating to ${ASSIGNMENT_PATH}...`);
  await page.goto(`${ASSIGNMENT_PATH}?p=${participantId}`);

  await page.waitForTimeout(2000);
  console.log(`[TEST] Clicking Continue...`);
  await page.getByText('Continue').click();

  await page.waitForTimeout(2000);
  console.log(`[TEST] Clicking Yes, I agree...`);
  await page.getByText('Yes, I agree').click();

  console.log(`[TEST] Clicking first work item...`);
  await page.getByTestId('work-list-item-0').click();

  console.log(`[TEST] Clicking Continue in start-container...`);
  await page.getByTestId('start-container').getByText('Continue').click();

  console.log(`[TEST] Opening file chooser...`);
  const fileChooserPromise = page.waitForEvent('filechooser');
  await page.locator('iframe').contentFrame().locator('div').filter({ hasText: 'E.g. data.zipChoose file' }).nth(5).click();
  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Choose file' }).click();
  const fileChooser = await fileChooserPromise;

  console.log(`[TEST] Uploading file...`);
  const testFile = path.resolve(__dirname, 'testfiles/user_data_tiktok_150K.zip');
  await fileChooser.setFiles(testFile, { timeout: 3000 });

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
