defmodule Systems.NextAction.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    NextAction
  }

  def intercept(:next_action_created, %{user: user, action: _action}) do
    NextAction.Presenter.update(user, user, NextAction.OverviewPage)
  end

  def intercept(:next_action_cleared, %{user: user, action_type: _action_type}) do
    NextAction.Presenter.update(user, user, NextAction.OverviewPage)
  end
end
