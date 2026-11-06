defmodule MicaSaas.SaaS do
  @moduledoc "Self, the reference SaaS on Mica."
  use Mica.SaaS

  @impl true
  def systems do
    Mica.Systems.all() ++
      [
        MicaSaas.Systems.Account.System,
        # Next systems that Self keeps until steps code-registry and
        # code-instance remove Mica's links to them.
        Next.Systems.Graphite.System,
        Next.Systems.Onyx.System,
        Next.Systems.Student.System,
        Next.Systems.Zircon.System,
        # Zircon's RIS import runs on Paper's ris_import queue.
        Next.Systems.Paper.System
      ]
  end

  @impl true
  def feature_flags, do: [password_sign_in: true, member_google_sign_in: true, otp: true]

  @impl true
  def start_pages, do: MicaSaas.StartPages

  @impl true
  def menu_items, do: MicaSaasWeb.Menu.Items

  @impl true
  def menu_builder(:workspace), do: MicaSaasWeb.Layouts.Workspace.MenuBuilder
  def menu_builder(:website), do: MicaSaasWeb.Layouts.Website.MenuBuilder
  def menu_builder(:stripped), do: MicaSaasWeb.Layouts.Stripped.MenuBuilder

  @impl true
  def title, do: "Self"

  @impl true
  def signed_in_page(:creator), do: "/project"
  def signed_in_page(:member), do: "/"
end
