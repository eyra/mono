use Mix.Config

config :core,
  promotion_plugins: [
    survey: Link.Survey.PromotionPlugin,
    lab: Link.Lab.PromotionPlugin
  ],
  menu_items: Link.Menu.Items,
  workspace_menu_builder: Link.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Link.Layouts.Website.MenuBuilder

config :core, :features,
  sign_in_with_apple: false,
  google_sign_in: false,
  password_sign_in: false
