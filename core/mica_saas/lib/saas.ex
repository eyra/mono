defmodule Self.SaaS do
  @moduledoc "Self, the reference SaaS on Mica."
  use Core.SaaS

  @impl true
  def systems do
    Core.Systems.all() ++
      [
        Self.Account.System,
        # Next systems that Self keeps until steps code-registry and
        # code-instance remove Mica's links to them.
        Systems.Graphite.System,
        Systems.Onyx.System,
        Systems.Student.System,
        Systems.Zircon.System,
        # Zircon's RIS import runs on Paper's ris_import queue.
        Systems.Paper.System
      ]
  end

  @impl true
  def feature_flags, do: [password_sign_in: true, member_google_sign_in: true, otp: true]

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
