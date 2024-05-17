defmodule Systems.Pool.OverviewPageBuilder do
  alias Systems.Pool

  def view_model(user, _assigns) do
    %{
      plugins: Pool.Public.list_directors() |> Enum.map(& &1.overview_plugin(user)),
      active_menu_item: :projects
    }
  end
end
