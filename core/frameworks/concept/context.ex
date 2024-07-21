defmodule Frameworks.Concept.Context do
  defmodule Handler do
    @type scope :: :self | :parent
    @type model :: struct()
    @callback name(scope, model) :: {:ok, binary()} | {:error, atom()}
  end

  def name(scope, model, default) when is_struct(model) and is_binary(default) do
    Enum.reduce(handlers(), default, fn handler, acc ->
      case handler.name(scope, model) do
        {:ok, name} -> name
        {:error, _} -> acc
      end
    end)
  end

  defp handlers() do
    Access.get(settings(), :handlers, [])
  end

  defp settings() do
    Application.fetch_env!(:core, :naming)
  end
end
