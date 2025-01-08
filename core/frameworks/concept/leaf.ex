defprotocol Frameworks.Concept.Leaf do
  @spec resource_id(t) :: binary()
  def resource_id(_t)

  @spec tag(t) :: binary()
  def tag(_t)

  @spec info(t, timezone :: binary()) :: list(binary())
  def info(_t, _timezone)

  @spec status(t) :: Frameworks.Concept.Leaf.Status.t()
  def status(_t)
end

defmodule Frameworks.Concept.Leaf.Status do
  @type t :: %__MODULE__{value: :private | :concept | :online | :offline | :idle}
  defstruct [:value]

  def values(), do: [:private, :concept, :online, :offline, :idle]
end
