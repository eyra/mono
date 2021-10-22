defmodule Core.Observatory.Switch do
  use Frameworks.Signal.Handler
  alias Core.Observatory

  def dispatch(:next_action_created, %{user: user} = message) do
    Observatory.local_dispatch(:next_action_created, [user.id], message)
  end

  def dispatch(:next_action_cleared, %{user: user} = message) do
    Observatory.local_dispatch(:next_action_cleared, [user.id], message)
  end

  def dispatch(:promotion_updated, promotion) do
    Observatory.local_dispatch(:promotion_updated, [promotion.id], promotion)
  end

  def dispatch(:tool_updated, tool) do
    promotion = Core.Promotions.get!(tool.promotion_id)
    Observatory.local_dispatch(:promotion_updated, [promotion.id], promotion)
  end
end
