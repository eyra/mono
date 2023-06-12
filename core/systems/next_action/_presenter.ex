defmodule Systems.NextAction.Presenter do
  use Systems.Presenter

  alias Frameworks.Signal

  alias Systems.{
    NextAction
  }

  @impl true
  def view_model(
        %{presenter: Systems.NextAction.Presenter},
        page,
        %{current_user: user} = assigns
      ) do
    view_model(user.id, page, assigns)
  end

  @impl true
  def view_model(user_id, NextAction.OverviewPage, %{current_user: user})
      when is_number(user_id) do
    %{
      next_actions: NextAction.Public.list_next_actions(user)
    }
  end

  def update(model, id, page) do
    Signal.Public.dispatch!(%{page: page}, %{
      id: id,
      model: model |> Map.put(:presenter, __MODULE__)
    })

    model
  end
end
