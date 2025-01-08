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

config :core, :features,
  sign_in_with_apple: false,
  surfconext_sign_in: false,
  member_google_sign_in: true,
  password_sign_in: true,
  notification_mails: false,
  debug_expire_force: false,
  leaderboard: true,
  panl: false,
  onyx: false

config :core, :meta,
  bundle_title: "Next",
  bundle: :next
