defmodule GreenLight.Principal do
  @moduledoc """
  The principal is used as a representation for any person / thing that can
  interact with the system.

  For more information see the [Wikipedia article on
  principals](https://en.wikipedia.org/wiki/Principal_(computer_security)/).
  """
  @type roles :: MapSet.t(atom())
  @type t :: %__MODULE__{id: integer() | nil, roles: roles}
  defstruct id: nil, roles: MapSet.new()
end
