import { test, expect } from '@playwright/test';

/**
 * Smoke test: verify the deployed app serves the apple-app-site-association
 * file with `webcredentials`, so the iOS sign-in sheet can hand an
 * identity-provider sign-in back to the Next app, and with no app links: for
 * now the apps open no page from outside, so invitation links (/assignment/*)
 * stay in the browser.
 *
 * Both app IDs are served on every environment; iOS only links a domain to an
 * app whose Associated Domains entitlement names that domain.
 */

const APP_IDS = ['XNWQJGGM96.co.eyra.next', 'XNWQJGGM96.co.eyra.next.dev'];

type Aasa = {
  applinks?: unknown;
  webcredentials: { apps: string[] };
};

const env = process.env.SMOKE_ENV || 'prod';

test(`deployed app (${env}) serves apple-app-site-association`, async ({ request }) => {
  const response = await request.get('/.well-known/apple-app-site-association');

  expect(response.status()).toBe(200);
  expect(response.headers()['content-type']).toContain('application/json');

  const aasa = await response.json() as Aasa;

  console.log(`[SMOKE] ${env} apple-app-site-association: ${JSON.stringify(aasa)}`);

  expect(aasa.webcredentials.apps).toEqual(expect.arrayContaining(APP_IDS));
  expect(aasa).not.toHaveProperty('applinks');
});
