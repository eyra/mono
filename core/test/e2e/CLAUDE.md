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

### 3. Wait on the destination, not on `.phx-connected`
After a navigation or action, wait on a `data-testid` of the **target page**.
Playwright's `expect(...).toBeVisible()` auto-polls — that one assertion both
waits for the navigation and verifies the target rendered. Don't wait on
`.phx-connected`: it's framework state of the source page, doesn't prove the
next page is ready, and forces the browser to tear down an active LiveView
WebSocket on the next action.

See `core/test/CLAUDE.md` → "Waiting After Navigation — Project Policy" for
the same rule applied to Wallaby feature tests.

```typescript
// ✅ wait on a user-visible element of the target page
await page.goto('/user/onboarding');
await expect(page.locator('[data-testid="profile-view"]')).toBeVisible();

// ❌ don't gate on the source page's WebSocket
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

## Infisical Configuration

E2E tests use Infisical for environment-specific secrets. The workspace is configured in `.infisical.json`.

### Required secrets per environment

| Secret | Description |
|--------|-------------|
| `E2E_BASE_URL` | Target server URL (e.g., `https://eyra-next-staging.fly.dev`) |
| `E2E_RESEARCHER_EMAIL` | Test researcher account email |
| `E2E_RESEARCHER_PASSWORD` | Test researcher account password |
| `E2E_PARTICIPANT_EMAIL` | Test participant account email |
| `E2E_PARTICIPANT_PASSWORD` | Test participant account password |
| `E2E_DONATE_ASSIGNMENT_PATH` | Assignment path for donate tests (e.g., `/a/nWPk4K`) |
| `SERVICE_LOGIN_KEY` | Must match the Fly secret for E2E bootstrap |

The enabled feature set is discovered automatically via `GET /api/e2e/features` during global-setup, so it does not need to be mirrored in Infisical. Feature-specific tests (e.g., PaNL tests) declare their required flags via `missingFeaturesReason(...)` in `lib/features.ts` and skip when those flags aren't enabled on the target environment.

## Running Tests

```bash
# Against localhost
E2E_BASE_URL=http://localhost:4000 npx playwright test --project=chromium

# Against test environment (uses Infisical for secrets)
infisical run --env=test1 -- npx playwright test --project=chromium

# Against staging
infisical run --env=staging -- npx playwright test --project=chromium

# Single test file
infisical run --env=staging -- npx playwright test donate.spec.ts --project=chromium

# Headed mode (see browser)
infisical run --env=staging -- npx playwright test donate.spec.ts --project=chromium --headed
```

## Timeout Guidelines

| Operation | Timeout |
|-----------|---------|
| Element visibility | 3s |
| Page navigation | 5s |
| LiveView connection | 5s |
| Global test timeout | 30s |
