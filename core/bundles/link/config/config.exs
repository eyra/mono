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
  participant_signed_in_first_time_page: Link.Onboarding.Wizard

config :core, :features,
  sign_in_with_apple: false,
  google_sign_in: true,
  password_sign_in: false,
  debug: true

config :core, Core.SurfConext, limit_schac_home_organization: "replace-with-vu"

config :core, :meta,
  bundle_title: "PaNL",
  bundle: :link

if Mix.env === :dev do
  import_config "#{Mix.env()}.exs"
end
