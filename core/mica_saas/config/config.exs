import Config

config :core, saas: Self.SaaS

# An unconfigured flag is on (Core.FeatureFlags.conf_enabled?/1), and
# ENABLED_APP_FEATURES can only switch flags on. The E2E API confirms accounts
# and hands out a service password, so it must be off here.
config :core, :features,
  e2e: false,
  debug_expire_force: false
