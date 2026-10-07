import { randomUUID } from 'node:crypto';
import { test, expect, Page } from '@playwright/test';
import { clickPhxButton, gotoLiveView, waitForLiveView } from './lib/liveview';
import { featureEnabled, missingFeaturesReason } from './lib/features';

const PDF_VIEWER = '[phx-hook="PDFViewer"]';
const LINK_URL = 'https://example.com/pdf-viewer-regression';

async function expectRenderedPages(page: Page) {
  const viewer = page.locator(PDF_VIEWER);
  await expect(viewer).toBeVisible();
  await expect(viewer.locator('canvas')).toHaveCount(3);

  // Read the shipped renderer's output in PDF coordinates, independent of DPR,
  // viewport size and OS font antialiasing. Canvas creation alone is not ready.
  await expect.poll(async () => viewer.evaluate(element => {
    const width = element.getBoundingClientRect().width;
    return Array.from(element.querySelectorAll('canvas')).map(canvas => {
      const context = canvas.getContext('2d');
      if (!context || !canvas.width || !canvas.height) return null;

      function region(x: number, y: number, w: number, h: number) {
        const left = Math.floor(x / 612 * canvas.width);
        const top = Math.floor((792 - y - h) / 792 * canvas.height);
        const right = Math.ceil((x + w) / 612 * canvas.width);
        const bottom = Math.ceil((792 - y) / 792 * canvas.height);
        return context!.getImageData(left, top, right - left, bottom - top).data;
      }

      function fraction(
        pixels: Uint8ClampedArray,
        matches: (r: number, g: number, b: number, a: number) => boolean
      ) {
        let count = 0;
        for (let i = 0; i < pixels.length; i += 4) {
          if (matches(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])) count++;
        }
        return count / (pixels.length / 4);
      }

      function color(x: number, y: number, rgb: number[]) {
        return fraction(region(x, y, 10, 10), (r, g, b, a) =>
          a > 240 && Math.abs(r - rgb[0]) < 30 &&
          Math.abs(g - rgb[1]) < 30 && Math.abs(b - rgb[2]) < 30
        ) > 0.95;
      }

      function textInk(y: number, h: number) {
        const ink = fraction(region(48, y, 500, h), (r, g, b, a) =>
          a > 240 && r < 100 && g < 100 && b < 100
        );
        return ink > 0.003 && ink < 0.3;
      }

      const image = region(58, 470, 140, 80);
      const bounds = canvas.getBoundingClientRect();
      return {
        fitsViewer: Math.abs(bounds.width - width) < 2,
        pageAspectRatio: Math.abs(bounds.height / bounds.width - 792 / 612) < 0.01,
        red: color(93, 625, [255, 0, 0]),
        green: color(209, 625, [0, 255, 0]),
        blue: color(325, 625, [0, 0, 255]),
        rasterYellow: fraction(image, (r, g, b, a) => a > 240 && r > 220 && g > 220 && b < 40) > 0.15,
        rasterCyan: fraction(image, (r, g, b, a) => a > 240 && r < 40 && g > 220 && b > 220) > 0.15,
        embeddedTitle: textInk(720, 30),
        embeddedBody: textInk(680, 30),
        standardFont: textInk(425, 25),
        bottomRows: textInk(32, 308),
      };
    });
  }), { message: 'All three PDF pages render vectors, raster image and text at the current width', timeout: 20_000 })
    .toEqual(Array.from({ length: 3 }, () => ({
      fitsViewer: true,
      pageAspectRatio: true,
      red: true,
      green: true,
      blue: true,
      rasterYellow: true,
      rasterCyan: true,
      embeddedTitle: true,
      embeddedBody: true,
      standardFont: true,
      bottomRows: true,
    })));
}

test('participant reads, resizes, reopens and completes a rendered PDF', async ({ page, context }, testInfo) => {
  test.skip(!featureEnabled('e2e'), missingFeaturesReason('e2e'));
  test.setTimeout(90_000);
  const assignmentPath = process.env.E2E_PDF_ASSIGNMENT_PATH;
  if (!assignmentPath) throw new Error('E2E setup must provide E2E_PDF_ASSIGNMENT_PATH');
  const participantPath = `${assignmentPath}?p=PW_PDF_${randomUUID()}`;
  const desktopViewport = page.viewportSize()!;
  const browserMessages: string[] = [];
  const renderingErrors: string[] = [];

  page.on('pageerror', error => {
    const message = `${error.message}\n${error.stack || ''}`;
    browserMessages.push(message);
    renderingErrors.push(message);
  });
  page.on('console', message => {
    if (message.type() !== 'error' && message.type() !== 'warning') return;
    const text = `[${message.type()}] ${message.text()}`;
    browserMessages.push(text);
    if (/setting up fake worker/i.test(text) ||
        (message.type() === 'error' && /pdf|worker|render|font|wasm/i.test(text))) {
      renderingErrors.push(text);
    }
  });

  try {
    await gotoLiveView(page, participantPath, { requireConnection: true });
    await expectRenderedPages(page);
    await testInfo.attach('pdf-desktop', { body: await page.screenshot({ fullPage: true }), contentType: 'image/png' });

    await page.setViewportSize({ width: 390, height: 844 });
    await expectRenderedPages(page);
    await testInfo.attach('pdf-narrow', { body: await page.screenshot({ fullPage: true }), contentType: 'image/png' });

    // Intercept only the annotation's external destination; the real PDF,
    // worker, canvas click handler and popup navigation remain in use.
    const destinations: string[] = [];
    await context.route(LINK_URL, async route => {
      destinations.push(route.request().url());
      await route.fulfill({ status: 200, contentType: 'text/html', body: '<title>PDF link destination</title>' });
    });
    const firstCanvas = page.locator(`${PDF_VIEWER} canvas`).first();
    const size = await firstCanvas.evaluate(canvas => {
      const { width, height } = canvas.getBoundingClientRect();
      return { width, height };
    });
    const popupPromise = page.waitForEvent('popup');
    await firstCanvas.click({ position: { x: size.width * 144 / 612, y: size.height * (792 - 385) / 792 } });
    const popup = await popupPromise;
    await popup.waitForURL(LINK_URL);
    await expect.poll(() => destinations).toEqual([LINK_URL]);
    await popup.close();

    await page.setViewportSize(desktopViewport);
    await expectRenderedPages(page);
    await page.reload();
    await waitForLiveView(page, { requireConnection: true });
    await expectRenderedPages(page);
    await testInfo.attach('pdf-reopened', { body: await page.screenshot({ fullPage: true }), contentType: 'image/png' });

    await clickPhxButton(page, '[phx-click="done"]');
    await expect(page.getByTestId('finished-view')).toBeVisible();
    await testInfo.attach('pdf-completed', { body: await page.screenshot({ fullPage: true }), contentType: 'image/png' });
    expect(renderingErrors, 'PDF/worker/render errors and uncaught browser errors').toEqual([]);
  } catch (error) {
    if (!page.isClosed()) {
      await testInfo.attach('pdf-failure', { body: await page.screenshot({ fullPage: true }), contentType: 'image/png' });
    }
    throw error;
  } finally {
    await testInfo.attach('pdf-browser-messages', {
      body: JSON.stringify({ renderingErrors, browserMessages }, null, 2),
      contentType: 'application/json',
    });
  }
});
