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
  sign_in_with_apple: false,
  surfconext_sign_in: false,
  member_google_sign_in: true,
  password_sign_in: true,
  notification_mails: false,
  debug_expire_force: false,
  leaderboard: true,
  panl: true,
  panl_post_launch: false,
  onyx: false,
  e2e: false

config :core, :meta,
  bundle_title: "Next",
  bundle: :next

config :core, :account,
  oauth_providers: %{
    "surfconext" => %{
      name: "SURFconext",
      logo: "/images/logos/platforms/surfconext.svg",
      auth_path: "/auth/surfconext"
    },
    "google" => %{
      name: "Google",
      logo: "/images/logos/platforms/google.svg",
      auth_path: "/auth/google"
    },
    "centerdata" => %{
      name: "Centerdata (LISS)",
      logo: "/images/logos/platforms/centerdata.svg",
      auth_path: "/centerdata"
    }
  }
