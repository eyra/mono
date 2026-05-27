/**
 * Feature-flag helpers for E2E tests.
 *
 * `ENABLED_APP_FEATURES` is set by `global-setup.ts` from the server's
 * `/api/features` endpoint, so what we read here mirrors the live
 * config of whatever environment the tests are pointed at.
 */

const ENABLED = (process.env.ENABLED_APP_FEATURES || '')
  .split(',')
  .map((f) => f.trim())
  .filter((f) => f.length > 0);

export function featureEnabled(name: string): boolean {
  return ENABLED.includes(name);
}

export function allFeaturesEnabled(...names: string[]): boolean {
  return names.every(featureEnabled);
}

/**
 * Returns a human-readable reason string suitable for `test.skip` when
 * any of the required features is not enabled. Returns an empty string
 * when all are enabled.
 */
export function missingFeaturesReason(...names: string[]): string {
  const missing = names.filter((name) => !featureEnabled(name));
  if (missing.length === 0) return '';
  return `required feature(s) not enabled: ${missing.join(', ')}`;
}
