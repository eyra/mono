#!/bin/bash
# Fly.io Cost Calculator for Eyra apps
# Shows current running costs based on machine state

set -e

# Pricing (approximate, per month)
# shared-cpu-1x: $5.70 base + memory
# shared-cpu-2x: $10.70 base + memory
# Memory: $6/GB/month
# Volume: $0.15/GB/month

calc_machine_cost() {
  local cpus=$1
  local cpu_kind=$2
  local memory_mb=$3
  local state=$4

  if [[ "$state" != "started" && "$state" != "running" ]]; then
    echo "0"
    return
  fi

  local cpu_cost=0
  if [[ "$cpu_kind" == "shared" ]]; then
    cpu_cost=$(echo "$cpus * 5.70" | bc)
  else
    cpu_cost=$(echo "$cpus * 30" | bc)  # performance CPUs
  fi

  local mem_cost=$(echo "$memory_mb / 1024 * 6" | bc -l)
  local total=$(echo "$cpu_cost + $mem_cost" | bc -l)
  printf "%.2f" "$total"
}

calc_volume_cost() {
  local size_gb=$1
  echo $(echo "$size_gb * 0.15" | bc -l)
}

echo "======================================"
echo "  Fly.io Cost Report - $(date +%Y-%m-%d)"
echo "======================================"
echo ""

total_running=0
total_volumes=0

# Get all eyra apps
apps=$(fly apps list --json 2>/dev/null | jq -r '.[] | select(.Name | startswith("eyra-")) | .Name' | sort)

printf "%-25s %-12s %-20s %10s %10s\n" "APP" "STATE" "SPECS" "RUN/mo" "VOL/mo"
printf "%s\n" "--------------------------------------------------------------------------------"

for app in $apps; do
  # Get machines
  machines=$(fly machine list -a "$app" --json 2>/dev/null)
  machine_count=$(echo "$machines" | jq 'length')

  if [[ "$machine_count" == "0" ]]; then
    printf "%-25s %-12s %-20s %10s %10s\n" "$app" "no machines" "-" "-" "-"
    continue
  fi

  # Get volumes
  volumes=$(fly volumes list -a "$app" --json 2>/dev/null || echo "[]")
  vol_total=0
  vol_size=$(echo "$volumes" | jq -r '[.[].size_gb // 0] | add // 0')
  if [[ -n "$vol_size" && "$vol_size" != "null" ]]; then
    vol_total=$(calc_volume_cost "$vol_size")
    total_volumes=$(echo "$total_volumes + $vol_total" | bc -l)
  fi

  # Process each machine
  echo "$machines" | jq -c '.[]' | while read -r machine; do
    state=$(echo "$machine" | jq -r '.state')
    cpus=$(echo "$machine" | jq -r '.config.guest.cpus // 1')
    cpu_kind=$(echo "$machine" | jq -r '.config.guest.cpu_kind // "shared"')
    memory_mb=$(echo "$machine" | jq -r '.config.guest.memory_mb // 256')

    specs="${cpus}x ${cpu_kind}, ${memory_mb}MB"
    cost=$(calc_machine_cost "$cpus" "$cpu_kind" "$memory_mb" "$state")

    if [[ "$state" == "started" || "$state" == "running" ]]; then
      state_display="RUNNING"
    else
      state_display="$state"
    fi

    printf "%-25s %-12s %-20s %10s %10s\n" "$app" "$state_display" "$specs" "\$$cost" "\$$vol_total"

    # Only count volume once per app (first machine)
    vol_total=0
  done

  # Accumulate running costs (do in subshell workaround)
done

echo ""
echo "======================================"

# Calculate totals properly
echo ""
echo "Calculating totals..."
echo ""

running_total=0
volume_total=0

for app in $apps; do
  machines=$(fly machine list -a "$app" --json 2>/dev/null)

  # Running machines cost
  while read -r line; do
    if [[ -n "$line" ]]; then
      state=$(echo "$line" | jq -r '.state')
      if [[ "$state" == "started" || "$state" == "running" ]]; then
        cpus=$(echo "$line" | jq -r '.config.guest.cpus // 1')
        cpu_kind=$(echo "$line" | jq -r '.config.guest.cpu_kind // "shared"')
        memory_mb=$(echo "$line" | jq -r '.config.guest.memory_mb // 256')
        cost=$(calc_machine_cost "$cpus" "$cpu_kind" "$memory_mb" "$state")
        running_total=$(echo "$running_total + $cost" | bc -l)
      fi
    fi
  done < <(echo "$machines" | jq -c '.[]')

  # Volume cost
  volumes=$(fly volumes list -a "$app" --json 2>/dev/null || echo "[]")
  vol_size=$(echo "$volumes" | jq -r '[.[].size_gb // 0] | add // 0')
  if [[ -n "$vol_size" && "$vol_size" != "null" && "$vol_size" != "0" ]]; then
    vol_cost=$(calc_volume_cost "$vol_size")
    volume_total=$(echo "$volume_total + $vol_cost" | bc -l)
  fi
done

printf "RUNNING MACHINES:  \$%.2f/month\n" "$running_total"
printf "VOLUMES (always):  \$%.2f/month\n" "$volume_total"
printf "─────────────────────────────────\n"
printf "TOTAL CURRENT:     \$%.2f/month\n" "$(echo "$running_total + $volume_total" | bc -l)"
echo ""
