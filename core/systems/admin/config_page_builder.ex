defmodule Systems.Admin.ConfigPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.Budget
  alias Systems.Citizen
  alias Systems.Org
  alias Systems.Pool

  def view_model(%{id: :singleton}, %{current_user: user} = assigns) do
    locale = Map.get(assigns, :locale, :en)
    is_admin? = Admin.Public.admin?(user)
    governable_orgs = Org.Public.list_orgs(user, Org.NodeModel.preload_graph(:full))

    # Sync NextActions as fallback when opening admin page
    Org.Public.sync_all_domain_match_next_actions(user)

    live_context =
      LiveContext.new(%{
        current_user: user,
        locale: locale,
        is_admin?: is_admin?,
        governable_orgs: governable_orgs
      })

    assigns_with_context =
      assigns
      |> Map.put(:live_context, live_context)
      |> Map.put(:locale, locale)
      |> Map.put(:is_admin?, is_admin?)
      |> Map.put(:governable_orgs, governable_orgs)

    %{
      tabbar_id: "admin_config",
      title: get_title(is_admin?, governable_orgs),
      active_menu_item: :admin,
      show_errors: false,
      tabs: create_tabs(assigns_with_context)
    }
  end

  # Page title is always "Admin" (matches menu item)
  defp get_title(_, _), do: dgettext("eyra-admin", "config.title")

  # System admins see all tabs
  defp create_tabs(%{is_admin?: true} = assigns) do
    [:system, :account, :org, :actions]
    |> Enum.map(&create_admin_tab(&1, assigns))
  end

  # Org admins see group tabs (e.g., Organisations)
  # Currently only Organisations group exists for non-admins
  defp create_tabs(%{governable_orgs: orgs} = assigns) when length(orgs) > 0 do
    # Show the Organisations group tab (same as admin :org tab)
    [create_admin_tab(:org, assigns)]
  end

  # No access - return empty tabs
  defp create_tabs(_assigns), do: []

  # Admin tabs (system, account, org list, actions)

  defp create_admin_tab(:system, %{live_context: context} = assigns) do
    child_context =
      LiveContext.extend(context, %{
        bank_accounts: get_bank_accounts(),
        bank_account_items: get_bank_account_items(assigns),
        citizen_pools: get_citizen_pools(),
        citizen_pool_items: get_citizen_pool_items(assigns)
      })

    element =
      LiveNest.Element.prepare_live_view(
        "admin_system_view",
        Admin.SystemView,
        live_context: child_context
      )

    %{
      id: :system,
      ready: false,
      show_errors: false,
      title: dgettext("eyra-admin", "system.title"),
      type: :fullpage,
      element: element
    }
  end

  defp create_admin_tab(:account, %{live_context: context}) do
    creators = Systems.Account.Public.list_creators()

    child_context =
      LiveContext.extend(context, %{
        creators: creators
      })

    element =
      LiveNest.Element.prepare_live_view(
        "admin_account_view",
        Admin.AccountView,
        live_context: child_context
      )

    %{
      id: :account,
      ready: false,
      show_errors: false,
      title: dgettext("eyra-admin", "account.title"),
      type: :fullpage,
      element: element
    }
  end

  defp create_admin_tab(:org, %{live_context: context}) do
    element =
      LiveNest.Element.prepare_live_view(
        "admin_org_view",
        Admin.OrgView,
        live_context: context
      )

    %{
      id: :org,
      ready: false,
      show_errors: false,
      title: dgettext("eyra-admin", "org.content.title"),
      type: :fullpage,
      element: element
    }
  end

  defp create_admin_tab(:actions, %{live_context: context}) do
    element =
      LiveNest.Element.prepare_live_view(
        "admin_actions_view",
        Admin.ActionsView,
        live_context: context
      )

    %{
      id: :actions,
      ready: false,
      show_errors: false,
      title: dgettext("eyra-admin", "actions.title"),
      type: :fullpage,
      element: element
    }
  end

  # Helper functions

  defp get_bank_accounts do
    Budget.Public.list_bank_accounts(Budget.BankAccountModel.preload_graph(:full))
  end

  defp get_bank_account_items(%{locale: locale}) do
    get_bank_accounts()
    |> Enum.map(&to_view_model(&1, locale))
  end

  defp get_citizen_pools do
    Citizen.Public.list_pools(currency: Budget.CurrencyModel.preload_graph(:full))
  end

  defp get_citizen_pool_items(%{locale: locale}) do
    get_citizen_pools()
    |> Enum.map(&to_view_model(&1, locale))
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
