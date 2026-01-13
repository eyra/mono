defmodule Systems.NextAction.Switch do
  use Frameworks.Signal.Handler

  alias CoreWeb.Endpoint

  alias Systems.{
    NextAction
  }

  def intercept({:next_action, :created}, %{user: user, action: _action, from_pid: from_pid}) do
    update(NextAction.OverviewPage, user, from_pid)
    notify_menus(user)
    :ok
  end

  def intercept({:next_action, :cleared}, %{
        user: user,
        action_type: _action_type,
        from_pid: from_pid
      }) do
    update(NextAction.OverviewPage, user, from_pid)
    notify_menus(user)
    :ok
  end

  defp update(page, %{id: id} = model, from_pid) do
    Signal.Public.dispatch!({:page, page}, %{id: id, model: model, from_pid: from_pid})
  end

  defp notify_menus(%{id: user_id}) do
    Endpoint.broadcast("next_actions:#{user_id}", "next_actions_updated", %{})
  end
end
