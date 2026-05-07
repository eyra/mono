defmodule Systems.Admin.AccountViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin AccountView.

  Builds the view model for user account management including:
  - User list with filtering and search
  - User action buttons (verify, activate, etc.)
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Core.ImageHelpers
  alias CoreWeb.UI.Timestamp
  alias Systems.Account
  alias Systems.Admin

  @doc """
  Builds the view model for the AccountView.

  The model parameter is unused (singleton).
  The assigns should contain active_filters and query for filtering users.
  """
  def view_model(_model, assigns) do
    active_filters = Map.get(assigns, :active_filters, [:creator])
    query = Map.get(assigns, :query, [])

    users = build_user_items(active_filters, query)

    %{
      title: dgettext("eyra-admin", "account.title"),
      filter_labels: Admin.UserFilters.labels(active_filters),
      active_filters: active_filters,
      search_placeholder: dgettext("eyra-admin", "search.placeholder"),
      users: users,
      user_count: length(users)
    }
  end

  @doc """
  Builds the list of user items with filtering applied.
  """
  def build_user_items(active_filters, query) do
    Account.Public.list_internal_users([:profile])
    |> Enum.sort(&(Account.User.label(&1) <= Account.User.label(&2)))
    |> filter_users(active_filters)
    |> filter_users(query)
    |> Enum.map(&build_user_item/1)
  end

  defp filter_users(users, nil), do: users
  defp filter_users(users, []), do: users

  defp filter_users(users, filters) when is_list(filters) do
    Enum.filter(users, &user_matches_filters?(&1, filters))
  end

  defp user_matches_filters?(_user, []), do: true

  defp user_matches_filters?(user, [filter]) do
    user_matches_filter?(user, filter)
  end

  defp user_matches_filters?(user, [filter | rest]) do
    user_matches_filter?(user, filter) and user_matches_filters?(user, rest)
  end

  defp user_matches_filter?(_user, ""), do: true

  defp user_matches_filter?(%Account.User{email: email, profile: profile}, word)
       when is_binary(word) do
    word = String.downcase(word)
    String.contains?(String.downcase(email), word) or profile_matches?(profile, word)
  end

  defp user_matches_filter?(%Account.User{verified_at: verified_at}, :verified) do
    verified_at != nil
  end

  defp user_matches_filter?(%Account.User{creator: creator}, :creator)
       when not is_nil(creator) do
    creator
  end

  defp user_matches_filter?(_user, _filter), do: false

  defp profile_matches?(%Account.UserProfileModel{fullname: fullname}, word)
       when not is_nil(fullname) do
    String.contains?(String.downcase(fullname), word)
  end

  defp profile_matches?(_profile, _word), do: false

  @doc """
  Builds a single user item for display.
  """
  def build_user_item(%Account.User{} = user) do
    %{
      photo_url: ImageHelpers.get_photo_url(user.profile),
      name: user.displayname,
      email: user.email,
      info: build_user_info(user),
      action_buttons: [
        build_activate_button(user),
        build_verify_button(user)
      ]
    }
  end

  defp build_user_info(%Account.User{verified_at: nil}), do: ""

  defp build_user_info(%Account.User{verified_at: verified_at}) do
    "Verified #{Timestamp.humanize(verified_at)}"
  end

  defp build_verify_button(%Account.User{creator: false, id: id}) do
    %{
      action: %{type: :send, event: "make_creator", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: "Make creator", icon: :add}
    }
  end

  defp build_verify_button(%Account.User{verified_at: nil, id: id}) do
    %{
      action: %{type: :send, event: "verify_creator", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: "Verify", icon: :verify}
    }
  end

  defp build_verify_button(%Account.User{id: id}) do
    %{
      action: %{type: :send, event: "unverify_creator", item: id, target: "#admin_account_view"},
      face: %{type: :plain, label: "Unverify", icon: :unverify}
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
