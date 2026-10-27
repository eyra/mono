defmodule Systems.Admin.ActionsPanel do
  use Systems.Admin.Panel
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Admin

  @impl true
  def id, do: :actions

  @impl true
  def title, do: dgettext("eyra-admin", "actions.title")

  @impl true
  def audience, do: :admin

  @impl true
  def live_view, do: Admin.ActionsView
end
