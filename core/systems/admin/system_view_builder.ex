defmodule Systems.Admin.SystemViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin SystemView.

  Builds the view model for system administration including:
  - Bank account management
  - Citizen pool management
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Budget
  alias Systems.Citizen

  def view_model(_model, assigns) do
    bank_accounts = Map.get(assigns, :bank_accounts, [])
    bank_account_items = Map.get(assigns, :bank_account_items, [])
    citizen_pools = Map.get(assigns, :citizen_pools, [])
    citizen_pool_items = Map.get(assigns, :citizen_pool_items, [])
    locale = Map.get(assigns, :locale, :en)
    current_user = Map.get(assigns, :current_user)

    %{
      bank_accounts_title: dgettext("eyra-admin", "system.bank.accounts.title"),
      bank_accounts_new_title: dgettext("eyra-admin", "system.bank.accounts.new.title"),
      bank_accounts: bank_accounts,
      bank_account_items: bank_account_items,
      bank_account_count: length(bank_account_items),
      citizen_pools_title: dgettext("eyra-admin", "system.citizen.pools.title"),
      citizen_pools_new_title: dgettext("eyra-admin", "system.citizen.pools.new.title"),
      citizen_pools: citizen_pools,
      citizen_pool_items: citizen_pool_items,
      citizen_pool_count: length(citizen_pool_items),
      locale: locale,
      current_user: current_user
    }
  end

  def build_bank_account_modal(bank_account, user) do
    LiveNest.Modal.prepare_live_component(
      "bank_account_form",
      Budget.BankAccountForm,
      params: [
        bank_account: bank_account,
        user: user
      ],
      style: :compact
    )
  end

  def build_citizen_pool_modal(pool, user, locale) do
    LiveNest.Modal.prepare_live_component(
      "pool_form",
      Citizen.Pool.Form,
      params: [
        pool: pool,
        user: user,
        locale: locale
      ],
      style: :compact
    )
  end
end
