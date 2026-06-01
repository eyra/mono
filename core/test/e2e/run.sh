#!/usr/bin/env bash
# Run E2E tests with the right SERVICE_LOGIN_KEY for the target environment.
#
# Usage:
#   ./run.sh                                          # local server
#   E2E_BASE_URL=https://eyra-next-dev.fly.dev ./run.sh --headed
#   E2E_BASE_URL=https://eyra-next-dev.fly.dev ./run.sh approve_reward.spec.ts --headed

set -e

# Always run from the e2e directory regardless of how the script is invoked
cd "$(dirname "$0")"

BASE_URL="${E2E_BASE_URL:-http://localhost:4000}"

if [[ "$BASE_URL" == *"fly.dev"* ]]; then
  APP=$(echo "$BASE_URL" | sed 's|https://||; s|\.fly\.dev.*||')
  echo "=== Fetching SERVICE_LOGIN_KEY from $APP ==="
  MACHINE=$(fly machine list -a "$APP" --json 2>/dev/null \
    | python3 -c "import sys,json; ms=json.load(sys.stdin); print(ms[0]['id'])" 2>/dev/null)
  KEY=$(fly machine exec "$MACHINE" "printenv SERVICE_LOGIN_KEY" -a "$APP" 2>/dev/null \
    | tr -d '\r\n')
  if [[ -z "$KEY" ]]; then
    echo "ERROR: Could not fetch SERVICE_LOGIN_KEY from $APP" >&2
    exit 1
  fi
  echo "=== Key fetched (${#KEY} chars) ==="
else
  # Local server uses the hardcoded dev key (set in config/dev.exs)
  KEY="dev-test-key"
fi

export E2E_BASE_URL="$BASE_URL"
export SERVICE_LOGIN_KEY="$KEY"
exec npx playwright test "$@"
