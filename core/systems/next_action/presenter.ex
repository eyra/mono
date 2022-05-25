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
        %{current_user: user} = assigns,
        url_resolver
      ) do
    view_model(user.id, page, assigns, url_resolver)
  end

  @impl true
  def view_model(user_id, NextAction.OverviewPage, %{current_user: user}, url_resolver)
      when is_number(user_id) do
    %{
      next_actions: NextAction.Context.list_next_actions(url_resolver, user)
    }
  end

  def update(model, id, page) do
    Signal.Context.dispatch!(%{page: page}, %{
      id: id,
      model: model |> Map.put(:presenter, __MODULE__)
    })

    model
  end
end
