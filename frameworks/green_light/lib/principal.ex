defprotocol GreenLight.Principal do
  @moduledoc """
  The principal is used as a representation for any person / thing that can
  interact with the system.

  For more information see the [Wikipedia article on
  principals](https://en.wikipedia.org/wiki/Principal_(computer_security)/).
  """
  @spec id(t) :: integer() | nil
  def id(_t)

  @spec roles(t) :: MapSet.t(atom())
  def roles(_t)
end
