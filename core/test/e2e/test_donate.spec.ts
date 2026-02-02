import { test, expect } from '@playwright/test';
import path from 'path';

function getRandomInt() {
  return Math.floor(Math.random() * 10000);
}

let dateTime = new Date()

test('test_donate', async ({ page }) => {
  const logs = []
  page.on('console', msg => {
    if (msg.type() === 'error' || msg.type() === 'warning' || msg.type() === 'info' || msg.type() === 'debug')
      logs.push({msg: msg.text(), type: msg.type()})
  });
  test.setTimeout(180_000);

  console.log('[TEST] Starting test...');
  await page.waitForTimeout(getRandomInt());

  console.log('[TEST] Navigating to page...');
  await page.goto(`https://next.dev.eyra.co/a/GAyz7L?p=ML_${dateTime.getTime()}`);

  await page.waitForTimeout(2000);
  console.log('[TEST] Clicking Continue...');
  await page.getByText('Continue').click();

  await page.waitForTimeout(2000);
  console.log('[TEST] Clicking Yes, I agree...');
  await page.getByText('Yes, I agree').click();

  console.log('[TEST] Clicking What\'sup doc?...');
  await page.getByText('What\'sup doc?').click();

  console.log('[TEST] Clicking Continue in start-container...');
  await page.getByTestId('start-container').getByText('Continue').click();

  console.log('[TEST] Opening file chooser...');
  const fileChooserPromise3 = page.waitForEvent('filechooser');
  await page.locator('iframe').contentFrame().locator('div').filter({ hasText: 'E.g. data.zipChoose file' }).nth(5).click();
  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Choose file' }).click();
  const fileChooser3 = await fileChooserPromise3;

  console.log('[TEST] Uploading file...');
  const testFile = path.resolve(__dirname, 'testfiles/user_data_tiktok_150K.zip');
  console.log('[TEST] File path:', testFile);
  await fileChooser3.setFiles(testFile, { timeout: 3000 });

  console.log('[TEST] Clicking Continue in iframe...');
  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Continue' }).click();

  await page.waitForTimeout(2000);
  console.log('[TEST] Clicking Donate and waiting for upload to complete...');

  // Wait for the donate API call to complete
  const donateResponsePromise = page.waitForResponse(
    response => response.url().includes('/api/feldspar/donate') && response.status() === 200,
    { timeout: 120000 }
  );

  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Donate' }).click();

  console.log('[TEST] Waiting for donate API response...');
  const donateResponse = await donateResponsePromise;
  console.log('[TEST] Donate API responded with status:', donateResponse.status());

  console.log('[TEST] Waiting for completion...');
  await expect(page.getByTestId('crew-task-list-view')).toContainText('Continue, I\'m done');

  console.log('[TEST] Test completed!');
  console.log('[TEST] Browser console logs:', JSON.stringify(logs, null, 2));
});
