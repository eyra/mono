defmodule Frameworks.Utility.Schema do
  @callback preload_graph(any()) :: list()

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      use Ecto.Schema

      import Ecto.Changeset
      alias Core.Repo

      def preload_graph(fields) when is_list(fields) do
        fields
        |> Enum.map(&preload_graph(&1))
        |> Enum.reduce([], &Keyword.merge(&1, &2))
      end
    end
  end
end
