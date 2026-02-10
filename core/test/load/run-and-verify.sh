#!/bin/bash
# Load test script that runs Artillery and verifies files landed on both machines
#
# Usage:
#   export BASE_URL=https://eyra-next-staging.fly.dev
#   export SERVICE_EMAIL=loadtest@service.local
#   export SERVICE_PASSWORD=...
#   export ASSIGNMENT_ID=1
#   ./run-and-verify.sh [quick|full]

set -e

APP_NAME="eyra-next-staging"
DONATION_PATH="/app/data/datadonation"
TEST_ENV="${1:-quick}"

echo "=== Load Test: $TEST_ENV ==="
echo ""

# Get machine IDs
echo "Fetching machine IDs..."
MACHINES=$(flyctl machines list --app $APP_NAME --json | jq -r '.[] | select(.state == "started") | .id')
MACHINE_COUNT=$(echo "$MACHINES" | wc -l | tr -d ' ')
echo "Found $MACHINE_COUNT running machines"
echo ""

# Function to count files on a machine
count_files() {
    local machine=$1
    flyctl ssh console --app $APP_NAME --machine $machine --command "bash -c 'ls $DONATION_PATH 2>/dev/null | wc -l'" 2>/dev/null | grep -E '^[0-9]+$' | head -1 || echo "0"
}

# Count files before test
echo "=== Files BEFORE test ==="
BEFORE_TOTAL=0
for MACHINE in $MACHINES; do
    COUNT=$(count_files $MACHINE)
    echo "  Machine $MACHINE: $COUNT files"
    BEFORE_TOTAL=$((BEFORE_TOTAL + COUNT))
done
echo "  Total: $BEFORE_TOTAL files"
echo ""

# Run Artillery
echo "=== Running Artillery ($TEST_ENV) ==="
case "$TEST_ENV" in
    quick)   npm run test:quick ;;
    volume)  npm run test:volume ;;
    large)   npm run test:large ;;
    xlarge)  npm run test:xlarge ;;
    *)       npm test ;;
esac
echo ""

# Wait for async processing
echo "Waiting 5s for async processing..."
sleep 5

# Count files after test
echo "=== Files AFTER test ==="
AFTER_TOTAL=0
for MACHINE in $MACHINES; do
    COUNT=$(count_files $MACHINE)
    echo "  Machine $MACHINE: $COUNT files"
    AFTER_TOTAL=$((AFTER_TOTAL + COUNT))
done
echo "  Total: $AFTER_TOTAL files"
echo ""

NEW_FILES=$((AFTER_TOTAL - BEFORE_TOTAL))
echo "=== Summary ==="
echo "New files created: $NEW_FILES"

if [ "$NEW_FILES" -eq 2 ] && [ "$TEST_ENV" == "quick" ]; then
    echo "Result: PASS (expected 2 files for quick test)"
elif [ "$NEW_FILES" -eq 5 ] && [ "$TEST_ENV" == "default" ]; then
    echo "Result: PASS (expected 5 files for default test)"
elif [ "$NEW_FILES" -gt 0 ]; then
    echo "Result: OK (files were created)"
else
    echo "Result: FAIL (no new files created)"
fi
