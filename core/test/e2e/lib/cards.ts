/**
 * Card selection utilities for E2E tests.
 *
 * The project / item pages render lists of `clickable_card` components whose
 * data-testid is `card_<id>`. Picking cards positionally (`.first()`, `.last()`)
 * is brittle on long-lived environments (e.g. dev) because accumulated state
 * from prior runs shifts the list.
 *
 * Use `snapshotCardTestids` + `pickNewCardTestid` around a create action to
 * deterministically pick the single newly-added card, regardless of sort
 * order or pre-existing cards.
 */

import { Page } from '@playwright/test';

export const CARD_SELECTOR = "[data-testid^='card_']";

/**
 * Capture the data-testid of all card_* elements currently in the DOM.
 * Use as a "before" snapshot, paired with `pickNewCardTestid` after the
 * create action.
 */
export async function snapshotCardTestids(page: Page): Promise<(string | null)[]> {
  return await page.locator(CARD_SELECTOR).evaluateAll(
    (els: Element[]) => els.map((el) => el.getAttribute('data-testid'))
  );
}

/**
 * Returns the data-testid of the single card that appeared after a creation
 * step — by diffing against the testids captured before the click. Waits for
 * the new card to be rendered (LiveView event → server → DOM patch is async).
 *
 * Throws if zero or more than one new card appears.
 */
export async function pickNewCardTestid(
  page: Page,
  before: (string | null)[]
): Promise<string> {
  await page.waitForFunction(
    ({ selector, expectedCount }: { selector: string; expectedCount: number }) =>
      document.querySelectorAll(selector).length >= expectedCount,
    { selector: CARD_SELECTOR, expectedCount: before.length + 1 },
    { timeout: 10000 }
  );
  const after = await snapshotCardTestids(page);
  const newCards = after.filter((id): id is string => id !== null && !before.includes(id));
  if (newCards.length === 0) {
    throw new Error(`No new card found. Before: [${before.join(', ')}]. After: [${after.join(', ')}]`);
  }
  if (newCards.length > 1) {
    throw new Error(`Multiple new cards found: [${newCards.join(', ')}]. Expected exactly one.`);
  }
  return newCards[0];
}
