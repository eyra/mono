#!/bin/bash
# Verify data donations on AWS or Fly
#
# Usage:
#   export PLATFORM=aws   # or fly
#   ./verify-donations.sh [before|after|count]
#
# Examples:
#   ./verify-donations.sh count      # Just show current count
#   ./verify-donations.sh before     # Save count to .before file
#   ./verify-donations.sh after      # Compare with .before file

set -e

PLATFORM="${PLATFORM:-aws}"
ACTION="${1:-count}"
COUNT_FILE=".donation-count-before"

# Function to get AWS hosts from bastion
get_aws_hosts() {
    local env=$1
    ssh bastion.eyra.co "~/devops/ansible/get-web-servers $env" 2>/dev/null | grep -E '^\|.*ec2-web' | awk -F'|' '{print $3}' | tr -d ' ' | tr '\n' ' ' | xargs
}

# Platform-specific config
if [ "$PLATFORM" == "fly" ]; then
    FLY_APP="${FLY_APP:-eyra-next-staging}"
    DONATION_PATH="/app/data/datadonation"
elif [ "$PLATFORM" == "aws" ]; then
    DONATION_PATH="/home/next/datadonation"

    if [ -n "$SSH_HOSTS" ]; then
        : # Use provided SSH_HOSTS
    elif [[ "$BASE_URL" == *"dev"* ]] || [ -z "$BASE_URL" ]; then
        SSH_HOSTS=$(get_aws_hosts dev)
    elif [[ "$BASE_URL" == *"next.eyra.co"* ]]; then
        SSH_HOSTS=$(get_aws_hosts prod)
    fi

    if [ -z "$SSH_HOSTS" ]; then
        echo "Failed to get hosts from bastion"
        exit 1
    fi
else
    echo "Unknown PLATFORM: $PLATFORM (use 'fly' or 'aws')"
    exit 1
fi

# Count functions
count_files_fly() {
    local machine=$1
    flyctl ssh console --app $FLY_APP --machine $machine --command "bash -c 'ls $DONATION_PATH 2>/dev/null | wc -l'" 2>/dev/null | grep -E '^[0-9]+$' | head -1 || echo "0"
}

count_files_aws() {
    local host=$1
    ssh $host "sudo ls $DONATION_PATH 2>/dev/null | wc -l" 2>/dev/null || echo "0"
}

list_files_aws() {
    local host=$1
    ssh $host "sudo ls -la $DONATION_PATH 2>/dev/null | tail -5" 2>/dev/null || echo "(none)"
}

# Get total count
get_total_count() {
    local total=0

    if [ "$PLATFORM" == "fly" ]; then
        MACHINES=$(flyctl machines list --app $FLY_APP --json | jq -r '.[] | select(.state == "started") | .id')
        for MACHINE in $MACHINES; do
            COUNT=$(count_files_fly $MACHINE)
            total=$((total + COUNT))
        done
    else
        for HOST in $SSH_HOSTS; do
            COUNT=$(count_files_aws $HOST)
            total=$((total + COUNT))
        done
    fi

    echo $total
}

# Main
case "$ACTION" in
    count)
        TOTAL=$(get_total_count)
        echo "Current donation files: $TOTAL"
        if [ "$PLATFORM" == "aws" ]; then
            echo ""
            echo "Recent files:"
            FIRST_HOST=$(echo $SSH_HOSTS | awk '{print $1}')
            list_files_aws $FIRST_HOST
        fi
        ;;
    before)
        TOTAL=$(get_total_count)
        echo $TOTAL > $COUNT_FILE
        echo "Saved count: $TOTAL"
        ;;
    after)
        if [ ! -f $COUNT_FILE ]; then
            echo "No .before file found. Run with 'before' first."
            exit 1
        fi
        BEFORE=$(cat $COUNT_FILE)
        AFTER=$(get_total_count)
        NEW=$((AFTER - BEFORE))
        echo "Before: $BEFORE"
        echo "After:  $AFTER"
        echo "New:    $NEW"

        if [ "$PLATFORM" == "aws" ]; then
            echo ""
            echo "Recent files:"
            FIRST_HOST=$(echo $SSH_HOSTS | awk '{print $1}')
            list_files_aws $FIRST_HOST
        fi

        rm -f $COUNT_FILE

        echo ""
        echo "=== Summary ==="
        if [ "$NEW" -gt 0 ]; then
            echo "Result: OK ($NEW new files created)"
        else
            echo "Result: FAIL (no new files created)"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [before|after|count]"
        exit 1
        ;;
esac
