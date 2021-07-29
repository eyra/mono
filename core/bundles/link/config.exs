use Mix.Config

config :core,
  promotion_plugins: [survey: Link.Survey.PromotionPlugin],
  menu_items: Link.Menu.Items,
  workspace_menu_builder: Link.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Link.Layouts.Website.MenuBuilder
