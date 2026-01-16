defmodule Systems.Admin.OrgViewBuilder do
  @moduledoc """
  ViewBuilder for the Admin OrgView.

  Builds the view model for organisation management including:
  - Organisation list with filtering and search
  - Organisation item view models
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Content
  alias Systems.NextAction
  alias Systems.Org

  @doc """
  Builds the view model for the OrgView.

  The model parameter is unused (singleton).
  The assigns should contain query, locale, and current_user.
  """
  # Threshold for showing search and filter UI
  @search_filter_threshold 5

  def view_model(_model, assigns) do
    query = Map.get(assigns, :query, nil)
    locale = Map.get(assigns, :locale, :en)
    active_filters = Map.get(assigns, :active_filters, [])
    current_user = Map.get(assigns, :current_user)
    is_admin? = Map.get(assigns, :is_admin?, false)
    governable_orgs = Map.get(assigns, :governable_orgs)

    base_orgs = get_base_orgs(is_admin?, governable_orgs)
    organisations = build_organisation_items(base_orgs, query, active_filters, locale, is_admin?)
    next_action_banners = build_next_action_banners(current_user)
    archived_count = if is_admin?, do: count_archived_nodes(), else: 0
    show_search_filter? = length(base_orgs) >= @search_filter_threshold

    %{
      title: dgettext("eyra-admin", "org.content.title"),
      search_placeholder: dgettext("eyra-org", "search.placeholder"),
      create_button: build_create_button(is_admin?),
      filter_labels: build_filter_labels(active_filters),
      organisations: organisations,
      next_action_banners: next_action_banners,
      org_count: length(organisations),
      archived_count: archived_count,
      show_archived_button: build_show_archived_button(archived_count),
      show_search_filter?: show_search_filter?
    }
  end

  defp get_base_orgs(true, _), do: Org.Public.list_nodes(Org.NodeModel.preload_graph(:full))
  defp get_base_orgs(_, orgs) when is_list(orgs), do: orgs
  defp get_base_orgs(_, _), do: []

  defp build_next_action_banners(nil), do: []

  defp build_next_action_banners(user) do
    NextAction.Public.list_next_actions_by_type(user, Org.NextActions.AddDomainMembers)
    |> List.first()
    |> case do
      nil -> []
      next_action -> [next_action_to_banner(next_action)]
    end
  end

  defp next_action_to_banner(%{
         title: title,
         description: description,
         cta_label: cta_label,
         cta_action: cta_action
       }) do
    %{
      title: title,
      subtitle: description,
      button: %{
        action: cta_action,
        face: %{type: :primary, label: cta_label}
      }
    }
  end

  defp count_archived_nodes do
    Org.Public.list_archived_nodes([]) |> length()
  end

  defp build_show_archived_button(count) when count > 0 do
    %{
      action: %{type: :send, event: "show_archived"},
      face: %{
        type: :plain,
        label:
          dngettext("eyra-admin", "show.archived.button", "show.archived.button.plural", count,
            count: count
          ),
        icon: :archive
      }
    }
  end

  defp build_show_archived_button(0), do: nil

  defp build_create_button(true = _is_admin?) do
    %{
      action: %{type: :send, event: "create_org"},
      face: %{type: :plain, label: dgettext("eyra-admin", "create.org.button"), icon: :forward},
      face_short: %{
        type: :plain,
        label: dgettext("eyra-admin", "create.org.button.short"),
        icon: :forward
      }
    }
  end

  defp build_create_button(_), do: nil

  @doc """
  Builds the modal for archived organisations.
  """
  def build_archived_orgs_modal(locale) do
    LiveNest.Modal.prepare_live_view(
      "archived-orgs-modal",
      Org.ArchiveModalView,
      session: [locale: locale],
      style: :sheet,
      context: dgettext("eyra-admin", "archived.context")
    )
  end

  @doc """
  Builds the modal for organisation admins.
  """
  def build_admins_modal(org_id, org_name) do
    LiveNest.Modal.prepare_live_view(
      "org-admins-modal",
      Org.AdminsModalView,
      session: [org_id: org_id],
      style: :sheet,
      context: org_name
    )
  end

  defp build_filter_labels(active_filters) do
    [
      %{id: :root, value: dgettext("eyra-org", "filter.root"), active: :root in active_filters},
      %{
        id: :nested,
        value: dgettext("eyra-org", "filter.nested"),
        active: :nested in active_filters
      }
    ]
  end

  @doc """
  Builds the list of organisation items from the given base orgs.
  """
  def build_organisation_items(base_orgs, query, active_filters, locale, is_admin?) do
    base_orgs
    |> filter_by_hierarchy(active_filters)
    |> Enum.map(&build_organisation_item(&1, locale, is_admin?))
    |> filter_by_query(query)
  end

  defp filter_by_hierarchy(organisations, []), do: organisations

  defp filter_by_hierarchy(organisations, active_filters) do
    all_selected = :root in active_filters and :nested in active_filters

    if all_selected do
      organisations
    else
      Enum.filter(organisations, fn org ->
        org_type = hierarchy_type(org)
        org_type in active_filters
      end)
    end
  end

  defp hierarchy_type(%{reverse_links: reverse_links}) do
    has_parent = not Enum.empty?(reverse_links || [])

    if has_parent, do: :nested, else: :root
  end

  @doc """
  Builds a single organisation item for display.
  """
  def build_organisation_item(%Org.NodeModel{id: id} = org, locale, is_admin?) do
    members = Org.Public.list_members(org)

    # Admin-only actions
    left_actions =
      if is_admin? do
        [
          %{
            action: %{type: :send, event: "setup_admins", item: id},
            face: %{type: :label, label: dgettext("eyra-admin", "admins.button"), wrap: true}
          }
        ]
      else
        []
      end

    right_actions =
      if is_admin? do
        [
          %{
            action: %{type: :send, event: "archive_org", item: id},
            face: %{type: :icon, icon: :remove}
          }
        ]
      else
        []
      end

    %{
      item: id,
      title: build_item_title(org, locale),
      description: build_description(members),
      tags: build_tags(org),
      left_actions: left_actions,
      right_actions: right_actions
    }
  end

  defp build_item_title(%{full_name_bundle: full_name_bundle}, locale) do
    Content.TextBundleModel.text(full_name_bundle, locale)
  end

  defp build_description(members) do
    member_count = Enum.count(members)
    "#{dgettext("eyra-org", "org.members.label")}: #{member_count}"
  end

  defp build_tags(%{domains: nil}), do: []
  defp build_tags(%{domains: domains}), do: domains

  defp filter_by_query(organisations, nil), do: organisations
  defp filter_by_query(organisations, []), do: organisations

  defp filter_by_query(organisations, query) when is_list(query) do
    Enum.filter(organisations, &matches_query?(&1, query))
  end

  defp matches_query?(_organisation, []), do: true

  defp matches_query?(organisation, [word]) do
    matches_word?(organisation, word)
  end

  defp matches_query?(organisation, [word | rest]) do
    matches_word?(organisation, word) and matches_query?(organisation, rest)
  end

  defp matches_word?(_organisation, ""), do: true

  defp matches_word?(organisation, word) when is_binary(word) do
    word = String.downcase(word)

    String.contains?(String.downcase(organisation.title), word) or
      String.contains?(String.downcase(organisation.description), word)
  end
end
