/**
 * Feldspar App Test Utilities for Playwright
 *
 * Feldspar apps run in iframes within LiveView pages.
 * This module provides utilities to interact with them.
 */

import { Page, FrameLocator, Locator } from '@playwright/test';

/**
 * Get the Feldspar iframe and wait for it to load.
 */
export async function getFeldsparFrame(
  page: Page,
  options: { timeout?: number } = {}
): Promise<FrameLocator> {
  const { timeout = 10000 } = options;

  // Wait for iframe to appear
  await page.waitForSelector('iframe', { timeout });

  // Get the frame
  const frame = page.locator('iframe').contentFrame();

  // Wait for some content to load in the frame
  // Feldspar apps typically have a body or main content
  await frame.locator('body').waitFor({ state: 'visible', timeout });

  return frame;
}

/**
 * Upload a file to a Feldspar file input.
 */
export async function uploadFileInFeldspar(
  frame: FrameLocator,
  filePath: string,
  options: { timeout?: number } = {}
): Promise<void> {
  const { timeout = 10000 } = options;

  const fileInput = frame.locator('input[type="file"]');
  await fileInput.waitFor({ state: 'attached', timeout });
  await fileInput.setInputFiles(filePath);
}

/**
 * Click a button in a Feldspar iframe.
 */
export async function clickFeldsparButton(
  frame: FrameLocator,
  buttonName: string,
  options: { timeout?: number } = {}
): Promise<void> {
  const { timeout = 10000 } = options;

  const button = frame.getByRole('button', { name: buttonName });
  await button.waitFor({ state: 'visible', timeout });
  await button.click();
}

/**
 * Wait for Feldspar app to be ready (loaded and interactive).
 */
export async function waitForFeldsparReady(
  page: Page,
  options: { timeout?: number } = {}
): Promise<FrameLocator> {
  const { timeout = 15000 } = options;

  const frame = await getFeldsparFrame(page, { timeout });

  // Feldspar apps emit a 'ready' event, but we can't easily listen for it.
  // Instead, wait for interactive elements to appear.
  // This is app-specific - override as needed.

  return frame;
}
