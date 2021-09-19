defmodule Core.Observatory.Switch do
  use Core.Signals.Handlers
  alias Core.Observatory

  def dispatch(:next_action_created, %{user: user} = message) do
    Observatory.local_dispatch(:next_action_created, [user.id], message)
  end

  def dispatch(:next_action_cleared, %{user: user} = message) do
    Observatory.local_dispatch(:next_action_cleared, [user.id], message)
  end
end
