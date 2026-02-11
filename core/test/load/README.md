# Load Tests

Artillery-based load tests for the data donation API.

## Setup

```bash
cd core/test/load
npm run setup  # Installs dependencies and generates test data files
```

This generates random binary files (1MB, 10MB, 100MB, 200MB) for upload testing. These files are gitignored and must be regenerated on each machine.

## Prerequisites

1. Create a service user with `@eyra.service` domain (e.g., `loadtest@eyra.service`)
   - Must be verified by an admin (the domain doesn't exist, so email verification won't work)
2. Set a strong password for the service user
3. Get the SERVICE_KEY for your environment (ask admin or check vault/fly secrets)
4. Ensure the target assignment has a storage endpoint configured

## Running Tests

```bash
export BASE_URL=https://eyra-staging.fly.dev
export SERVICE_EMAIL=loadtest@eyra.service
export SERVICE_PASSWORD=your_password
export SERVICE_KEY=your_service_key
export ASSIGNMENT_ID=4

# Quick test: 2 uploads
npm run test:quick

# Default: 5 uploads over 1 minute
npm test

# Full load test: 55 uploads over 5 minutes
npm run test:full
```

## How It Works

1. Artillery logs in via `POST /api/service/login` with:
   - `X-Service-Key` header (must match server's SERVICE_LOGIN_KEY)
   - Email (must end with `@eyra.service`)
   - Password
2. Captures the session cookie from the response
3. Uses the cookie for all subsequent upload requests to `/api/feldspar/donate`

## Test Configurations

| Environment | Uploads | Duration |
|-------------|---------|----------|
| quick       | 2       | 60s      |
| default     | 5       | 60s      |
| full        | 55      | 5min     |
