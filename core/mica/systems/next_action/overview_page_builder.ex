defmodule Systems.NextAction.OverviewPageBuilder do
  alias Systems.NextAction

  def view_model(user, _assigns) do
    %{
      user: user,
      next_actions: NextAction.Public.list_next_actions(user),
      active_menu_item: :todo
    }
  end
end
