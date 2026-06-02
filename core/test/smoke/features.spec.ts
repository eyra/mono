import { test, expect } from '@playwright/test';

/**
 * Smoke test: verify the deployed app exposes exactly the expected feature flags.
 *
 * Any deviation is a signal that the deployment is misconfigured.
 * On prod/staging this is a hard failure; on pre-prod it is informational.
 *
 * Rules:
 * - prod, staging:       must match PROD_FEATURES exactly
 * - dev, test1, test2:   must match PRE_PROD_FEATURES exactly (test2 is the reference)
 */

const PROD_FEATURES = [
  'debug',
  'leaderboard',
  'member_google_sign_in',
  'panl',
  'password_sign_in',
].sort();

const EXPECTED: Record<string, string[]> = {
  prod: PROD_FEATURES,
  staging: [...PROD_FEATURES, 'e2e'].sort(),  // prod + e2e so E2E suite can run against staging
  dev: [
    'e2e',
    'leaderboard',
    'member_google_sign_in',
    'onyx',
    'panl',
    'panl_post_launch',
    'password_sign_in',
    'surfconext_sign_in',
  ].sort(),
  test1: [
    'e2e',
    'leaderboard',
    'member_google_sign_in',
    'onyx',
    'panl',
    'password_sign_in',
  ].sort(),
  test2: [
    'e2e',
    'leaderboard',
    'member_google_sign_in',
    'onyx',
    'panl',
    'panl_post_launch',
    'password_sign_in',
  ].sort(),
};

const env = process.env.SMOKE_ENV || 'prod';
const expected = EXPECTED[env] ?? PROD_FEATURES;

test(`deployed app (${env}) has exactly the expected feature flags`, async ({ request }) => {
  const response = await request.get('/api/e2e/features');

  expect(response.status()).toBe(200);

  const { features } = await response.json() as { features: string[] };
  const actual = [...features].sort();

  console.log(`[SMOKE] ${env} actual:   ${actual.join(', ')}`);
  console.log(`[SMOKE] ${env} expected: ${expected.join(', ')}`);

  expect(actual).toEqual(expected);
});
