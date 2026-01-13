defmodule Systems.Org.UserViewBuilder do
  @moduledoc """
  ViewBuilder for Org.UserView (members tab).

  Provides the data needed by PeopleEditorView:
  - title: The section title
  - people: Current org members
  - users: Available users that can be added as members
  - domain_banner: Banner for domain-matched users with specific count
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Org

  def view_model(
        %{id: org_id, domains: domains} = node,
        %{current_user: current_user, locale: locale} = _assigns
      ) do
    # Option C pattern: auth roles are source of truth for membership
    members = Org.Public.list_members(node)
    owners = Org.Public.list_owners(node)

    # Get all users who aren't already members or owners
    member_ids = Enum.map(members, & &1.id)
    owner_ids = Enum.map(owners, & &1.id)
    excluded_ids = member_ids ++ owner_ids

    users =
      Account.Public.list_creators([:profile])
      |> Enum.reject(&(&1.id in excluded_ids))

    # Find domain-matched users and sync NextAction
    domain_matched = Org.Public.find_domain_matched_users(domains, members ++ owners)
    Org.Public.sync_domain_match_next_action(node, current_user, locale)

    # Build banner for domain-matched users (with specific count)
    domain_banner = build_domain_banner(domain_matched, org_id)

    %{
      title: dgettext("eyra-org", "user.title"),
      people: members,
      users: users,
      domain_banner: domain_banner
    }
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
