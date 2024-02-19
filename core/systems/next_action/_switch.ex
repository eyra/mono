defmodule Systems.NextAction.Switch do
  use Frameworks.Signal.Handler

  alias Systems.{
    NextAction
  }

  def intercept({:next_action, :created}, %{user: user, action: _action, from_pid: from_pid}) do
    update(NextAction.OverviewPage, user, from_pid)
    :ok
  end

  def intercept({:next_action, :cleared}, %{
        user: user,
        action_type: _action_type,
        from_pid: from_pid
      }) do
    update(NextAction.OverviewPage, user, from_pid)
    :ok
  end

  defp update(page, %{id: id} = model, from_pid) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end
end
