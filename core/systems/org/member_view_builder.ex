defmodule Systems.Org.MemberViewBuilder do
  @moduledoc """
  ViewBuilder for Org.MemberView (members tab).

  Provides the data needed by PeopleEditorView:
  - title: The section title
  - people: Current org members (filtered, searched, capped at @max_members)
  - users: Available users that can be added as members
  - user_count: Total members after filter+search (uncapped) — drives the
    count next to the "Members" title
  - filter_labels: Pixel.Selector items for the :external and :recent chips
  - search_placeholder / query_string: powers the SearchBar
  - domain_banner: Banner for domain-matched users with specific count

  Filters use OR semantics (a member is shown if they match ANY active
  chip). No chips selected = show everything. The :recent chip selects
  members whose role was granted in the current ISO week (Mon 00:00 UTC
  onward).
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Org

  @max_members 50

  def view_model(
        %{id: org_id, domains: domains} = node,
        %{current_user: current_user, locale: locale} = assigns
      ) do
    active_filters = Map.get(assigns, :active_filters, [])
    query = Map.get(assigns, :query, [])
    query_string = Map.get(assigns, :query_string, "")

    members_with_added_at = Org.Public.list_members_with_added_at(node)
    owners = Org.Public.list_owners(node)

    filtered =
      members_with_added_at
      |> filter_by_chips(active_filters, domains, week_start_naive())
      |> filter_by_query(query)
      |> Enum.sort_by(fn {user, _} -> Account.User.label(user) end)

    members = Enum.map(filtered, fn {user, _} -> user end)
    capped_members = Enum.take(members, @max_members)

    # All members (uncapped, unfiltered) — needed for "available users" and
    # the domain banner so they aren't affected by the filter UI.
    all_members = Enum.map(members_with_added_at, fn {user, _} -> user end)

    member_ids = Enum.map(all_members, & &1.id)
    owner_ids = Enum.map(owners, & &1.id)
    excluded_ids = member_ids ++ owner_ids

    users =
      Account.Public.list_creators([:profile])
      |> Enum.reject(&(&1.id in excluded_ids))

    domain_matched = Org.Public.find_domain_matched_users(domains, all_members ++ owners)

    if Org.Public.can_manage?(node, current_user) do
      Org.Public.sync_domain_match_next_action(node, current_user, locale)
    end

    domain_banner = build_domain_banner(domain_matched, org_id)

    %{
      title: dgettext("eyra-org", "user.title"),
      people: capped_members,
      users: users,
      user_count: length(filtered),
      filter_labels: Org.MemberFilters.labels(active_filters),
      search_placeholder: dgettext("eyra-org", "search.placeholder"),
      query_string: query_string,
      domain_banner: domain_banner
    }
  end

  defp filter_by_chips(rows, [], _domains, _week_start), do: rows

  defp filter_by_chips(rows, active_filters, domains, week_start) do
    Enum.filter(rows, fn row ->
      Enum.any?(active_filters, &chip_matches?(row, &1, domains, week_start))
    end)
  end

  defp chip_matches?({user, _added_at}, :external, domains, _week_start),
    do: not domain_match?(user, domains)

  defp chip_matches?({_user, added_at}, :recent, _domains, week_start),
    do: NaiveDateTime.compare(added_at, week_start) != :lt

  defp chip_matches?(_row, _filter, _domains, _week_start), do: false

  defp domain_match?(_user, nil), do: false
  defp domain_match?(_user, []), do: false

  defp domain_match?(%Account.User{email: email}, domains) when is_list(domains) do
    email = String.downcase(email || "")
    Enum.any?(domains, &String.ends_with?(email, "@" <> String.downcase(&1)))
  end

  defp domain_match?(_user, _domains), do: false

  defp filter_by_query(rows, []), do: rows
  defp filter_by_query(rows, nil), do: rows

  defp filter_by_query(rows, query) when is_list(query) do
    Enum.filter(rows, fn {user, _} -> matches_query?(user, query) end)
  end

  defp matches_query?(_user, []), do: true

  defp matches_query?(user, [term | rest]),
    do: matches_term?(user, term) and matches_query?(user, rest)

  defp matches_term?(_user, ""), do: true

  defp matches_term?(%Account.User{email: email, profile: profile}, term) when is_binary(term) do
    term = String.downcase(term)
    String.contains?(String.downcase(email || ""), term) or profile_matches?(profile, term)
  end

  defp matches_term?(_user, _term), do: false

  defp profile_matches?(%Account.UserProfileModel{fullname: fullname}, term)
       when is_binary(fullname),
       do: String.contains?(String.downcase(fullname), term)

  defp profile_matches?(_profile, _term), do: false

  defp week_start_naive do
    Date.utc_today()
    |> Date.beginning_of_week()
    |> NaiveDateTime.new!(~T[00:00:00])
  end

  defp build_domain_banner([], _org_id), do: nil

  defp build_domain_banner(domain_matched, org_id) do
    count = length(domain_matched)

    %{
      title:
        dngettext(
          "eyra-org",
          "domain.match.banner.title.singular",
          "domain.match.banner.title.plural",
          count,
          count: count
        ),
      subtitle: dgettext("eyra-org", "domain.match.banner.subtitle"),
      button: %{
        action: %{type: :send, event: "add_all_domain_matched", item: org_id},
        face: %{type: :primary, label: dgettext("eyra-org", "domain.match.banner.button")}
      }
    }
  end
end
