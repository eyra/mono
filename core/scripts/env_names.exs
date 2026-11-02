# Environment variable names: what production sets, what staging sets and what
# the release reads, so a name that one deployment lacks shows up before a
# release depends on it. Prints names only, never values.
#
# Production: the `Environment=` lines of the systemd unit template in
# eyra/devops (ansible/roles/predeploy/templates/bundle.service). Staging: the
# `[env]` table of fly.staging.toml, the `--env` names its deploy workflow
# passes and the app's Fly secrets (`fly secrets list --json`). The release
# reads: the names in config/runtime.exs and Core.RuntimeConfig, the names lib
# code reads with System.get_env/fetch_env, the names rel/env.sh.eex reads and
# those of the Elixir release start script.
#
# Fails when a name the release requires (System.fetch_env!/1 or
# Core.RuntimeConfig.fetch!/2) is missing on either side, or when a name differs
# between production and staging (read but set on one side only, or set but
# never read) and env_names_accepted.exs does not list it with a reason.
#
# Usage (from core/):
#   elixir scripts/env_names.exs --prod-unit <devops>/ansible/roles/predeploy/templates/bundle.service \
#     --staging-app eyra-next-staging
#   elixir scripts/env_names.exs --prod-unit <file> --staging-secrets <fly secrets list --json output>
# Tests: elixir scripts/env_names_test.exs

Code.require_file("env_names.ex", __DIR__)

EnvNames.main(System.argv())
