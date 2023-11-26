defmodule Systems.NextAction.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    NextAction
  }

  def intercept({:next_action, :created}, %{user: user, action: _action}) do
    update(NextAction.OverviewPage, user)
  end

  def intercept({:next_action, :cleared}, %{user: user, action_type: _action_type}) do
    update(NextAction.OverviewPage, user)
  end

  defp update(page, %{id: id} = model) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: model})
  end
end
