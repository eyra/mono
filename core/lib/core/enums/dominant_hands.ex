defmodule Core.Enums.DominantHands do
  @moduledoc """
  Defines hands used as user feature.
  """
  use Core.Enums.Base, {:hands, [:left, :right]}
end
