use Mix.Config

config :core,
  promotion_plugins: [survey: Link.Survey.PromotionPlugin],
  menu_items: Link.Menu.Items,
  workspace_builder: CoreWeb.Layouts.Workspace.MenuBuilder,
  website_builder: CoreWeb.Layouts.Website.MenuBuilder
