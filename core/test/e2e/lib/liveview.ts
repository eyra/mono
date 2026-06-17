/**
 * LiveView Test Utilities for Playwright
 *
 * Phoenix LiveView pages render in two phases:
 * 1. Static HTML (immediate) - forms, content visible
 * 2. WebSocket connection (async) - enables phx-click, live updates
 *
 * This module provides utilities to wait for the right conditions.
 */

import { Page, Locator, expect } from '@playwright/test';
import { featureEnabled } from './features';

/**
 * Wait for a LiveView page to be ready for interaction.
 *
 * Strategy:
 * 1. Wait for [data-phx-main] to exist (static render complete)
 * 2. Wait for .phx-connected OR timeout (WebSocket may be slow)
 * 3. Return connection status for diagnostics
 */
export async function waitForLiveView(
  page: Page,
  options: { timeout?: number; requireConnection?: boolean } = {}
): Promise<{ connected: boolean; classes: string | null }> {
  const { timeout = 5000, requireConnection = false } = options;

  // Wait for static render
  await page.waitForSelector('[data-phx-main]', { timeout });

  // Try to wait for WebSocket connection
  try {
    await page.waitForSelector('[data-phx-main].phx-connected', { timeout });
    const classes = await page.locator('[data-phx-main]').getAttribute('class');
    return { connected: true, classes };
  } catch {
    const classes = await page.locator('[data-phx-main]').getAttribute('class');

    if (requireConnection) {
      throw new Error(
        `LiveView did not connect within ${timeout}ms. Classes: ${classes}`
      );
    }

    return { connected: false, classes };
  }
}

/**
 * Navigate to a page and wait for LiveView to be ready.
 */
export async function gotoLiveView(
  page: Page,
  url: string,
  options: { timeout?: number; requireConnection?: boolean } = {}
): Promise<{ connected: boolean; classes: string | null }> {
  await page.goto(url);
  return waitForLiveView(page, options);
}

/**
 * Wait for a LiveView element to be interactive.
 *
 * For elements with phx-click, phx-change etc., we need the WebSocket
 * to be connected. This function waits for both the element AND connection.
 */
export async function waitForInteractive(
  page: Page,
  selector: string,
  options: { timeout?: number } = {}
): Promise<Locator> {
  const { timeout = 5000 } = options;

  // First wait for connection
  await page.waitForSelector('[data-phx-main].phx-connected', { timeout });

  // Then wait for the element
  const locator = page.locator(selector);
  await locator.waitFor({ state: 'visible', timeout });

  return locator;
}

/**
 * Click a phx-click button safely.
 *
 * Waits for LiveView connection before clicking.
 */
export async function clickPhxButton(
  page: Page,
  selector: string,
  options: { timeout?: number } = {}
): Promise<void> {
  const locator = await waitForInteractive(page, selector, options);
  await locator.click();
}

/**
 * Fill a form field in a LiveView form.
 *
 * Form fields work with static render, but for phx-change to work
 * we need WebSocket connection.
 */
export async function fillLiveField(
  page: Page,
  selector: string,
  value: string,
  options: { timeout?: number; requireConnection?: boolean } = {}
): Promise<void> {
  const { timeout = 5000, requireConnection = true } = options;

  if (requireConnection) {
    await page.waitForSelector('[data-phx-main].phx-connected', { timeout });
  }

  const field = page.locator(selector);
  await field.waitFor({ state: 'visible', timeout });
  await field.fill(value);
}

/**
 * Wait for navigation to complete and LiveView to be ready.
 *
 * Use this after clicking a link or submitting a form that navigates.
 */
export async function waitForNavigation(
  page: Page,
  urlPattern: string | RegExp,
  options: { timeout?: number; requireConnection?: boolean } = {}
): Promise<{ connected: boolean; url: string }> {
  const { timeout = 5000, requireConnection = true } = options;

  await page.waitForURL(urlPattern, { timeout });
  const result = await waitForLiveView(page, { timeout, requireConnection });

  return { ...result, url: page.url() };
}

/**
 * Activate the local payment provider for the current browser session.
 *
 * Calls POST /api/e2e/use_local_payment which sets a session flag that the
 * Payment LiveView hook picks up. Allows staging (configured with OPP sandbox)
 * to use the local simulator for E2E payment flows without affecting manual testers.
 *
 * No-op when the :e2e feature is not enabled on the target server.
 */
export async function activateLocalPayment(page: Page): Promise<void> {
  if (!featureEnabled('e2e')) return;
  await page.request.post('/api/e2e/inject', {
    data: { payment_provider: 'local' }
  });
}

/**
 * Debug helper: log LiveView state
 */
export async function debugLiveViewState(page: Page): Promise<void> {
  const mainEl = page.locator('[data-phx-main]');
  const exists = await mainEl.count() > 0;

  if (!exists) {
    console.log('[DEBUG] No [data-phx-main] element found');
    return;
  }

  const classes = await mainEl.getAttribute('class');
  const id = await mainEl.getAttribute('id');
  const phxSession = await mainEl.getAttribute('data-phx-session');

  console.log('[DEBUG] LiveView state:');
  console.log(`  - id: ${id}`);
  console.log(`  - classes: ${classes}`);
  console.log(`  - phx-session: ${phxSession ? 'present' : 'missing'}`);
  console.log(`  - connected: ${classes?.includes('phx-connected')}`);
  console.log(`  - loading: ${classes?.includes('phx-loading')}`);
  console.log(`  - error: ${classes?.includes('phx-error')}`);
}
