defmodule Systems.Admin.SystemPanel do
  use Systems.Admin.Panel
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.Citizen
  alias Systems.Fund
  alias Systems.Pool

  @impl true
  def id, do: :system

  @impl true
  def title, do: dgettext("eyra-admin", "system.title")

  @impl true
  def audience, do: :admin

  @impl true
  def live_view, do: Admin.SystemView

  @impl true
  def live_context(%LiveContext{data: %{locale: locale}} = context) do
    bank_accounts = Fund.Public.list_bank_accounts(Fund.BankAccountModel.preload_graph(:full))
    citizen_pools = Citizen.Public.list_pools(currency: Fund.CurrencyModel.preload_graph(:full))

    LiveContext.extend(context, %{
      bank_accounts: bank_accounts,
      bank_account_items: Enum.map(bank_accounts, &to_view_model(&1, locale)),
      citizen_pools: citizen_pools,
      citizen_pool_items: Enum.map(citizen_pools, &to_view_model(&1, locale))
    })
  end

  defp to_view_model(
         %Fund.BankAccountModel{id: id, name: name, icon: icon, currency: currency},
         locale
       ) do
    %{
      icon: icon,
      title: name,
      subtitle: Fund.CurrencyModel.title(currency, locale),
      action: %{type: :send, event: "edit_bank_account", item: id}
    }
  end

  defp to_view_model(%Pool.Model{id: id, name: name, icon: icon, currency: currency}, locale) do
    %{
      icon: icon,
      title: name,
      subtitle: Fund.CurrencyModel.title(currency, locale),
      action: %{type: :send, event: "edit_citizen_pool", item: id}
    }
  end
end
