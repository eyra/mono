import Config

config :core,
  start_pages: Self.StartPages,
  menu_items: Self.Menu.Items,
  workspace_menu_builder: Self.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Self.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Self.Layouts.Stripped.MenuBuilder

config :core, Systems.Account.UserAuth,
  creator_signed_in_page: "/project",
  member_signed_in_page: "/"

# An unconfigured flag is on (Core.FeatureFlags.conf_enabled?/1), and
# ENABLED_APP_FEATURES can only switch flags on. The E2E API confirms accounts
# and hands out a service password, so it must be off here.
config :core, :features,
  e2e: false,
  debug_expire_force: false

config :core, :meta,
  bundle_title: "Self",
  bundle: :port
