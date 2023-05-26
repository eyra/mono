import Config

config :core,
  start_pages: Port.StartPages,
  menu_items: Port.Menu.Items,
  workspace_menu_builder: Port.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Port.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Port.Layouts.Stripped.MenuBuilder

config :core, :meta,
  bundle_title: "Port",
  bundle: :port
