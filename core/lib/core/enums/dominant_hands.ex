defmodule Core.Enums.DominantHands do
  @moduledoc """
  Defines hands used as user feature.
  """
  use Core.Enums.Base, {:dominant_hands, [:left, :right]}
end
