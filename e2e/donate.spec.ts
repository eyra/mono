import { test, expect } from '@playwright/test';

function getRandomInt() {
  return Math.floor(Math.random() * 10000);
}

let dateTime = new Date()

test('test_donate', async ({ page }) => {
  test.setTimeout(180_000);
  await page.waitForTimeout(getRandomInt());
  await page.goto(`<PARTICIPANT URL>${dateTime.getTime()}`);
  await page.waitForTimeout(3000);
  await page.getByText('Continue').click();

  await page.waitForTimeout(3000);
  await page.getByText('Yes, I agree').click();
  await page.getByText('DATA DONATION ITEM NAME').click();
  await page.getByTestId('start-container').getByText('Continue').click();

  const fileChooserPromise3 = page.waitForEvent('filechooser');
  await page.locator('iframe').contentFrame().locator('div').filter({ hasText: 'E.g. data.zipChoose file' }).nth(5).click();
  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Choose file' }).click();
  const fileChooser3 = await fileChooserPromise3;
  await fileChooser3.setFiles('./e2e/testfiles/user_data_tiktok_150K.zip', { timeout: 3000 });
  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Continue' }).click();
  await page.waitForTimeout(2000);

  // Wait for the donate API call to complete
  const donateResponsePromise = page.waitForResponse(
    response => response.url().includes('/api/feldspar/donate') && response.status() === 200,
    { timeout: 240_000 }
  );

  await page.locator('iframe').contentFrame().getByRole('button', { name: 'Donate' }).click();
  console.log('[TEST] Waiting for donate API response...');
  const donateResponse = await donateResponsePromise;
  console.log('[TEST] Donate API responded with status:', donateResponse.status());

  await expect(page.getByTestId('crew-task-list-view')).toContainText('Continue, I\'m done');
});
