#!/usr/bin/env bash
# Run smoke tests against a target environment.
#
# Usage:
#   ./run.sh                                        # dev (default)
#   SMOKE_BASE_URL=https://eyra-next-prod.fly.dev ./run.sh

set -e

cd "$(dirname "$0")"

BASE_URL="${SMOKE_BASE_URL:-https://eyra-next-dev.fly.dev}"
echo "=== Smoke tests against $BASE_URL ==="

export SMOKE_BASE_URL="$BASE_URL"
exec npx playwright test "$@"
