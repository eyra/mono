defmodule Systems.Admin.AccountViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin AccountView.

  Builds the view model for user account management including:
  - User list with filtering and search
  - User action buttons (licenses, activate, etc.)

  The user list is capped at @max_users; user_count reflects the
  unfiltered match count so admins can tell when results were trimmed.

  The matching itself is `Systems.Admin.Public.list_matching_users/2`.
  """
  use Gettext, backend: MicaWeb.Gettext

  alias Mica.ImageHelpers
  alias Systems.Account
  alias Systems.Admin
  alias Systems.License
  alias Systems.Pool

  @max_users 50

  def view_model(_model, assigns) do
    active_filters = Map.get(assigns, :active_filters, [:creator])
    query = Map.get(assigns, :query, [])

    filtered = filter_user_list(active_filters, query)

    users =
      filtered
      |> Enum.take(@max_users)
      |> Enum.map(&build_user_item/1)

    %{
      title: dgettext("eyra-admin", "account.title"),
      filter_labels: Admin.UserFilters.labels(active_filters, filters()),
      active_filters: active_filters,
      search_placeholder: dgettext("eyra-admin", "search.placeholder"),
      users: users,
      user_count: length(filtered)
    }
  end

  # A filter per license in use, so Pay-in only behind its flag.
  defp filters do
    Admin.UserFilters.values() -- (License.Model.licenses() -- License.Public.licenses())
  end

  @doc """
  Builds the (uncapped) list of user items with filters and search query
  applied. Kept public to support direct testing of filter behaviour.
  """
  def build_user_items(active_filters, query) do
    active_filters
    |> filter_user_list(query)
    |> Enum.map(&build_user_item/1)
  end

  defp filter_user_list(active_filters, query) do
    Admin.Public.list_matching_users(active_filters, query)
  end

  @doc """
  Builds the view-model item for a single user. Public for direct testing.
  """
  def build_user_item(%Account.User{} = user) do
    %{
      photo_url: ImageHelpers.get_photo_url(user.profile),
      name: user.displayname,
      email: user.email,
      info: build_user_info(user),
      action_buttons: [
        build_activate_button(user),
        build_licenses_button(user)
      ]
    }
  end

  @doc "The Licenses dialog of the user with `user_id`."
  def build_licenses_modal(user_id) do
    LiveNest.Modal.prepare_live_view(
      Admin.LicensesModalView.modal_id(),
      Admin.LicensesModalView,
      session: [user_id: user_id],
      style: :sheet
    )
  end

  defp build_user_info(%Account.User{} = user) do
    case Pool.Public.list_by_participant(user) do
      [] -> ""
      pools -> "Pools: " <> Enum.map_join(pools, ", ", & &1.name)
    end
  end

  defp build_licenses_button(%Account.User{creator: false, id: id}) do
    %{
      action: %{type: :send, event: "make_creator", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: "Make creator", icon: :add}
    }
  end

  defp build_licenses_button(%Account.User{id: id}) do
    %{
      action: %{type: :send, event: "licenses", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: dgettext("eyra-admin", "licenses.button"), icon: :verify}
    }
  end

  defp build_activate_button(%Account.User{confirmed_at: nil, id: id}) do
    %{
      action: %{type: :send, event: "activate_user", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: "Activate", icon: :verify}
    }
  end

  defp build_activate_button(%Account.User{id: id}) do
    %{
      action: %{type: :send, event: "deactivate_user", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: "Deactivate", icon: :unverify}
    }
  end
end
