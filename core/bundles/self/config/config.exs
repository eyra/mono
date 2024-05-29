import Config

config :core,
  start_pages: Self.StartPages,
  menu_items: Self.Menu.Items,
  workspace_menu_builder: Self.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Self.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Self.Layouts.Stripped.MenuBuilder

config :core, Systems.Account.UserAuth,
  researcher_signed_in_page: "/project",
  participant_signed_in_page: "/project"

config :core, :meta,
  bundle_title: "Self",
  bundle: :port
