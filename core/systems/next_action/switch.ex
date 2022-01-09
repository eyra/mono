defmodule Systems.NextAction.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    NextAction
  }

  def dispatch(:next_action_created, %{user: user, action: action}) do
    %{created: action}
    |> NextAction.Presenter.update(user.id, NextAction.OverviewPage)
  end

  def dispatch(:next_action_cleared, %{user: user, action_type: action_type}) do
    %{cleared: action_type}
    |> NextAction.Presenter.update(user.id, NextAction.OverviewPage)
  end
end
