defmodule CoreWeb.Live.Subroutes do
  def normalize(sub) do
    sub
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join()
  end

  defmacro __using__(subs) do
    for sub <- subs do
      sub = CoreWeb.Live.Subroutes.normalize(sub)
      module = String.to_atom("Elixir.CoreWeb.Live.#{sub}.Routes")

      quote do
        require unquote(module)
        unquote(module).routes()
      end
    end
  end
end
