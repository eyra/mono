#!/bin/bash
# Allow staging machines to auto-suspend when idle
#
# Usage: ./staging-suspend.sh
#
# This script:
# 1. Enables auto-stop=suspend (allows auto-suspend when idle)
# 2. Machines will suspend automatically when there's no traffic

set -e

APP_NAME="eyra-next-staging"

echo "=== Enabling auto-suspend for staging ($APP_NAME) ==="
echo ""

# Get all machine IDs
MACHINES=$(fly machines list -a "$APP_NAME" --json | jq -r '.[].id')
MACHINE_COUNT=$(echo "$MACHINES" | wc -l | tr -d ' ')

echo "Found $MACHINE_COUNT machines"
echo ""

# Enable auto-stop=suspend on all machines
echo "Enabling auto-stop=suspend on all machines..."
for MACHINE_ID in $MACHINES; do
  echo "  Updating $MACHINE_ID..."
  fly machine update "$MACHINE_ID" --autostop=suspend --autostart -a "$APP_NAME" --skip-health-checks -y
done
echo ""

# Show current state
echo "Current machine states:"
fly machines list -a "$APP_NAME" --json | jq -r '.[] | "  \(.id): \(.state)"'

echo ""
echo "=== Auto-suspend enabled ==="
echo "Machines will suspend when idle. Run ./staging-wake.sh to wake them."
