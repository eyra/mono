defmodule Systems.Observatory.Switch do
  @moduledoc """
  DEPRECATED: This module is no longer needed and will be removed in a future version.

  Observatory updates should now be collected during transactions using:
    Observatory.Public.collect_update({:page, MyPage}, [id], %{model: model})

  And committed after transaction using:
    Observatory.Public.commit_updates()

  This module now acts as a pass-through for backwards compatibility.
  """

  use Frameworks.Signal.Handler

  alias Systems.{
    Observatory
  }

  def intercept({:page, page}, %{id: id, user_id: user_id} = message) do
    Observatory.Public.dispatch(page, [id, user_id], message)
    :ok
  end

  def intercept({:page, page}, %{id: id} = message) do
    Observatory.Public.dispatch(page, [id], message)
    :ok
  end

  def intercept({:embedded_live_view, live_view}, %{id: id, user_id: user_id} = message) do
    Observatory.Public.dispatch(live_view, [id, user_id], message)
    :ok
  end

  def intercept({:embedded_live_view, live_view}, %{id: id} = message) do
    Observatory.Public.dispatch(live_view, [id], message)
    :ok
  end
end
