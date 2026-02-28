# Load Tests

Artillery-based load tests for the Next platform.

## Setup

```bash
cd core/test/load
npm run setup  # Installs dependencies and generates test data files
```

This generates random binary files (1MB, 10MB, 100MB, 200MB) for upload testing. These files are gitignored and must be regenerated on each machine.

## Environment Variables

Configure these in Infisical (`Next Load` project) per environment:

| Variable | Required | Description |
|----------|----------|-------------|
| `LOAD_BASE_URL` | Yes | Target URL (e.g., `https://eyra-next-test1.fly.dev`) |
| `LOAD_SERVICE_EMAIL` | For donate | Service user email (e.g., `loadtest@eyra.service`) |
| `LOAD_SERVICE_PASSWORD` | For donate | Service user password |
| `LOAD_SERVICE_KEY` | For donate | X-Service-Key header value |
| `LOAD_ASSIGNMENT_ID` | For donate | Assignment ID for donations |
| `LOAD_FILE_SIZE_MB` | No | File size: 1, 10, 100, or 200 (default: 1) |

## Running Tests

### With Infisical

```bash
cd core/test/load

# Donate tests
infisical run --projectId="Next Load" --env=test1 -- npm run test:quick
infisical run --projectId="Next Load" --env=test1 -- npm run test:volume
infisical run --projectId="Next Load" --env=test1 -- npm run test:large

# Affiliate tests
infisical run --projectId="Next Load" --env=test1 -- npm run test:affiliate
infisical run --projectId="Next Load" --env=test1 -- npm run test:affiliate-race
```

### Manual (with env vars)

```bash
export LOAD_BASE_URL=https://eyra-next-test1.fly.dev
export LOAD_SERVICE_EMAIL=loadtest@eyra.service
export LOAD_SERVICE_PASSWORD=your_password
export LOAD_SERVICE_KEY=your_service_key
export LOAD_ASSIGNMENT_ID=4

npm run test:quick
```

## Service User Setup

Create a service user on each environment:

```bash
fly ssh console -a <app> -C '/opt/app/bin/core rpc "
  {:ok, user} = Systems.Account.Public.register_user(%{
    email: \"loadtest@eyra.service\",
    password: \"YourSecurePassword\"
  })
  now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  user
  |> Ecto.Changeset.change(%{confirmed_at: now, verified_at: now})
  |> Core.Repo.update!()
"'
```

The `@eyra.service` domain is required for service login. The `LOAD_SERVICE_KEY` must match the server's `SERVICE_LOGIN_KEY` secret.

## Test Configurations

### Donate Tests

| Test | Uploads | Duration | Use Case |
|------|---------|----------|----------|
| `test:quick` | 2 | 60s | Sanity check |
| `test:volume` | 320 | ~2min | Concurrent load (use FILE_SIZE_MB=1 or 10) |
| `test:large` | 50 | 150s | Large file handling (use FILE_SIZE_MB=100) |
| `test:xlarge` | 10 | 20s | Max size stress test (FILE_SIZE_MB=200) |

### Affiliate Tests

| Test | Description |
|------|-------------|
| `test:affiliate` | Concurrent affiliate requests |
| `test:affiliate-quick` | Quick race condition test |
| `test:affiliate-race` | Same-user concurrent access |
| `test:affiliate-session` | Session verification after redirect |

## How It Works

1. Artillery logs in via `POST /api/service/login` with:
   - `X-Service-Key` header (must match server's SERVICE_LOGIN_KEY)
   - Email (must end with `@eyra.service`)
   - Password
2. Captures the session cookie from the response
3. Uses the cookie for all subsequent upload requests to `/api/feldspar/donate`
