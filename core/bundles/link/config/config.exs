import Config

config :core,
  start_pages: Link.StartPages,
  menu_items: Link.Menu.Items,
  workspace_menu_builder: Link.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Link.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Link.Layouts.Stripped.MenuBuilder

config :core, CoreWeb.UserAuth,
  researcher_signed_in_page: Link.Console,
  participant_signed_in_page: Link.Console,
  participant_onboarding_page: Link.Onboarding.Wizard

config :core, :features,
  sign_in_with_apple: false,
  member_google_sign_in: false,
  password_sign_in: false,
  notification_mails: false,
  debug_expire_force: false

config :core, Core.SurfConext, limit_schac_home_organization: "vu.nl"

config :core, :meta,
  bundle_title: "Panl",
  bundle: :link

if Mix.env() === :dev do
  import_config "#{Mix.env()}.exs"
end
