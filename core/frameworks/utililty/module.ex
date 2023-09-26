defmodule Frameworks.Utility.Module do
  def get(system, name) when is_atom(system),
    do: get(Atom.to_string(system), name)

  def get(system, name) when is_binary(system) do
    system = Macro.camelize(system)

    "Elixir.Systems.#{system}.#{name}"
    |> String.to_existing_atom()
  end

  def to_system(module) when is_atom(module) do
    to_system(String.split(Atom.to_string(module), "."))
  end

  def to_system(["Elixir", "Systems", system | _]), do: system
  def to_system([system]) when is_binary(system), do: system
end
