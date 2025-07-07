defmodule Systems.Observatory.Switch do
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
