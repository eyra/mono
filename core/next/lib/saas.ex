defmodule Next.SaaS do
  @moduledoc "Next, Eyra's SaaS on Mica."
  use Core.SaaS

  @impl true
  def systems do
    Core.Systems.all() ++
      [
        Next.WellKnown.System,
        Next.Account.System,
        Next.E2E.System,
        Systems.Graphite.System,
        Systems.Onyx.System,
        Systems.Student.System,
        Systems.Zircon.System
      ]
  end

  @impl true
  def start_pages, do: Next.StartPages

  @impl true
  def menu_items, do: Next.Menu.Items

  @impl true
  def menu_builder(:workspace), do: Next.Layouts.Workspace.MenuBuilder
  def menu_builder(:website), do: Next.Layouts.Website.MenuBuilder
  def menu_builder(:stripped), do: Next.Layouts.Stripped.MenuBuilder

  @impl true
  def title, do: "Next"

  @impl true
  def signed_in_page(:creator), do: "/project"
  def signed_in_page(:member), do: "/"
end
