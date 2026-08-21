defmodule Systems.Desktop.PageBuilder do
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

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

    %{
      title: dgettext("eyra-desktop", "title"),
      active_menu_item: :desktop,
      content_items: content_items,
      next_best_action: next_best_action
    }
  end

  defp recent_items(user) do
    user
    |> Project.Public.list_owned_projects(preload: Project.Model.preload_graph(:down))
    |> Enum.flat_map(& &1.root.items)
    |> Enum.reject(&(&1.name == "Data"))
    |> Enum.sort_by(& &1.updated_at, {:desc, NaiveDateTime})
    |> Enum.take(@recent_items_limit)
  end
end
