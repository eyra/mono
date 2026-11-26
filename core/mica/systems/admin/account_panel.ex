defmodule Systems.Admin.AccountPanel do
  use Systems.Admin.Panel
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Admin

  @impl true
  def id, do: :account

  @impl true
  def title, do: dgettext("eyra-admin", "account.title")

  @impl true
  def audience, do: :admin

  @impl true
  def live_view, do: Admin.AccountView
end
