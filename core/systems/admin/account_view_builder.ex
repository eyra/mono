defmodule Systems.Admin.AccountViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin AccountView.

  Builds the view model for user account management including:
  - User list with filtering and search
  - User action buttons (verify, activate, etc.)

  The user list is capped at @max_users; user_count reflects the
  unfiltered match count so admins can tell when results were trimmed.

  Performance: when :affiliate or :in_pool filters are active, the
  membership lookup is pre-built into a MapSet (one bulk query per
  filter) instead of N+1 queries per user.
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Core.ImageHelpers
  alias CoreWeb.UI.Timestamp
  alias Systems.Account
  alias Systems.Admin
  alias Systems.Affiliate
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
      filter_labels: Admin.UserFilters.labels(active_filters),
      active_filters: active_filters,
      search_placeholder: dgettext("eyra-admin", "search.placeholder"),
      users: users,
      user_count: length(filtered)
    }
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
    Account.Public.list_users([:profile])
    |> Enum.sort(&(Account.User.label(&1) <= Account.User.label(&2)))
    |> filter_users(active_filters, build_filter_index(active_filters))
    |> filter_users(query)
  end

  defp build_filter_index(filters) do
    index = %{}

    index =
      if :affiliate in filters do
        Map.put(index, :affiliate_user_ids, MapSet.new(Affiliate.Public.list_user_ids()))
      else
        index
      end

    if :in_pool in filters do
      Map.put(index, :pool_user_ids, MapSet.new(Pool.Public.list_participant_ids()))
    else
      index
    end
  end

  defp filter_users(users, nil), do: users
  defp filter_users(users, []), do: users

  defp filter_users(users, query) when is_list(query) do
    Enum.filter(users, &matches?(&1, query))
  end

  defp filter_users(users, filters, index) when is_list(filters) do
    Enum.filter(users, &matches_filters?(&1, filters, index))
  end

  defp matches_filters?(_user, [], _index), do: true

  defp matches_filters?(user, [filter | rest], index),
    do: matches_filter?(user, filter, index) and matches_filters?(user, rest, index)

  defp matches_filter?(%Account.User{id: id}, :affiliate, %{affiliate_user_ids: ids}),
    do: MapSet.member?(ids, id)

  defp matches_filter?(%Account.User{id: id}, :in_pool, %{pool_user_ids: ids}),
    do: MapSet.member?(ids, id)

  defp matches_filter?(user, filter, _index) when is_atom(filter),
    do: matches_filter?(user, filter)

  defp matches_filter?(%Account.User{verified_at: verified_at}, :verified),
    do: verified_at != nil

  defp matches_filter?(%Account.User{creator: creator}, :creator) when not is_nil(creator),
    do: creator

  defp matches_filter?(%Account.User{}, :affiliate), do: false
  defp matches_filter?(%Account.User{}, :in_pool), do: false
  defp matches_filter?(_user, _filter), do: false

  defp matches?(_user, []), do: true

  defp matches?(user, [term | rest]),
    do: matches_word?(user, term) and matches?(user, rest)

  defp matches_word?(_user, ""), do: true

  defp matches_word?(%Account.User{email: email, profile: profile}, word) when is_binary(word) do
    word = String.downcase(word)
    String.contains?(String.downcase(email), word) or profile_matches?(profile, word)
  end

  defp matches_word?(_user, _word), do: false

  defp profile_matches?(%Account.UserProfileModel{fullname: fullname}, word)
       when not is_nil(fullname) do
    String.contains?(String.downcase(fullname), word)
  end

  defp profile_matches?(_profile, _word), do: false

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
        build_verify_button(user)
      ]
    }
  end

  defp build_user_info(%Account.User{} = user) do
    case Pool.Public.list_by_participant(user) do
      [] -> verified_info(user)
      pools -> "Pools: " <> Enum.map_join(pools, ", ", & &1.name)
    end
  end

  defp verified_info(%Account.User{verified_at: nil}), do: ""

  defp verified_info(%Account.User{verified_at: verified_at}),
    do: "Verified #{Timestamp.humanize(verified_at)}"

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
