defmodule Self.SaaS do
  @moduledoc "Self, the reference SaaS on Mica."
  use Core.SaaS

  @impl true
  def systems do
    Core.SaaS.mica_systems() ++
      [
        Self.Account.System,
        # Mica code still links to Graphite and Onyx pages, until steps
        # code-registry and code-instance remove those links.
        Systems.Graphite.System,
        Systems.Onyx.System
      ]
  end

  @impl true
  def start_pages, do: Self.StartPages

  @impl true
  def menu_items, do: Self.Menu.Items

  @impl true
  def menu_builder(:workspace), do: Self.Layouts.Workspace.MenuBuilder
  def menu_builder(:website), do: Self.Layouts.Website.MenuBuilder
  def menu_builder(:stripped), do: Self.Layouts.Stripped.MenuBuilder

  @impl true
  def title, do: "Self"

  @impl true
  def signed_in_page(:creator), do: "/project"
  def signed_in_page(:member), do: "/"
end
