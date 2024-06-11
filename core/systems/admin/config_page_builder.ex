defmodule Systems.Admin.ConfigPageBuilder do
  import CoreWeb.Gettext

  alias Systems.Admin
  alias Systems.Budget
  alias Systems.Citizen
  alias Systems.Pool

  def view_model(%{id: :singleton}, assigns) do
    %{
      tabbar_id: "admin_config",
      title: dgettext("eyra-admin", "config.title"),
      active_menu_item: :admin,
      show_errors: false
    }
    |> put_tabs(assigns)
  end

  defp put_tabs(vm, assigns) do
    Map.put(vm, :tabs, create_tabs(false, assigns))
  end

  defp create_tabs(show_errors, assigns) do
    get_tab_keys()
    |> Enum.map(&create_tab(&1, show_errors, assigns))
  end

  defp get_tab_keys() do
    [:system, :account, :org, :actions]
  end

  defp create_tab(
         :system,
         show_errors,
         %{fabric: fabric, locale: locale, current_user: user} = assigns
       ) do
    ready? = false

    child =
      Fabric.prepare_child(
        fabric,
        :system,
        Admin.SystemView,
        %{
          locale: locale,
          user: user
        }
        |> put_bank_accounts()
        |> put_bank_account_items(assigns)
        |> put_citizen_pools()
        |> put_citizen_pool_items(assigns)
      )

    %{
      id: :system,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "system.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :account,
         show_errors,
         %{fabric: fabric, current_user: user}
       ) do
    ready? = false

    creators = Systems.Account.Public.list_creators()

    child =
      Fabric.prepare_child(
        fabric,
        :account,
        Admin.AccountView,
        %{
          user: user,
          creators: creators
        }
      )

    %{
      id: :account,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "account.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :org,
         show_errors,
         %{fabric: fabric, locale: locale}
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :org, Admin.OrgView, %{
        locale: locale
      })

    %{
      id: :org,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "org.content.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(
         :actions,
         show_errors,
         %{fabric: fabric}
       ) do
    ready? = false

    child =
      Fabric.prepare_child(fabric, :org, Admin.ActionsView, %{
        tickets: []
      })

    %{
      id: :actions,
      ready: ready?,
      show_errors: show_errors,
      title: dgettext("eyra-admin", "actions.title"),
      type: :fullpage,
      child: child
    }
  end

  defp put_bank_accounts(vm) do
    Map.put(
      vm,
      :bank_accounts,
      Budget.Public.list_bank_accounts(Budget.BankAccountModel.preload_graph(:full))
    )
  end

  defp put_bank_account_items(%{bank_accounts: bank_accounts} = vm, %{locale: locale}) do
    Map.put(vm, :bank_account_items, Enum.map(bank_accounts, &to_view_model(&1, locale)))
  end

  defp put_citizen_pools(vm) do
    Map.put(
      vm,
      :citizen_pools,
      Citizen.Public.list_pools(currency: Budget.CurrencyModel.preload_graph(:full))
    )
  end

  defp put_citizen_pool_items(%{citizen_pools: citizen_pools} = vm, %{locale: locale}) do
    Map.put(vm, :citizen_pool_items, Enum.map(citizen_pools, &to_view_model(&1, locale)))
  end

  defp to_view_model(
         %Budget.BankAccountModel{id: id, name: name, icon: icon, currency: currency},
         locale
       ) do
    subtitle = Budget.CurrencyModel.title(currency, locale)

    %{
      icon: icon,
      title: name,
      subtitle: subtitle,
      action: %{type: :send, event: "edit_bank_account", item: id}
    }
  end

  defp to_view_model(
         %Pool.Model{id: id, name: name, icon: icon, currency: currency},
         locale
       ) do
    subtitle = Budget.CurrencyModel.title(currency, locale)

    %{
      icon: icon,
      title: name,
      subtitle: subtitle,
      action: %{type: :send, event: "edit_citizen_pool", item: id}
    }
  end
end
