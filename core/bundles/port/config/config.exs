import Config

config :core,
  start_pages: Port.StartPages,
  menu_items: Port.Menu.Items,
  workspace_menu_builder: Port.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Port.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Port.Layouts.Stripped.MenuBuilder

config :core, CoreWeb.UserAuth,
  researcher_signed_in_page: Port.Console.Page,
  participant_signed_in_page: Port.Console.Page

config :core, :meta,
  bundle_title: "Port",
  bundle: :port
