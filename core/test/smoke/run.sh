#!/usr/bin/env bash
# Run smoke tests against a named environment.
#
# Usage:
#   ./run.sh dev              # https://eyra-next-dev.fly.dev
#   ./run.sh staging          # https://eyra-next-staging.fly.dev
#   ./run.sh test1            # https://eyra-next-test1.fly.dev
#   ./run.sh test2            # https://eyra-next-test2.fly.dev
#   ./run.sh prod             # https://eyra-next-prod.fly.dev (TODO: AWS URL)
#   ./run.sh dev --headed     # pass extra args to playwright

set -e

cd "$(dirname "$0")"

# First arg is env name only if it doesn't start with '-'
if [[ "${1:-}" =~ ^(dev|staging|test1|test2|prod)$ ]]; then
  ENV="$1"
  shift
else
  ENV="prod"
fi

case "$ENV" in
  dev)      BASE_URL="https://eyra-next-dev.fly.dev" ;;
  staging)  BASE_URL="https://eyra-next-staging.fly.dev" ;;
  test1)    BASE_URL="https://eyra-next-test1.fly.dev" ;;
  test2)    BASE_URL="https://eyra-next-test2.fly.dev" ;;
  prod)     BASE_URL="https://next.eyra.co" ;;
  *)        echo "Unknown environment: $ENV"; echo "Usage: $0 [dev|staging|test1|test2|prod]"; exit 1 ;;
esac

echo "=== Smoke tests against $ENV ($BASE_URL) ==="

export SMOKE_BASE_URL="$BASE_URL"
exec npx playwright test "$@"
