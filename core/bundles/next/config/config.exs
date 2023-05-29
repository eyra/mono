import Config

config :core,
  start_pages: Next.StartPages,
  menu_items: Next.Menu.Items,
  workspace_menu_builder: Next.Layouts.Workspace.MenuBuilder,
  website_menu_builder: Next.Layouts.Website.MenuBuilder,
  stripped_menu_builder: Next.Layouts.Stripped.MenuBuilder

config :core, CoreWeb.UserAuth,
  researcher_signed_in_page: Next.Console.Page,
  participant_signed_in_page: Next.Console.Page

config :core, :meta,
  bundle_title: "Eyra",
  bundle: :next
