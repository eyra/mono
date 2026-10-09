import { test, expect } from '@playwright/test';

/**
 * Smoke test: verify the deployed app serves the apple-app-site-association
 * file, so iOS opens invitation links (/assignment/*) in the Next app.
 *
 * Both app IDs are served on every environment; iOS only links a domain to an
 * app whose Associated Domains entitlement names that domain.
 */

const APP_IDS = ['XNWQJGGM96.co.eyra.next', 'XNWQJGGM96.co.eyra.next.dev'];

type Aasa = {
  applinks: {
    details: { appIDs: string[]; components: Record<string, string>[] }[];
  };
};

const env = process.env.SMOKE_ENV || 'prod';

test(`deployed app (${env}) serves apple-app-site-association`, async ({ request }) => {
  const response = await request.get('/.well-known/apple-app-site-association');

  expect(response.status()).toBe(200);
  expect(response.headers()['content-type']).toContain('application/json');

  const { applinks } = await response.json() as Aasa;

  console.log(`[SMOKE] ${env} applinks: ${JSON.stringify(applinks)}`);

  expect(applinks.details).toContainEqual(
    expect.objectContaining({
      appIDs: expect.arrayContaining(APP_IDS),
      components: expect.arrayContaining([{ '/': '/assignment/*' }]),
    }),
  );
});
