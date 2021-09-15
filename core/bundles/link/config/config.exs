use Mix.Config

config :core,
  promotion_plugins: [
    survey: Link.Survey.PromotionPlugin,
    lab: Link.Lab.PromotionPlugin
  ],
  menu_items: Link.Menu.Items,
  workspace_menu_builder: Link.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Link.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Link.Layouts.Stripped.MenuBuilder

config :core, CoreWeb.UserAuth,
  researcher_signed_in_page: Link.Dashboard,
  participant_signed_in_page: Link.Marketplace,
  participant_onboarding_page: Link.Onboarding.Wizard

config :core, :features,
  marketplace: false,
  sign_in_with_apple: false,
  member_google_sign_in: false,
  password_sign_in: false,
  notification_mails: false

config :core, Core.SurfConext, limit_schac_home_organization: "vu.nl"

config :core, :meta,
  bundle_title: "Panl",
  bundle: :link

if Mix.env() === :dev do
  import_config "#{Mix.env()}.exs"
end
