defmodule Systems.Campaign.Director do
  @behaviour Frameworks.Promotable.Director

  alias Systems.{
    Campaign
  }

  @impl true
  defdelegate reward_value(promotable), to: Campaign.Public

  @impl true
  defdelegate validate_open(promotable, user), to: Campaign.Public
end
