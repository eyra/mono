defmodule Systems.NextAction.Presenter do
  use Frameworks.Concept.Presenter

  alias Frameworks.Signal

  alias Systems.{
    NextAction
  }

  @impl true
  def view_model(%Core.Accounts.User{} = user, NextAction.OverviewPage, _) do
    %{next_actions: NextAction.Public.list_next_actions(user)}
  end

  def update(model, %Core.Accounts.User{id: id}, page) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: model})
    model
  end
end
