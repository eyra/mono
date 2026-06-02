import { test, expect } from '@playwright/test';

/**
 * Smoke test: verify the deployed app exposes the expected feature flags.
 *
 * Uses /api/e2e/features which is intentionally ungated — available on all
 * environments so smoke tests can discover the feature set without needing
 * the :e2e feature to be enabled on prod.
 */

type FeatureConfig = {
  required: string[];
  forbidden: string[];
};

const FEATURE_CONFIG: Record<string, FeatureConfig> = {
  prod: {
    required: ['panl', 'password_sign_in'],
    forbidden: ['e2e'],
  },
  staging: {
    required: ['panl', 'password_sign_in'],
    forbidden: ['e2e'],
  },
  dev: {
    required: ['e2e', 'panl', 'panl_post_launch', 'password_sign_in'],
    forbidden: [],
  },
  test1: {
    required: ['panl', 'password_sign_in'],
    forbidden: [],
  },
  test2: {
    required: ['panl', 'password_sign_in'],
    forbidden: [],
  },
};

const env = process.env.SMOKE_ENV || 'prod';
const config = FEATURE_CONFIG[env] ?? FEATURE_CONFIG['prod'];

test(`deployed app (${env}) exposes expected feature flags`, async ({ request }) => {
  const response = await request.get('/api/e2e/features');

  expect(response.status()).toBe(200);

  const { features } = await response.json() as { features: string[] };

  console.log(`[SMOKE] ${env} features: ${features.join(', ')}`);

  for (const feature of config.required) {
    expect(features, `Expected feature "${feature}" to be enabled on ${env}`).toContain(feature);
  }

  for (const feature of config.forbidden) {
    expect(features, `Feature "${feature}" must NOT be enabled on ${env}`).not.toContain(feature);
  }
});
