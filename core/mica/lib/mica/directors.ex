defmodule Mica.Directors do
  @moduledoc "The directors of the composition (`c:Mica.System.directors/0`)."

  @doc "Director name to module."
  def all, do: Map.new(Mica.SaaS.directors())

  @doc "The module of a director name (atom or string), or `nil`."
  def get(name) when is_atom(name), do: Map.get(all(), name)

  def get(name) when is_binary(name),
    do: Enum.find_value(all(), fn {key, module} -> Atom.to_string(key) == name && module end)

  @doc "The module of a director name. Raises for a name the composition doesn't have."
  def fetch!(name) do
    get(name) || raise ArgumentError, "no director #{inspect(name)} in the composition"
  end
end
