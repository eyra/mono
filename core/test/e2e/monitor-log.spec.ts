import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';

/**
 * E2E test for Feldspar monitor:log protocol.
 *
 * Tests that monitor:log messages from Feldspar apps are correctly
 * routed through the glue layer to the /api/feldspar/log endpoint.
 */

const MOCK_APP_ID = 'mock_monitor_app';
const MOCK_APP_SOURCE = path.resolve(__dirname, '../systems/feldspar/mock_monitor_app');

// Get upload path from environment or use default test path
const UPLOAD_PATH = process.env.UPLOAD_PATH || '/tmp';

test.describe('Feldspar monitor:log protocol', () => {
  test.beforeAll(async () => {
    // Copy mock app to where the Feldspar plug serves static files from
    const targetPath = path.join(UPLOAD_PATH, MOCK_APP_ID);

    // Clean up any existing mock app
    if (fs.existsSync(targetPath)) {
      fs.rmSync(targetPath, { recursive: true });
    }

    // Copy mock app files
    fs.cpSync(MOCK_APP_SOURCE, targetPath, { recursive: true });
  });

  test.afterAll(async () => {
    // Clean up mock app
    const targetPath = path.join(UPLOAD_PATH, MOCK_APP_ID);
    if (fs.existsSync(targetPath)) {
      fs.rmSync(targetPath, { recursive: true });
    }
  });

  test('monitor:log messages are routed to log endpoint', async ({ page }) => {
    // Track log API calls
    const logRequests: { level: string; message: string }[] = [];

    // Intercept log API calls
    await page.route('**/api/feldspar/log', async (route) => {
      const request = route.request();
      const postData = request.postDataJSON();
      logRequests.push({
        level: postData.level,
        message: postData.message,
      });
      // Continue with the actual request (or mock a response)
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ status: 'ok' }),
      });
    });

    // Log browser console messages for debugging
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        console.log(`[BROWSER ERROR] ${msg.text()}`);
      } else if (msg.text().includes('Feldspar')) {
        console.log(`[BROWSER] ${msg.text()}`);
      }
    });

    // Navigate to the mock Feldspar app
    console.log(`[TEST] Navigating to /feldspar/apps/${MOCK_APP_ID}`);
    await page.goto(`/feldspar/apps/${MOCK_APP_ID}`);

    // Wait for LiveView to connect
    await page.waitForSelector('[data-phx-main].phx-connected', { timeout: 10000 });
    console.log('[TEST] LiveView connected');

    // Wait for iframe to load
    await page.waitForSelector('iframe', { timeout: 5000 });
    console.log('[TEST] iframe found');

    // Access iframe content
    const frame = page.locator('iframe').contentFrame();

    // Wait for the mock app to finish sending logs
    await expect(frame.locator('#status')).toContainText('Logs sent!', { timeout: 5000 });
    console.log('[TEST] Mock app finished sending logs');

    // Verify log API was called with expected messages
    console.log(`[TEST] Log requests captured: ${logRequests.length}`);
    logRequests.forEach((req, i) => {
      console.log(`[TEST]   ${i + 1}. ${req.level}: ${req.message}`);
    });

    // Assert we received the expected log messages
    expect(logRequests.length).toBeGreaterThanOrEqual(2);

    // Check for the info log
    const infoLog = logRequests.find(
      (r) => r.level === 'info' && r.message === 'Mock app initialized'
    );
    expect(infoLog).toBeDefined();

    // Check for the error log
    const errorLog = logRequests.find(
      (r) => r.level === 'error' && r.message === 'Mock error for testing'
    );
    expect(errorLog).toBeDefined();

    console.log('[TEST] All assertions passed!');
  });
});
