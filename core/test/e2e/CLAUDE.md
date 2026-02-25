# E2E Testing with Playwright + LiveView + Feldspar

## Key Principles

### 1. Never rely on labels
Labels change with translations. Always use `data-testid` attributes.

```typescript
// WRONG - label can change
await page.getByText('Start browsing').click();

// CORRECT - stable selector
await page.locator('[data-testid="onboarding-continue"]').click();
```

### 2. Short timeouts - fail fast
Long timeouts make test development slow. Use 3-5 seconds for most operations.

```typescript
// WRONG - too slow
await expect(element).toBeVisible({ timeout: 30000 });

// CORRECT - fail fast
await expect(element).toBeVisible({ timeout: 3000 });
```

### 3. Wait for specific elements, not just connection
Don't always wait for `.phx-connected`. Wait for the elements you need.

```typescript
// Often sufficient - wait for the element you need
await expect(page.locator('[data-testid="profile-view"]')).toBeVisible();

// Only when you need LiveView interactivity
await page.waitForSelector('[data-phx-main].phx-connected', { timeout: 5000 });
```

### 4. Use data-testid naming conventions
```
element_id          -> card_7, form_signup
action__element_id  -> delete__action__card_7
```

### 5. Adding data-testid to Phoenix components
```elixir
# In LiveView templates
<Button.dynamic {@vm.continue_button} data-testid="onboarding-continue" />

# In regular HTML
<div data-testid="profile-view">
```

## Project Structure

```
core/test/e2e/
├── lib/
│   ├── liveview.ts    # LiveView waiting utilities
│   ├── feldspar.ts    # Feldspar iframe utilities
│   └── index.ts       # Exports
├── playwright.config.ts
├── global-setup.ts
└── *.spec.ts          # Test files
```

## LiveView Page Lifecycle

1. **Static HTML render** (immediate) - forms, content visible
2. **WebSocket connection** (async) - enables phx-click, live updates

Most tests only need to wait for static render. Use `waitForLiveView()` from `lib/liveview.ts` when you need connection.

## Running Tests

```bash
# Against localhost
E2E_BASE_URL=http://localhost:4000 npx playwright test --project=chromium

# Against test environment (uses Infisical for secrets)
npx playwright test --project=chromium

# Single test file
npx playwright test panl_onboarding --project=chromium

# Headed mode (see browser)
npx playwright test panl_onboarding --project=chromium --headed
```

## Timeout Guidelines

| Operation | Timeout |
|-----------|---------|
| Element visibility | 3s |
| Page navigation | 5s |
| LiveView connection | 5s |
| Global test timeout | 30s |
