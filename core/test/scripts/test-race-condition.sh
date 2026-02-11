#!/bin/bash
# Quick race condition test - sends 5 concurrent requests to same participant URL
# Usage: ./test-race-condition.sh <base_url> <assignment_id>
# Example: ./test-race-condition.sh https://next.dev.eyra.co 458
# Example: ./test-race-condition.sh https://eyra-next-test1.fly.dev 1
#
# Expected results:
# - Without fix: 500 200 200 200 200 (first response is the failing one, returns faster)
# - With fix:    200 200 200 200 200 (all succeed)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOAD_DIR="${SCRIPT_DIR}/../load"

BASE_URL=${1:-https://next.dev.eyra.co}
ASSIGNMENT_ID=${2:-458}

SQID=$(cd "$LOAD_DIR" && node -e "const Sqids = require('sqids').default; const s = new Sqids({minLength: 6, alphabet: 'ib09gZ5ICaXJKHtLAvu6Rj4yGwsofN1p8nxWeFQYVcBz7lkqP23dTSErMODmhU'}); console.log(s.encode([0, ${ASSIGNMENT_ID}]))")
PARTICIPANT="race_test_$(date +%s)"
URL="${BASE_URL}/a/${SQID}?p=${PARTICIPANT}"

echo "Testing: ${URL}"
echo -n "Results: "
for i in {1..5}; do
  curl -sL -o /dev/null -w "%{http_code} " "$URL" &
done
wait
echo ""
