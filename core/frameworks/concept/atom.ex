defprotocol Frameworks.Concept.Atom do
  @spec resource_id(t) :: binary()
  def resource_id(_t)

  @spec tag(t) :: binary()
  def tag(_t)

  @spec info(t, timezone :: binary()) :: list(binary())
  def info(_t, _timezone)

  @spec status(t) :: Frameworks.Concept.Atom.Status.t()
  def status(_t)
end

defmodule Frameworks.Concept.Atom.Status do
  @type t :: %__MODULE__{value: :concept | :online | :offline | :idle}
  defstruct [:value]

  def values(), do: [:concept, :online, :offline, :idle]
end
