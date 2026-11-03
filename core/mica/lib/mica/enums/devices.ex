defmodule Mica.Enums.Devices do
  @moduledoc """
  Defines device categories for participants.
  """
  use Mica.Enums.Base, {:devices, [:desktop, :phone, :tablet]}
end
