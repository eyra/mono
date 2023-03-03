defmodule Systems.Director do
  def get(director), do: module(director, "Director")
  def public(director), do: module(director, "Public")
  def presenter(director), do: module(director, "Presenter")

  defp module(%{director: director}, name) when is_atom(director),
    do: module(Atom.to_string(director), name)

  defp module(director, name) when is_atom(director), do: module(Atom.to_string(director), name)

  defp module(director, name) do
    director = Macro.camelize(director)

    "Elixir.Systems.#{director}.#{name}"
    |> String.to_existing_atom()
  end
end
