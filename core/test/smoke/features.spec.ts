import { test, expect } from '@playwright/test';

/**
 * Smoke test: verify the deployed app exposes exactly the expected feature flags.
 *
 * Any deviation — feature added or removed — is a signal that the deployment
 * is misconfigured. On prod this is a hard failure; on pre-prod envs it is a
 * signal (handled by the workflow, not this spec).
 *
 * Uses /api/e2e/features which is intentionally ungated — available on all
 * environments including prod.
 */

const EXPECTED_FEATURES: Record<string, string[]> = {
  prod: [
    'debug',
    'leaderboard',
    'member_google_sign_in',
    'panl',
    'password_sign_in',
  ],
  staging: [
    'leaderboard',
    'member_google_sign_in',
    'panl',
    'password_sign_in',
  ],
  dev: [
    'e2e',
    'leaderboard',
    'member_google_sign_in',
    'onyx',
    'panl',
    'panl_post_launch',
    'password_sign_in',
    'surfconext_sign_in',
  ],
  test1: [
    'leaderboard',
    'member_google_sign_in',
    'panl',
    'password_sign_in',
  ],
  test2: [
    'e2e',
    'leaderboard',
    'member_google_sign_in',
    'onyx',
    'panl',
    'panl_post_launch',
    'password_sign_in',
  ],
};

const env = process.env.SMOKE_ENV || 'prod';
const expected = (EXPECTED_FEATURES[env] ?? EXPECTED_FEATURES['prod']).sort();

test(`deployed app (${env}) has exactly the expected feature flags`, async ({ request }) => {
  const response = await request.get('/api/e2e/features');

  expect(response.status()).toBe(200);

  const { features } = await response.json() as { features: string[] };
  const actual = [...features].sort();

  console.log(`[SMOKE] ${env} actual:   ${actual.join(', ')}`);
  console.log(`[SMOKE] ${env} expected: ${expected.join(', ')}`);

  expect(actual).toEqual(expected);
});
