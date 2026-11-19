defmodule Systems.Desktop.PageBuilder do
  use MicaWeb, :verified_routes

  use Gettext, backend: MicaWeb.Gettext

  alias Frameworks.Utility.ViewModelBuilder
  alias Systems.NextAction
  alias Systems.Project

  @recent_items_limit 6

  def view_model(user, assigns) do
    content_items =
      user
      |> recent_items()
      |> Enum.map(&ViewModelBuilder.view_model(&1, {Project.NodePage, :item_card}, assigns))

    next_best_action = NextAction.Public.next_best_action(user)
    sections = sections(user, assigns)

    %{
      title: dgettext("eyra-desktop", "title"),
      active_menu_item: :desktop,
      content_items: content_items,
      next_best_action: next_best_action,
      sections_before_recent_items: placed(sections, :before_recent_items),
      sections_after_recent_items: placed(sections, :after_recent_items)
    }
  end

  defp recent_items(user) do
    user
    |> Project.Public.list_owned_projects(preload: Project.Model.preload_graph(:down))
    |> Enum.flat_map(& &1.root.items)
    |> Enum.reject(&Project.ItemModel.data?/1)
    |> Enum.sort_by(& &1.updated_at, {:desc, NaiveDateTime})
    |> Enum.take(@recent_items_limit)
  end

  defp sections(user, assigns) do
    for section <- section_modules(), vm = section.view_model(user, assigns), vm != nil do
      %{
        id: section.id(),
        title: section.title(),
        placement: section.placement(),
        full_list: section.full_list(vm),
        module: section,
        vm: vm
      }
    end
  end

  defp placed(sections, placement), do: Enum.filter(sections, &(&1.placement == placement))

  defp section_modules, do: Mica.SaaS.desktop_sections()
end
