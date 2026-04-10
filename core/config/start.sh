#!/bin/bash
eval "$(infisical export --env=local --format=dotenv-export)"
if [ -f .env ]; then
  set -a
  source .env
  set +a
fi
exec iex -S mix phx.server
