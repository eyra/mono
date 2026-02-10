# Load Tests

Artillery-based load tests for the data donation API.

## Setup

```bash
cd core/test/load
npm run setup  # Installs dependencies and generates test data files
```

This generates random binary files (1MB, 10MB, 100MB, 200MB) for upload testing. These files are gitignored and must be regenerated on each machine.

## Prerequisites

1. Create a service user on the target server (e.g., `service-loadtest@eyra.local`)
2. Set a strong password for the service user
3. Ensure assignment 1 has a storage endpoint configured

## Running Tests

```bash
export BASE_URL=https://eyra-staging.fly.dev
export SERVICE_EMAIL=service-loadtest@eyra.local
export SERVICE_PASSWORD=your_password
export ASSIGNMENT_ID=4

# Quick test: 2 uploads
npm run test:quick

# Default: 5 uploads over 1 minute
npm test

# Full load test: 55 uploads over 5 minutes
npm run test:full
```

## How It Works

1. Artillery logs in via `POST /api/service/login` with email/password
2. Captures the session cookie from the response
3. Uses the cookie for all subsequent upload requests to `/api/feldspar/donate`

## Test Configurations

| Environment | Uploads | Duration |
|-------------|---------|----------|
| quick       | 2       | 60s      |
| default     | 5       | 60s      |
| full        | 55      | 5min     |
