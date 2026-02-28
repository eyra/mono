# E2E Tests

Playwright-based end-to-end tests for the Next platform.

## Environment Variables

Configure these in Infisical per environment:

| Variable | Required | Description |
|----------|----------|-------------|
| `E2E_BASE_URL` | Yes | Base URL of the environment (e.g., `https://eyra-next-test1.fly.dev`) |
| `E2E_RESEARCHER_EMAIL` | For `panl_study_advert` | Test researcher account email |
| `E2E_RESEARCHER_PASSWORD` | For `panl_study_advert` | Test researcher account password |
| `E2E_DONATE_ASSIGNMENT_PATH` | For `donate` | Assignment affiliate path (e.g., `/a/GAyz7L`) |
| `E2E_DONATE_DATA_SOURCE` | No | Data source type, defaults to `tiktok` |

## Running Tests

### With Infisical

```bash
cd core/test/e2e

# Run all tests against test1
infisical run --projectId="Next E2E" --env=test1 -- npx playwright test

# Run specific test
infisical run --projectId="Next E2E" --env=test1 -- npx playwright test panl_study_advert.spec.ts

# Run headed (visible browser)
infisical run --projectId="Next E2E" --env=test1 -- npx playwright test --headed

# Run with specific browser
infisical run --projectId="Next E2E" --env=test1 -- npx playwright test --project=chromium
```

### Manual (with env vars)

```bash
E2E_BASE_URL=https://eyra-next-test1.fly.dev \
E2E_RESEARCHER_EMAIL=test@example.com \
E2E_RESEARCHER_PASSWORD=secret \
npx playwright test
```

## Test Accounts Setup

### Researcher Account

Create a verified researcher account on each environment:

```bash
fly ssh console -a <app> -C '/opt/app/bin/core rpc "
  {:ok, user} = Systems.Account.Public.register_user(%{
    email: \"test-researcher@eyra.co\",
    password: \"YourSecurePassword\"
  })
  now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  user
  |> Ecto.Changeset.change(%{confirmed_at: now, verified_at: now, creator: true})
  |> Core.Repo.update!()
"'
```

### PaNL Pool

Ensure the PaNL pool exists:

```bash
fly ssh console -a <app> -C '/opt/app/bin/core rpc "
  Systems.Pool.Assembly.get_or_create_panl()
"'
```

## Tests

| Test | Description |
|------|-------------|
| `donate.spec.ts` | Data donation flow via Feldspar |
| `panl_onboarding.spec.ts` | PaNL participant signup and onboarding |
| `panl_study_advert.spec.ts` | Researcher creates study, advert, and publishes |
