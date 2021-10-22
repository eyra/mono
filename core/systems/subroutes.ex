defmodule Systems.Subroutes do
  def normalize(sub) do
    sub
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join()
  end

  defmacro __using__(subs) do
    for sub <- subs do
      sub = Systems.Subroutes.normalize(sub)
      module = String.to_atom("Elixir.Systems.#{sub}.Routes")

      quote do
        require unquote(module)
        unquote(module).routes()
      end
    end
  end
end
