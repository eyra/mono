defmodule Systems.Desktop.PageBuilder do
  @moduledoc false
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.NextAction
  alias Systems.Project

  def view_model(user, _assigns) do
    content_items =
      user
      |> Project.Public.list_owned_projects(preload: Project.Model.preload_graph(:down))
      |> Enum.map(&map_project/1)

    next_best_action = NextAction.Public.next_best_action(user)

    %{
      title: dgettext("eyra-desktop", "title"),
      active_menu_item: :desktop,
      content_items: content_items,
      next_best_action: next_best_action
    }
  end

  def map_project(%{name: name, root: %{id: root_node_id}}) do
    %{
      path: ~p"/project/node/#{root_node_id}",
      title: name,
      subtitle: "<subtitle>",
      tag: %{text: "Concept", type: :success},
      level: :critical,
      image: nil,
      quick_summary: ""
    }
  end
end
