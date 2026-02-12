#!/bin/bash
# Wake staging machines and keep them running
#
# Usage: ./staging-wake.sh
#
# This script:
# 1. Disables auto-stop (prevents auto-suspend)
# 2. Starts all machines if suspended
# 3. Waits for health checks

set -e

APP_NAME="eyra-next-staging"

echo "=== Waking staging ($APP_NAME) ==="
echo ""

# Get all machine IDs
MACHINES=$(fly machines list -a "$APP_NAME" --json | jq -r '.[].id')
MACHINE_COUNT=$(echo "$MACHINES" | wc -l | tr -d ' ')

echo "Found $MACHINE_COUNT machines"
echo ""

# Start any stopped/suspended machines first
echo "Starting machines..."
for MACHINE_ID in $MACHINES; do
  STATE=$(fly machines list -a "$APP_NAME" --json | jq -r ".[] | select(.id == \"$MACHINE_ID\") | .state")
  echo "  $MACHINE_ID: $STATE"

  if [ "$STATE" = "stopped" ] || [ "$STATE" = "suspended" ]; then
    echo "    Starting..."
    fly machines start "$MACHINE_ID" -a "$APP_NAME"
  fi
done
echo ""

# Wait for all machines to be started
echo "Waiting for machines to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ALL_STARTED=true

  for MACHINE_ID in $MACHINES; do
    STATE=$(fly machines list -a "$APP_NAME" --json | jq -r ".[] | select(.id == \"$MACHINE_ID\") | .state")
    if [ "$STATE" != "started" ]; then
      ALL_STARTED=false
      break
    fi
  done

  if [ "$ALL_STARTED" = true ]; then
    echo "All machines are running!"
    break
  fi

  ATTEMPT=$((ATTEMPT + 1))
  echo "  Attempt $ATTEMPT/$MAX_ATTEMPTS..."
  sleep 2
done
echo ""

# Disable auto-stop on all machines to prevent suspension
echo "Disabling auto-stop on all machines..."
for MACHINE_ID in $MACHINES; do
  echo "  Updating $MACHINE_ID..."
  fly machine update "$MACHINE_ID" --autostop=off -a "$APP_NAME" --skip-health-checks -y
done

echo ""
echo "=== Staging is awake and will stay running ==="
echo "Run ./staging-suspend.sh when done to allow auto-suspend"
