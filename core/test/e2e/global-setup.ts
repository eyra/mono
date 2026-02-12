import { chromium } from '@playwright/test';

const BASE_URL = process.env.BASE_URL || 'https://eyra-next-test1.fly.dev';

export default async function globalSetup() {
  console.log(`[GLOBAL SETUP] Warming up server at ${BASE_URL}...`);

  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Step 1: Hit wakeup endpoint to trigger fresh DB connection
  // This forces a new connection attempt which wakes up suspended Fly Postgres
  let wakeupAttempts = 0;
  const maxWakeupAttempts = 20;

  while (wakeupAttempts < maxWakeupAttempts) {
    wakeupAttempts++;
    const start = Date.now();

    try {
      const response = await page.goto(`${BASE_URL}/.status/wakeup`, {
        timeout: 35000,
        waitUntil: 'load'
      });
      const elapsed = Date.now() - start;

      if (response && response.status() === 200) {
        console.log(`[GLOBAL SETUP] DB awake (attempt ${wakeupAttempts}, ${elapsed}ms)`);
        break;
      } else {
        const body = await response?.text();
        console.log(`[GLOBAL SETUP] Wakeup attempt ${wakeupAttempts} (${elapsed}ms): ${response?.status()} - ${body}`);
      }
    } catch (error: any) {
      const elapsed = Date.now() - start;
      console.log(`[GLOBAL SETUP] Wakeup attempt ${wakeupAttempts} (${elapsed}ms): ${error.message}`);
    }

    // Wait before retry
    await page.waitForTimeout(3000);
  }

  if (wakeupAttempts >= maxWakeupAttempts) {
    await browser.close();
    throw new Error(`[GLOBAL SETUP] Failed to wake up DB after ${maxWakeupAttempts} attempts`);
  }

  // Step 2: Verify with health check
  console.log(`[GLOBAL SETUP] Verifying with health check...`);
  try {
    const response = await page.goto(`${BASE_URL}/.status/health`, {
      timeout: 10000,
      waitUntil: 'load'
    });
    if (response && response.status() === 200) {
      console.log(`[GLOBAL SETUP] Health check passed`);
    } else {
      console.log(`[GLOBAL SETUP] Health check returned ${response?.status()}`);
    }
  } catch (error: any) {
    console.log(`[GLOBAL SETUP] Health check warning: ${error.message}`);
  }

  await browser.close();
  console.log(`[GLOBAL SETUP] Server ready`);
}
