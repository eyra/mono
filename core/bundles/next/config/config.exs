import Config

config :core,
  start_pages: Next.StartPages,
  menu_items: Next.Menu.Items,
  workspace_menu_builder: Next.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Next.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Next.Layouts.Stripped.MenuBuilder

config :core, CoreWeb.UserAuth,
  researcher_signed_in_page: "/project",
  participant_signed_in_page: "/project"

config :core, :features,
  sign_in_with_apple: false,
  member_google_sign_in: false,
  password_sign_in: true,
  notification_mails: false,
  debug_expire_force: false

config :core, :meta,
  bundle_title: "Eyra",
  bundle: :next
