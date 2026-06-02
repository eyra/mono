import { chromium } from '@playwright/test';

const BASE_URL = process.env.E2E_BASE_URL || 'http://localhost:4000';

// Service account credentials for E2E setup
const SERVICE_EMAIL = process.env.E2E_SERVICE_EMAIL || 'e2e@eyra.service';
const SERVICE_PASSWORD = process.env.E2E_SERVICE_PASSWORD || 'E2EServicePassword123!';
const SERVICE_KEY = process.env.SERVICE_LOGIN_KEY || 'dev-test-key';

// Store fixtures globally for tests to access
interface E2EFixtures {
  researcher_email: string;
  researcher_password: string;
  researcher_b_email: string;
  researcher_b_password: string;
  participant_email: string;
  participant_password: string;
  donate_assignment_path: string;
  test_org_id?: number;
}

declare global {
  var e2eFixtures: E2EFixtures | null;
}

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

  // Step 2b: Discover enabled features from the server (single source of truth)
  try {
    const response = await fetch(`${BASE_URL}/.status/features`);
    if (response.ok) {
      const { features } = await response.json() as { features: string[] };
      process.env.ENABLED_APP_FEATURES = features.join(',');
      console.log(`[GLOBAL SETUP] Enabled features: ${process.env.ENABLED_APP_FEATURES}`);
    } else {
      console.log(`[GLOBAL SETUP] /.status/features returned ${response.status}, falling back to env var`);
    }
  } catch (error: any) {
    console.log(`[GLOBAL SETUP] /.status/features fetch failed: ${error.message}, falling back to env var`);
  }

  // Step 3: Setup E2E fixtures (skip on production - use Infisical values)
  if (process.env.E2E_SKIP_SETUP !== 'true') {
    console.log(`[GLOBAL SETUP] Setting up E2E fixtures...`);
    try {
      const fixtures = await setupE2EFixtures(BASE_URL);
      globalThis.e2eFixtures = fixtures;

      // Also set as env vars for tests that read them
      process.env.E2E_RESEARCHER_EMAIL = fixtures.researcher_email;
      process.env.E2E_RESEARCHER_PASSWORD = fixtures.researcher_password;
      process.env.E2E_RESEARCHER_B_EMAIL = fixtures.researcher_b_email;
      process.env.E2E_RESEARCHER_B_PASSWORD = fixtures.researcher_b_password;
      process.env.E2E_PARTICIPANT_EMAIL = fixtures.participant_email;
      process.env.E2E_PARTICIPANT_PASSWORD = fixtures.participant_password;
      process.env.E2E_DONATE_ASSIGNMENT_PATH = fixtures.donate_assignment_path;
      if (fixtures.test_org_id != null) {
        process.env.E2E_TEST_ORG_ID = String(fixtures.test_org_id);
      }

      console.log(`[GLOBAL SETUP] Fixtures ready:`);
      console.log(`  Researcher: ${fixtures.researcher_email}`);
      console.log(`  Assignment: ${fixtures.donate_assignment_path}`);
    } catch (error: any) {
      console.log(`[GLOBAL SETUP] Fixture setup failed: ${error.message}`);
      console.log(`[GLOBAL SETUP] Tests requiring fixtures will use Infisical env vars`);
    }
  } else {
    console.log(`[GLOBAL SETUP] Skipping fixture setup (E2E_SKIP_SETUP=true)`);
  }

  await browser.close();
  console.log(`[GLOBAL SETUP] Server ready`);
}

async function setupE2EFixtures(baseUrl: string): Promise<E2EFixtures> {
  // Step 1: Bootstrap - create service user if needed (no auth required)
  console.log(`[GLOBAL SETUP] Bootstrapping service user...`);
  const bootstrapResponse = await fetch(`${baseUrl}/api/e2e/bootstrap`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  });

  if (!bootstrapResponse.ok) {
    const body = await bootstrapResponse.text();
    throw new Error(`Bootstrap failed: ${bootstrapResponse.status} - ${body}`);
  }

  // Step 2: Login as service account
  const loginResponse = await fetch(`${baseUrl}/api/service/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Service-Key': SERVICE_KEY,
    },
    body: JSON.stringify({
      email: SERVICE_EMAIL,
      password: SERVICE_PASSWORD,
    }),
  });

  if (!loginResponse.ok) {
    const body = await loginResponse.text();
    throw new Error(`Service login failed: ${loginResponse.status} - ${body}`);
  }

  // Get session cookie from response
  const cookies = loginResponse.headers.get('set-cookie');
  if (!cookies) {
    throw new Error('No session cookie in login response');
  }

  // Step 3: Call E2E setup endpoint
  const setupResponse = await fetch(`${baseUrl}/api/e2e/setup`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Cookie': cookies,
    },
  });

  if (!setupResponse.ok) {
    const body = await setupResponse.text();
    throw new Error(`E2E setup failed: ${setupResponse.status} - ${body}`);
  }

  return await setupResponse.json() as E2EFixtures;
}
