defmodule Systems.Org.ArchiveModalViewBuilder do
  @moduledoc """
  ViewBuilder for the ArchiveModalView.

  Builds the view model for archived organisation management including:
  - Archived organisation list with filtering and search
  - Organisation item view models with restore buttons
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Content
  alias Systems.Org

  def view_model(_model, assigns) do
    query = Map.get(assigns, :query, nil)
    locale = Map.get(assigns, :locale, :en)
    active_filters = Map.get(assigns, :active_filters, [])

    organisations = build_archived_organisation_items(query, active_filters, locale)

    %{
      title: dgettext("eyra-admin", "archived.org.content.title"),
      search_placeholder: dgettext("eyra-org", "search.placeholder"),
      filter_labels: build_filter_labels(active_filters),
      organisations: organisations,
      org_count: length(organisations)
    }
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

  defp build_archived_organisation_items(query, active_filters, locale) do
    Org.Public.list_archived_nodes(Org.NodeModel.preload_graph(:full))
    |> filter_by_hierarchy(active_filters)
    |> Enum.map(&build_archived_organisation_item(&1, locale))
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

  defp build_archived_organisation_item(%Org.NodeModel{id: id} = org, locale) do
    %{
      item: id,
      title: build_item_title(org, locale),
      description: build_description(org),
      tags: build_tags(org),
      action_buttons: [
        %{
          action: %{type: :send, event: "restore_org", item: id},
          face: %{type: :plain, label: dgettext("eyra-admin", "restore.button"), icon: :accept}
        }
      ]
    }
  end

  defp build_item_title(%{full_name_bundle: full_name_bundle}, locale) do
    Content.TextBundleModel.text(full_name_bundle, locale)
  end

  defp build_description(org) do
    [
      members_label(org),
      admins_label(org)
    ]
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.join("  |  ")
  end

  defp members_label(%{users: users}) do
    "#{dgettext("eyra-org", "org.members.label")}: #{Enum.count(users)}"
  end

  defp admins_label(_) do
    "#{dgettext("eyra-org", "org.admins.label")}: 0"
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
