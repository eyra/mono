#!/bin/sh
# Runs phoenix_routes.exs in the Mix project and prints its JSON. Mix and the
# app may print to stdout while they compile and load, so the script writes
# its output to a file.
#   sh phoenix_routes.sh SCRIPT CTX
set -eu
script=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
out=$(mktemp)
trap 'rm -f "$out"' EXIT
cd core
mix compile >&2
ROUTES_SCRIPT="$script" mix eval 'Code.eval_file(System.fetch_env!("ROUTES_SCRIPT"))' "$2" "$out" >&2 </dev/null
cat "$out"
