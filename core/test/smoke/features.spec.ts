import { test, expect } from '@playwright/test';

/**
 * Smoke test: verify the deployed app exposes the expected feature flags.
 *
 * Uses /api/e2e/features which is intentionally ungated (available on all
 * environments) so smoke tests can discover the feature set without needing
 * the :e2e feature to be enabled on prod.
 */

const REQUIRED_FEATURES = ['panl', 'panl_post_launch', 'password_sign_in'];

test('deployed app exposes expected feature flags', async ({ request }) => {
  const response = await request.get('/api/e2e/features');

  expect(response.status()).toBe(200);

  const { features } = await response.json() as { features: string[] };

  console.log(`[SMOKE] Enabled features: ${features.join(', ')}`);

  for (const feature of REQUIRED_FEATURES) {
    expect(features, `Expected feature "${feature}" to be enabled`).toContain(feature);
  }
});
