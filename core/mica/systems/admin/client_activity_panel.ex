defmodule Systems.Admin.ClientActivityPanel do
  use Systems.Admin.Panel
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Admin

  @impl true
  def id, do: :client_activity

  @impl true
  def title, do: dgettext("eyra-admin", "client_activity.title")

  @impl true
  def audience, do: :admin

  @impl true
  def live_view, do: Admin.ClientActivityView
end
