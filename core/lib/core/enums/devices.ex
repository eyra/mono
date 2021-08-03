defmodule Core.Enums.Devices do
  @moduledoc """
  Defines device categories for participants.
  """
  use Core.Enums.Base, {:devices, [:phone, :tablet, :desktop]}
end
