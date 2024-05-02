defmodule Systems.Advert.Director do
  @behaviour Frameworks.Promotable.Director

  alias Systems.{
    Advert
  }

  @impl true
  defdelegate reward_value(promotable), to: Advert.Public

  @impl true
  defdelegate validate_open(promotable, user), to: Advert.Public
end
