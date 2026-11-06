defmodule Systems.Admin.OrgPanel do
  use Systems.Admin.Panel
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Admin

  @impl true
  def id, do: :org

  @impl true
  def title, do: dgettext("eyra-admin", "org.content.title")

  @impl true
  def audience, do: :org_admin

  @impl true
  def live_view, do: Admin.OrgView
end
