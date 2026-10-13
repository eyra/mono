#!/usr/bin/env bash
# Run smoke tests against a named environment.
#
# Usage:
#   ./run.sh dev              # https://eyra-next-dev.fly.dev
#   ./run.sh staging          # https://eyra-next-staging.fly.dev
#   ./run.sh prod             # https://eyra-next-prod.fly.dev (TODO: AWS URL)
#   ./run.sh dev --headed     # pass extra args to playwright

set -e

cd "$(dirname "$0")"

# First arg is env name only if it doesn't start with '-'
if [[ "${1:-}" =~ ^(dev|staging|prod)$ ]]; then
  ENV="$1"
  shift
else
  ENV="prod"
fi

case "$ENV" in
  dev)      BASE_URL="https://eyra-next-dev.fly.dev" ;;
  staging)  BASE_URL="https://eyra-next-staging.fly.dev" ;;
  prod)     BASE_URL="https://next.eyra.co" ;;
  *)        echo "Unknown environment: $ENV"; echo "Usage: $0 [dev|staging|prod]"; exit 1 ;;
esac

echo "=== Smoke tests against $ENV ($BASE_URL) ==="

export SMOKE_BASE_URL="$BASE_URL"
export SMOKE_ENV="$ENV"
exec npx playwright test "$@"
