defmodule Systems.Console.PageBuilder do
  use CoreWeb, :verified_routes

  alias Systems.Project
  alias Systems.NextAction

  def view_model(user, _assigns) do
    content_items =
      Project.Public.list_owned_projects(user, preload: Project.Model.preload_graph(:down))
      |> Enum.map(&map_project/1)

    next_best_action = NextAction.Public.next_best_action(user)

    %{
      content_items: content_items,
      next_best_action: next_best_action,
      active_menu_item: :console
    }
  end

  def map_project(%{
        name: name,
        root: %{
          id: root_node_id
        }
      }) do
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
