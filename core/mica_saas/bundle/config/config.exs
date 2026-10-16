import Config

config :core,
  start_pages: Self.StartPages,
  menu_items: Self.Menu.Items,
  workspace_menu_builder: Self.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Self.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Self.Layouts.Stripped.MenuBuilder

config :core, Systems.Account.UserAuth,
  creator_signed_in_page: "/project",
  member_signed_in_page: "/console"

config :core, :meta,
  bundle_title: "Self",
  bundle: :port
