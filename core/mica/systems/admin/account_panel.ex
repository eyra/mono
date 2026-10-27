defmodule Systems.Admin.AccountPanel do
  use Systems.Admin.Panel
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Admin

  @impl true
  def id, do: :account

  @impl true
  def title, do: dgettext("eyra-admin", "account.title")

  @impl true
  def audience, do: :admin

  @impl true
  def live_view, do: Admin.AccountView

  @impl true
  def live_context(context) do
    LiveContext.extend(context, %{creators: Account.Public.list_creators()})
  end
end
