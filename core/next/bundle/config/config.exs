import Config

config :core,
  start_pages: Next.StartPages,
  menu_items: Next.Menu.Items,
  workspace_menu_builder: Next.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Next.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Next.Layouts.Stripped.MenuBuilder

config :core, Systems.Account.UserAuth,
  creator_signed_in_page: "/project",
  member_signed_in_page: "/"

# Feature flags: these are the defaults for local dev.
# On Fly/AWS, ENABLED_APP_FEATURES merges on top: listed flags become true,
# unlisted flags keep their default from this config.
config :core, :features,
  surfconext_sign_in: false,
  centerdata_sign_in: false,
  member_google_sign_in: true,
  password_sign_in: true,
  debug_expire_force: false,
  leaderboard: true,
  panl: true,
  panl_post_launch: false,
  opp_phase_3: false,
  onyx: false,
  otp: false,
  e2e: false

config :core, :meta,
  bundle_title: "Next",
  bundle: :next

config :core, :account,
  auth_methods: %{
    surfconext: %{provider: true, satellite: true},
    centerdata: %{provider: true, satellite: true},
    google: %{provider: true, satellite: true, mx_provider: "google"},
    email: %{provider: false, satellite: true}
  }

config :core, :pixel, pool_assets: [:panl, :panl_wide, :panl_dark, :panl_wide_dark]
